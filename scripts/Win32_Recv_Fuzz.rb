## In memory recv() fuzzing

def mutate(data, len)
    s = rand(len-1)
	data[s] = rand(255).to_s.pack('i')
	return data
end

if dir.to_s =~ /enter/
    @recv_buf = @ragweed.process.read32(ctx.esp+8)
    @maxlen = @ragweed.process.read32(ctx.esp+12)
else
    len = ctx.eax

    if len != 0xffffffff

        log_str "--> Read #{len.to_s(16)} to #{@recv_buf.to_s(16)}"

        data = @ragweed.process.read(@recv_buf, len)
        @ragweed.process.write(@recv_buf, mutate(data, len))
    end
end
