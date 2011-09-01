## This script is for tracing calls to RtlAllocateHeap

begin
  if dir.to_s =~ /enter/
    @log.str "RtlAllocateHeap -> Size requested #{@ragweed.process.read32(ctx.esp+12)}"
    @log.str "RtlAllocateHeap -> Heap handle is @ #{@ragweed.process.read32(ctx.esp+4).to_s(16)}"
  else
    @log.str "RtlAllocateHeap <- Heap chunk returned @ #{ctx.eax.to_s(16)}"
  end
rescue =>
  puts "Does your configuration use hook=true?"
  #puts e.inspect
  #puts e.backtrace
  #exit
end
