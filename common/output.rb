## Wrapper methods for output
## Nothing here yet!

class Nerve
    def output_init
        @out.puts "Nerve ..."
    end

    def output_finalize
        @out.puts "... Done!"
    end

    def output_str(str)
        @out.puts str
    end

    def output_hit(addr, function_name)
        ## Uncomment this line to see output for each hit
        #@out.puts "[ #{addr} #{function_name} ]"
    end
end
