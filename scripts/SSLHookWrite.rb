## This example script hooks SSL_read

if dir.to_s =~ /enter/
    addr = @ragweed.process.read32(ctx.esp+8)
    len = @ragweed.process.read32(ctx.esp+12)
    buf = @ragweed.process.read(addr, len)
    @log.str "Read #{len} from #{addr} got:"
    @log.str buf
end
