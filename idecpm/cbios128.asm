	cpu	z80
;==============================================================================
; Contents of this file are copyright Grant Searle
; Blocking/unblocking routines are the published version by Digital Research
; (bugfixed, as found on the web)
;
; You have permission to use this for NON COMMERCIAL USE ONLY
; If you wish to use it elsewhere, please include an acknowledgement to myself.
;
; http://searle.hostei.com/grant/index.html
;
; eMail: home.micros01@btinternet.com
;
; If the above don't work, please perform an Internet search to see if I have
; updated the web page hosting service.
; Patched for scrumep2d aka Scrumpel CP/M cube Nick Brok
;==============================================================================

ccp		EQU	0C000h		; Base of CCP.
bdos		EQU	ccp + 0806h	; Base of BDOS.
bios		EQU	ccp + 1600h	; Base of BIOS.

; Set CP/M low memory datA, vector and buffer addresses.

iobyte		EQU	03h		; Intel standard I/O definition byte.
userdrv		EQU	04h		; Current user number and drive.
tpabuf		EQU	80h		; Default I/O buffer and command line storage.

acia0stat	equ	01h
acia0data	equ	02h
acia1stat	equ	0a1h
acia1data	equ	0a0h

; IDE interface
; PORT1A and PORT1B are used for controlling the CF-card
; CS0 IWR IRD RST nc  AD2 AD1 AD0	port1a
; DB7 DB6 DB5 DB4 DB3 DB2 DB1 DB0	port1b

port1a		equ	060h
port1b		equ	061h
port1c		equ	062h
port1ctl	equ	063h

int38		EQU	38H
nmi		EQU	66H

blksiz		equ	4096		;CP/M allocation size
hstsiz		equ	512		;host disk sector size
hstspt		equ	32		;host disk sectors/trk
hstblk		equ	hstsiz/128	;CP/M sects/host buff
cpmspt		equ	hstblk * hstspt	;CP/M sectors/track
secmsk		equ	hstblk-1	;sector mask
					;compute sector mask
;secshf		.equ	2		;log2(hstblk)

wrall		equ	0		;write to allocated
wrdir		equ	1		;write to directory
wrual		equ	2		;write to unallocated



; CF registers via port1a

CF_DATA		EQU	0h
CF_FEATURES	EQU	1h
CF_ERROR	EQU	1h
CF_SECCOUNT	EQU	2h
CF_SECTOR	EQU	3h
CF_CYL_LOW	EQU	4h
CF_CYL_HI	EQU	5h
CF_HEAD		EQU	6h
CF_STATUS	EQU	7h
CF_COMMAND	EQU	7h
CF_LBA0		EQU	3h
CF_LBA1		EQU	4h
CF_LBA2		EQU	5h
CF_LBA3		EQU	6h

;CF Features

CF_8BIT		EQU	1
CF_NOCACHE	EQU	082H

;CF Commands

CF_READ_SEC	EQU	020H
CF_WRITE_SEC	EQU	030H
CF_SET_FEAT	EQU 	0EFH

LF		EQU	0AH		;line feed
FF		EQU	0CH		;form feed
CR		EQU	0DH		;carriage RETurn

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

;==============================================================================

	org	bios		; BIOS origin.

;==============================================================================
; BIOS jump table.
;==============================================================================

	jp	boot		;  0 Initialize.
wboote	jp	wboot		;  1 Warm boot.
	jp	const		;  2 Console status.
	jp	conin		;  3 Console input.
	jp	conout		;  4 Console OUTput.
	jp	list		;  5 List OUTput.
	jp	punch		;  6 punch OUTput.
	jp	reader		;  7 Reader input.
	jp	home		;  8 Home disk.
	jp	seldsk		;  9 Select disk.
	jp	settrk		; 10 Select track.
	jp	setsec		; 11 Select sector.
	jp	setdma		; 12 Set DMA ADDress.
	jp	read		; 13 Read 128 bytes.
	jp	write		; 14 Write 128 bytes.
	jp	listst		; 15 List status.
	jp	sectran		; 16 Sector translate.

;==============================================================================
; Disk parameter headers for disk 0 to 15
;==============================================================================
dpbase 	DW 0000h,0000h,0000h,0000h,dirbuf,dpb0,0000h,alv00
 	DW 0000h,0000h,0000h,0000h,dirbuf,dpb,0000h,alv01
 	DW 0000h,0000h,0000h,0000h,dirbuf,dpb,0000h,alv02
 	DW 0000h,0000h,0000h,0000h,dirbuf,dpb,0000h,alv03
 	DW 0000h,0000h,0000h,0000h,dirbuf,dpb,0000h,alv04
 	DW 0000h,0000h,0000h,0000h,dirbuf,dpb,0000h,alv05
 	DW 0000h,0000h,0000h,0000h,dirbuf,dpb,0000h,alv06
 	DW 0000h,0000h,0000h,0000h,dirbuf,dpb,0000h,alv07
 	DW 0000h,0000h,0000h,0000h,dirbuf,dpb,0000h,alv08
 	DW 0000h,0000h,0000h,0000h,dirbuf,dpb,0000h,alv09
 	DW 0000h,0000h,0000h,0000h,dirbuf,dpb,0000h,alv10
 	DW 0000h,0000h,0000h,0000h,dirbuf,dpb,0000h,alv11
 	DW 0000h,0000h,0000h,0000h,dirbuf,dpb,0000h,alv12
 	DW 0000h,0000h,0000h,0000h,dirbuf,dpb,0000h,alv13
 	DW 0000h,0000h,0000h,0000h,dirbuf,dpb,0000h,alv14
 	DW 0000h,0000h,0000h,0000h,dirbuf,dpbLast,0000h,alv15

; First drive has a reserved track for CP/M
dpb0	DW 128	;SPT - sectors per track
	DB 5	;BSH - block shift factor
	DB 31	;BLM - block mask
	DB 1	;EXM - Extent mask
	DW 2043	; (2047-4) DSM - Storage size (blocks - 1)
	DW 511	;DRM - Number of directory entries - 1
	DB 240	;AL0 - 1 bit set per directory block
	DB 0	;AL1 -            "
	DW 0	;CKS - DIR check vector size (DRM+1)/4 (0=fixed disk)
	DW 1	;OFF - Reserved tracks

dpb	DW 128	;SPT - sectors per track
	DB 5	;BSH - block shift factor
	DB 31	;BLM - block mask
	DB 1	;EXM - Extent mask
	DW 2047	;DSM - Storage size (blocks - 1)
	DW 511	;DRM - Number of directory entries - 1
	DB 240	;AL0 - 1 bit set per directory block
	DB 0	;AL1 -            "
	DW 0	;CKS - DIR check vector size (DRM+1)/4 (0=fixed disk)
	DW 0	;OFF - Reserved tracks

; Last drive is smaller because CF is never full 64MB or 128MB
dpbLast
	DW 128	;SPT - sectors per track
	DB 5	;BSH - block shift factor
	DB 31	;BLM - block mask
	DB 1	;EXM - Extent mask
	DW 511	;DSM - Storage size (blocks - 1)  ; 511 = 2MB
		;(for 128MB card), 1279 = 5MB (for 64MB card)
	DW 511	;DRM - Number of directory entries - 1
	DB 240	;AL0 - 1 bit set per directory block
	DB 0	;AL1 -            "
	DW 0	;CKS - DIR check vector size (DRM+1)/4 (0=fixed disk)
	DW 0	;OFF - Reserved tracks

;==============================================================================
; Cold boot
;==============================================================================

boot	di				; Disable interrupts.
	ld	sp,biosstack		; Set default stack.

;	Turn off ROM

	xor	a
	out	(040h),a

;	Initialise SIO already done in ROM


	call	printInline
	db ff
	db "Z80 CP/M BIOS 1.0 by G. Searle 2007-18/PE1GOO"
	db cr,lf
	db cr,lf
	db "CP/M 2.2 "
	db	"Copyright"
	dB	" 1979 (c) by Digital Research"
	db cr,lf,0


	call	cfWait
	ld 	a,CF_8BIT	; Set IDE to be 8bit
	ideout	CF_FEATURES
	ld	a,CF_SET_FEAT
	ideout	CF_COMMAND


	call	cfWait
	ld 	a,CF_NOCACHE	; No write cache
	ideout	CF_FEATURES
	ld	a,CF_SET_FEAT
	ideout	CF_COMMAND

	xor	a		; Clear I/O & drive bytes.
	ld	(userdrv),A
	jp	gocpm

;==============================================================================
; Warm boot
;==============================================================================

wboot	di				; Disable interrupts.
	ld	sp,biosstack		; Set default stack.

	ld	b,11 ; Number of sectors to reload

	ld	a,0
	ld	(hstsec),A
	ld	hl,ccp

rdSectors

	call	cfWait
	ld	a,(hstsec)
	ideout 	CF_LBA0
	ld	a,0
	ideout 	CF_LBA1
	ideout 	CF_LBA2
	ld	a,0E0H
	ideout 	CF_LBA3
	ld 	a,1
	ideout	CF_SECCOUNT

	push 	bc

	call 	cfWait

	LD 	A,CF_READ_SEC
	ideout 	CF_COMMAND

	call 	cfWait

	ld 	c,4

rd4secs512

	ld 	b,128

rdByte512

	idein 	CF_DATA
	ld 	(hl),a
	inc 	hl
	dec 	b
	jr 	nz, rdByte512
	dec 	c
	jr 	nz,rd4secs512

	pop 	bc

	ld	a,(hstsec)
	inc	a
	ld	(hstsec),a

	djnz	rdSectors


;==============================================================================
; Common code for cold and warm boot
;==============================================================================

rtcint	equ	0000h

gocpm	xor	a			; 0 to accumulator
	ld	(hstact),a		; host buffer inactive
	ld	(unacnt),a		; clear unalloc count

	ld	hl,rtcint		; ADDress of serial interrupt.
	ld	(039h),hl
	ld	hl,tpabuf		; ADDress of BIOS DMA buffer.
	ld	(dmaAddr),hl
	ld	a,0C3h			; Opcode for 'JP'.
	ld	(00h),a			; Load at start of RAM.
	ld	(38h),a
	ld	(nmi),a			; Init NMI vector
	ld	hl,wboote		; ADDress of jump for a warm boot.
	ld	(01h),hl
	ld	(nmi+1),hl		; Warm reset per NMI
	ld	(05h),a			; Opcode for 'JP'.
	ld	hl,bdos			; ADDress of jump for the BDOS.
	ld	(06h),hl
	ld	a,(userdrv)		; Save new drive number (0).
	ld	c,a			; Pass drive number in C.
	jp	ccp			; Start CP/M by jumping to the CCP.

;==============================================================================
; Console I/O routines
;==============================================================================

const	ld	a,(iobyte)
	and	00001011b ; Mask off console and high bit of reader
	cp	00001010b ; redirected to reader on UR1/2 (Serial A)
	jr	z,constA
	cp	00000010b ; redirected to reader on TTY/RDR (Serial B)
	jr	z,constB

	and	03 ; remove the reader from the mask - only console bits then remain
	cp	01
	jr	nz,constB

constA	push	hl
	in	a,(acia0stat)
	bit	1,a
	jr	z, dataAEmpty
	ld	a,0FFH
	pop	hl
	ret

dataAEmpty

	ld	a,0
	pop	hl
       	ret


constB	push	hl
	in	a,(acia1stat)
	bit	1,a
	jr	z, dataBEmpty
 	ld	a,0FFH
	pop	hl
	ret

dataBEmpty

	ld	a,0
	pop	hl
        ret

;-----------------------------------------------------------------------------
reader	push	hl
	push	af
reader2	ld	a,(iobyte)
	and	08
	cp	08
	jr	nz,coninB
	jr	coninA
;------------------------------------------------------------------------------

conin	push	hl
	push	af
	ld	a,(iobyte)
	and	03
	cp	02
	jr	z,reader2	; "BAT:" redirect
	cp	01
	jr	nz,coninB
	

coninA	pop	af

waitForCharA

	in	a,(acia0stat)
	bit	1,a
	jr	z,waitForCharA
	in	a,(acia0data)
	pop	hl
	ret			; Char ready in A


coninB	pop	af

waitForCharB

	in	a,(acia1stat)
	bit	1,a
	jr	z, waitForCharB
	in	a,(acia1data)
	pop	hl
	ret			; Char ready in A

;------------------------------------------------------------------------------

list	push	af		; Store character
list2	ld	a,(iobyte)
	and	0C0h
	cp	040h
	jr	nz,conoutB1
	jr	conoutA1

;------------------------------------------------------------------------------
punch	push	af		; Store character
	ld	a,(iobyte)
	and	020h
	cp	020h
	jr	nz,conoutB1
	jr	conoutA1

;------------------------------------------------------------------------------
conout	push	af		; Store character
	ld	a,(iobyte)
	and	03
	CP	02
	jr	z,list2		; "BAT:" redirect
	cp	01
	jr	nz,conoutB1

conoutA1

	in	a,(acia0stat)
	bit	0,a
	jr	z,conouta1
	ld	a,c
	out	(acia0data),a	; OUTput the character
	pop	aF		; RETrieve character
	ret

conoutB1

	in	a,(acia1stat)	; See if SIO channel B is finished transmitting
	bit	0,a
	jr	z,conoutB1	; Loop until SIO flag signals ready
	ld	a,c
	out	(acia1data),a		; OUTput the character
	pop	af		; RETrieve character
	ret

;------------------------------------------------------------------------------
listst	ld	a,0FFh		; Return list status of 0xFF (ready).
	ret

;==============================================================================
; Disk processing entry points
;==============================================================================

seldsk	ld	hl,0000
	ld	a,c
	cp	16		; 16 for 128MB disk, 8 for 64MB disk
	jr	c,chgdsk	; if invalid drive will give BDOS error
	ld	a,(userdrv)	; so set the drive back to a:
	cp	c		; If the default disk is not the same as the
	ret	nz		; selected drive then return, 
	xor	a		; else reset default back to a:
	ld	(userdrv),A	; otherwise will be stuck in a loop
	ld	(sekdsk),A
	ret

chgdsk	ld 	(sekdsk),A
	rlc	a		;*2
	rlc	a		;*4
	rlc	a		;*8
	rlc	a		;*16
	ld 	hl,dpbase
	ld	b,0
	ld	c,a	
	add	hl,bc
	ret

;------------------------------------------------------------------------------
home	ld	a,(hstwrt)	;check for pending write
	or	a
	jr	nz,homed
	ld	(hstact),a	;clear host active flag
homed	ld 	bc,0000h

;------------------------------------------------------------------------------------------------
settrk	ld 	(sektrk),bc	; Set track passed from BDOS in register BC.
	ret

;------------------------------------------------------------------------------
setsec	ld 	(seksec),bc	; Set sector passed from BDOS in register BC.
	ret

;------------------------------------------------------------------------------
setdma	ld 	(dmaAddr),bc	; Set DMA ADDress given by registers BC.
	ret

;------------------------------------------------------------------------------
sectran	push 	bc
	pop 	hl
	ret

;------------------------------------------------------------------------------
		;read the selected CP/M sector

read	xor	a
	ld	(unacnt),a
	ld	a,1
	ld	(readop),a	;read operation
	ld	(rsflag),a	;must read data
	ld	a,wrual
	ld	(wrtype),a	;treat as unalloc
	jp	rwoper		;to perform the read


;------------------------------------------------------------------------------
		;write the selected CP/M sector
write	xor	a		;0 to accumulator
	ld	(readop),a	;not a read operation
	ld	a,c		;write type in c
	ld	(wrtype),a
	cp	wrual		;write unallocated?
	jr	nz,chkuna	;check for unalloc

;
;		write to unallocated, set parameters

	ld	a,blksiz/128	;next unalloc recs
	ld	(unacnt),a
	ld	a,(sekdsk)	;disk to seek
	ld	(unadsk),a	;unadsk = sekdsk
	ld	hl,(sektrk)
	ld	(unatrk),hl	;unatrk = sectrk
	ld	a,(seksec)
	ld	(unasec),a	;unasec = seksec

	;		check for write to unallocated sector

chkuna	ld	a,(unacnt)	;any unalloc remain?
	or	a	
	jr	z,alloc		;skip if not

;
;		more unallocated records remain

	dec	a		;unacnt = unacnt-1
	ld	(unacnt),a
	ld	a,(sekdsk)	;same disk?
	ld	hl,unadsk
	cp	(hl)		;sekdsk = unadsk?
	jp	nz,alloc	;skip if not

;
;		disks are the same

	ld	hl,unatrk
	call	sektrkcmp	;sektrk = unatrk?
	jp	nz,alloc	;skip if not

;
;		tracks are the same

	ld	a,(seksec)	;same sector?
	ld	hl,unasec
	cp	(hl)		;seksec = unasec?
	jp	nz,alloc	;skip if not

;
;		match, move to next sector for future ref

	inc	(hl)		;unasec = unasec+1
	ld	a,(hl)		;end of track?
	cp	cpmspt		;count CP/M sectors
	jr	c,noovf		;skip if no overflow
;
;		overflow to next track

	ld	(hl),0		;unasec = 0
	ld	hl,(unatrk)
	inc	hl
	ld	(unatrk),hl	;unatrk = unatrk+1

;
		;match found, mark as unnecessary read

noovf	xor	a		;0 to accumulator
	ld	(rsflag),a	;rsflag = 0
	jr	rwoper		;to perform the write
;
		;not an unallocated record, requires pre-read

alloc	xor	a		;0 to accum
	ld	(unacnt),a	;unacnt = 0
	inc	a		;1 to accum
	ld	(rsflag),a	;rsflag = 1

;------------------------------------------------------------------------------
		;enter here to perform the read/write

rwoper	xor	a		;zero to accum
	ld	(erflag),a	;no errors (yet)
	ld	a,(seksec)	;compute host sector
	or	a		;carry = 0
	rra			;shift right
	or	a		;carry = 0
	rra			;shift right
	ld	(sekhst),a	;host sector to seek
;
;		active host sector?

	ld	hl,hstact	;host active flag
	ld	a,(hl)
	ld	(hl),1		;always becomes 1
	or	a		;was it already?
	jr	z,filhst	;fill host if not
;
;		host buffer active, same as seek buffer?

	ld	a,(sekdsk)
	ld	hl,hstdsk	;same disk?
	cp	(hl)		;sekdsk = hstdsk?
	jr	nz,nomatch
;
;		same disk, same track?

	ld	hl,hsttrk
	call	sektrkcmp	;sektrk = hsttrk?
	jr	nz,nomatch

;
;		same disk, same track, same buffer?

	ld	a,(sekhst)
	ld	hl,hstsec	;sekhst = hstsec?
	cp	(hl)
	jr	z,match		;skip if match

		;proper disk, but not correct sector

nomatch	ld	a,(hstwrt)	;host written?
	or	a
	call	nz,writehst	;clear host buff

;
		;may have to fill the host buffer

filhst	ld	a,(sekdsk)
	ld	(hstdsk),a
	ld	hl,(sektrk)
	ld	(hsttrk),hl
	ld	a,(sekhst)
	ld	(hstsec),a
	ld	a,(rsflag)	;need to read?
	or	a
	call	nz,readhst	;yes, if 1
	xor	a		;0 to accum
	ld	(hstwrt),a	;no pending write

		;copy data to or from buffer

match	ld	a,(seksec)	;mask buffer number
	and	secmsk		;least signif bits
	ld	l,a		;ready to shift
	ld	h,0		;double count
	add	hl,hl
	add	hl,hl
	add	hl,hl
	add	hl,hl
	add	hl,hl
	add	hl,hl
	add	hl,hl

;		hl has relative host buffer address

	ld	de,hstbuf
	add	hl,de		;hl = host address
	ex	de,hl		;now in DE
	ld	hl,(dmaAddr)	;get/put CP/M data
	ld	c,128		;length of move
	ld	a,(readop)	;which way?
	or	a
	jr	nz,rwmove	;skip if read
;
;	write operation, mark and switch direction

	ld	a,1
	ld	(hstwrt),a	;hstwrt = 1
	ex	de,hl		;source/dest swap
;
		;C initially 128, DE is source, HL is dest

rwmove	ld	a,(de)		;source character
	inc	de
	ld	(hl),a		;to dest
	inc	hl
	dec	c		;loop 128 times
	jr	nz,rwmove

;
;		data has been moved to/from host buffer

	ld	a,(wrtype)	;write type
	cp	wrdir		;to directory?
	ld	a,(erflag)	;in case of errors
	ret	nz		;no further processing

;
;		clear host buffer for directory write

	or	a		;errors?
	ret	nz		;skip if so
	xor	a		;0 to accum
	ld	(hstwrt),a	;buffer written
	call	writehst
	ld	a,(erflag)
	ret

;------------------------------------------------------------------------------
;Utility subroutine for 16-bit compare
sektrkcmp:
		;HL = .unatrk or .hsttrk, compare with sektrk

	ex	de,hl
	ld	hl,sektrk
	ld	a,(de)		;low byte compare
	cp	(HL)		;same?
	ret	nz			;return if not

;		low bytes equal, test high 1s

	inc	de
	inc	hl
	ld	a,(de)
	cp	(hl)	;sets flags
	ret

;==============================================================================
; Convert track/head/sector into LBA for physical access to the disk
;==============================================================================
setLBAaddr:	

	ld	hl,(hsttrk)
	rlc	l
	rlc	l
	rlc	l
	rlc	l
	rlc	l
	ld	a,l
	and	0E0H
	ld	l,a
	ld	a,(hstsec)
	add	a,l
	ld	(lba0),A

	ld	hl,(hsttrk)
	rrc	l
	rrc	l
	rrc	l
	ld	a,l
	and	01FH
	ld	l,a
	rlc	h
	rlc	h
	rlc	h
	rlc	h
	rlc	h
	ld	a,h
	and	020H
	ld	h,a
	ld	a,(hstdsk)
	rlc	a
	rlc	a
	rlc	a
	rlc	a
	rlc	a
	rlc	a
	and	0C0H
	add	a,h
	add	a,l
	ld	(lba1),a
		
	ld	a,(hstdsk)
	rrc	a
	rrc	a
	and	03H
	ld	(lba2),a

; LBA Mode using drive 0 = E0

	ld	a,0E0H
	ld	(lba3),a

	ld	a,(lba0)
	ideout	CF_LBA0
	ld	a,(lba1)
	ideout 	CF_LBA1
	ld	a,(lba2)
	ideout	CF_LBA2

	ld	a,(lba3)
	ideout 	CF_LBA3

	ld 	a,1
	ideout 	CF_SECCOUNT

	ret				

;==============================================================================
; Read physical sector from host
;==============================================================================

readhst	push 	af
	push 	bc
	push 	hl

	call 	cfWait

	call 	setLBAaddr

	ld 	a,CF_READ_SEC
	ideout 	CF_COMMAND

	call 	cfWait

	ld 	c,4
	ld 	hl,hstbuf
rd4secs	ld 	b,128
rdByte	idein 	CF_DATA
	ld 	(hl),a
	inc 	hl
	dec 	b
	jr 	nz, rdByte
	dec 	c
	jr 	nz,rd4secs
	pop 	hl
	pop 	bc
	pop 	af

	xor 	a
	ld	(erflag),a
	ret

;==============================================================================
; Write physical sector to host
;==============================================================================

writehst
	push 	af
	push 	bc
	push 	hl


	call 	cfWait

	call 	setLBAaddr

	ld 	a,CF_WRITE_SEC
	ideout 	CF_COMMAND

	call 	cfWait

	ld 	c,4
	ld 	HL,hstbuf
wr4secs	ld 	b,128
wrByte	ld 	a,(hl)
	ideout	CF_DATA
	inc 	hl
	dec 	b
	jr 	nz, wrByte

	dec 	c
	jr 	nz,wr4secs
	pop 	hl
	pop 	bc
	pop 	af

	xor 	a
	ld	(erflag),a
	ret

;==============================================================================
; Wait for disk to be ready (busy=0,ready=1)
;==============================================================================

cfWait	push 	af
cfWait1	idein 	CF_STATUS
	and 	080H
	cp 	080H
	jr	z,cfWait1
	pop 	af
	ret

;==============================================================================
; Utilities
;==============================================================================

printInline
	ex 	(sp),hl 	; PUSH HL and put RET ADDress into HL
	push 	af
	push 	bc
nextILChar
	ld 	a,(hl)
	CP	0
	jr	z,endOfPrint
	ld  	c,a
	call 	conout		; Print to TTY
	inc 	hl
	jr	nextILChar
endOfPrint
	inc 	hl 		; Get past "null" terminator
	pop 	bc
	pop 	af
	ex 	(sp),hl 	; PUSH new RET ADDress on stack and restore HL
	ret

;==============================================================================
; Data storage
;==============================================================================

dirbuf 	ds 128			;scratch directory area
alv00	ds 257			;allocation vector 0
alv01	ds 257			;allocation vector 1
alv02	ds 257			;allocation vector 2
alv03	ds 257			;allocation vector 3
alv04	ds 257			;allocation vector 4
alv05	ds 257			;allocation vector 5
alv06	ds 257			;allocation vector 6
alv07	ds 257			;allocation vector 7
alv08	ds 257			;allocation vector 8
alv09	ds 257			;allocation vector 9
alv10	ds 257			;allocation vector 10
alv11	ds 257			;allocation vector 11
alv12	ds 257			;allocation vector 12
alv13	ds 257			;allocation vector 13
alv14	ds 257			;allocation vector 14
alv15	ds 257			;allocation vector 15

lba0	DB	00h
lba1	DB	00h
lba2	DB	00h
lba3	DB	00h

	DS	020h		; Start of BIOS stack area.

biosstack	EQU	$

sekdsk	ds	1		;seek disk number
sektrk	ds	2		;seek track number
seksec	ds	2		;seek sector number
;
hstdsk	ds	1		;host disk number
hsttrk	ds	2		;host track number
hstsec	ds	1		;host sector number
;
sekhst	ds	1		;seek shr secshf
hstact	ds	1		;host active flag
hstwrt	ds	1		;host written flag
;
unacnt	ds	1		;unalloc rec cnt
unadsk	ds	1		;last unalloc disk
unatrk	ds	2		;last unalloc track
unasec	ds	1		;last unalloc sector
;
erflag	ds	1		;error reporting
rsflag	ds	1		;read sector flag
readop	ds	1		;1 if read operation
wrtype	ds	1		;write operation type
dmaAddr	ds	2		;last dma address
hstbuf	ds	512		;host buffer

hstBufEnd	EQU	$


biosEnd		EQU	$

; Disable the ROM, pop the active IO port from the stack (supplied by monitor),
; then start CP/M
popAndRun

	xor	a 
	out	(040h),A

	cp	01
	jr	z,consoleAtB
	ld	a,01

;(List is TTY:, Punch is TTY:, Reader is TTY:, Console is CRT:)

	jr	setIOByte

consoleAtB

	ld	a,00

;(List is TTY:, Punch is TTY:, Reader is TTY:, Console is TTY:)

setIOByte

	ld	(iobyte),A
	jp	bios

;Delay routine for soft reset CF-card

vdelay	ld	a,2
del1	dec	a
	jr	nz,del1
	dec	de
	ld	a,d
	or	e
	jp	nz,vdelay
	ret

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

;==============================================================================
; Normal start CP/M vector
;==============================================================================

	org	0FFFEH

	dw	popAndRun

	end
