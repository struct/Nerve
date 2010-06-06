class Nerve
    ## This could use some work
    def parse_breakpoint_file(file)
        fd = File.open(file)
        lines = fd.readlines
        lines.map { |x| x.chomp }

        lines.each do |tl|

            if tl.match(';') or tl.nil? then next end

            o = OpenStruct.new
            o.base = 0

            r = tl.split(",")

            if r.count < 2 then next end

            r.each do |e|

                if e.match(/bp=/)
                    addr = e.split("bp=").last
                    o.addr = addr.gsub(/[\s\n]+/, "")
                end

                if e.match(/name=/)
                    name = e.split("name=").last
                    o.name = name.gsub(/[\s\n]+/, "")
                end

                if e.match(/bpc=/)
                    bpc = e.split("bpc=").last
                    o.bpc = bpc.to_i
                end

                if e.match(/lib=/)
                    lib = e.split("lib=").last
                    o.lib = lib.gsub(/[\s\n]+/, "")

                    ## TODO - addr must already be parsed
                    ## for this to work correctly
                    if RUBY_PLATFORM =~ /linux/i
                        @so.each_pair do |k,v|
                            if v =~ /#{o.lib}/
                                o.base = k
                            end
                        end
                    end
                end
            end

            if o.base != 0
                o.addr = o.base.to_i(16)+o.addr.to_i(16)
                o.addr = sprintf("0x0%x", o.addr)
            end

            o.hits = 0
            @bps.push(o)
        end
end

## This is the old code that parses the older
## simplistic breakpoint file format.
## Not ready to trash it just yet
=begin
    ## Parse Win32 breakpoint file
    def parse_win32_bp_file(file)
        fd = File.open(file)
        lines = fd.readlines
        lines.map { |x| x.chomp }
        i = 0
        lines.each do |tl|
            addr, name, = tl.split(",", 3)
            if addr =~ /;/ or name.nil? then next end
            addr.gsub!(/[\s\n]+/, "")
            name.gsub!(/[\s\n]+/, "")
            @bps.store(addr, name)
            @stats.store(addr, 0)
        end
    end

    ## Parse OS X breakpoint file
    def parse_osx_bp_file(file)
        fd = File.open(file)
        lines = fd.readlines
        lines.map { |x| x.chomp }
        lines.each do |tl|
            addr, fn, lib = tl.split(",", 2)
            if addr =~ /;/ or fn.nil? then next end
            fn.gsub!(/[\s\n]+/, "")
            @bps.store(addr, fn)
            @stats.store(addr, 0)
        end
    end

    ## Parse Linux breakpoint file
    def parse_tux_bp_file(file)
        fd = File.open(file)
        lines = fd.readlines
        lines.map { |x| x.chomp }
        lines.each do |tl|
            addr, fn, lib = tl.split(",", 3)
            if addr =~ /;/ or fn.nil? then next end
            fn.gsub!(/[\s\n]+/, "")

            if lib == nil
                @bps.store(addr, fn)
                @stats.store(addr, 0)
            else
                lib.gsub!(/[\s\n]+/, "")
                @so.each_pair do |k,v|
                    if v =~ /#{lib}/
                        k = k.to_i(16)+addr.to_i(16)
                        k = sprintf("0x0%x", k)
                        @bps.store(k, "#{fn}@#{lib}")
                        @stats.store(k, 0)
                    end
                end
            end
        end
    end
=end
end
