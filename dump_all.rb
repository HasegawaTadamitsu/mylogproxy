#!/usr/bin/ruby
# coding: utf-8

require "socket"

udp_r = UDPSocket.open()
udp_s = UDPSocket.open()

udp_r.bind("127.0.0.1", 2237)
upd_s_addr = Socket.pack_sockaddr_in(2238, "127.0.0.1")

loop do
  tmp=udp_r.recv(65535)
  udp_s.send(tmp,0,upd_s_addr)
  str= tmp.bytes.map do  |b|
    if 32 <= b && b <= 126   then
     ret =  ("%c") % b
    else
      ret = "_"
    end
    ret
  end
  hex= tmp.bytes.map do  |b|
    ( "%02X" % b) 
  end
  print "\n"
  jp_date=Time.now
  gm_date=jp_date.getgm
  jp_date_str= jp_date.strftime("%Y/%m/%d  %H:%M:%S")
  gm_date_str= gm_date.strftime("%Y/%m/%d  %H:%M:%S")
  jp_sec = jp_date.to_i
  gm_sec = gm_date.to_i

  jp_sec_str = ("%08X" % jp_sec)
  gm_sec_str = ("%08X" % gm_sec)
 
  print "jp date #{jp_date} #{jp_sec_str}\n"
  print "gm date #{gm_date} #{gm_sec_str}\n"
  print "input:\n#{str.join}\n"
  print "hex:\n"
  hex.each_with_index do |val,i|
    if i % 8 == 0 then 
      addr= sprintf("%04X",i / 16 )
      print "#{addr}: "
    end
    print "#{val} "
    if i % 8 == 7 then
      line = i/8
      str_tmp = str[line * 8 .. line*8 +7].join
      print ":#{str_tmp}\n"
    end
  end
  amari = hex.size % 8
  if amari != 0  then
    print "   " * (8- amari)
    line = hex.size / 8
    str_tmp = str[line * 8 .. line*8 +7].join
    print ":#{str_tmp}\n"
  end
end

udp_r.close
udp_s.close

