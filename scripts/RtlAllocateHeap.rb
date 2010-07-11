## This script is for Win32 RtlAllocateHeap

if dir.to_s =~ /enter/
    @log.str "Size requested #{@ragweed.process.read32(ctx.esp+12)}"
    @log.str "Heap handle is @ #{@ragweed.process.read32(ctx.esp+4).to_s(16)}"
else
    @log.str "Heap chunk returned @ #{ctx.eax.to_s(16)}"
end
