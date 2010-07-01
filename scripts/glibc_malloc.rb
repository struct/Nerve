## Read the size argument to a malloc() call
r = @rw.get_registers
esp = Ragweed::Wraptux::ptrace(Ragweed::Wraptux::Ptrace::PEEK_TEXT, @pid, r[:esp]+4, 0)
puts "malloc(#{esp})"
