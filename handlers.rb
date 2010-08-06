## You can use the methods within these classes to
## extend the basic Ragweed signal/event handlers.
## Sometimes you may need to call super if the handler
## is also implemented by Ragweed.

require 'common/constants'

case
when RUBY_PLATFORM =~ WINDOWS_OS
    class NerveWin32 < Ragweed::Debugger32

        attr_accessor :log, :pid, :bps, :threads, :event_handlers

        def initialize(pid)
            @pid = pid
            super
        end

        def log_init(l)
            @log = l
        end

        def save_bps(b) @bps = b; end
        def save_threads(t) @threads = t; end
        def save_handlers(h) @event_handlers = h end

        def dump_stats(ev)
            a = self.context(ev)
            log.str a.dump
            log.str "Dumping stats"
            log.str "Pid is #{ev.pid}"
            log.str "Tid is #{ev.tid}"

            bps.each do |o|
                log.str "#{o.addr} - #{o.name} | #{o.hits} hit(s)"
            end
        end

        def on_access_violation(ev)
            dump_stats(ev)
            log.str "Access violation!"
        end

        def on_exit_process(ev)
            dump_stats(ev)
            super
        end

        def on_load_dll(ev)     super   end
        def on_breakpoint(ev)   super   end
        def on_single_step(ev)  super   end
        def on_create_process(ev)       end
        def on_create_thread(ev)        end
        def on_exit_thread(ev)          end
        def on_output_debug_string(ev)  end
        def on_rip(ev)                  end
        def on_unload_dll(ev)           end
        def on_alignment(ev)            end
        def on_bounds(ev)               end
        def on_divide_by_zero(ev)       end
        def on_int_overflow(ev)         end
        def on_invalid_handle(ev)       end
        def on_priv_instruction(ev)     end
        def on_stack_overflow(ev)       end
        def on_invalid_disposition(ev)  end
    end

when RUBY_PLATFORM =~ LINUX_OS
    class NerveLinux < Ragweed::Debuggertux

        attr_accessor :log, :pid, :bps, :threads

        def initialize(pid, opts)
            @pid = pid
            super
        end

        def log_init(l)
            @log = l
        end

        def save_bps(b) @bps = b; end
        def save_threads(t) @threads = t; end
        def save_handlers(h) @event_handlers = h end

        def dump_stats
            log.str "Dumping stats"
            bps.each do |o|
                log.str "#{o.addr} - #{o.name} | #{o.hits} hit(s)"
            end
        end

        def on_fork_child(pid)
            @pid = pid
            log.str "Parent process forked a child with pid #{pid}"
        end

        def on_sigterm
            log.str "Process Terminated!"
            self.print_regs
            dump_stats
            exit
        end
    
        def on_segv
            log.str "Segmentation Fault!"
            self.print_registers
            dump_stats
            exit
        end

        def on_breakpoint
            super
        end

        def on_exit
            log.str "Process Exited!"
            dump_stats
        end

        def on_illegalinst
            log.str "Illegal Instruction!"
            dump_stats
        end

        def on_attach
            super
        end

        def on_detach
            super
        end

        def on_sigtrap
            super
        end

        def on_continue
            super
        end

        def on_sigstop
            super
        end

        def on_signal
            super
        end

        def on_single_step
            super
        end
    end

when RUBY_PLATFORM =~ OSX_OS
    class NerveOSX < Ragweed::Debuggerosx

        attr_accessor :log, :pid, :bps, :threads

        def initialize(pid)
            @pid = pid
            super
        end

        def log_init(l)
            @log = l
        end

        def save_bps(b) @bps = b; end
        def save_threads(t) @threads = t; end
        def save_handlers(h) @event_handlers = h end

        def dump_stats
            log.str "Dumping stats"
            bps.each do |o|
                log.str "#{o.addr} - #{o.name} | #{o.hits} hit(s)"
            end
        end

        def on_sigterm
            log.str "Process Terminated!"
            self.print_regs
            dump_stats
            exit
        end
    
        def on_breakpoint(thread)
            super
        end
  
        def on_exit
          log.str "Process Exited!"
          dump_stats
          super
        end

        def on_single_step
            super
        end

        def on_signal(signal)
            super
        end

        def on_stop(signal)
            super
        end

        def on_continue
            super
        end

        def on_attach
            super
        end

        def on_detach
            super
        end
    end
end
