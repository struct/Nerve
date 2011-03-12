#!/usr/bin/env ruby

$: << File.dirname('..')

require 'rubygems'
require 'ragweed'
require 'optparse'
require 'handlers'
require 'ostruct'
require 'common/parse_config_file'
require 'common/output'
require 'common/common'
require 'common/constants'
require 'common/helpers'

class Nerve
    attr_accessor :opts, :ragweed, :pid, :threads, :breakpoints, :so, :log, :event_handlers, :exec_proc

    def initialize(opts)
        @opts = opts
        @pid = opts[:pid]
        @breakpoints = Array.new
        @exec_proc = OpenStruct.new
        @event_handlers = Hash.new
        @threads = Array.new
        @out = opts[:out]
        @log = NerveLog.new(@out)

        parse_exec_proc(opts[:ep_file]) if !opts[:ep_file].nil?

        launch_process if !exec_proc.target.nil?

        case
            when RUBY_PLATFORM =~ WINDOWS_OS

                parse_config_file(opts[:bp_file])

                if pid.kind_of?(String) and pid.to_i == 0
                    while @ragweed.nil?
                        @ragweed = NerveWin32.find_by_regex(/#{pid}/)
                    end
                else
                    @ragweed = NerveWin32.new(pid.to_i)
                end

                if @ragweed.nil?
                    puts "Failed to find process: #{pid}"
                    exit
                end

                @ragweed.log_init(log)

                ## TODO: debugger32 threads returns an OStruct
                ## and pid is not always a Numeric value
                @threads = @ragweed.process.threads(true)

                if !@threads.nil?
                    @threads.each do |x|
                        #log.str "#{x.th32OwnerProcessID} => #{x.th32ThreadID})"
                    end 
                end

            when RUBY_PLATFORM =~ LINUX_OS
                if pid.kind_of?(String) and pid.to_i == 0
                    @pid = NerveLinux.find_by_regex(/#{pid}/).to_i
                else
                    @pid = pid.to_i
                end

                @so = NerveLinux.shared_libraries(pid)
                
                parse_config_file(opts[:bp_file])

                @threads = NerveLinux.threads(pid)
                self.which_threads

                lo = {}

                if opts[:fork] == true
                    lo[:fork] = true
                end

                @ragweed = NerveLinux.new(pid, lo)

                if @ragweed.nil?
                    puts "Failed to find process: #{pid}"
                    exit
                end

                @ragweed.log_init(log)

            when RUBY_PLATFORM =~ OSX_OS

                parse_config_file(opts[:bp_file])

                if pid.kind_of?(String) and pid.to_i.nil?
                    @pid = NerveOSX.find_by_regex(/#{pid}/)
                else
                    @pid = pid.to_i
                end

                @ragweed = NerveOSX.new(pid)

                if @ragweed.nil?
                    puts "Failed to find process: #{pid}"
                    exit
                end

                @ragweed.log_init(log)
                @threads = @ragweed.threads
                self.which_threads
        end

        @ragweed.save_threads(@threads)
        @ragweed.save_handlers(@event_handlers)

        @ragweed.attach if RUBY_PLATFORM !~ WINDOWS_OS

        self.set_breakpoints

        bp_count = 0
        @breakpoints.each {|b| bp_count+=1 if b.flag == true }

        log.str "#{bp_count} Breakpoints set ..."

        @ragweed.save_breakpoints(@breakpoints)

        if RUBY_PLATFORM !~ WINDOWS_OS
            @ragweed.install_bps

            if opts[:fork] == true and RUBY_PLATFORM =~ LINUX_OS
                @ragweed.set_options(Ragweed::Wraptux::Ptrace::SetOptions::TRACEFORK)
            end

            @ragweed.continue
        end

        trap("INT") do
            @ragweed.uninstall_bps if RUBY_PLATFORM !~ WINDOWS_OS
            @ragweed.dump_stats
            log.finalize
            exit
        end

        catch(:throw) { @ragweed.loop }

        ## This is commented out because the stats should
        ## have been dumped already if we reached this
        ## point through some debugger event
        #@ragweed.dump_stats
    end

    def set_breakpoints
        @breakpoints.each do |bp|

            if bp.addr.nil?
                bp.flag = false
                next
            end
 
            log.str "Setting breakpoint: #{bp.addr}, #{bp.name} #{bp.lib}"

            case
                when RUBY_PLATFORM =~ WINDOWS_OS
                    if opts[:hook] == true
                        @ragweed.hook(bp.addr, bp.nargs) do |evt, ctx, dir, args|
                            eval(bp.code) if !bp.code.nil?

                            bp.hits += 1 if dir.to_s =~ /enter/

                            check_bp_max(bp, ctx)
                        end
                    else
                        @ragweed.breakpoint_set(bp.addr) do |evt, ctx|
                            eval(bp.code) if !bp.code.nil?

                            bp.hits += 1

                            check_bp_max(bp, ctx)
                        end
                    end

                when RUBY_PLATFORM =~ LINUX_OS, RUBY_PLATFORM =~ OSX_OS
                    @ragweed.breakpoint_set(bp.addr.to_i(16), bp.name, (bpl = proc do 
                        eval(bp.code) if !bp.code.nil?

                        bp.hits += 1

                        if !bp.bpc.nil? and bp.hits.to_i >= bp.bpc.to_i
                            bp.flag = false
                            regs = @ragweed.get_registers
                            @ragweed.breakpoint_clear(regs.eip-1)
                        end
                    end ))
            end
        end
    end

    def check_bp_max(bp, ctx)
        if !bp.bpc.nil? and bp.hits.to_i >= bp.bpc.to_i
           r = @ragweed.breakpoint_clear(ctx.eip-1)
           bp.flag = false
        end
    end

    def launch_process
        if RUBY_PLATFORM =~ WINDOWS_OS
            exec_proc.env.each_pair { |k,v| ENV[k] = v }
            proc_info = Ragweed::Wrap32::ProcessInfo.new
            startup_info = Ragweed::Wrap32::StartupInfo.new
            target = FFI::MemoryPointer.from_string("#{exec_proc.target} #{exec_proc.args}")
            ## TODO: Port -f option to CreateProcess. We can pass along DEBUG_PROCESS
            r = Ragweed::Wrap32::Win::CreateProcessA(nil, target, nil, nil, false, 0x0, nil, nil, startup_info, proc_info)
            @pid = proc_info[:pid] if r != 0
        else
            @pid = fork do
                exec_proc.env.each_pair { |k,v| ENV[k] = v }
                exec("#{exec_proc.target} #{exec_proc.args}")
            end
        end
    end
end

NERVE_OPTS = {
    :pid => nil,
    :pe_file => nil,
    :bp_file => nil,
    :out => STDOUT,
    :hook => false,
    :fork => false
}

opts = OptionParser.new do |opts|
    opts.banner = "\nNerve #{NERVE_VERSION} | Chris Rohlf 2009-2011\n\n"

    opts.on("-p", "--pid PID/Name", "Attach to this pid OR process name (ex: -p 12345 | -p gcalctool | -p notepad.exe)") do |o|
        NERVE_OPTS[:pid] = o
    end

    opts.on("-x", "--exec_proc FILE", "Launch a process according to the configuration found in this file") do |o|
        NERVE_OPTS[:ep_file] = o
    end

    opts.on("-b", "--config_file FILE", "Read all breakpoints and handler event configurations from this file") do |o|
        NERVE_OPTS[:bp_file] = o
    end

    opts.on("-o", "--output FILE", "Dump all output to a file (default is STDOUT)") do |o|
        NERVE_OPTS[:out] = File.open(o, "w") rescue (bail $!)
    end

    ## FIX: When hook() is available on all three
    ## platforms this conditional should go away
    if RUBY_PLATFORM =~ WINDOWS_OS
        opts.on("-k", "--hook", "Automatically hook the entry and exit of a function call (Windows only)") do |o|
            NERVE_OPTS[:hook] = true
        end
    end

    ## FIX: Port this feature when Ragweed is ready
    if RUBY_PLATFORM =~ LINUX_OS
        opts.on("-f", "Optional flag indicates whether or not to trace forked child processes (Linux only)") do |o|
            NERVE_OPTS[:fork] = true
        end
    end
end

opts.parse!(ARGV) rescue (STDERR.puts $!; exit 1)

if NERVE_OPTS[:pid] == nil
    puts opts.banner
#    exit
end

## Never is still under heavy development
## we want to see gross errors for now
#begin
    Nerve.new(NERVE_OPTS)
#rescue
#end
