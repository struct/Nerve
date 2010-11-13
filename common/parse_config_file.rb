class Nerve
    ## This could use some work
    def parse_config_file(file)
        fd = File.open(file)

        ## All the handlers a user can script
        hdlrs = %w[ on_access_violation on_alignment on_attach on_bounds on_breakpoint on_continue
                    on_create_process on_create_thread on_detach on_divide_by_zero on_exit on_exit_process
                    on_exit_thread on_fork_child on_illegalinst on_int_overflow on_invalid_disposition
                    on_invalid_handle on_load_dll on_output_debug_string on_priv_instruction on_rip on_segv
                    on_signal on_sigstop on_sigchild on_sigterm on_sigtrap on_single_step on_stack_overflow
                    on_stop on_unload_dll ]

        lines = fd.readlines
        lines.map { |x| x.chomp }

        lines.each do |tl|

            if tl.match(';') or tl.nil? then next end

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
