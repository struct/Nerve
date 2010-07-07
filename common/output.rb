## Wrapper methods for output
## Nothing here yet!

class Nerve
    def log_init
        @out.puts "Nerve ..."
    end

    def log_str(str)
        @out.puts str
    end

    def log_hit(addr, function_name)
        @out.puts "[ #{addr} #{function_name} ]"
    end

    def log_finalize
        @out.puts "... Nerve is done!"
    end
end
