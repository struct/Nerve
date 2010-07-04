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
require 'rubygems'
require 'ragweed'
require 'dasm'
require 'rupe'
require 'set'

if !ARGV[0]
	puts "need a file!"
	exit
end

p = RUPE.new(ARGV[0])

entry = p.peo.address_of_entry_point

#        # Find code section and disassemble entry point routine.
#        TextSec = PEObj.GetSectionByVA(PEObj.EntryPoint)
#        if TextSec == None:
#            return
#        l = distorm.Decode(PEObj.ImageBase + PEObj.EntryPoint, T
#                extSec.Data[PEObj.EntryPoint - TextSec.VA:][:4*1024], DecodeType)


p.pe_shdrs.each do |x| 
  if x.nam.match(/\.text/)
    entry_offset = entry.to_i - x.virtual_address
    # TODO: verify alignment [taken from diSlib64.py]
    file_offset = x.pointer_to_raw_data & ~( p.peo.file_alignment-1)
    file = File.read(ARGV[0])

    $text = file[file_offset + entry_offset, x.virtual_size - entry_offset]
    @sec = x    
    break
  end
end

dasm = Dasm.new
branches = [Dasm::Instruction::Type::JMP, 
            Dasm::Instruction::Type::JMPC, 
            Dasm::Instruction::Type::CALL]
op_imm = Dasm::Operand::Type::Immediate

bps = Set.new

start = false
dasm.disassemble($text) do |instruction, offset|

#    puts "0x%.8x:  #{instruction}"%(offset)
 
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
    pc = offset+@sec.virtual_address
 
    #this is the branch source
    #bps.add( [pc, offset] )

    #these are the branch destinations    
    if not instruction.op1
      puts 'wtfbbq'
    end
    if instruction.op1 and instruction.op1.type == op_imm
      branchdest = (instruction.op1.immediate + instruction.length + pc).to_i
      branchdest2 = (instruction.length + pc).to_i
      
      bps.add( [branchdest, branchdest-@sec.virtual_address] )
      bps.add( [branchdest2, branchdest2-@sec.virtual_address] )      
    end

    
  end
end



bps.each do |b|
  out = "break=#{b[0].to_hex}, name="
  out += "#{b[1]}"
  puts out
end


