## You can use these classes to extend the basic
## Ragweed signal handlers. Please see the Ragweed
## code to see what you should name them!

require 'common/constants'

case
when RUBY_PLATFORM =~ WINDOWS_OS
    class NerveWin32 < Ragweed::Debugger32
        def initialize(pid)
            @pid = pid
            super
        end

        def save_bps(b) @bps = b; end
        def save_threads(t) @threads = t; end

        def dump_stats(ev)
            a = self.context(ev)
            puts a.dump
            puts "Dumping stats"
            puts "Pid is #{ev.pid}"
            puts "Tid is #{ev.tid}"

            @bps.each do |o|
                puts "#{o.addr} - #{o.name} | #{o.hits} hit(s)"
            end
        end

        def on_load_dll(ev)
            super
        end

        def on_exit_process(ev)
            dump_stats(ev)
            super
        end

        def on_access_violation(ev)
            dump_stats(ev)
            puts "Access violation!"
        end
    end

when RUBY_PLATFORM =~ LINUX_OS
    class NerveLinux < Ragweed::Debuggertux
        def initialize(pid, opts)
            @pid = pid
            super
        end

        def save_bps(b) @bps = b; end
        def save_threads(t) @threads = t; end

        def dump_stats
            puts "Dumping stats"
            @bps.each do |o|
                puts "#{o.addr} - #{o.name} | #{o.hits} hit(s)"
            end
        end

        def on_fork_child(pid)
            @pid = pid
        end

        def on_sigterm
            puts "Process Terminated!"
            self.print_regs
            dump_stats
            exit
        end
    
        def on_segv
            puts "Segmentation Fault!"
            self.print_registers
            dump_stats
            exit
        end

        def on_breakpoint
            super
        end
    end

when RUBY_PLATFORM =~ OSX_OS
    class NerveOSX < Ragweed::Debuggerosx
        def initialize(pid)
            @pid = pid
            super
        end

        def save_bps(b) @bps = b; end
        def save_threads(t) @threads = t; end

        def dump_stats
            puts "Dumping stats"
            @bps.each do |o|
                puts "#{o.addr} - #{o.name} | #{o.hits} hit(s)"
            end
        end

        def on_sigterm
            puts "Process Terminated!"
            self.print_regs
            dump_stats
            exit
        end
    
        def on_segv
            puts "Segmentation Fault!"
            self.print_regs
            dump_stats
            exit
        end

        def on_breakpoint
            super
        end
    end
end
