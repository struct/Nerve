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
			o.flag = true
			o.hits = 0

            r = tl.split(",")

            if r.size < 2 then next end

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

                if e.match(/code=/)
                    code = e.split("code=").last
                    c = code.gsub(/[\s\n]+/, "")
                    r = File.read(c)
                    o.code = r
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
end
