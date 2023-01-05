#!/usr/bin/env ruby
# coding: utf-8


list = Dir.glob("./log/WSJT_*.tsv").sort
fd = File.open(list[-1],"r")
begin
  fd.sysseek(-1000, IO::SEEK_END)
rescue
  fd.sysseek(0, IO::SEEK_SET)    
end
dummy= fd.readline

def read_and_wait fd
    while  fd.eof?
      sleep 1
    end
    data = fd.readline
    return data
end
ALPHABET_TABLE={'A'=>0,
                'B'=>1,
                'C'=>2,
                'D'=>3,
                'E'=>4,
                'F'=>5,
                'G'=>6,
                'H'=>7,
                'I'=>8,
                'J'=>9,
                'K'=>10,
                'L'=>11,
                'M'=>12,
                'N'=>13,
                'O'=>14,
                'P'=>15,
                'Q'=>16,
                'R'=>17,
                'S'=>18,
                'T'=>19,
                'U'=>20,
                'V'=>21,
                'W'=>22,
                'X'=>23,
                'Y'=>24,
                'Z'=>25}

def alphabet2number str
  return ALPHABET_TABLE[str]
end

def isGridLocator str
  ret = str.match(/^[A-Z]{2}[0-9]{2}$/)
  return false if ret == nil
  return false if str =="RR73"
  return true
end

def gridLocator2location str
  x = alphabet2number(str[0]) * 20 -180 + str[2].to_i* 2  + 1.0
  y = alphabet2number(str[1]) * 10 - 90 + str[3].to_i* 1  + 0.5
  return [x,y]
end


loop do
  tmp = read_and_wait fd
  data=tmp.chomp.split("\t")
  msg =  data[-1]
  msgs=msg.split(/\s+/)
  next if msgs.size < 3
  next unless  isGridLocator( msgs[-1])
  call_id = msgs[-2]
  gl = msgs[-1]
  location = gridLocator2location gl
  puts "Grid locator #{call_id} #{gl} #{msgs} #{location}"
end

