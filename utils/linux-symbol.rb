## Simple script that uses relf http://github.com/struct/relf
## to generate a list of breakpoints
## that might match a function name
##
## ruby linux-symbol.rb /usr/local/my_binary authenticate

require 'relf'

if !ARGV[0] or !ARGV[1]
	puts "I need a file and a symbol!"
	exit
end

d = RELF.new(ARGV[0])
m = ARGV[1]

d.parse_dynsym do |sym|
    if d.get_dyn_symbol_name(sym).match(/#{m}/) and d.get_symbol_type(sym) =~ /FUNC/i and sym.st_value.to_i != 0
       puts sprintf("bp=0x%08x, name=%s\n", sym.st_value.to_i, d.get_dyn_symbol_name(sym))
    end
end

d.parse_symtab do |sym|
    if d.get_sym_symbol_name(sym).match(/#{m}/) and d.get_symbol_type(sym) =~ /FUNC/i and sym.st_value.to_i != 0
        puts sprintf("bp=0x%08x, name=%s\n", sym.st_value.to_i, d.get_sym_symbol_name(sym))
    end
end
