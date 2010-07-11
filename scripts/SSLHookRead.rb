## This example script hooks SSL_read

if dir.to_s =~ /leave/
    addr = @ragweed.process.read32(ctx.esp+4)
    len = ctx.eax

    @log.str "Read #{len.to_s(16)} from #{addr.to_s(16)}; #{@ragweed.process.read32(ctx.esp).to_s(16)}"

    if len != 0xffffffff
        buf = @ragweed.process.read(addr, len)
        @log.str "Read #{len} from #{addr} got:"
        @log.str buf
    end
end
