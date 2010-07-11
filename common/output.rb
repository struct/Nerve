## Wrapper methods for output
## Nothing here yet!

class NerveLog
    def initialize(out)
        @out = out
    end

    def str(s)
        @out.puts s
    end

    def hit(addr, function_name)
        @out.puts "[ #{addr} #{function_name} ]"
    end

    def finalize
        @out.puts "...Nerve is done!"
    end
end
