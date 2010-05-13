#!/usr/bin/env ruby

## Nerve is a ragweed based, cross platform code tracer. Nerve takes a breakpoint
## file with the following format:
##
## Win32 Example: 0xXXXXXXXX, SomeLabel
## Win32 Example: kernel32!CreateFileW, Label
##
## Linux Example: 0xXXXXXXXX, function_name, ncurses.so.5.1
## Linux Example: 0xXXXXXXXX, function_name
##
## OS X  Example: 0xXXXXXXXX, function_name
##
## Chris @ Matasano.com

require 'rubygems'
require 'ragweed'
require 'optparse'
require 'handlers'
require 'common/parse_bp_file'
require 'common/output'
require 'common/common'

class Nerve
    attr_accessor :pid, :threads, :bps, :so, :out, :stats

    def initialize(pid, bp_file)
        @pid = pid
        @bps = Hash.new
        @stats = Hash.new
        @threads = Array.new
        @out = NERVE_OPTS[:out]

        case
            when RUBY_PLATFORM =~ /win(dows|32)/i
                parse_win32_bp_file(bp_file)

                if @pid.to_i == 0
                    @rw = NerveWin32.find_by_regex(/#{@pid}/)
                else
                    @rw = NerveWin32.new(@pid.to_i)
                end

                ## FIX: debugger32 threads returns an OStruct
                ## and pid is not always a Numeric value
                @threads = @rw.process.threads(true)

                if !@threads.nil?
                    @threads.each do |x|
                        #puts "#{x.th32OwnerProcessID} => #{x.th32ThreadID}"
                    end 
                end

            when RUBY_PLATFORM =~ /linux/i
                if @pid.to_i == 0
                    @pid = NerveLinux.find_by_regex(/#{@pid}/)
                else
                    @pid = @pid.to_i
                end

                @so = NerveLinux.procparse(@pid)
                parse_tux_bp_file(bp_file)

                @threads = NerveLinux.threads(@pid)
                self.which_threads
                @rw = NerveLinux.new(@pid)

            when RUBY_PLATFORM =~ /darwin/i
                parse_osx_bp_file(bp_file)

                if @pid.to_i == 0
                    @pid = NerveOSX.find_by_regex(/#{@pid}/)
                else
                    @pid = @pid.to_i
                end

                @rw = NerveOSX.new(@pid)
                @threads = @rw.threads
                self.which_threads
        end

        @rw.save_threads(@threads)
        @rw.save_stats(@stats)

        self.output_init

        @rw.attach if RUBY_PLATFORM !~ /win(dows|32)/i

        self.set_breakpoints

        @rw.save_bps(@bps)

        if RUBY_PLATFORM !~ /win(dows|32)/i
            @rw.install_bps
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

    def set_breakpoints
        @bps.each_pair do |k,v|
            output_str("Setting breakpoint: [#{k},#{v}]")
            case
                when RUBY_PLATFORM =~ /win(dows|32)/i
                    @rw.hook(k, v) do |evt, ctx, loc, args|
                        if !args.nil?
                            0.upto(args.size) do |i|
                                #puts @rw.process.read(args[i],512).from_utf16_buffer
                            end
                        end
                        analyze(v, k)
                    end
                when RUBY_PLATFORM =~ /linux/i, RUBY_PLATFORM =~ /darwin/i
                    @rw.breakpoint_set(k.to_i(16), v, (bpl = lambda do analyze(k, v); end))
            end
        end
    end

    def analyze(addr, function_name)
        output_hit(addr, function_name)
        @stats.each_pair do |k,v|
            if k == addr or k =~ /#{function_name}/
                @stats.store(k, v+=1)
            end
        end
    end

    ## We still want to dump stats if we Ctrl+C
    ## Note: this method is different then the
    ## one in handlers.rb for Win32. I need a
    ## better way of handling interrupts so we
    ## dont have to duplicate this method!
    def dump_stats
        puts "Dumping stats"
        fn = ""
        @stats.each_pair do |k,v|
            @bps.each_pair do |a,b|
                if a == k
                    fn = b
                end
            end
            if v != 0
                puts "#{k} - #{fn} | #{v} hit(s)"
            end
        end
    end
end

NERVE_OPTS = {
    :pid => 0,
    :bp_file => nil,
    :out => STDOUT
}

opts = OptionParser.new do |opts|
    opts.banner = "\nRagweed Nerve 1.0 (Use -h for help)\n\n"

    opts.on("-p", "--pid PID/Name", "Attach to this pid OR process name (ex: -p 12345 | -p gcalctool)") do |o|
        NERVE_OPTS[:pid] = o
    end

    opts.on("-b", "--breakpoint_file FILE", "Read all breakpoints from this file") do |o|
        NERVE_OPTS[:bp_file] = o
    end

    opts.on("-o", "--output FILE", "Dump all output to a file\n\n") do |o|
        NERVE_OPTS[:out] = File.open(o, "w") rescue (bail $!)
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
