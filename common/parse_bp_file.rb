## These methods parse breakpoint files
## Each platform has (or may have in the
## future) subtle differences between them

class Nerve
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
end
