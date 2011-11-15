## Borrowed from Eric Monti's Ruby Blackbag
require 'stringio'

class String
  def hexdump(opt={})
    s=self
    out = opt[:out] || StringIO.new
    len = (opt[:len] and opt[:len] > 0)? opt[:len] + (opt[:len] % 2) : 16

    off = opt[:start_addr] || 0
    offlen = opt[:start_len] || 8

    hlen=len/2

    s.scan(/(?:.|\n){1,#{len}}/) do |m|
      out.write(off.to_s(16).rjust(offlen, "0") + '  ')

      i=0
      m.each_byte do |c|
        out.write c.to_s(16).rjust(2,"0") + " "
        out.write(' ') if (i+=1) == hlen
      end

      out.write("   " * (len-i) ) # pad
      out.write(" ") if i < hlen

      out.write(" |#{m.tr("\0-\37\177-\377", '.')}|\n")
      off += m.length
    end

    out.write(off.to_s(16).rjust(offlen,'0') + "\n")

    if out.class == StringIO
      out.string
    end
  end
end

