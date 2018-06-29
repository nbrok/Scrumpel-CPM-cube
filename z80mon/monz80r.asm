	cpu	z80

;********************************************************************
;* Z80 scrumpel 2d monitor with cp/m bootloader                     *
;* (c) 2018 N Brok, PE1GOO                                          *
;* Created 24 june 2018   ROM Version                               *
;********************************************************************

;* Serial I/O with 82C51A *

acia0stat	equ	1
acia0data	equ	0

acia1stat	equ	0a1h
acia1data	equ	0a0h

;* Parallel ports 82C55 *

port0a		equ	20h
port0b		equ	21h
port0c		equ	22h
port0ctl	equ	23h
port1a		equ	60h			;Used for IDE controller
port1b		equ	61h			;Used for IDE controller
port1c		equ	62h
port1ctl	equ	63h

; Port 1a and 1b are used for the IDE interface

; Software SPI for RTC and SD-card

sd_port		equ	80h

romdis		equ	40h

cls		equ	0ch
cr		equ	0dh
lf		equ	0ah
esc		equ	1bh
bs		equ	08h
space		equ	20h

membegin	equ	2000h
crc		equ	membegin
teller		equ	crc+1
buffer		equ	teller+1
tobuf		equ	buffer+2
dmaaddr		equ	tobuf+2
secno		equ	dmaaddr+2

stackbase	equ	membegin+1024

	org	0

; Initialisation routines

rst00	im	1		; IM Mode is 1
	di			; Disable Interrupts
	jr	init

; TX a character over RS232 ACIA0

	org	8
rst08	jp	sot

; RX a character over RS232 ACIA0

	org	010h
rst10	jp	sin

; Check serial status

	org	018h
rst18	in	a,(acia0stat)
	bit	1,a
	ret

; NMI vector
	org	0066h
	jp	return

init	xor	a			; Clr A
	out	(acia0stat),a		; Reset 8251 sequence.
	out	(acia0stat),a
	out	(acia0stat),a
	ld	a,40h			; Set 8251 reset flag
	out	(acia0stat),a
	ld	a,01001110b		; 1 stopbits, 8 databits and 16Xbaud
	out	(acia0stat),a
	ld	a,00100101b		; TX and RX enabled
	out	(acia0stat),a

	xor	a			; Clr A
	out	(acia1stat),a		; Reset 8251 sequence.
	out	(acia1stat),a
	out	(acia1stat),a
	ld	a,40h			; Set 8251 reset flag
	out	(acia1stat),a
	ld	a,01001110b		; 1 stopbits, 8 databits and 16Xbaud
	out	(acia1stat),a
	ld	a,00100101b		; TX and RX enabled
	out	(acia1stat),a

clear_memory

        ld      hl,2000h
        ld      de,0dfffh
clmlp   xor     a
        ld      (hl),a
        inc     hl
        dec     de
        ld      a,d
        or      e
        jr      nz,clmlp
	jp	0100h

	org	0100h

	ld	a,82h			; Set port0 B to input.
	out	(port0ctl),a		; Set port0 A and C to output.
	out	(port1ctl),a		; Do the same for port1
	ld	a,00001100b		; SPI CS lines set to high
	out	(sd_port),a

	ld	sp,stackbase
	ld	hl,groettekst
	call	sott			; Print greeting text
	jp	monitor

groettekst

	db	cls,"Scrumpel 2d Z80 monitor version 1.0",cr,lf
	db	"(c) 2018 by PE1GOO.",cr,lf,0

;-----------------------------------------------------
; Serial output routine for 8251 acia

sot	push	af
lp0	in	a,(acia0stat)
	bit	0,a
	jr	z,lp0
	pop	af
	out	(acia0data),a
	ret

esctxt	db	cr,lf,"Escaped.",0
prompt	db	cr,lf,"MONZ80> ",0
alt2	db	" : ",0

escape	ld	hl,esctxt
	call	sott
	jp	return

sinul	in	a,(acia0stat)
	bit	1,a
	jr	z,sinul
	in	a,(acia0data)
	and	a,7fh
	cp	a,esc
	jr	z,escape
	ret

sin	call	sinul
	cp	a,'z'
	jr	z,conup
	jr	c,nolc
	ret
conup	and	a,05fh
	ret
nolc	cp	a,'a'
	jr	z,conup
	jr	nc,conup
	ret

sott	ld	a,(hl)
	or	a
	ret	z
	call	sot
	inc	hl
	jr	sott

getnibble

	call	sin
alnibin	cp	a,'0'
	jr	c,error
	cp	a,03ah
	jr	c,sub0
	cp	a,'A'
	jr	c,error
	cp	a,'G'
	jr	nc,error
	call	sot
	sub	a,7h
	jr	add0
sub0	call	sot
add0	sub	a,'0'
	or	a,a
	ret
error	scf
	ret

byte_in	call	getnibble
	jr	c,byte_in
albytin	sla	a
	sla	a
	sla	a
	sla	a
	ld	b,a

byte_in1

	call	getnibble
	jr	c,byte_in1
	add	a,b
	ret

word_in	push	af
	call	byte_in
	ld	h,a
	call	byte_in
	ld	l,a
	pop	af
	ret

crlf	ld	a,cr
	call	sot
	ld	a,lf
	jp	sot

; word in HL, AF saved

wordot	push	af
	ld	a,h
	call	bytot
	ld	a,l
	call	bytot
	pop	af
	ret

; byte in a

bytot	push	af
	push	af
	and	0f0h
	rra
	rra
	rra
	rra
	call	nibbleot
	pop	af
	and	0fh
	call	nibbleot
	pop	af
	ret

nibbleot

	and	0fh
	cp	0ah
	jr	nc,outnibbleless
	add	a,48
	jp	sot

outnibbleless

	add	a,55
	jp	sot

monitor	ld	hl,prompt
	call	sott

;Command interpreter.

cmdlp	call	sin
	cp	a,lf
	jr	z,cmdlp
	call	sot
	cp	a,cr
	jr	z,return
	cp	a,'?'
	jr	nz,cmdnxt
	call	help
	jp	return
cmdnxt	ld	c,a
	call	sin
	call	sot
	ld	b,a
	ld	a,space
	call	sot
	ld	hl,command_table
cmdlp1	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	a,d
	or	a,e
	jr	z,cerror
	ld	a,c
	cp	a,e
	jr	nz,nextc
	ld	a,d
	cp	a,b
	jr	nz,nextc
	ld	de,return
	push	de
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	h,b
	ld	l,c
	jp	(hl)
		
nextc	inc	hl
	inc	hl
	jr	cmdlp1

cerror	ld	hl,command_error_text
merror	call	sott
return	ld	sp,stackbase
	jp	monitor

command_error_text

	db	" Unknown command type ? or HE for help.",0

command_table

	db	"AM"
	dw	alter			;Alter memory command.
	db	"AP"
	dw	alterport		;Alter ports.
	db	"GO"
	dw	goto			;Goto command.
	db	"BC"
	dw	bootcpm			;Boot CP/M command.
	db	"TI"
	dw	transfer_in		;Intel hex transfer in command.
	db	"TO"
	dw	transfer_ot		;Intel hex transfer ot command.
	db	"HE"
	dw	help			;Help command.
	db	"CS"
	dw	ecls			;Clear screen command.
	db	"HD"
	dw	hdump			;Hexdump command.
	db	"PM"
	dw	preset_mem		;Preset memory command.
	db	"FI"
	dw	snuffel			;Search in memory command.
	dw	0

ecls	ld	a,cls
	jp	sot


helptext

	db	cr,lf,"This is the Z80-monitor command helpmenu."
	db	cr,lf,lf,lf
	db	"AM <Alter Memory>    AP <Alter Port>      GO <Goto>",cr,lf
	db	"BC <Boot CP/M>       CS <Clear screen>    TI <Transfer Input>"
	db	cr,lf
	db	"TO <Transfer Output> PM <Preset Memory>   HD <Hexdump>",cr,lf
	db	"FI <Find>            HE <Help, this menu>  ? <Help, this menu>"
	db	cr,lf,lf,lf,0

help	ld	a,cls
	call	sot
	ld	hl,helptext
	jp	sott

asciiot	and	a,7fh
	cp	a,7eh
	jr	nc,otpunt
	cp	a,space
	jr	nc,otkar
otpunt	ld	a,'.'
otkar	jp	sot

alterg	call	sot
	ld	a,space
	call	sot

alter	call	word_in
altl0	call	crlf
	call	wordot
	ld	a,space
	call	sot
	ld	a,(hl)
	push	af
	call	bytot
	ld	a,space
	call	sot
	pop	af
	call	asciiot
	push	hl
	ld	hl,alt2
	call	sott
	pop	hl
altla	call	sin
	cp	a,cr
	jr	z,plus
	cp	a,'-'
	jr	z,min
	cp	a,'G'
	jr	z,alterg
alnxt	cp	a,'R'
	jr	z,relative
	cp	a,"'"
	jr	z,txtin
	call	alnibin
	jr	c,altla
	call	albytin
	ld	(hl),a
	jr	plus1
plus	ld	a,'+'
	call	sot
plus1	inc	hl
	jr	altl0
min	call	sot
	dec	hl
	jr	altl0
txtin	call	sot
txtinl	call	sinul
	call	sot
	cp	a,08h
	jr	nz,txtver
	dec	hl
	jr	txtinl
txtver	cp	a,"'"
	jr	z,altl0
	ld	(hl),a
	inc	hl
	jr	txtinl

relative

	call	sot
	ld	(buffer),hl
	ld	a,space
	call	sot
	call	word_in
	ld	(tobuf),hl
	ccf
	ld	hl,(tobuf)
	ld	de,(buffer)
	sbc	hl,de
	ld	a,h
	or	a,a
	jr	z,fwrd
	cp	a,0ffh
	jr	z,back
offerr	ld	hl,offseterr
	call	sott
	ld	hl,(buffer)
	jp	altl0
back	ld	a,h
	or	a,a
	jp	p,offerr
	jr	oexit
fwrd	ld	a,h
	or	a,a
	jp	m,offerr
oexit	ld	a,l
	ld	hl,(buffer)
	ld	(hl),a
	push	af
	ld	a,'='
	call	sot
	pop	af
	call	bytot
	jp	plus1

offseterr

	db	" Relative offset out of range.",0
	
goto	call	word_in
	call	sin
	call	crlf
	ld	bc,return
	push	bc
	jp	(hl)			; Jump to address in HL

; Scrumpel's 8255 8 bit IDE interface
; PORT1A and PORT1B are used for controlling the CF-card
; CS0 IWR IRD RST nc  AD2 AD1 AD0	port1a
; DB7 DB6 DB5 DB4 DB3 DB2 DB1 DB0	port1b

; CF registers via port1a

cf_data		equ	0h
cf_features	equ	1h
cf_error	equ	1h
cf_seccount	equ	2h
cf_sector	equ	3h
cf_cyl_low	equ	4h
cf_cyl_hi	equ	5h
cf_head		equ	6h
cf_status	equ	7h
cf_command	equ	7h
cf_lba0		equ	3h
cf_lba1		equ	4h
cf_lba2		equ	5h
cf_lba3		equ	6h

;CF Features

cf_8bit		equ	1
cf_nocache	equ	082h

;CF Commands

cf_read_sec	equ	020h
cf_write_sec	equ	030h
cf_set_feat	equ	0efh

loadaddr	equ	0c000h	; CP/M load address
numsecs		equ	32	; number of 512 sectors to be loaded

; macro's for ide-out and ide-in

ideout	macro	adres
	push	af
	push	bc
	ld	b,adres
	call	idewr
	pop	bc
	pop	af

	endm

idein	macro	adres
	push	bc
	ld	b,adres
	call	iderd
	pop	bc

	endm

; ide bus routines

;	a=data, b=port adress

idewr	ld	c,a			; Data in C
	ld	a,80h			; Databus to write direction
	out	(port1ctl),a
	ld	a,b			; Address in B
	out	(port1a),a
	in	a,(port1a)
	or	a,10000000b		; CS
	out	(port1a),a
	or	a,11000000b		; CS & WR               
	out	(port1a),a
	ld	b,a
	ld	a,c
	out	(port1b),a		; Data on databus
	ld	a,b
	and	a,10000111b		; CS
	out	(port1a),a
	and	a,00000111b             
	out	(port1a),a
	ret

iderd	ld	a,82h
	out	(port1ctl),a
	ld	a,b
	out	(port1a),a
	in	a,(port1a)
	or	a,10000000b		; CS
	out	(port1a),a
	or	a,10100000b		; CS & RD
	out	(port1a),a
	in	a,(port1b)
	ld	c,a
	in	a,(port1a)
	and	a,10000111b		; CS
	out	(port1a),a
	and	a,00000111b
	out	(port1a),a
	ld	a,c
	ret

bootcpm	ld	hl,cpmtext
	call	sott
	call	cfwait
	ld	a,cf_8bit		; Set IDE to be 8bit
	ideout	cf_features
	ld	a,cf_set_feat
	ideout	cf_command

	call	cfwait
	ld	a,cf_nocache		; No write cache
	ideout	cf_features
	ld	a,cf_set_feat
	ideout	cf_command

	ld	b,numsecs
	xor	a
	ld	(secno),a
	ld	hl,loadaddr
	ld	(dmaaddr),hl

processectors

	call	cfwait
	ld	a,(secno)
	ideout	cf_lba0
	xor	a
	ideout	cf_lba1
	ideout	cf_lba2
	ld	a,0e0h
	ideout	cf_lba3
	ld	a,1
	ideout	cf_seccount
	call	read
	ld	de,0200h
	ld	hl,(dmaaddr)
	add	hl,de
	ld	(dmaaddr),hl
	ld	a,(secno)
	inc	a
	ld	(secno),a
	djnz	processectors

; Start CP/M using entry at top of BIOS
; The current active console stream ID is pushed onto the stack
; to allow the CBIOS to pick it up
; 0 = ACIA 0, 1 = ACIA 1

	xor	a
	push	af
	ld	hl,(0fffeh)
	jp	(hl)

read	push	af
	push	bc
	push	hl
	call	cfwait
	ld	a,cf_read_sec
	ideout	cf_command
	call	cfwait
	ld	c,4
	ld	hl,(dmaaddr)
rd4secs	ld	b,128
rdbyte	nop
	nop
	idein	cf_data
	ld	(hl),a
	inc	hl
	djnz	rdbyte
	dec	c
	jr	nz,rd4secs
	pop	hl
	pop	bc
	pop	af
	ret

; Wait for disk to be ready (busy=0,ready=1)

cfwait	push	af
cfwait1	idein	cf_status
	and	080h
	cp	080h
	jr	z,cfwait1
	pop	af
	ret

cpmtext	db	cr,lf,"Loading CP/M from CF card on IDE0.",cr,lf,0

alprtg	call	sot
	ld	a,space
	call	sot

alterport

	call	byte_in
	ld	c,a
altprt1	call	crlf
	ld	a,c
	call	bytot
	ld	a,space
	call	sot
	in	a,(c)
	call	bytot
	ld	hl,alt2
	call	sott
altp1	call	sin
	cp	a,cr
	jr	z,pplus
	cp	a,'-'
	jr	z,pmin
	cp	a,'G'
	jr	z,alprtg
	call	alnibin
	jr	c,altp1
	call	albytin
	out	(c),a
	jr	pplus1
pplus	ld	a,'+'
	call	sot
pplus1	inc	c
	jr	altprt1
pmin	call	sot
	dec	c
	jr	altprt1

preset_mem

	call	word_in
	push	hl
	ld	a,space
	call	sot
	call	word_in
	ld	(buffer),hl
	pop	hl
	ld	a,space
	call	sot
	call	byte_in
presl1	ld	(hl),a
	inc	hl
	push	hl
	ccf
	ld	de,(buffer)
	sbc	hl,de
	pop	hl
	jr	nz,presl1
	ld	(hl),a
	ret
	
transfer_in

	ld	hl,iloadtxt
	call	sott
	jp	transfer_start
	              
iloadtxt
	db	cr,lf,"Ready for intel-hex transfer",cr,lf,0

chksum	push	bc
	ld	b,a
	ld	a,(crc)
	add	a,b
	ld	(crc),a
	pop	bc
	ret

transfer_start

	push	af
	push	bc
	push	de
	push	hl
tr_in	call	crlf
trl1	call	sin
	cp	a,':'
	jr	nz,trl1
	call	sot
	call	byte_in
	cp	a,0h
	jr	z,trend
	ld	(teller),a
	push	af
	xor	a
	ld	(crc),a
	pop	af
	call	chksum
	call	byte_in
	ld	(buffer+1),a
	call	chksum
	call	byte_in
	ld	(buffer),a
	call	chksum
	ld	hl,(buffer)
	call	byte_in
	call	chksum
trl0	call	byte_in
	ld	(hl),a
	call	chksum
	inc	hl
	ld	a,(teller)	
	dec	a
	ld	(teller),a
	jr	nz,trl0
	call	byte_in
	neg
	ld	b,a
	ld	a,(crc)
	cp	a,b
	jr	z,tr_in
chkerr	ld	hl,errortxt
	call	sott
	jr	trex
trend	call	sin
	cp	a,cr
	jr	nz,trend
trex	pop	hl
	pop	de
	pop	bc
	pop	af
	ret

errortxt

	db	cr,lf,"CRC error in Intel-hex transfer.",0

transfer_ot

	call	word_in
	push	hl
	ld	a,space
	call	sot
	call	word_in
	ld	(tobuf),hl
	pop	hl
tril1	xor	a
	ld	(crc),a
	call	crlf
	ld	(buffer),hl
	ld	a,':'
	call	sot
	ld	a,010h
	ld	b,a
	call	bytot
	call	chksum
	ld	a,(buffer+1)
	call	bytot
	call	chksum
	ld	a,(buffer)
	call	bytot
	call	chksum
	xor	a
	call	bytot
	call	chksum
tril0	ld	a,(hl)
	call	bytot
	call	chksum
	inc	hl
	djnz	tril0
	ld	a,(crc)
	neg
	call	bytot
	push	hl
	ld	hl,(tobuf)
	dec	hl
	ld	a,l
	or	a,h
	jr	z,trend1
	ld	(tobuf),hl
	pop	hl
	jr	tril1
trend1	pop	hl
	ld	hl,trendt
	jp	sott

trendt	db	cr,lf,":00000001FF",cr,lf,0

snuffel	call	word_in
	push	hl
	ld	a,space
	call	sot
	call	word_in
	ld	(tobuf),hl
	pop	hl
	ld	a,space
	call	sot
	call	byte_in

snuffel_verder

	push	hl
	ld	de,(tobuf)
	ccf
	sbc	hl,de
	pop	hl
	jr	z,snuffel_niet_gevonden
	ld	b,(hl)
	inc 	hl
	cp	a,b
	jr	nz,snuffel_verder
	push	hl
	ld	hl,snuffel_gevonden_text
	call	sott
	pop	hl
	dec	hl
	jp	wordot

snuffel_niet_gevonden

	ld	hl,snuffel_niet_gevonden_text
	jp	sott

snuffel_gevonden_text

	db	" found at : ",0

snuffel_niet_gevonden_text

	db	" not found in given memory block.",0

hdump	call	word_in
hloop	call	crlf
	push	hl
	call	wordot
	ld	a,space
	call	sot
	ld	b,8
hloop1	ld	a,space
	call	sot
	ld	a,(hl)
	call	bytot
	inc	hl
	ld	a,(hl)
	call	bytot
	inc	hl
	djnz	hloop1
	pop	hl
	ld	a,space
	call	sot
	ld	b,010h
hloop2	ld	a,(hl)
	call	asciiot
	inc	hl
	djnz	hloop2
	in	a,(acia0stat)
	bit	1,a
	jr	z,hloop
	in	a,(acia0data)
	ret

	end
