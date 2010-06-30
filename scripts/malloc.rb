## This script is for Win32 RtlAllocateHeap

if dir.to_s =~ /enter/
    puts "Size requested #{@rw.process.read32(ctx.esp+12)}"
    puts "Heap handle is @ #{@rw.process.read32(ctx.esp+4).to_s(16)}"
else
    puts "Heap chunk returned @ #{ctx.eax.to_s(16)}"
end
