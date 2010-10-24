## Get and print the register states
## Read the size argument to malloc
## Search the heap buffer for a DWORD
regs = @ragweed.get_registers

puts "-----------------"
#puts sprintf "eax = %08x\nebx = %08x\necx = %08x\nedx = %08x\nesp = %08x\nebp = %08x\neip = %08x\n",
#    regs.eax, regs.ebx, regs.ecx, regs.edx, regs.esp, regs.ebp, regs.eip
@ragweed.print_registers

esp = Ragweed::Wraptux::ptrace(Ragweed::Wraptux::Ptrace::PEEK_TEXT, @pid, regs.esp+4, 0)
@log.str "malloc(#{esp})"

#locs = @ragweed.search_process(0x41414141)
locs = @ragweed.search_heap(0x41414141)

if !locs.empty?
    puts "0x41414141 found at:"
    locs.map do |l|
        puts " -> #{l.to_s(16)} #{@ragweed.get_mapping_name(l)}"
    end
end
