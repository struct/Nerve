#!/usr/bin/env ruby

## Nerve is a cross platform debugger designed for security researchers. It
## is based on Ragweed (http://github.com/tduehr/ragweed)
##
## Please refer to the README file for more information
##
## Nerve is developed by:
## Chris @ Matasano.com
## AlexRad

require 'rubygems'
require 'ragweed'
require 'optparse'
require 'handlers'
require 'ostruct'
require 'common/parse_bp_file'
require 'common/output'
require 'common/common'
require 'common/constants'

class Nerve
    attr_accessor :pid, :threads, :bps, :so, :out, :stats

    def initialize(pid, bp_file)
        @pid = pid
        @bps = Array.new
        @threads = Array.new
        @out = NERVE_OPTS[:out]

        self.log_init

        case
            when RUBY_PLATFORM =~ WINDOWS_OS

                parse_breakpoint_file(bp_file)

                if @pid.kind_of?(String) && @pid.to_i == 0
                    @rw = NerveWin32.find_by_regex(/#{@pid}/)
                else
                    @rw = NerveWin32.new(@pid.to_i)
                end

                self.check_pid

                ## FIX: debugger32 threads returns an OStruct
                ## and pid is not always a Numeric value
                @threads = @rw.process.threads(true)

                if !@threads.nil?
                    @threads.each do |x|
                        #log_str("#{x.th32OwnerProcessID} => #{x.th32ThreadID})"
                    end 
                end

            when RUBY_PLATFORM =~ LINUX_OS

                if @pid.kind_of?(String) && @pid.to_i == 0
                    @pid = NerveLinux.find_by_regex(/#{@pid}/)
                else
                    @pid = @pid.to_i
                end

                self.check_pid

                @so = NerveLinux.procparse(@pid)
                parse_breakpoint_file(bp_file)

                @threads = NerveLinux.threads(@pid)
                self.which_threads

                opts = {}

                if NERVE_OPTS[:fork] == true
                    opts[:fork] = true
                end

                @rw = NerveLinux.new(@pid, opts)

            when RUBY_PLATFORM =~ OSX_OS

                parse_breakpoint_file(bp_file)

                if @pid.kind_of?(String) && @pid.to_i.nil?
                    @pid = NerveOSX.find_by_regex(/#{@pid}/)
                else
                    @pid = @pid.to_i
                end

                self.check_pid

                @rw = NerveOSX.new(@pid)
                @threads = @rw.threads
                self.which_threads
        end

        @rw.save_threads(@threads)

        @rw.attach if RUBY_PLATFORM !~ WINDOWS_OS

        self.set_breakpoints
        log_str("Breakpoints set ...")

        @rw.save_bps(@bps)

        if RUBY_PLATFORM !~ WINDOWS_OS
            @rw.install_bps

            if NERVE_OPTS[:fork] == true && RUBY_PLATFORM =~ LINUX_OS
                @rw.set_options(Ragweed::Wraptux::Ptrace::SetOptions::TRACEFORK)
            end

            @rw.continue
        end

        trap("INT") do
            @rw.uninstall_bps if RUBY_PLATFORM !~ WINDOWS_OS
            dump_stats
            log_finalize
            exit
        end

        catch(:throw) do
            @rw.loop
        end

        self.dump_stats
    end

    def check_pid
        if @pid.nil?
            puts "Need a valid PID!"
        end
    end

    def set_breakpoints
        @bps.each do |o|
            #log_str("Setting breakpoint: [ #{o.addr}, #{o.name} #{o.lib}]")

            case
                when RUBY_PLATFORM =~ WINDOWS_OS
                    @rw.hook(o.addr, 0) do |evt, ctx, dir, args|
                        ## Call the ruby code associated with this breakpoint
                        if !o.code.nil?
                            eval(o.code)
                        end

                        if dir.to_s =~ /enter/
                            analyze(o)
                        end

                        if o.hits.to_i > o.bpc.to_i and !o.bpc.nil?
                            o.flag = false
                            @rw.breakpoint_clear(ctx.eip-1)
                            log_str("(Breakpoint #{o.name} cleared)")
                        end
                    end

                when RUBY_PLATFORM =~ LINUX_OS, RUBY_PLATFORM =~ OSX_OS
                    @rw.breakpoint_set(o.addr.to_i(16), o.name, (bpl = lambda do 
                        if !o.code.nil?
                            eval(o.code)
                        end

                        analyze(o)

                        if o.hits.to_i > o.bpc.to_i
                            o.flag = false
                            r = @rw.get_registers
                            #@rw.breakpoint_clear(r[:eip]-1)
                        end
                    end ))
            end
        end
    end

    def analyze(o)
        #log_hit(o.addr, o.name)
        o.hits = o.hits.to_i + 1
    end

    ## We still want to dump stats if we Ctrl+C
    ## Note: this method is different then the
    ## one in handlers.rb for Win32. Fortunately
    ## there is also a on_exit_process which will
    ## dump the context for us.
    ## We need a better way of handling interrupts
    ## so we dont have to duplicate this method!
    def dump_stats
        log_str("Dumping breakpoint stats ...")
        @bps.each do |o|
            if o.addr != 0
                log_str("#{o.addr} - #{o.name} | #{o.hits} hit(s)")
            end
        end
    end
end

NERVE_OPTS = {
    :pid => 0,
    :bp_file => nil,
    :out => STDOUT,
    :fork => false
}

opts = OptionParser.new do |opts|
    opts.banner = "\nRagweed Nerve 1.2 (Use -h for help)\n\n"

    opts.on("-p", "--pid PID/Name", "Attach to this pid OR process name (ex: -p 12345 | -p gcalctool)") do |o|
        NERVE_OPTS[:pid] = o
    end

    opts.on("-b", "--breakpoint_file FILE", "Read all breakpoints from this file") do |o|
        NERVE_OPTS[:bp_file] = o
    end

    opts.on("-o", "--output FILE", "Dump all output to a file") do |o|
        NERVE_OPTS[:out] = File.open(o, "w") rescue (bail $!)
    end

    if RUBY_PLATFORM =~ LINUX_OS
        opts.on("-f", "Optional flag indicates whether or not to trace forked child processes (Linux only)\n\n") do |o|
            NERVE_OPTS[:fork] = true
        end
    end
end

opts.parse!(ARGV) rescue (STDERR.puts $!; exit 1)

if NERVE_OPTS[:pid] == nil || NERVE_OPTS[:bp_file] == nil
    puts opts.banner
    exit
end

## Never is still under heavy development
## we want to see gross errors for now
#begin
    w = Nerve.new(NERVE_OPTS[:pid], NERVE_OPTS[:bp_file])
#rescue; end
