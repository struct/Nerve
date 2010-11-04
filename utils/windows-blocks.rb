# Requires: rbdasm from libdasm (Ruby 1.8.7) and http://github.com/struct/rupe
# Output: A Nerve configuration file for all branch/entry points

require 'rubygems'
require 'dasm'
require 'rupe'
require 'set'

if !ARGV[1]
	puts "ruby windows-blocks.rb <binary> <output>"
	exit
end

output = ARGV[1]

text = String.new
sec = RUPE::ImageSectionHdr.new
p = RUPE.new(ARGV[0])

entry = p.peo.image_base

p.pe_shdrs.each do |x| 
  if x.nam.match(/\.text/)
puts sprintf "%x", p.peo.size_of_code
    e = entry.to_i + x.virtual_size + p.peo.size_of_code
    puts x.to_human
    file = File.read(ARGV[0])
puts sprintf "%x", e.to_i
puts x.size_of_raw_data.to_i
    text = file[e.to_i, p.peo.size_of_code]
    sec = x
    break
  end
end

dasm = Dasm.new
branches = [Dasm::Instruction::Type::JMP, 
            Dasm::Instruction::Type::JMPC,
            Dasm::Instruction::Type::CALL ]
op_imm = Dasm::Operand::Type::Immediate

bps = Set.new
start = false

dasm.disassemble(text) do |instruction, offset|
  if branches.include? instruction.type
    pc = offset+sec.virtual_address
	 puts "Branch: #{instruction.to_s}"

    if instruction.op1 and instruction.op1.type == op_imm
      branchdest = (instruction.op1.immediate + instruction.length + pc).to_i
      branchdest2 = (instruction.length + pc).to_i

      bps.add([branchdest, branchdest-sec.virtual_address])
      bps.add([branchdest2, branchdest2-sec.virtual_address])
    end
  end
end

puts "Writing output file to #{output}"

file = File.open(output, "w+")

bps.each do |b|
  file.puts "bp=#{b[0].to_hex}, name=#{b[1]}"
end
