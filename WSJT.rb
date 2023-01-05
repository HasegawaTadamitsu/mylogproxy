#!/usr/bin/env ruby
# coding: utf-8
require 'bindata'
require "socket"

class Wsjt_header_data < BinData::Record
  endian    :little
  uint32be  :magic_code
  uint32be  :unknown_1
  uint32be  :mode
  uint32be  :pg_str_size 
  string    :pg_str, :read_length => :pg_str_size
end

class Wsjt_info_data < BinData::Record
  uint32be  :unknown
  uint32be  :pg_ver_str_size
  string    :pg_ver_str, :read_length => :pg_ver_str_size
end

class Wsjt_receive_data < BinData::Record
  uint8be  :unknown_3
  uint32be :utc_sec
  int32be  :db
  double_be :dt
  uint32be  :freq_detail
  uint32be  :mode_flg_str_size 
  string    :mode_flg_str, :read_length => :mode_flg_str_size
  uint32be  :msg_str_size 
  string    :msg_str, :read_length => :msg_str_size

  def str_utc_sec
    #05 0A E4 C0
    #inputs 050AE4C0
    #output 84600 000
    # now 23 30 00
    #23*60*60+30*60 * 00 = 84600
    hour = utc_sec / (60*60*1000)
    min  = (utc_sec - hour* 60*60*1000 ) / (60*1000)
    sec  = (utc_sec - hour* 60*60*1000 - min*60*1000) / 1000
    usec = (utc_sec - hour* 60*60*1000 - min*60*1000 - sec*1000)    
    tmp = Time.utc(2023,1,1,hour,min,sec,usec)
    tmp.strftime "%H%M%S"
  end
  def str_info
    ret = Array.new
    ret.push str_utc_sec
    ret.push db
    ret.push "%0.1f" % dt
    ret.push freq_detail
    ret.push mode_flg_str
    ret.push msg_str
    return ret
  end
end

class Wsjt_adif_data < BinData::Record
  uint32be  :adif_str_size 
  string    :adif_str, :read_length => :adif_str_size
end

class Wsjt_search_data < BinData::Record
  uint32be  :unknown_3
  uint32be  :freq
  uint32be  :mode_str_size 
  string    :mode_str, :read_length => :mode_str_size
  uint32be  :dxcall_str_size 
  string    :dxcall_str, :read_length => :ch_dxcall_str_size
  uint32be  :dxcall_db_str_size 
  string    :dxcall_db_str, :read_length => :dxcall_db_str_size
  uint32be  :mode2_str_size 
  string    :mode2_str, :read_length => :mode2_str_size
  uint8be  :can_send_flg
  uint8be  :unknown_5
  uint8be  :decode_now_flg
  uint32be  :rx_freq_detail
  uint32be  :tx_freq_detail
  uint32be  :my_call_sin_str_size 
  string    :my_call_sin_str, :read_length => :my_call_sin_str_size
  uint32be  :my_grid_locater_str_size 
  string    :my_grid_locater_str, :read_length => :my_grid_locater_str_size
  uint32be  :dx_grid_locater_str_size 
  string    :dx_grid_locater_str, :read_length => :ch_dx_grid_locater_str_size
  uint8be   :unknown_7
  uint32be  :unknown_8
  uint8be   :unknown_9
  uint8be   :unknown_10
  uint32be  :unknown_12
  uint32be  :unknown_13  
  uint32be  :config_str_size 
  string    :config_str, :read_length => :config_str_size

  def ch_dxcall_str_size
    # 4294967295 = 0xFF FF FF FF
    ret= (dxcall_str_size == 4294967295 )? 0:( dxcall_str_size)
    # p ret 
    return ret 
  end
  
  def  ch_dx_grid_locater_str_size
    # 4294967295 = 0xFF FF FF FF
    ret=(dx_grid_locater_str_size == 4294967295 )? 0:(dx_grid_locater_str_size)
    # p ret 
    return ret 
  end
end

def print_hex_dump target
    str= target.bytes.map do  |b|
    if 32 <= b && b <= 126   then
     ret =  ("%c") % b
    else
      ret = "_"
    end
    ret
  end
  hex= target.bytes.map do  |b|
    ( "%02X" % b) 
  end
  print "\n"
  jp_date=Time.now
  gm_date=jp_date.getgm
  jp_date_str= jp_date.strftime("%Y/%m/%d  %H:%M:%S")
  gm_date_str= gm_date.strftime("%Y/%m/%d  %H:%M:%S")

  puts "jp date #{jp_date}."
  puts "gm date #{gm_date}."
  puts "input:\n#{str.join}"
  target_size=target.bytes.size
  target_size_hex=("%04X" % target_size)
  puts "input size #{target_size}(#{target_size_hex})."
  puts "hex:"
  hex.each_with_index do |val,i|
    if i % 8 == 0 then 
      addr= sprintf("%04X",i / 16)
      print "#{addr}: "
    end
    print "#{val} "
    if i % 8 == 7 then
      line = i/8
      str_tmp = str[line * 8 .. line*8 +7].join
      puts ":#{str_tmp}"
    end
  end
  amari = hex.size % 8
  if amari != 0  then
    print "   " * (8- amari)
    line = hex.size / 8
    str_tmp = str[line * 8 .. line*8 +7].join
    puts ":#{str_tmp}"
  end
end

udp_r = UDPSocket.open()
udp_s = UDPSocket.open()

jp_date=Time.now
jp_date_str= jp_date.strftime("WSJT_receive_%Y%m%d%H%M%S")
fd = File.open("./log/#{jp_date_str}.tsv","a")
          
udp_r.bind("127.0.0.1", 2237)
upd_s_addr = Socket.pack_sockaddr_in(2238, "127.0.0.1")

loop do
  packet=udp_r.recv(65535)
  udp_s.send(packet,0,upd_s_addr)

  header = Wsjt_header_data.new.read packet
  header_size =header.to_binary_s.size
  body_packet = packet[header_size  .. -1]
  
  if ( header.mode == 0 ) then
    puts "program version received."
    data = Wsjt_info_data.new.read body_packet
 #   p data
    next
  end
  
  if ( header.mode == 1 ) then
    puts "header mode search."
    begin
      data = Wsjt_search_data.new.read body_packet
    rescue =>e
      print_hex_dump packet
      p e
      p e.message
      e.backtrace.each do |val|
        p val
      end
      exit 1
    end
#    puts "--debug start--"
#    print_hex_dump packet
#    p data
#    puts "--debug end--"
    next
  end

  if ( header.mode == 2 ) then
    puts "receive_data received."
    begin
      data = Wsjt_receive_data.new.read body_packet
    rescue =>e
      print_hex_dump packet
      p e
      p e.message
      e.backtrace.each do |val|
        p val
      end
      exit 1
    end
    puts  data.str_info.join "\t"
    date_str= Time.now.strftime("%Y/%m/%d\t%H:%M:%S.%s")
    fd.write  date_str + "\t" + data.str_info.join("\t") +"\n"
    fd.flush
    next
  end
  
  if ( header.mode == 3 ) then
    puts "header only received."
#    p body
    next
  end

  if ( header.mode == 6 ) then
    puts "config change received."
    puts "TODO."
    next
  end

  if ( header.mode == 5 ) then
    puts "write QSO log received."
    puts "TODO."
    next
  end

  if ( header.mode == 12 ) then
    puts "ADIF received."
    begin
      data = Wsjt_adif_data.new.read body_packet
    rescue =>e
      print_hex_dump packet
      p e
      p e.message
      e.backtrace.each do |val|
        p val
      end
      exit 1
    end
    puts "--debug start--"
    print_hex_dump packet
    p data
    puts "--debug end--"
    next
  end

  puts "unknown header mode #{header.mode}."
  print_hex_dump packet
  exit 
end

