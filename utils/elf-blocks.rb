# Requires: rbdasm from libdasm (Ruby 1.8.7) and http://github.com/struct/relf
# Output: A Nerve configuration file for all branch/entry points

require 'dasm'
require 'relf'
require 'rubygems'
require 'set'

if !ARGV[1]
	puts "ruby elf-blocks.rb <binary> <output>"
	exit
end

output = ARGV[1]

text = String.new
d = RELF.new(ARGV[0])
d.parse_dynsym
d.parse_symtab
d.parse_reloc

d.shdr.each do |s|
    if d.get_shdr_name(s) =~ /.text/
        file = File.open(ARGV[0]).read
        text = file[s.sh_offset.to_i, s.sh_size.to_i]
        @shdr = s
    end
end

dasm = Dasm.new
branches = [Dasm::Instruction::Type::JMP, 
            Dasm::Instruction::Type::JMPC, 
            Dasm::Instruction::Type::CALL]
op_imm = Dasm::Operand::Type::Immediate

bps = Set.new

start = false
dasm.disassemble(text) do |instruction, offset|
  if branches.include? instruction.type
	puts "Branch: #{instruction.to_s}"
    pc = offset+@shdr.sh_addr
 
    if instruction.op1 and instruction.op1.type == op_imm
      branchdest = (instruction.op1.immediate + instruction.length + pc).to_i
      branchdest2 = (instruction.length + pc).to_i
      
      bps.add( [branchdest, branchdest-@shdr.sh_addr] )
      bps.add( [branchdest2, branchdest2-@shdr.sh_addr] )
    end 
  end
end

x = Hash.new

for sym in d.dynsym_symbols
  x[sym.st_value.to_i] = d.get_dyn_symbol_name(sym)
end

puts "Writing output file to #{output}"

file = File.open(output, "w+")

bps.each do |b|
  out = "bp=#{b[0].to_hex}, name=block_"
  if x.include? b[0]
    out += "#{x[b[0]]}"
  else
    out += "#{b[1]}"
  end
  file.puts out
end
