#!/usr/bin/tclsh
array set mem {}
fconfigure stdin -encoding binary
fconfigure stdout -encoding binary
fconfigure stdin -translation binary
fconfigure stdout -translation binary

set overlapvirgin 1
while {![eof stdin]} {
 set s [gets stdin]
 if {[string range $s 3 6] == ""} break
 set addr [format "%d" "0x[string range $s 3 6]"]
 set data [string range $s 9 end-2]
 foreach {hi lo} [split $data ""] {
#  puts -nonewline [format "%c" "[expr (16 * 0x$hi ) + 0x$lo]"]
  if {[lsearch -exact [array names mem] $addr] != -1} {
   if {$overlapvirgin} {
    puts stderr "Warning! Overlaps :" 
    set overlapvirgin 0
   }
   puts  -nonewline stderr "[format "%X" $addr] //$addr  "
  }
  set mem($addr) "$hi$lo"
  incr addr
 }      
}
puts stderr "\n Storing..."
for {set i 0} {$i < 65536} {incr i} {
 if {[lsearch -exact [array names mem] $i] == -1} {
  puts -nonewline " " 
  # the value of unused byte. If it is not used, it may me even 88
 } else {
  foreach {hi lo} [split $mem($i) ""] break
#  puts "Hi $hi Lo $lo"
  puts -nonewline [format "%c" "[expr (16 * 0x$hi ) + 0x$lo]"]
 }
}
