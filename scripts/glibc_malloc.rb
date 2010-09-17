## Read the size argument to a malloc() call
## Search the heap buffer for a DWORD

r = @ragweed.get_registers
esp = Ragweed::Wraptux::ptrace(Ragweed::Wraptux::Ptrace::PEEK_TEXT, @pid, r[:esp]+4, 0)
@log.str "malloc(#{esp})"

locs = @ragweed.search_heap(0x41414141)

if !locs.empty?
    puts "0x41414141 found at:"
    locs.map do |l|
        print "\t#{l.to_s(16)} "
        puts "#{@ragweed.get_mapping_name(l)}"
    end
end
