#!/usr/bin/env ruby

## Nerve is a scriptable debugger built on Ragweed
## Please refer to the README file for more information

require 'rubygems'
require 'ragweed'
require 'optparse'
require 'handlers'
require 'ostruct'
require 'common/parse_config_file'
require 'common/output'
require 'common/common'
require 'common/constants'

class Nerve
    attr_accessor :ragweed, :pid, :threads, :bps, :so, :log, :event_handlers

    def initialize(pid, bp_file)
        @pid = pid
        @bps = Array.new
        @event_handlers = Hash.new
        @threads = Array.new
        @out = NERVE_OPTS[:out]
        @log = NerveLog.new(@out)

        case
            when RUBY_PLATFORM =~ WINDOWS_OS

                parse_config_file(bp_file)

                if @pid.kind_of?(String) && @pid.to_i == 0
                    @ragweed = NerveWin32.find_by_regex(/#{@pid}/)
                else
                    @ragweed = NerveWin32.new(@pid.to_i, log)
                end

                if @ragweed.nil?
                    puts "Failed to find process: #{@pid}"
                    exit
                end

                @ragweed.log_init(log)

                ## FIX: debugger32 threads returns an OStruct
                ## and pid is not always a Numeric value
                @threads = @ragweed.process.threads(true)

                if !@threads.nil?
                    @threads.each do |x|
                        #log.str("#{x.th32OwnerProcessID} => #{x.th32ThreadID})"
                    end 
                end

            when RUBY_PLATFORM =~ LINUX_OS

                if @pid.kind_of?(String) && @pid.to_i == 0
                    @pid = NerveLinux.find_by_regex(/#{@pid}/).to_i
                else
                    @pid = @pid.to_i
                end

                @so = NerveLinux.procparse(@pid)
                parse_config_file(bp_file)

                @threads = NerveLinux.threads(@pid)
                self.which_threads

                opts = {}

                if NERVE_OPTS[:fork] == true
                    opts[:fork] = true
                end

                @ragweed = NerveLinux.new(@pid, opts)

                if @ragweed.nil?
                    puts "Failed to find process: #{@pid}"
                    exit
                end

                @ragweed.log_init(log)

            when RUBY_PLATFORM =~ OSX_OS

                parse_config_file(bp_file)

                if @pid.kind_of?(String) && @pid.to_i.nil?
                    @pid = NerveOSX.find_by_regex(/#{@pid}/)
                else
                    @pid = @pid.to_i
                end

                @ragweed = NerveOSX.new(@pid)

                if @ragweed.nil?
                    puts "Failed to find process: #{@pid}"
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
        log.str("#{@bps.size} Breakpoints set ...")

        @ragweed.save_bps(@bps)

        if RUBY_PLATFORM !~ WINDOWS_OS
            @ragweed.install_bps

            if NERVE_OPTS[:fork] == true && RUBY_PLATFORM =~ LINUX_OS
                @ragweed.set_options(@ragweed::Wraptux::Ptrace::SetOptions::TRACEFORK)
            end

            @ragweed.continue
        end

        trap("INT") do
            @ragweed.uninstall_bps if RUBY_PLATFORM !~ WINDOWS_OS
            dump_stats
            log.finalize
            exit
        end

        catch(:throw) do
            @ragweed.loop
        end

        ## We shouldn't reach this but if we
        ## do we still want to see bp stats
        self.dump_stats
    end

    def set_breakpoints
        @bps.each do |o|
            log.str("Setting breakpoint: [ #{o.addr}, #{o.name} #{o.lib} ]")

            case
                when RUBY_PLATFORM =~ WINDOWS_OS
                    @ragweed.hook(o.addr, 0) do |evt, ctx, dir, args|
                        if !o.code.nil?
                            eval(o.code)
                        end

                        if dir.to_s =~ /enter/
                            analyze(o)
                        end

                        if o.hits.to_i > o.bpc.to_i and !o.bpc.nil?
                            @ragweed.breakpoint_clear(ctx.eip-1)
                            o.flag = false
                            log.str("(Breakpoint #{o.name} cleared)")
                        end
                    end

                when RUBY_PLATFORM =~ LINUX_OS, RUBY_PLATFORM =~ OSX_OS
                    @ragweed.breakpoint_set(o.addr.to_i(16), o.name, (bpl = lambda do 
                        if !o.code.nil?
                            eval(o.code)
                        end

                        analyze(o)

                        if o.hits.to_i > o.bpc.to_i
                            o.flag = false
                            r = @ragweed.get_registers
                            #@ragweed.breakpoint_clear(r[:eip]-1)
                        end
                    end ))
            end
        end
    end

    def analyze(o)
        #log.hit(o.addr, o.name)
        o.hits = o.hits.to_i + 1
    end

    ## This dump_stats differs from the one
    ## in handlers.rb. This is because its
    ## called when the user hits Ctrl+C
    def dump_stats
        log.str("Dumping breakpoint stats ...")
        @bps.each do |o|
            if o.addr != 0
                log.str("#{o.addr} - #{o.name} | #{o.hits} hit(s)")
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
    opts.banner = "\nNerve 1.4\n\n"

    opts.on("-p", "--pid PID/Name", "Attach to this pid OR process name (ex: -p 12345 | -p gcalctool)") do |o|
        NERVE_OPTS[:pid] = o
    end

    opts.on("-b", "--config_file FILE", "Read all breakpoints and handler event configurations from this file") do |o|
        NERVE_OPTS[:bp_file] = o
    end

    opts.on("-o", "--output FILE", "Dump all output to a file") do |o|
        NERVE_OPTS[:out] = File.open(o, "w") rescue (bail $!)
    end

    ## FIX: Port this feature when Ragweed is ready
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
