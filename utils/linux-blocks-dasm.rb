#requires rbdasm from libdisassemble
#
#  Usage: blah.rb /bin/ls
#
#  Output: all block branches/entry points to set breakpoints on.
#
#
# There are some highly specific libdasm things in here
# Mainly, when grabbing an immediate value is it relative 
# or absolute? Ideally any disassembler lib would have a helper
# function that given an opcode and a program counter gives you
# the possible destinations for immediate-only instructions.
#
# http://code.google.com/p/libdasm/downloads/detail?name=libdasm-beta.zip
require 'dasm'
require 'relf'
require 'rubygems'
require 'ragweed'
require 'set'

if !ARGV[0]
	puts "need a file!"
	exit
end

d = RELF.new(ARGV[0])
d.parse_dynsym
d.parse_symtab
d.parse_reloc

#puts d.ehdr.e_entry.

##(03:26:23 PM) chrisrohlf: ## Disassemble the .text and inspect all call instructions.
d.shdr.each do |s|
#    puts s.to_human
    if d.get_shdr_name(s) =~ /.text/
        file = File.read(ARGV[0])
        $text = file[s.sh_offset.to_i, s.sh_size.to_i]
        @shdr = s
    end
end

dasm = Dasm.new
branches = [Dasm::Instruction::Type::JMP, 
            Dasm::Instruction::Type::JMPC, 
            Dasm::Instruction::Type::CALL]
op_imm = Dasm::Operand::Type::Immediate

#libdasm.h:#define AM_A 0x00010000		// Direct address with segment prefix
#libdasm.h:#define AM_I 0x00060000		// Immediate data follows
#libdasm.h:#define AM_J 0x00070000		// Immediate value is relative to EIP
#libdasm.h:#define AM_I1  0x00200000	// Immediate byte 1 encoded in instruction
AM_A = 0x00010000
AM_I = 0x00060000
AM_J = 0x00070000
AM_I1 = 0x00200000

bps = Set.new

start = false
dasm.disassemble($text) do |instruction, offset|
 
  #TODO: rbdasm has some type of race or uninit memory bug 
#blocks-dasm.rb:77: method `type' called on terminated object (0xb77d80cc) (NotImplementedError)
#	from blocks-dasm.rb:61:in `disassemble'
#	from blocks-dasm.rb:61
  if not start
    sleep(0.1)
    start = true
  end
### end of wtf ###
 
  if branches.include? instruction.type:
    pc = offset+@shdr.sh_addr
 
    #this is the branch source
    #bps.add( [pc, offset] )

    #these are the branch destinations    
    if not instruction.op1
      puts 'wtfbbq'
    end
    if instruction.op1 and instruction.op1.type == op_imm
      branchdest = (instruction.op1.immediate + instruction.length + pc).to_i
      branchdest2 = (instruction.length + pc).to_i
      
      bps.add( [branchdest, branchdest-@shdr.sh_addr] )
      bps.add( [branchdest2, branchdest2-@shdr.sh_addr] )
      
#      puts branchdest.to_hex
#      puts branchdest2.to_hex     
#      puts "0x%.8x:  #{instruction}"%(offset+@shdr.sh_addr)
#      puts 
    end

    
  end
end


x = Hash.new
for sym in d.symbols
  x[sym.st_value.to_i] = d.get_dyn_symbol_name(sym)
end

bps.each do |b|
  out = "break=#{b[0].to_hex}, name="
  if x.include? b[0]
    out += "#{x[b[0]]}"
  else
    out += "#{b[1]}"
  end
  puts out
end


