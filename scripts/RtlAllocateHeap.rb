## This script is for Win32 RtlAllocateHeap

if dir.to_s =~ /enter/
    output_str "Size requested #{@rw.process.read32(ctx.esp+12)}"
    output_str "Heap handle is @ #{@rw.process.read32(ctx.esp+4).to_s(16)}"
else
    output_str "Heap chunk returned @ #{ctx.eax.to_s(16)}"
end
