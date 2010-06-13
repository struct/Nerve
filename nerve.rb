#!/usr/bin/env ruby

## Nerve is a ragweed based, cross platform code tracer. Nerve takes a breakpoint
## file with the following format:
##
## Win32 Breakpoint Configuration
## break=<Address or Function!Library>, name=<Function Name>, bpc=<Breakpoint Count (Optional)>
## break=0x12345678, name=SomeFunction, bpc=2
## break=kernel32!CreateFileW, name=SomeFunction
##
## Linux Breakpoint Configuration
## break=<Address>, name=<Function Name>, lib=<LibraryName (optional)>, bpc=<Breakpoint Count (Optional)>
## break=0x12345678, name=function_name, lib=ncurses.so.5.1, bpc=1
## break=0x12345678, name=function_name
##
## OS X  Breakpoint Configuration: 
## break=<Address>, name=<Function Name>, bpc=<Breakpoint Count (Optional)>
## break=0x12345678, name=function_name, bpc=6
##
## Chris @ Matasano.com

require 'rubygems'
require 'ragweed'
require 'optparse'
require 'handlers'
require 'ostruct'
require 'common/parse_bp_file'
require 'common/output'
require 'common/common'

class Nerve
    attr_accessor :pid, :threads, :bps, :so, :out, :stats

    def initialize(pid, bp_file)
        @pid = pid
        @bps = Array.new
        @threads = Array.new
        @out = NERVE_OPTS[:out]

        case
            when RUBY_PLATFORM =~ /win(dows|32)/i

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
                        #puts "#{x.th32OwnerProcessID} => #{x.th32ThreadID}"
                    end 
                end

            when RUBY_PLATFORM =~ /linux/i

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

            when RUBY_PLATFORM =~ /darwin/i

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

        self.output_init

        @rw.attach if RUBY_PLATFORM !~ /win(dows|32)/i

        self.set_breakpoints

        @rw.save_bps(@bps)

        if RUBY_PLATFORM !~ /win(dows|32)/i
            @rw.install_bps

            if NERVE_OPTS[:fork] == true && RUBY_PLATFORM =~ /linux/i
                @rw.set_options(Ragweed::Wraptux::Ptrace::SetOptions::TRACEFORK)
            end

            @rw.continue
        end

        trap("INT") do
            @rw.uninstall_bps if RUBY_PLATFORM !~ /win(dows|32)/i
            dump_stats
            output_finalize
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
            output_str("Setting breakpoint: [ #{o.addr}, #{o.name} #{o.lib}]")
            
            case
                when RUBY_PLATFORM =~ /win(dows|32)/i
                    @rw.hook(o.addr, o.name) do |evt, ctx, loc, args|
                        if !args.nil?
                            0.upto(args.size) do |i|
                                #puts @rw.process.read(args[i],512).from_utf16_buffer
                            end
                        end
                        analyze(o)
                    end
                when RUBY_PLATFORM =~ /linux/i, RUBY_PLATFORM =~ /darwin/i
                    @rw.breakpoint_set(o.addr.to_i(16), o.name, (bpl = lambda do analyze(o); end))
            end
        end
    end

    def analyze(o)
        output_hit(o.addr, o.name)
        o.hits = o.hits.to_i + 1

        if o.hits.to_i > o.bpc.to_i
            o.flag = false
            ## XXX Uninstall this breakpoint!
        end
    end

    ## We still want to dump stats if we Ctrl+C
    ## Note: this method is different then the
    ## one in handlers.rb for Win32. I need a
    ## better way of handling interrupts so we
    ## dont have to duplicate this method!
    def dump_stats
        puts "Dumping breakpoint stats ..."
        @bps.each do |o|
            if o.addr != 0
                output_str("#{o.addr} - #{o.name} | #{o.hits} hit(s)")
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
    opts.banner = "\nRagweed Nerve 1.1 (Use -h for help)\n\n"

    opts.on("-p", "--pid PID/Name", "Attach to this pid OR process name (ex: -p 12345 | -p gcalctool)") do |o|
        NERVE_OPTS[:pid] = o
    end

    opts.on("-b", "--breakpoint_file FILE", "Read all breakpoints from this file") do |o|
        NERVE_OPTS[:bp_file] = o
    end

    opts.on("-o", "--output FILE", "Dump all output to a file") do |o|
        NERVE_OPTS[:out] = File.open(o, "w") rescue (bail $!)
    end

    opts.on("-f", "Optional flag indicates whether or not to trace forked child processes (Linux only)\n\n") do |o|
        NERVE_OPTS[:fork] = true
    end
end

opts.parse!(ARGV) rescue (STDERR.puts $!; exit 1)

if NERVE_OPTS[:pid] == nil || NERVE_OPTS[:bp_file] == nil
    puts opts.banner
    exit
end

begin
    w = Nerve.new(NERVE_OPTS[:pid], NERVE_OPTS[:bp_file])
rescue; end
