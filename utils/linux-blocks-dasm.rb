# requires rbdasm from libdasm
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

d.shdr.each do |s|
    if d.get_shdr_name(s) =~ /.text/
        file = File.open(ARGV[0]).read
        $text = file[s.sh_offset.to_i, s.sh_size.to_i]
        @shdr = s
    end
end

dasm = Dasm.new
branches = [#Dasm::Instruction::Type::JMP, 
            #Dasm::Instruction::Type::JMPC, 
             Dasm::Instruction::Type::CALL]
op_imm = Dasm::Operand::Type::Immediate

bps = Set.new

start = false
dasm.disassemble($text) do |instruction, offset|
 
  if branches.include? instruction.type:
    pc = offset+@shdr.sh_addr
 
    if instruction.op1 and instruction.op1.type == op_imm
      branchdest = (instruction.op1.immediate + instruction.length + pc).to_i
      branchdest2 = (instruction.length + pc).to_i
      
      bps.add( [branchdest, branchdest-@shdr.sh_addr] )
      bps.add( [branchdest2, branchdest2-@shdr.sh_addr] )
#      puts branchdest.to_hex
#      puts branchdest2.to_hex     
#      puts "0x%.8x: #{instruction}" % (offset+@shdr.sh_addr)
    end 
  end
end

x = Hash.new
for sym in d.dynsym_symbols
  x[sym.st_value.to_i] = d.get_dyn_symbol_name(sym)
end

bps.each do |b|
  out = "bp=#{b[0].to_hex}, name=call_"
  if x.include? b[0]
    out += "#{x[b[0]]}"
  else
    out += "#{b[1]}"
  end
  puts out
end
