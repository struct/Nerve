## This example script performs in memory
## fuzzing of the Win32 Recv() function

def mutate(data, len)
    s = rand(len-1)
    data[0..s].to_s + rand(255).chr + data[s+1..-1].to_s
end

if dir.to_s =~ /enter/
    @addr = @rw.process.read32(ctx.esp+8)
    @maxlen = @rw.process.read32(ctx.esp+12)
else
    len = ctx.eax
    if len != 0xffffffff

        log_str "--> Read #{len.to_s(16)} to #{@addr.to_s(16)}"

        data = @rw.process.read(@addr, len)
        @rw.process.write(@addr, mutate(data, len))
    end
end
