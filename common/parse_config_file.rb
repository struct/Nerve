class Nerve
    def parse_exec_proc(file)

        return if file.nil?

        fd = File.open(file)
        proc_control = %w[ target args env ]

        lines = fd.readlines
        lines.map { |x| x.chomp }

        exec_proc.args = Array.new
        exec_proc.env = Hash.new

        lines.each do |tl|
            if tl[0].chr == ';' or tl.nil? then next end

            k,v,l = tl.split(':')

            if k.match(/target/)
                ## Dirty little hack if a : is used
                ## in the target path (C:\Windows...)
                if !l.nil?
                    v = "#{v}:#{l}"
                end
                v.gsub!(/[\n]+/, "")
                v.gsub!(/[\s]+/, "")
                exec_proc.target = v
            end

            if k.match(/args/)
                v.gsub!(/[\n]+/, "")
                exec_proc.args = v
            end

            if k.match(/env/)
                v.gsub!(/[\n]+/, "")
                k,v = v.split(/=/)
                k.gsub!(/[\s]+/, "")
                exec_proc.env.store(k,v)
            end
        end
    end

    def parse_config_file(file)

        return if file.nil?

        fd = File.open(file)

        ## All the handlers a user can script
        ## There is no specific order to this
        hdlrs = %w[ on_access_violation on_alignment on_attach on_bounds on_breakpoint on_continue
                    on_create_process on_create_thread on_detach on_divide_by_zero on_exit on_exit_process
                    on_exit_thread on_fork_child on_illegalinst on_int_overflow on_invalid_disposition
                    on_invalid_handle on_load_dll on_output_debug_string on_priv_instruction on_rip on_segv
                    on_signal on_sigstop on_sigchild on_sigterm on_sigtrap on_single_step on_stack_overflow
                    on_stop on_unload_dll on_iot_trap on_guard_page ]

        lines = fd.readlines
        lines.map { |x| x.chomp }

        lines.each do |tl|

            if tl[0].chr == ';' or tl.nil? then next end

            hdlrs.each do |l|
              if tl.match(/#{l}/)
                i,p = tl.split("=")
                i.gsub!(/[\s\n]+/, "")
                p.gsub!(/[\s\n]+/, "")
                p = File.read(p)
                event_handlers.store(i,p)
                next
              end
            end

            bp = OpenStruct.new
            bp.base = 0
			bp.flag = true
			bp.hits = 0
            bp.hook = false
            bp.bpc = nil
            bp.nargs = 0

            r = tl.split(",")

            if r.size < 2 then next end

            r.each do |e|
                if e.match(/bp=/)
                    addr = e.split("bp=").last
                    bp.addr = addr.gsub(/[\s\n]+/, "")
                end

                if e.match(/name=/)
                    name = e.split("name=").last
                    bp.name = name.gsub(/[\s\n]+/, "")
                end

                ## Win32 only until ragweed supports it
                if e.match(/hook=/)
                    hook = e.split("hook=").last
                    bp.hook = true if hook.gsub(/[\s\n]+/, "") =~ /true/
                end

                if e.match(/bpc=/)
                    bpc = e.split("bpc=").last
                    bp.bpc = bpc.to_i
                end

                if e.match(/bpc=/)
                    nargs = e.split("nargs=").last
                    bp.nargs = nargs.to_i
                end

                if e.match(/code=/)
                    code = e.split("code=").last
                    c = code.gsub(/[\s\n]+/, "")
                    r = File.read(c)
                    bp.code = r
                end

                if e.match(/lib=/)
                    lib = e.split("lib=").last
                    bp.lib = lib.gsub(/[\s\n]+/, "")

                    ## TODO - addr must already be parsed
                    ## for this to work correctly
                    if RUBY_PLATFORM =~ LINUX_OS
                        so.each_pair do |k,v|
                            if v =~ /#{bp.lib}/
                                bp.base = k
                            end
                        end
                    end
                end
            end

            if bp.base != 0
                bp.addr = bp.base.to_i(16)+bp.addr.to_i(16)
                bp.addr = sprintf("0x0%x", bp.addr)
            end

            bp.hits = 0
            breakpoints.push(bp)
        end
    end
end
