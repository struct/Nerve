## Get and print the register states
## Read the size argument to malloc
## Search the heap buffer for a DWORD

puts "-----------------"
@ragweed.print_registers
regs = @ragweed.get_registers

size = Ragweed::Wraptux::ptrace(Ragweed::Wraptux::Ptrace::PEEK_TEXT, @pid, regs.esp+4, 0)
@log.str "malloc(#{size})"

#locs = @ragweed.search_process(0x41414141)
locs = @ragweed.search_heap(0x41414141)

if !locs.empty?
    puts "0x41414141 found at:"
    locs.map do |l|
        puts " -> #{l.to_s(16)} #{@ragweed.get_mapping_name(l)}"
    end
end

puts "Stack => #{@ragweed.get_stack_range.inspect}"
puts "Heap => #{@ragweed.get_heap_range.inspect}"
