	cpu	z80
;**************************************************************
;*
;*             C P / M   version   2 . 2
;*
;*   Reconstructed from memory image on February 27, 1981
;*
;*                by Clark A. Calkins
;*
;* Optimized for Z80 and some additions Nick Brok
;**************************************************************
;
;   Set memory limit here. This is the amount of contigeous
; ram starting from 0000. CP/M will reside at the end of this space.
;

iobyte	equ	3		;i/o definition byte.
tdrive	equ	4		;current drive name and user number.
entry	equ	5		;entry point for the cp/m bdos.
tfcb	equ	5ch		;default file control block.
tbuff	equ	80h		;i/o buffer and command line storage.
tbase	equ	100h		;transiant program storage area.
;
;   Set control character equates.
;
cntrlc	equ	3		;control-c
cntrle	equ	05h		;control-e
bs	equ	08h		;backspace
tab	equ	09h		;tab
lf	equ	0ah		;line feed
ff	equ	0ch		;form feed
cr	equ	0dh		;carriage return
cntrlp	equ	10h		;control-p
cntrlr	equ	12h		;control-r
cntrls	equ	13h		;control-s
cntrlu	equ	15h		;control-u
cntrlx	equ	18h		;control-x
cntrlz	equ	1ah		;control-z (end-of-file mark)
del	equ	7fh		;rubout
;
;   Set origin for CP/M
;
	org	0c000h
;
cbase	jp	command		;execute command processor (ccp).
	jp	clearbuf	;entry to empty input buffer before starting ccp.

;
;   Standard cp/m ccp input buffer. Format is (max length),
; (actual length), (char #1), (char #2), (char #3), etc.
;
inbuff	db	127		;length of input buffer.
	db	0		;current length of contents.
	db	"Copyright"
	db	" 1979 (c) by Digital Research      "
	db	0,0,0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0,0,0,0
inpoint dw	inbuff+2	;input line pointer
namepnt dw	0		;input line pointer used for error message. Points to
;			;start of name in error.
;
;   Routine to print (A) on the console. All registers used.
;
print	ld	e,a		;setup bdos call.
	ld	c,2
	jp	entry
;
;   Routine to print (A) on the console and to save (BC).
;
printb	push	bc
	call	print
	pop	bc
	ret	
;
;   Routine to send a carriage return, line feed combination
; to the console.
;
crlf	ld	a,cr
	call	printb
	ld	a,lf
	jr	printb
;
;   Routine to send one space to the console and save (BC).
;
space	ld	a,' '
	jr	printb
;
;   Routine to print character string pointed to be (BC) on the
; console. It must terminate with a null byte.
;
pline	push	bc
	call	crlf
	pop	hl
pline2	ld	a,(hl)
	or	a
	ret	z
	inc	hl
	push	hl
	call	print
	pop	hl
	jr	pline2
;
;   Routine to reset the disk system.
;
resdsk	ld	c,13
	jp	entry
;
;   Routine to select disk (A).
;
dsksel	ld	e,a
	ld	c,14
	jp	entry
;
;   Routine to call bdos and save the return code. The zero
; flag is set on a return of 0ffh.
;
entry1	call	entry
	ld	(rtncode),A	;save return code.
	inc	a		;set zero if 0ffh returned.
	ret	
;
;   Routine to open a file. (DE) must point to the FCB.
;
open	ld	c,15
	jr	entry1
;
;   Routine to open file at (FCB).
;
openfcb xor	a		;clear the record number byte at fcb+32
	ld	(fcb+32),a
	ld	de,fcb
	jr	open
;
;   Routine to close a file. (DE) points to FCB.
;
close	ld	c,16
	jr	entry1
;
;   Routine to search for the first file with ambigueous name
; (DE).
;
srchfst ld	c,17
	jr	entry1
;
;   Search for the next ambigeous file name.
;
srchnxt ld	c,18
	jr	entry1
;
;   Search for file at (FCB).
;
srchfcb ld	de,fcb
	jr	srchfst
;
;   Routine to delete a file pointed to by (DE).
;
delete	ld	c,19
	jp	entry
;
;   Routine to call the bdos and set the zero flag if a zero
; status is returned.
;
entry2	call	entry
	or	a		;set zero flag if appropriate.
	ret	
;
;   Routine to read the next record from a sequential file.
; (DE) points to the FCB.
;
rdrec	ld	c,20
	jr	entry2
;
;   Routine to read file at (FCB).
;
readfcb ld	de,fcb
	jr	rdrec
;
;   Routine to write the next record of a sequential file.
; (DE) points to the FCB.
;
wrtrec	ld	c,21
	jr	entry2
;
;   Routine to create the file pointed to by (DE).
;
create 	ld	c,22
	jp	entry1
;
;   Routine to rename the file pointed to by (DE). Note that
; the new name starts at (DE+16).
;
renam	ld	c,23
	jp	entry
;
;   Get the current user code.
;
getusr	ld	e,0ffh
;
;   Routne to get or set the current user code.
; If (E) is FF then this is a GET, else it is a SET.
;
getsetuc
	ld	c,32
	jp	entry
;
;   Routine to set the current drive byte at (TDRIVE).
;
setcdrv call	getusr		;get user number
	add	a,a		;and shift into the upper 4 bits.
	add	a,a
	add	a,a
	add	a,a
	ld	hl,cdrive	;now add in the current drive number.
	or	(hl)
	ld	(tdrive),a	;and save.
	ret	
;
;   Move currently active drive down to (TDRIVE).
;
movecd	ld	a,(cdrive)
	ld	(tdrive),a
	ret	
;
;   Routine to convert (A) into upper case ascii. Only letters
; are affected.
;
upper	cp	'A'		;check for letters in the range of 'a' to 'z'.
	ret	c
	cp	'{'
	ret	nc
	and	5fh		;convert it if found.
	ret	
;
;   Routine to get a line of input. We must check to see if the
; user is in (BATCH) mode. If so, then read the input from file
; ($$$.SUB). At the end, reset to console input.
;
getinp	ld	a,(batch)	;if =0, then use console input.
	or	a
	jp	z,getinp1
;
;   Use the submit file ($$$.sub) which is prepared by a
; SUBMIT run. It must be on drive (A) and it will be deleted
; if and error occures (like eof).
;
	ld	a,(cdrive)	;select drive 0 if need be.
	or	a
	ld	a,0		;always use drive A for submit.
	call	nz,dsksel	;select it if required.
	ld	de,batchfcb
	call	open		;look for it.
	jp	z,getinp1	;if not there, use normal input.
	ld	a,(batchfcb+15)	;get last record number+1.
	dec	a
	ld	(batchfcb+32),a
	ld	de,batchfcb
	call	rdrec		;read last record.
	jp	nz,getinp1	;quit on end of file.
;
;   Move this record into input buffer.
;
	ld	de,inbuff+1
	ld	hl,tbuff	;data was read into buffer here.
	ld	b,128		;all 128 characters may be used.
	call	hl2de		;(HL) to (DE), (B) bytes.
	ld	hl,batchfcb+14
	ld	(hl),0		;zero out the 's2' byte.
	inc	hl		;and decrement the record count.
	dec	(hl)
	ld	de,batchfcb	;close the batch file now.
	call	close
	jp	z,getinp1	;quit on an error.
	ld	a,(cdrive)	;re-select previous drive if need be.
	or	a
	call	nz,dsksel	;don't do needless selects.
;
;   Print line just read on console.
;
	ld	hl,inbuff+2
	call	pline2
	call	chkcon		;check console, quit on a key.
	jr	z,getinp2	;jump if no key is pressed.
;
;   Terminate the submit job on any keyboard input. Delete this
; file such that it is not re-started and jump to normal keyboard
; input section.
;
	call	delbatch	;delete the batch file.
	jp	cmmnd1		;and restart command input.
;
;   Get here for normal keyboard input. Delete the submit file
; incase there was one.
;
getinp1	call	delbatch	;delete file ($$$.sub).
	call	setcdrv		;reset active disk.
	ld	c,10		;get line from console device.
	ld	de,inbuff
	call	entry
	call	movecd		;reset current drive (again).
;
;   Convert input line to upper case.
;
getinp2	ld	hl,inbuff+1
	ld	b,(hl)		;(B)=character counter.
getinp3 inc	hl
	ld	a,b		;end of the line?
	or	a
	jr	z,getinp4
	ld	a,(hl)		;convert to upper case.
	call	upper
	ld	(hl),a
	dec	b		;adjust character count.
	jr	getinp3
getinp4 ld	(hl),a		;add trailing null.
	ld	hl,inbuff+2
	ld	(inpoint),hl	;reset input line pointer.
	ret	
;
;   Routine to check the console for a key pressed. The zero
; flag is set is none, else the character is returned in (A).
;
chkcon	ld	c,11		;check console.
	call	entry
	or	a
	ret	z		;return if nothing.
	ld	c,1		;else get character.
	call	entry
	or	a		;clear zero flag and return.
	ret	
;
;   Routine to get the currently active drive number.
;
getdsk	ld	c,25
	jp	entry
;
;   Set the standard dma address.
;
stddma	ld	de,tbuff
;
;   Routine to set the dma address to (DE).
;
dmaset	ld	c,26
	jp	entry
;
;  Delete the batch file created by SUBMIT.
;
delbatch
	ld	hl,batch	;is batch active?
	ld	a,(hl)
	or	a
	ret	z
	ld	(hl),0		;yes, de-activate it.
	xor	a
	call	dsksel		;select drive 0 for sure.
	ld	de,batchfcb	;and delete this file.
	call	delete
	ld	a,(cdrive)	;reset current drive.
	jp	dsksel
;
;   Check to two strings at (PATTRN1) and (PATTRN2). They must be
; the same or we halt....
;
verify	ld	de,pattrn1	;these are the serial number bytes.
	ld	hl,pattrn2	;ditto, but how could they be different?
	ld	b,6		;6 bytes each.
verify1	ld	a,(de)
	cp	(hl)
	jp	nz,halt		;jump to halt routine.
	inc	de
	inc	hl
	dec	b
	jr	nz,verify1
	ret	
;
;   Print back file name with a '?' to indicate a syntax error.
;
synerr	call	crlf		;end current line.
	ld	hl,(namepnt)	;this points to name in error.
synerr1	ld	a,(hl)		;print it until a space or null is found.
	cp	' '
	jr	z,synerr2
	or	a
	jr	z,synerr2
	push	hl
	call	print
	pop	hl
	inc	hl
	jr	synerr1
synerr2 ld	a,'?'		;add trailing '?'.
	call	print
	call	crlf
	call	delbatch	;delete any batch file.
	jp	cmmnd1		;and restart from console input.
;
;   Check character at (DE) for legal command input. Note that the
; zero flag is set if the character is a delimiter.
;
check	ld	a,(de)
	or	a
	ret	z
	cp	' '		;control characters are not legal here.
	jp	c,synerr
	ret	z		;check for valid delimiter.
	cp	'='
	ret	z
	cp	'_'
	ret	z
	cp	'.'
	ret	z
	cp	':'
	ret	z
	cp	03bh ; ';'
	ret	z
	cp	'<'
	ret	z
	cp	'>'
	ret	z
	ret	
;
;   Get the next non-blank character from (DE).
;
nonblank
	ld	a,(de)
	or	a		;string ends with a null.
	ret	z
	cp	' '
	ret	nz
	inc	de
	jr	nonblank
;
;   Add (HL)=(HL)+(A)
;
addhl	add	a,l
	ld	l,a
	ret	nc		;take care of any carry.
	inc	h
	ret	
;
;   Convert the first name in (FCB).
;
convfst ld	a,0
;
;   Format a file name (convert * to '?', etc.). On return,
; (A)=0 is an unambigeous name was specified. Enter with (A) equal to
; the position within the fcb for the name (either 0 or 16).
;
convert ld	hl,fcb
	call	addhl
	push	hl
	push	hl
	xor	a
	ld	(chgdrv),a	;initialize drive change flag.
	ld	hl,(inpoint)	;set (HL) as pointer into input line.
	ex	de,hl
	call	nonblank	;get next non-blank character.
	ex	de,hl
	ld	(namepnt),hl	;save pointer here for any error message.
	ex	de,hl
	pop	hl
	ld	a,(de)		;get first character.
	or	a
	jr	z,convrt1
	sbc	a,'A'-1		;might be a drive name, convert to binary.
	ld	b,a		;and save.
	inc	de		;check next character for a ':'.
	ld	a,(de)
	cp	':'
	jr	z,convrt2
	dec	de		;nope, move pointer back to the start of the line.
convrt1 ld	a,(cdrive)
	ld	(hl),a
	jr	convrt3
convrt2 ld	a,b
	ld	(chgdrv),a	;set change in drives flag.
	ld	(hl),b
	inc	de
;
;   Convert the basic file name.
;
convrt3 ld	b,08h
convrt4 call	check
	jr	z,convrt8
	inc	hl
	cp	'*'		;note that an '*' will fill the remaining
	jr	nz,convrt5	;field with '?'.
	ld	(hl),'?'
	jr	convrt6
convrt5 ld	(hl),a
	inc	de
convrt6 dec	b
	jr	nz,convrt4
CONVRT7 call	check		;get next delimiter.
	jr	z,getext
	inc	de
	jr	convrt7
convrt8 inc	hl		;blank fill the file name.
	ld	(hl),' '
	dec	b
	jr	nz,convrt8
;
;   Get the extension and convert it.
;
getext	ld	b,03h
	cp	'.'
	jr	nz,getext5
	inc	de
getext1 call	check
	jr	z,getext5
	inc	hl
	cp	'*'
	jr	nz,getext2
	ld	(hl),'?'
	jr	getext3
getext2 ld	(hl),a
	inc	de
getext3 dec	b
	jr	nz,getext1
getext4 call	check
	jp	z,getext6
	inc	de
	jr	getext4
getext5 inc	hl
	ld	(hl),' '
	dec	b
	jr	nz,getext5
getext6 ld	b,3
getext7 inc	hl
	ld	(hl),0
	dec	b
	jr	nz,getext7
	ex	de,hl
	ld	(inpoint),hl	;save input line pointer.
	pop	hl
;
;   Check to see if this is an ambigeous file name specification.
; Set the (A) register to non zero if it is.
;
	ld	bc,11		;set name length.
getext8 inc	hl
	ld	a,(hl)
	cp	'?'		;any question marks?
	jr	nz,getext9
	inc	b		;count them.
getext9 dec	c
	jr	nz,getext8
	ld	a,b
	or	a
	ret	
;
;   CP/M command table. Note commands can be either 3 or 4 characters long.
;
numcmds equ	6		;number of commands
cmdtbl	db	"DIR "
	db	"ERA "
	db	"TYPE"
	db	"SAVE"
	db	"REN "
	db	"USER"
;
;   The following six bytes must agree with those at (PATTRN2)
; or cp/m will HALT. Why?
;
pattrn1 db	0,22,0,0,0,0	;(* serial number bytes *).
;
;   Search the command table for a match with what has just
; been entered. If a match is found, then we jump to the
; proper section. Else jump to (UNKNOWN).
; On return, the (C) register is set to the command number
; that matched (or NUMCMDS+1 if no match).
;
search	ld	hl,cmdtbl
	ld	c,0
search1 ld	a,c
	cp	numcmds		;this commands exists.
	ret	nc
	ld	de,fcb+1	;check this one.
	ld	b,4		;max command length.
search2 ld	a,(de)
	cp	(hl)
	jr	nz,search3	;not a match.
	inc	de
	inc	hl
	dec	b
	jr	nz,search2
	ld	a,(de)		;allow a 3 character command to match.
	cp	' '
	jr	nz,search4
	ld	a,c		;set return register for this command.
	ret	
search3 inc	hl
	dec	b
	jr	nz,search3
search4 inc	c
	jr	search1
;
;   Set the input buffer to empty and then start the command
; processor (ccp).
;
clearbuf
	xor	a
	ld	(inbuff+1),a	;second byte is actual length.
;
;**************************************************************
;*
;*
;* C C P  -   C o n s o l e   C o m m a n d   P r o c e s s o r
;*
;**************************************************************
;*
command ld	sp,ccpstack	;setup stack area.
	push	bc		;note that (C) should be equal to:
	ld	a,c		;(uuuudddd) where 'uuuu' is the user number
	rra			;and 'dddd' is the drive number.
	rra	
	rra	
	rra	
	and	0fh		;isolate the user number.
	ld	e,a
	call	getsetuc	;and set it.
	call	resdsk		;reset the disk system.
	ld	(batch),a	;clear batch mode flag.
	pop	bc
	ld	a,c
	and	0fh		;isolate the drive number.
	ld	(cdrive),a	;and save.
	call	dsksel		;...and select.
	ld	a,(inbuff+1)
	or	a		;anything in input buffer already?
	jr	nz,cmmnd2	;yes, we just process it.
;
;   Entry point to get a command line from the console.
;
cmmnd1	ld	sp,ccpstack	;set stack straight.
	call	crlf		;start a new line on the screen.
	call	getdsk		;get current drive.
	add	a,'A'
	call	print		;print current drive.
	ld	a,'>'
	call	print		;and add prompt.
	call	getinp		;get line from user.
;
;   Process command line here.
;
cmmnd2	ld	de,tbuff
	call	dmaset		;set standard dma address.
	call	getdsk
	ld	(cdrive),a	;set current drive.
	call	convfst		;convert name typed in.
	call	nz,synerr	;wild cards are not allowed.
	ld	a,(chgdrv)	;if a change in drives was indicated,
	or	a		;then treat this as an unknown command
	jp	nz,unknown	;which gets executed.
	call	search		;else search command table for a match.
;
;   Note that an unknown command returns
; with (A) pointing to the last address
; in our table which is (UNKNOWN).
;
	ld	hl,cmdadr	;now, look thru our address table for command (A).
	ld	e,a		;set (DE) to command number.
	ld	d,0
	add	hl,de
	add	hl,de		;(HL)=(CMDADR)+2*(command number).
	ld	a,(hl)		;now pick out this address.
	inc	hl
	ld	h,(hl)
	ld	l,a
	jp	(hl)		;now execute it.
;
;   CP/M command address table.
;
cmdadr	dw	direct,erase,type,save
	dw	rename,user,unknown
;
;   Halt the system. Reason for this is unknown at present.
;
halt	ld	hl,76f3h	;'DI HLT' instructions.
	ld	(cbase),hl
	ld	hl,cbase
	jp	(hl)
;
;   Read error while TYPEing a file.
;
rderror ld	bc,rderr
	jp	pline
rderr 	db	"Read error"
	db	0
;
;   Required file was not located.
;
none	ld	bc,nofile
	jp	pline
nofile	db	"No file"
	db	0
;
;   Decode a command of the form 'A>filename number{ filename}.
; Note that a drive specifier is not allowed on the first file
; name. On return, the number is in register (A). Any error
; causes 'filename?' to be printed and the command is aborted.
;
decode	call	convfst		;convert filename.
	ld	a,(chgdrv)	;do not allow a drive to be specified.
	or	a
	jp	nz,synerr
	ld	hl,fcb+1	;convert number now.
	ld	bc,11		;(B)=sum register, (C)=max digit count.
decode1 ld	a,(hl)
	cp	' '		;a space terminates the numeral.
	jr	z,decode3
	inc	hl
	sub	'0'		;make binary from ascii.
	cp	10		;legal digit?
	jp	nc,synerr
	ld	d,a		;yes, save it in (D).
	ld	a,b		;compute (B)=(B)*10 and check for overflow.
	and	0e0h
	jp	nz,synerr
	ld	a,b
	rlca	
	rlca	
	rlca			;(A)=(B)*8
	add	a,b		;.......*9
	jp	c,synerr
	add	a,b		;.......*10
	jp	c,synerr
	add	a,d		;add in new digit now.
decode2 jp	c,synerr
	ld	b,a		;and save result.
	dec	c		;only look at 11 digits.
	jr	nz,decode1
	ret	
decode3 ld	a,(hl)		;spaces must follow (why?).
	cp	' '
	jp	nz,synerr
	inc	hl
decode4:dec	c
	jr	nz,decode3
	ld	a,b		;set (A)=the numeric value entered.
	ret	
;
;   Move 3 bytes from (HL) to (DE). Note that there is only
; one reference to this at (A2D5h).
;
move3	ld	b,3
;
;   Move (B) bytes from (HL) to (DE).
;
hl2de	ld	a,(hl)
	ld	(de),a
	inc	hl
	inc	de
	dec	b
	jr	nz,hl2de
	ret	
;
;   Compute (HL)=(TBUFF)+(A)+(C) and get the byte that's here.
;
extract ld	hl,tbuff
	add	a,c
	call	addhl
	ld	a,(hl)
	ret	
;
;  Check drive specified. If it means a change, then the new
; drive will be selected. In any case, the drive byte of the
; fcb will be set to null (means use current drive).
;
dselect xor	a		;null out first byte of fcb.
	ld	(fcb),a
	ld	a,(chgdrv)	;a drive change indicated?
	or	a
	ret	z
	dec	a		;yes, is it the same as the current drive?
	ld	hl,cdrive
	cp	(hl)
	ret	z
	jp	dsksel		;no. Select it then.
;
;   Check the drive selection and reset it to the previous
; drive if it was changed for the preceeding command.
;
resetdr ld	a,(chgdrv)	;drive change indicated?
	or	a
	ret	z
	dec	a		;yes, was it a different drive?
	ld	hl,cdrive
	cp	(hl)
	ret	z
	ld	a,(cdrive)	;yes, re-select our old drive.
	jp	dsksel
;
;**************************************************************
;*
;*           D I R E C T O R Y   C O M M A N D
;*
;**************************************************************
;
direct	call	convfst		;convert file name.
	call	dselect		;select indicated drive.
	ld	hl,fcb+1	;was any file indicated?
	ld	a,(hl)
	cp	' '
	jr	nz,direct2
	ld	b,11		;no. Fill field with '?' - same as *.*.
direct1 ld	(hl),'?'
	inc	hl
	dec	b
	jr	nz,direct1
direct2 ld	e,0		;set initial cursor position.
	push	de
	call	srchfcb		;get first file name.
	call	z,none		;none found at all?
direct3 jp	z,direct9	;terminate if no more names.
	ld	a,(rtncode)	;get file's position in segment (0-3).
	rrca	
	rrca	
	rrca	
	and	60h		;(A)=position*32
	ld	c,a
	ld	a,10
	call	extract		;extract the tenth entry in fcb.
	rla			;check system file status bit.
	jr	c,direct8	;we don't list them.
	pop	de
	ld	a,e		;bump name count.
	inc	e
	push	de
	and	03h		;at end of line?
	push	af
	jr	nz,direct4
	call	crlf		;yes, end this line and start another.
	push	bc
	call	getdsk		;start line with ('A:').
	pop	bc
	add	a,'A'
	call	printb
	ld	a,':'
	call	printb
	jr	direct5
direct4 call	space		;add seperator between file names.
	ld	a,':'
	call	printb
direct5 call	space
	ld	b,1		;'extract' each file name character at a time.
direct6 ld	a,b
	call	extract
	and	7fh		;strip bit 7 (status bit).
	cp	' '		;are we at the end of the name?
	jr	nz,drect65
	pop	af		;yes, don't print spaces at the end of a line.
	push	af
	cp	3
	jr	nz,drect63
	ld	a,9		;first check for no extension.
	call	extract
	and	7fh
	cp	' '
	jr	z,direct7	;don't print spaces.
drect63 ld	a,' '		;else print them.
drect65 call	printb
	inc	b		;bump to next character psoition.
	ld	a,b
	cp	12		;end of the name?
	jr	nc,direct7
	cp	9		;nope, starting extension?
	jr	nz,direct6
	call	space		;yes, add seperating space.
	jr	direct6
direct7 pop	af		;get the next file name.
direct8 call	chkcon		;first check console, quit on anything.
	jr	nz,direct9
	call	srchnxt		;get next name.
	jr	direct3		;and continue with our list.
direct9 pop	de		;restore the stack and return to command level.
	jp	getback
;
;**************************************************************
;*
;*                E R A S E   C O M M A N D
;*
;**************************************************************
;
erase	call	convfst		;convert file name.
	cp	11		;was '*.*' entered?
	jr	nz,erase1
	ld	bc,yesno	;yes, ask for confirmation.
	call	pline
	call	getinp
	ld	hl,inbuff+1
	dec	(hl)		;must be exactly 'y'.
	jp	nz,cmmnd1
	inc	hl
	ld	a,(hl)
	cp	'y'
	jp	nz,cmmnd1
	inc	hl
	ld	(inpoint),hl	;save input line pointer.
erase1	call	dselect		;select desired disk.
	ld	de,fcb
	call	delete		;delete the file.
	inc	a
	call	z,none		;not there?
	jp	getback		;return to command level now.
yesno	db	"All (y/n)?"
	db	0
;
;**************************************************************
;*
;*            T Y P E   C O M M A N D
;*
;**************************************************************
;
type	call	convfst		;convert file name.
	jp	nz,synerr	;wild cards not allowed.
	call	dselect		;select indicated drive.
	call	openfcb		;open the file.
	jr	z,type5		;not there?
	call	crlf		;ok, start a new line on the screen.
	ld	hl,nbytes	;initialize byte counter.
	ld	(hl),0ffh	;set to read first sector.
type1	ld	hl,nbytes
type2	ld	a,(hl)		;have we written the entire sector?
	cp	128
	jp	c,type3
	push	hl		;yes, read in the next one.
	call	readfcb
	pop	hl
	jr	nz,type4	;end or error?
	xor	a		;ok, clear byte counter.
	ld	(hl),a
type3	inc	(hl)		;count this byte.
	ld	hl,tbuff	;and get the (A)th one from the buffer (TBUFF).
	call	addhl
	ld	a,(hl)
	cp	cntrlz		;end of file mark?
	jp	z,getback
	call	print		;no, print it.
	call	chkcon		;check console, quit if anything ready.
	jp	nz,getback
	jr	type1
;
;   Get here on an end of file or read error.
;
type4	dec	a		;read error?
	jp	z,getback
	call	rderror		;yes, print message.
type5	call	resetdr		;and reset proper drive
	jp	synerr		;now print file name with problem.
;
;**************************************************************
;*
;*            S A V E   C O M M A N D
;*
;**************************************************************
;
save	call	decode		;get numeric number that follows SAVE.
	push	af		;save number of pages to write.
	call	convfst		;convert file name.
	jp	nz,synerr	;wild cards not allowed.
	call	dselect		;select specified drive.
	ld	de,fcb		;now delete this file.
	push	de
	call	delete
	pop	de
	call	create		;and create it again.
	jr	z,save3		;can't create?
	xor	a		;clear record number byte.
	ld	(fcb+32),a
	pop	af		;convert pages to sectors.
	ld	l,a
	ld	h,0
	add	hl,hl		;(HL)=number of sectors to write.
	ld	de,tbase	;and we start from here.
save1	ld	a,h		;done yet?
	or	l
	jr	z,save2
	dec	hl		;nope, count this and compute the start
	push	hl		;of the next 128 byte sector.
	ld	hl,128
	add	hl,de
	push	hl		;save it and set the transfer address.
	call	dmaset
	ld	de,fcb		;write out this sector now.
	call	wrtrec
	pop	de		;reset (DE) to the start of the last sector.
	pop	hl		;restore sector count.
	jr	nz,save3	;write error?
	jr	save1
;
;   Get here after writing all of the file.
;
save2	ld	de,fcb		;now close the file.
	call	close
	inc	a		;did it close ok?
	jr	nz,save4
;
;   Print out error message (no space).
;
save3	ld	bc,nospace
	call	pline
save4	call	stddma		;reset the standard dma address.
	jp	getback
nospace db	"No space"
	db	0
;
;**************************************************************
;*
;*           R E N A M E   C O M M A N D
;*
;**************************************************************
;
rename	call	convfst		;convert first file name.
	jp	nz,synerr	;wild cards not allowed.
	ld	a,(chgdrv)	;remember any change in drives specified.
	push	af
	call	dselect		;and select this drive.
	call	srchfcb		;is this file present?
	jr	nz,rename6	;yes, print error message.
	ld	hl,fcb		;yes, move this name into second slot.
	ld	de,fcb+16
	ld	b,16
	call	hl2de
	ld	hl,(inpoint)	;get input pointer.
	ex	de,hl
	call	nonblank	;get next non blank character.
	cp	'='		;only allow an '=' or '_' seperator.
	jr	z,rename1
	cp	'_'
	jr	nz,rename5
rename1 ex	de,hl
	inc	hl		;ok, skip seperator.
	ld	(inpoint),hl	;save input line pointer.
	call	convfst		;convert this second file name now.
	jr	nz,rename5	;again, no wild cards.
	pop	af		;if a drive was specified, then it
	ld	b,a		;must be the same as before.
	ld	hl,chgdrv
	ld	a,(hl)
	or	a
	jr	z,rename2
	cp	b
	ld	(hl),b
	jr	nz,rename5	;they were different, error.
rename2 ld	(hl),b		;	reset as per the first file specification.
	xor	a
	ld	(fcb),a		;clear the drive byte of the fcb.
rename3 call	srchfcb		;and go look for second file.
	jr	z,rename4	;doesn't exist?
	ld	de,fcb
	call	renam		;ok, rename the file.
	jp	getback
;
;   Process rename errors here.
;
rename4 call	none		;file not there.
	jp	getback
rename5 call	resetdr		;bad command format.
	jp	synerr
rename6 ld	bc,exists	;destination file already exists.
	call	pline
	jp	getback
exists	db	"File exists"
	db	0
;
;**************************************************************
;*
;*             U S E R   C O M M A N D
;*
;**************************************************************
;
user	call	decode		;get numeric value following command.
	cp	16		;legal user number?
	jp	nc,synerr
	ld	e,a		;yes but is there anything else?
	ld	a,(fcb+1)
	cp	' '
	jp	z,synerr	;yes, that is not allowed.
	call	getsetuc	;ok, set user code.
	jp	getback1
;
;**************************************************************
;*
;*        T R A N S I A N T   P R O G R A M   C O M M A N D
;*
;**************************************************************
;
unknown call	verify		;check for valid system (why?).
	ld	a,(fcb+1)	;anything to execute?
	cp	' '
	jr	nz,unkwn1
	ld	a,(chgdrv)	;nope, only a drive change?
	or	a
	jp	z,getback1	;neither???
	dec	a
	ld	(cdrive),a	;ok, store new drive.
	call	movecd		;set (TDRIVE) also.
	call	dsksel		;and select this drive.
	jp	getback1	;then return.
;
;   Here a file name was typed. Prepare to execute it.
;
unkwn1	ld	de,fcb+9	;an extension specified?
	ld	a,(de)
	cp	' '
	jp	nz,synerr	;yes, not allowed.
unkwn2	push	de
	call	dselect		;select specified drive.
	pop	de
	ld	hl,comfile	;set the extension to 'COM'.
	call	move3
	call	openfcb		;and open this file.
	jp	z,unkwn9	;not present?
;
;   Load in the program.
;
	ld	hl,tbase	;store the program starting here.
unkwn3	push	hl
	ex	de,hl
	call	dmaset		;set transfer address.
	ld	de,fcb		;and read the next record.
	call	rdrec
	jr	nz,unkwn4	;end of file or read error?
	pop	hl		;nope, bump pointer for next sector.
	ld	de,128
	add	hl,de
	ld	de,cbase	;enough room for the whole file?
	ld	a,l
	sub	e
	ld	a,h
	sbc	a,d
	jr	nc,unkwn0	;no, it can't fit.
	jr	unkwn3
;
;   Get here after finished reading.
;
unkwn4	pop	hl
	dec	a		;normal end of file?
	jp	nz,unkwn0
	call	resetdr		;yes, reset previous drive.
	call	convfst		;convert the first file name that follows
	ld	hl,chgdrv	;command name.
	push	hl
	ld	a,(hl)		;set drive code in default fcb.
	ld	(fcb),a
	ld	a,16		;put second name 16 bytes later.
	call	convert		;convert second file name.
	pop	hl
	ld	a,(hl)		;and set the drive for this second file.
	ld	(fcb+16),a
	xor	a		;clear record byte in fcb.
	ld	(fcb+32),a
	ld	de,tfcb		;move it into place at(005Ch).
	ld	hl,fcb
	ld	b,33
	call	hl2de
	ld	hl,inbuff+2	;now move the remainder of the input
unkwn5	ld	a,(hl)		;line down to (0080h). Look for a non blank.
	or	a		;or a null.
	jr	z,unkwn6
	cp	' '
	jr	z,unkwn6
	inc	hl
	jr	unkwn5
;
;   Do the line move now. It ends in a null byte.
;
unkwn6	ld	b,0		;keep a character count.
	ld	de,tbuff+1	;data gets put here.
unkwn7	ld	a,(hl)		;move it now.
	ld	(de),a
	or	a
	jr	z,unkwn8
	inc	b
	inc	hl
	inc	de
	jr	unkwn7
unkwn8	ld	a,b		;now store the character count.
	ld	(tbuff),a
	call	crlf		;clean up the screen.
	call	stddma		;set standard transfer address.
	call	setcdrv		;reset current drive.
	call	tbase		;and execute the program.
;
;   Transiant programs return here (or reboot).
;
	ld	sp,batch	;set stack first off.
	call	movecd		;move current drive into place (TDRIVE).
	call	dsksel		;and reselect it.
	jp	cmmnd1		;back to comand mode.
;
;   Get here if some error occured.
;
unkwn9	call	resetdr		;inproper format.
	jp	synerr
unkwn0	ld	bc,badload	;read error or won't fit.
	call	pline
	jp	getback
badload db	"Bad load"
	db	0
comfile db	"COM"		;command file extension.
;
;   Get here to return to command level. We will reset the
; previous active drive and then either return to command
; level directly or print error message and then return.
;
getback	call	resetdr		;reset previous drive.
getback1
	call	convfst		;convert first name in (FCB).
	ld	a,(fcb+1)	;if this was just a drive change request,
	sub	' '		;make sure it was valid.
	ld	hl,chgdrv
	or	(hl)
	jp	nz,synerr
	jp	cmmnd1		;ok, return to command level.
;
;   ccp stack area.
;
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

ccpstack	equ	$	;end of ccp stack area.
;
;   Batch (or SUBMIT) processing information storage.
;
batch		db	0		;batch mode flag (0=not active).
batchfcb	db	0
		db "$$$     SUB"
		db 0,0,0,0,0,0,0,0,0,0,0,0
		db 0,0,0,0,0,0,0,0,0
;
;   File control block setup by the CCP.
;
fcb	db	0
	db	"           "
	db	0,0,0,0,0
	db	"           "
	db	0,0,0,0,0
rtncode db	0		;status returned from bdos call.
cdrive	db	0		;currently active drive.
chgdrv	db	0		;change in drives flag (0=no change).
nbytes	dw	0		;byte counter used by TYPE.
;
;   Room for expansion?
;
	db	0,0,0,0,0,0,0,0,0,0,0,0,0
;
;   Note that the following six bytes must match those at
; (PATTRN1) or cp/m will HALT. Why?
;
pattrn2 db	0,22,0,0,0,0	;(* serial number bytes *).
;
;**************************************************************
;*
;*                    B D O S   E N T R Y
;*
;**************************************************************
;
fbase	jp	fbase1
;
;   Bdos error table.
;
BADSCTR		DW	ERROR1		;bad sector on read or write.
BADSLCT		DW	ERROR2		;bad disk select.
RODISK		DW	ERROR3		;disk is read only.
ROFILE		DW	ERROR4		;file is read only.
;
;   Entry into bdos. (DE) or (E) are the parameters passed. The
; function number desired is in register (C).
;
fbase1	ex	de,hl		;save the (DE) parameters.
	ld	(params),hl
	ex	de,hl
	ld	a,e		;and save register (E) in particular.
	ld	(eparam),a
	ld	hl,0
	ld	(status),hl	;clear return status.
	add	hl,sp
	ld	(usrstack),hl	;save users stack pointer.
	ld	sp,stkarea	;and set our own.
	xor	a		;clear auto select storage space.
	ld	(autoflag),a
	ld	(auto),a
	ld	hl,goback	;set return address.
	push	hl
	ld	a,c		;get function number.
	cp	nfuncts		;valid function number?
	ret	nc
	ld	c,e		;keep single register function here.
	ld	hl,functns	;now look thru the function table.
	ld	e,a
	ld	d,0		;(DE)=function number.
	add	hl,de
	add	hl,de		;(HL)=(start of table)+2*(function number).
	ld	e,(hl)
	inc	hl
	ld	d,(hl)		;now (DE)=address for this function.
	ld	hl,(params)	;retrieve parameters.
	ex	de,hl		;now (DE) has the original parameters.
	jp	(hl)		;execute desired function.
;
;   BDOS function jump table.
;
nfuncts equ	41		;number of functions in followin table.
;
functns	dw	wboot,getcon,outcon,getrdr,punch,list,dircio,getiob
	dw	setiob,prtstr,rdbuff,getcsts,getver,rstdsk,setdsk,openfil
	dw	closefil,getfst,getnxt,delfile,readseq,wrtseq,fcreate
	dw	renfile,getlog,getcrnt,putdma,getaloc,wrtprtd,getrov,setattr
	dw	getparm,getuser,rdrandom,wtrandom,filesize,setran,logoff,rtn
	dw	rtn,wtspecl
;
;   Bdos error message section.
;
error1	ld	hl,badsec	;bad sector message.
	call	prterr		;print it and get a 1 char responce.
	cp	cntrlc		;re-boot request (control-c)?
	jp	z,0		;yes.
	ret			;no, return to retry i/o function.
;
error2	ld	hl,badsel	;bad drive selected.
	jr	error5
;
error3	ld	hl,diskro	;disk is read only.
	jr	error5
;
ERROR4	ld	hl,filero	;file is read only.
;
ERROR5	call	prterr
	jp	0		;always reboot on these errors.
;
bdoserr	db	"Bdos Err On "
bdosdrv db	" : $"
badsec	db	"Bad Sector$"
badsel	db	"Select$"
filero	db	"File "
diskro	db	"R/O$"
;
;   Print bdos error message.
;
prterr	push	hl		;save second message pointer.
	call	outcrlf		;send (cr)(lf).
	ld	a,(active)	;get active drive.
	add	a,'A'		;make ascii.
	ld	(bdosdrv),a	;and put in message.
	ld	bc,bdoserr	;and print it.
	call	prtmesg
	pop	bc		;print second message line now.
	call	prtmesg
;
;   Get an input character. We will check our 1 character
; buffer first. This may be set by the console status routine.
;
getchar ld	hl,charbuf	;check character buffer.
	ld	a,(hl)		;anything present already?
	ld	(hl),0		;...either case clear it.
	or	a
	ret	nz		;yes, use it.
	jp	conin		;nope, go get a character responce.
;
;   Input and echo a character.
;
getecho call	getchar		;input a character.
	call	chkchar		;carriage control?
	ret	c		;no, a regular control char so don't echo.
	push	af		;ok, save character now.
	ld	c,a
	call	outcon		;and echo it.
	pop	af		;get character and return.
	ret	
;
;   Check character in (A). Set the zero flag on a carriage
; control character and the carry flag on any other control
; character.
;
chkchar cp	cr		;check for CR, LF, backspace,
	ret	z		;or a tab.
	cp	lf
	ret	z
	cp	tab
	ret	z
	cp	bs
	ret	z
	cp	' '		;other control char? Set carry flag.
	ret	
;
;   Check the console during output. Halt on a control-s, then
; reboot on a control-c. If anything else is ready, clear the
; zero flag and return (the calling routine may want to do
; something).
;
ckconsol
	ld	a,(charbuf)	;check buffer.
	or	a		;if anything, just return without checking.
	jr	nz,ckcon2
	call	const		;nothing in buffer. Check console.
	and	01h		;look at bit 0.
	ret	z		;return if nothing.
	call	conin		;ok, get it.
	cp	cntrls		;if not control-s, return with zero cleared.
	jr	nz,ckcon1
	call	conin		;halt processing until another char
	cp	cntrlc		;is typed. Control-c?
	jp	z,0		;yes, reboot now.
	xor	a		;no, just pretend nothing was ever ready.
	ret	
ckcon1	ld	(charbuf),a	;save character in buffer for later processing.
ckcon2	ld	a,1		;set (A) to non zero to mean something is ready.
	ret	
;
;   Output (C) to the screen. If the printer flip-flop flag
; is set, we will send character to printer also. The console
; will be checked in the process.
;
outchar ld	a,(outflag)	;check output flag.
	or	a		;anything and we won't generate output.
	jr	nz,outchr1
	push	bc
	call	ckconsol	;check console (we don't care whats there).
	pop	bc
	push	bc
	call	conout		;output (C) to the screen.
	pop	bc
	push	bc
	ld	a,(prtflag)	;check printer flip-flop flag.
	or	a
	call	nz,list		;print it also if non-zero.
	pop	bc
outchr1 ld	a,c		;update cursors position.
	ld	hl,curpos
	cp	del		;rubouts don't do anything here.
	ret	z
	inc	(hl)		;bump line pointer.
	cp	' '		;and return if a normal character.
	ret	nc
	dec	(hl)		;restore and check for the start of the line.
	ld	a,(hl)
	or	a
	ret	z		;ingnore control characters at the start of the line.
	ld	a,c
	cp	bs		;is it a backspace?
	jr	nz,outchr2
	dec	(hl)		;yes, backup pointer.
	ret	
outchr2 cp	lf		;is it a line feed?
	ret	nz		;ignore anything else.
	ld	(hl),0		;reset pointer to start of line.
	ret	
;
;   Output (A) to the screen. If it is a control character
; (other than carriage control), use ^x format.
;
showit	ld	a,c
	CALL	CHKCHAR		;check character.
	jr	nc,outcon	;not a control, use normal output.
	push	af
	ld	c,'^'		;for a control character, preceed it with '^'.
	call	outchaR
	pop	af
	or	'@'		;and then use the letter equivelant.
	ld	c,a
;
;   Function to output (C) to the console device and expand tabs
; if necessary.
;
outcon	ld	a,c
	cp	tab		;is it a tab?
	jp	nz,outchar	;use regular output.
outcon1 ld	c,' '		;yes it is, use spaces instead.
	call	outchar
	ld	a,(curpos)	;go until the cursor is at a multiple of 8

	and	07h		;position.
	jr	nz,outcon1
	ret	
;
;   Echo a backspace character. Erase the prevoius character
; on the screen.
;
backup	call	backup1		;backup the screen 1 place.
	ld	c,' '		;then blank that character.
	call	conout
backup1 ld	c,bs		;then back space once more.
	jp	conout
;
;   Signal a deleted line. Print a '#' at the end and start
; over.
;
newline ld	c,'#'
	call	outchar		;print this.
	call	outcrlf		;start new line.
newln1	ld	a,(curpos)	;move the cursor to the starting position.
	ld	hl,starting
	cp	(hl)
	ret	nc		;there yet?
	ld	c,' '
	call	outchar		;nope, keep going.
	jr	newln1
;
;   Output a (cr) (lf) to the console device (screen).
;
outcrlf ld	c,cr
	call	outchar
	ld	c,lf
	jp	outchar
;
;   Print message pointed to by (BC). It will end with a '$'.
;
prtmesg ld	a,(bc)		;check for terminating character.
	cp	'$'
	ret	z
	inc	bc
	push	bc		;otherwise, bump pointer and print it.
	ld	c,a
	call	outcon
	pop	bc
	jr	prtmesg
;
;   Function to execute a buffered read.
;
rdbuff	ld	a,(curpos)	;use present location as starting one.
	ld	(starting),a
	ld	hl,(params)	;get the maximum buffer space.
	ld	c,(hl)
	inc	hl		;point to first available space.
	push	hl		;and save.
	ld	b,0		;keep a character count.
rdbuf1	push	bc
	push	hl
rdbuf2	call	getchar		;get the next input character.
	and	7fh		;strip bit 7.
	pop	hl		;reset registers.
	pop	bc
	cp	cr		;en of the line?
	jp	z,rdbuf17
	cp	lf
	jp	z,rdbuf17
	cp	bs		;how about a backspace?
	jr	nz,rdbuf3
	ld	a,b		;yes, but ignore at the beginning of the line.
	or	a
	jr	z,rdbuf1
	dec	b		;ok, update counter.
	ld	a,(curpos)	;if we backspace to the start of the line,
	ld	(outflag),a	;treat as a cancel (control-x).
	jr	rdbuf10
rdbuf3	cp	del		;user typed a rubout?
	jr	nz,rdbuf4
	ld	a,b		;ignore at the start of the line.
	or	a
	jr	z,rdbuf1
	ld	a,(hl)		;ok, echo the prevoius character.
	dec	b		;and reset pointers (counters).
	dec	hl
	jp	rdbuf15
rdbuf4	cp	cntrle		;physical end of line?
	jr	nz,rdbuf5
	push	bc		;yes, do it.
	push	hl
	call	outcrlf
	xor	a		;and update starting position.
	ld	(starting),a
	jr	rdbuf2
rdbuf5	cp	cntrlp		;control-p?
	jr	nz,rdbuf6
	push	hl		;yes, flip the print flag filp-flop byte.
	ld	hl,prtflag
	ld	a,1		;PRTFLAG=1-PRTFLAG
	sub	(hl)
	ld	(hl),a
	pop	hl
	jr	rdbuf1
rdbuf6	cp	cntrlx		;control-x (cancel)?
	jr	nz,rdbuf8
	pop	hl
rdbuf7	ld	a,(starting)	;yes, backup the cursor to here.
	ld	hl,curpos
	cp	(hl)
	jr	nc,rdbuff	;done yet?
	dec	(hl)		;no, decrement pointer and output back up one space.
	call	backup
	jr	rdbuf7
rdbuf8	cp	cntrlu		;cntrol-u (cancel line)?
	jr	nz,rdbuf9
	call	newline		;start a new line.
	pop	hl
	jr	rdbuff
rdbuf9	cp	cntrlr		;control-r?
	jr	nz,rdbuf14
rdbuf10 push	bc		;yes, start a new line and retype the old one.
	call	newline
	pop	bc
	pop	hl
	push	hl
	push	bc
rdbuf11 ld	a,b		;done whole line yet?
	or	a
	jr	z,rdbuf12
	inc	hl		;nope, get next character.
	ld	c,(hl)
	dec	b		;count it.
	push	bc
	push	hl
	call	showit		;and display it.
	pop	hl
	pop	bc
	jr	rdbuf11
RDBUF12 push	hl		;done with line. If we were displaying
	ld	a,(outflag)	;then update cursor position.
	or	a
	jp	z,rdbuf2
	ld	hl,curpos	;because this line is shorter, we must
	sub	(hl)		;back up the cursor (not the screen however)
	ld	(outflag),A	;some number of positions.
RDBUF13 call	backup		;note that as long as (OUTFLAG) is non
	ld	hl,outflag	;zero, the screen will not be changed.
	dec	(hl)
	jr	nz,rdbuf13
	jp	rdbuf2		;now just get the next character.
;
;   Just a normal character, put this in our buffer and echo.
;
rdbuf14 inc	hl
	ld	(hl),a		;store character.
	inc	b		;and count it.
rdbuf15 push	bc
	push	hl
	ld	c,a		;echo it now.
	call	showit
	pop	hl
	pop	bc
	ld	a,(hl)		;was it an abort request?
	cp	cntrlc		;control-c abort?
	ld	a,b
	jr	nz,rdbuf16
	cp	1		;only if at start of line.
	jp	z,0
rdbuf16 cp	c		;nope, have we filled the buffer?
	jp	c,rdbuf1
rdbuf17 pop	hl		;yes end the line and return.
	ld	(hl),b
	ld	c,cr
	jp	outchar		;output (cr) and return.
;
;   Function to get a character from the console device.
;
getcon	call	getecho		;get and echo.
	jp	setstat		;save status and return.
;
;   Function to get a character from the tape reader device.
;
getrdr	call	reader		;get a character from reader, set status and return.
	jp	setstat
;
;  Function to perform direct console i/o. If (C) contains (FF)
; then this is an input request. If (C) contains (FE) then
; this is a status request. Otherwise we are to output (C).
;
dircio	ld	a,c		;test for (FF).
	inc	a
	jr	z,dirc1
	inc	a		;test for (FE).
	jp	z,const
	jp	conout		;just output (C).
dirc1	call	const		;this is an input request.
	or	a
	jp	z,goback1	;not ready? Just return (directly).
	call	conin		;yes, get character.
	jp	setstat		;set status and return.
;
;   Function to return the i/o byte.
;
getiob	ld	a,(iobyte)
	jp	setstat
;
;   Function to set the i/o byte.
;
setiob	ld	hl,iobyte
	ld	(hl),c
	ret	
;
;   Function to print the character string pointed to by (DE)
; on the console device. The string ends with a '$'.
;
prtstr	ex	de,hl
	ld	c,l
	ld	b,h		;now (BC) points to it.
	jp	prtmesg
;
;   Function to interigate the console device.
;
getcsts call	ckconsol
;
;   Get here to set the status and return to the cleanup
; section. Then back to the user.
;
setstat ld	(status),a
rtn	ret	
;
;   Set the status to 1 (read or write error code).
;
ioerr1	ld	a,1
	jr	setstat
;
outflag		db	0	;output flag (non zero means no output).
starting	db	2	;starting position for cursor.
curpos		db	0	;cursor position (0=start of line).
prtflag		db	0	;printer flag (control-p toggle). List if non zero.
charbuf		db	0	;single input character buffer.
;
;   Stack area for BDOS calls.
;
usrstack	dw	0		;save users stack pointer here.
;
		db	0,0,0,0,0,0,0,0,0,0,0,0,0
		db	0,0,0,0,0,0,0,0,0,0,0
		db	0,0,0,0,0,0,0,0,0,0,0,0,0
		db	0,0,0,0,0,0,0,0,0,0,0

stkarea  equ	$		;end of stack area.
;
userno	db	0		;current user number.
active	db	0		;currently active drive.
params	dw	0		;save (DE) parameters here on entry.
status	dw	0		;status returned from bdos function.
;
;   Select error occured, jump to error routine.
;
slcterr ld	hl,badslct
;
;   Jump to (HL) indirectly.
;
jumphl	ld	e,(hl)
	inc	hl
	ld	d,(hl)		;now (DE) contain the desired address.
	ex	de,hl
	jp	(hl)
;
;   Block move. (DE) to (HL), (C) bytes total.
;
de2hl	inc	c		;is count down to zero?
de2hl1	dec	c
	ret	z		;yes, we are done.
	ld	a,(de)		;no, move one more byte.
	ld	(hl),a
	inc	de
	inc	hl
	jr	de2hl1		;and repeat.
;
;   Select the desired drive.
;
select	ld	a,(active)	;get active disk.
	ld	c,a
	call	seldsk		;select it.
	ld	a,h		;valid drive?
	or	l		;valid drive?
	ret	z		;return if not.
;
;   Here, the BIOS returned the address of the parameter block
; in (HL). We will extract the necessary pointers and save them.
;
	ld	e,(hl)		;yes, get address of translation table into (DE).
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	(scratch1),hl	;save pointers to scratch areas.
	inc	hl
	inc	hl
	ld	(scratch2),hl	;ditto.
	inc	hl
	inc	hl
	ld	(scratch3),hl	;ditto.
	inc	hl
	inc	hl
	ex	de,hl		;now save the translation table address.
	ld	(xlate),hl
	ld	hl,dirbuf	;put the next 8 bytes here.
	ld	c,8		;they consist of the directory buffer
	call	de2hl		;pointer, parameter block pointer,
	ld	hl,(diskpb)	;check and allocation vectors.
	ex	de,hl
	ld	hl,sectors	;move parameter block into our ram.
	ld	c,15		;it is 15 bytes long.
	call	de2hl
	ld	hl,(dsksize)	;check disk size.
	ld	a,h		;more than 256 blocks on this?
	ld	hl,bigdisk
	ld	(hl),0ffh	;set to samll.
	or	a
	jr	z,select1
	ld	(hl),0		;wrong, set to large.
select1	ld	a,0ffh		;clear the zero flag.
	or	a
	ret	
;
;   Routine to home the disk track head and clear pointers.
;
homedrv call	home		;home the head.
	xor	a
	ld	hl,(scratch2)	;set our track pointer also.
	ld	(hl),a
	inc	hl
	ld	(hl),a
	ld	hl,(scratch3)	;and our sector pointer.
	ld	(hl),a
	inc	hl
	ld	(hl),a
	ret	
;
;   Do the actual disk read and check the error return status.
;
doread	call	read
	jr	ioret
;
;   Do the actual disk write and handle any bios error.
;
dowrite call	write
ioret	or	a
	ret	z		;return unless an error occured.
	ld	hl,badsctr	;bad read/write on this sector.
	jp	jumphl
;
;   Routine to select the track and sector that the desired
; block number falls in.
;
trksec	ld	hl,(filepos)	;get position of last accessed file
	ld	c,2		;in directory and compute sector #.
	call	shiftr		;sector #=file-position/4.
	ld	(blknmbr),hl	;save this as the block number of interest.
	ld	(cksumtbl),hl	;what's it doing here too?
;
;   if the sector number has already been set (BLKNMBR), enter
; at this point.
;
trksec1 ld	hl,blknmbr
	ld	c,(hl)		;move sector number into (BC).
	inc	hl
	ld	b,(hl)
	ld	hl,(scratch3)	;get current sector number and
	ld	e,(hl)		;move this into (DE).
	inc	hl
	ld	d,(hl)
	ld	hl,(scratch2)	;get current track number.
	ld	a,(hl)		;and this into (HL).
	inc	hl
	ld	h,(hl)
	ld	l,a
trksec2 ld	a,c		;is desired sector before current one?
	sub	e
	ld	a,b
	sbc	a,d
	jr	nc,trksec3
	push	hl		;yes, decrement sectors by one track.
	ld	hl,(sectors)	;get sectors per track.
	ld	a,e
	sub	l
	ld	e,a
	ld	a,d
	sbc	a,h
	ld	d,a		;now we have backed up one full track.
	pop	hl
	dec	hl		;adjust track counter.
	jr	trksec2
trksec3 push	hl		;desired sector is after current one.
	ld	hl,(sectors)	;get sectors per track.
	add	hl,de		;bump sector pointer to next track.
	jr	c,trksec4
	ld	a,c		;is desired sector now before current one?
	sub	l
	ld	a,b
	sbc	a,h
	jr	c,trksec4
	ex	de,hl		;not yes, increment track counter
	pop	hl		;and continue until it is.
	inc	hl
	jr	trksec3
;
;   here we have determined the track number that contains the
; desired sector.
;
trksec4 pop	hl		;get track number (HL).
	push	bc
	push	de
	push	hl
	ex	de,hl
	ld	hl,(offset)	;adjust for first track offset.
	add	hl,de
	ld	b,h
	ld	c,l
	call	settrk		;select this track.
	pop	de		;reset current track pointer.
	ld	hl,(scratch2)
	ld	(hl),e
	inc	hl
	ld	(hl),d
	pop	de
	ld	hl,(scratch3)	;reset the first sector on this track.
	ld	(hl),e
	inc	hl
	ld	(hl),d
	pop	bc
	ld	a,c		;now subtract the desired one.
	sub	e		;to make it relative (1-# sectors/track).
	ld	c,a
	ld	a,b
	sbc	a,d
	ld	b,a
	ld	hl,(xlate)	;translate this sector according to this table.
	ex	de,hl
	call	sectrn		;let the bios translate it.
	ld	c,l
	ld	b,h
	jp	setsec		;and select it.
;
;   Compute block number from record number (SAVNREC) and
; extent number (SAVEXT).
;
getblock
	ld	hl,blkshft	;get logical to physical conversion.
	ld	c,(hl)		;note that this is base 2 log of ratio.
	ld	a,(savnrec)	;get record number.
getblk1 or	a		;compute (A)=(A)/2^BLKSHFT.
	rra	
	dec	c
	jr	nz,getblk1
	ld	b,a		;save result in (B).
	ld	a,8
	sub	(hl)
	ld	c,a		;compute (C)=8-BLKSHFT.
	ld	a,(savext)
getblk2 dec	c		;compute (A)=SAVEXT*2^(8-BLKSHFT).
	jr	z,getblk3
	or	a
	rla	
	jr	getblk2
getblk3 add	a,b
	ret	
;
;   Routine to extract the (BC) block byte from the fcb pointed
; to by (PARAMS). If this is a big-disk, then these are 16 bit
; block numbers, else they are 8 bit numbers.
; Number is returned in (HL).
;
extblk	ld	hl,(params)	;get fcb address.
	ld	de,16		;block numbers start 16 bytes into fcb.
	add	hl,de
	add	hl,bc
	ld	a,(bigdisk)	;are we using a big-disk?
	or	a
	jr	z,extblk1
	ld	l,(hl)		;no, extract an 8 bit number from the fcb.
	ld	h,0
	ret	
extblk1 add	hl,bc		;yes, extract a 16 bit number.
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ex	de,hl		;return in (HL).
	ret	
;
;   Compute block number.
;
comblk	call	getblock
	ld	c,a
	ld	b,0
	call	extblk
	ld	(blknmbr),hl
	ret	
;
;   Check for a zero block number (unused).
;
chkblk	ld	hl,(blknmbr)
	ld	a,l		;is it zero?
	or	h
	ret	
;
;   Adjust physical block (BLKNMBR) and convert to logical
; sector (LOGSECT). This is the starting sector of this block.
; The actual sector of interest is then added to this and the
; resulting sector number is stored back in (BLKNMBR). This
; will still have to be adjusted for the track number.
;
logical ld	a,(blkshft)	;get log2(physical/logical sectors).
	ld	hl,(blknmbr)	;get physical sector desired.
logicl1 add	hl,hl		;compute logical sector number.
	dec	a		;note logical sectors are 128 bytes long.
	jr	nz,logicl1
	ld	(logsect),hl	;save logical sector.
	ld	a,(blkmask)	;get block mask.
	ld	c,a
	ld	a,(savnrec)	;get next sector to access.
	and	c		;extract the relative position within physical block.
	or	l		;and add it too logical sector.
	ld	l,a
	ld	(blknmbr),hl	;and store.
	ret	
;
;   Set (HL) to point to extent byte in fcb.
;
setext	ld	hl,(params)
	ld	de,12		;it is the twelth byte.
	add	hl,de
	ret	
;
;   Set (HL) to point to record count byte in fcb and (DE) to
; next record number byte.
;
sethlde ld	hl,(params)
	ld	de,15		;record count byte (#15).
	add	hl,de
	ex	de,hl
	ld	hl,17		;next record number (#32).
	add	hl,de
	ret	
;
;   Save current file data from fcb.
;
strdata call	sethlde
	ld	a,(hl)		;get and store record count byte.
	ld	(savnrec),a
	ex	de,hl
	ld	a,(hl)		;get and store next record number byte.
	ld	(savnxt),a
	call	setext		;point to extent byte.
	ld	a,(extmask)	;get extent mask.
	and	(hl)
	ld	(savext),a	;and save extent here.
	ret	
;
;   Set the next record to access. If (MODE) is set to 2, then
; the last record byte (SAVNREC) has the correct number to access.
; For sequential access, (MODE) will be equal to 1.
;
setnrec call	sethlde
	ld	a,(mode)	;get sequential flag (=1).
	cp	2		;a 2 indicates that no adder is needed.
	jr	nz,stnrec1
	xor	a		;clear adder (random access?).
stnrec1 ld	c,a
	ld	a,(savnrec)	;get last record number.
	add	a,c		;increment record count.
	ld	(hl),a		;and set fcb's next record byte.
	ex	de,hl
	ld	a,(savnxt)	;get next record byte from storage.
	ld	(hl),a		;and put this into fcb as number of records used.
	ret	
;
;   Shift (HL) right (C) bits.
;
shiftr 	inc	c
SHIFTR1 dec	c
	ret	z
	ld	a,h
	or	a
	rra	
	ld	h,a
	ld	a,l
	rra	
	ld	l,a
	jr	shiftr1
;
;   Compute the check-sum for the directory buffer. Return
; integer sum in (A).
;
checksum
	ld	c,128		;length of buffer.
	ld	hl,(dirbuf)	;get its location.
	xor	a		;clear summation byte.
chksum1 add	a,(hl)		;and compute sum ignoring carries.
	inc	hl
	dec	c
	jr	nz,chksum1
	ret	
;
;   Shift (HL) left (C) bits.
;
shiftl	inc	c
shiftl1 dec	c
	ret	z
	add	hl,hl		;shift left 1 bit.
	jr	shiftl1
;
;   Routine to set a bit in a 16 bit value contained in (BC).
; The bit set depends on the current drive selection.
;
setbit	push	bc		;save 16 bit word.
	ld	a,(active)	;get active drive.
	ld	c,a
	ld	hl,1
	call	shiftl		;shift bit 0 into place.
	pop	bc		;now 'or' this with the original word.
	ld	a,c
	or	l
	ld	l,a		;low byte done, do high byte.
	ld	a,b
	or	h
	ld	h,a
	ret	
;
;   Extract the write protect status bit for the current drive.
; The result is returned in (A), bit 0.
;
getwprt ld	hl,(wrtprt)	;get status bytes.
	ld	a,(active)	;which drive is current?
	ld	c,a
	call	shiftr		;shift status such that bit 0 is the
	ld	a,l		;one of interest for this drive.
	and	01h		;and isolate it.
	ret	
;
;   Function to write protect the current disk.
;
wrtprtd ld	hl,wrtprt	;point to status word.
	ld	c,(hl)		;set (BC) equal to the status.
	inc	hl
	ld	b,(hl)
	call	setbit		;and set this bit according to current drive.
	ld	(wrtprt),hl	;then save.
	ld	hl,(dirsize)	;now save directory size limit.
	inc	hl		;remember the last one.
	ex	de,hl
	ld	hl,(scratch1)	;and store it here.
	ld	(hl),e		;put low byte.
	inc	hl
	ld	(hl),d		;then high byte.
	ret	
;
;   Check for a read only file.
;
chkrofl call	fcb2hl		;set (HL) to file entry in directory buffer.
ckrof1	ld	de,9		;look at bit 7 of the ninth byte.
	add	hl,de
	ld	a,(hl)
	rla	
	ret	nc		;return if ok.
	ld	hl,rofile	;else, print error message and terminate.
	jp	jumphl
;
;   Check the write protect status of the active disk.
;
chkwprt call	getwprt
	ret	z		;return if ok.
	ld	hl,rodisk	;else print message and terminate.
	jp	jumphl
;
;   Routine to set (HL) pointing to the proper entry in the
; directory buffer.
;
fcb2hl	ld	hl,(dirbuf)	;get address of buffer.
	ld	a,(fcbpos)	;relative position of file.
;
;   Routine to add (A) to (HL).
;
adda2hl add	a,l
	ld	l,a
	ret	nc
	inc	h		;take care of any carry.
	ret	
;
;   Routine to get the 's2' byte from the fcb supplied in
; the initial parameter specification.
;
gets2	ld	hl,(params)	;get address of fcb.
	ld	de,14		;relative position of 's2'.
	add	hl,de
	ld	a,(hl)		;extract this byte.
	ret	
;
;   Clear the 's2' byte in the fcb.
;
clears2 call	gets2		;this sets (HL) pointing to it.
	ld	(hl),0		;now clear it.
	ret	
;
;   Set bit 7 in the 's2' byte of the fcb.
;
sets2b7 call	gets2		;get the byte.
	or	80h		;and set bit 7.
	ld	(hl),a		;then store.
	ret	
;
;   Compare (FILEPOS) with (SCRATCH1) and set flags based on
; the difference. This checks to see if there are more file
; names in the directory. We are at (FILEPOS) and there are
; (SCRATCH1) of them to check.
;
morefls ld	hl,(filepos)	;we are here.
	ex	de,hl
	ld	hl,(scratch1)	;and don't go past here.
	ld	a,e		;compute difference but don't keep.
	sub	(hl)
	inc	hl
	ld	a,d
	sbc	a,(hl)		;set carry if no more names.
	ret	
;
;   Call this routine to prevent (SCRATCH1) from being greater
; than (FILEPOS).
;
chknmbr call	morefls		;SCRATCH1 too big?
	ret	c
	inc	de		;yes, reset it to (FILEPOS).
	ld	(hl),d
	dec	hl
	ld	(hl),e
	ret	
;
;   Compute (HL)=(DE)-(HL)
;
subhl	ld	a,e		;compute difference.
	sub	l
	ld	l,a		;store low byte.
	ld	a,d
	sbc	a,h
	ld	h,a		;and then high byte.
	ret	
;
;   Set the directory checksum byte.
;
setdir	ld	c,0ffh
;
;   Routine to set or compare the directory checksum byte. If
; (C)=0ffh, then this will set the checksum byte. Else the byte
; will be checked. If the check fails (the disk has been changed),
; then this disk will be write protected.
;
checkdir
	ld	hl,(cksumtbl)
	ex	de,hl
	ld	hl,(alloc1)
	call	subhl
	ret	nc		;ok if (CKSUMTBL) > (ALLOC1), so return.
	push	bc
	call	checksum	;else compute checksum.
	ld	hl,(chkvect)	;get address of checksum table.
	ex	de,hl
	ld	hl,(cksumtbl)
	add	hl,de		;set (HL) to point to byte for this drive.
	pop	bc
	inc	c		;set or check ?
	jr	z,chkdir1
	cp	(hl)		;check them.
	ret	z		;return if they are the same.
	call	morefls		;not the same, do we care?
	ret	nc
	call	wrtprtd		;yes, mark this as write protected.
	ret	
chkdir1 ld	(hl),a		;just set the byte.
	ret	
;
;   Do a write to the directory of the current disk.
;
dirwrite
	call	setdir		;set checksum byte.
	call	dirdma		;set directory dma address.
	ld	c,1		;tell the bios to actually write.
	call	dowrite		;then do the write.
	jp	defdma
;
;   Read from the directory.
;
dirread call	dirdma		;set the directory dma address.
	call	doread		;and read it.
;
;   Routine to set the dma address to the users choice.
;
defdma	ld	hl,userdma	;reset the default dma address and return.
	jr	dirdma1
;
;   Routine to set the dma address for directory work.
;
dirdma	ld	hl,dirbuf
;
;   Set the dma address. On entry, (HL) points to
; word containing the desired dma address.
;
dirdma1 ld	c,(hl)
	inc	hl
	ld	b,(hl)		;setup (BC) and go to the bios to set it.
	jp	setdma
;
;   Move the directory buffer into user's dma space.
;
movedir ld	hl,(dirbuf)	;buffer is located here, and
	ex	de,hl
	ld	hl,(userdma)	; put it here.
	ld	c,128		;this is its length.
	jp	de2hl		;move it now and return.
;
;   Check (FILEPOS) and set the zero flag if it equals 0ffffh.
;
ckfilpos
	ld	hl,filepos
	ld	a,(hl)
	inc	hl
	cp	(hl)		;are both bytes the same?
	ret	nz
	inc	a		;yes, but are they each 0ffh?
	ret	
;
;   Set location (FILEPOS) to 0ffffh.
;
stfilpos
	ld	hl,0ffffh
	ld	(filepos),hl
	ret	
;
;   Move on to the next file position within the current
; directory buffer. If no more exist, set pointer to 0ffffh
; and the calling routine will check for this. Enter with (C)
; equal to 0ffh to cause the checksum byte to be set, else we
; will check this disk and set write protect if checksums are
; not the same (applies only if another directory sector must
; be read).
;
nxentry ld	hl,(dirsize)	;get directory entry size limit.
	ex	de,hl
	ld	hl,(filepos)	;get current count.
	inc	hl		;go on to the next one.
	ld	(filepos),hl
	call	subhl		;(HL)=(DIRSIZE)-(FILEPOS)
	jr	nc,nxent1	;is there more room left?
	jp	stfilpos	;no. Set this flag and return.
nxent1	ld	a,(filepos)	;get file position within directory.
	and	03h		;only look within this sector (only 4 entries fit).
	ld	b,5		;convert to relative position (32 bytes each).
nxent2	add	a,a		;note that this is not efficient code.
	dec	b		;5 'ADD A's would be better.
	jr	nz,nxent2
	ld	(fcbpos),a	;save it as position of fcb.
	or	a
	ret	nz		;return if we are within buffer.
	push	bc
	call	trksec		;we need the next directory sector.
	call	dirread
	pop	bc
	jp	checkdir
;
;   Routine to to get a bit from the disk space allocation
; map. It is returned in (A), bit position 0. On entry to here,
; set (BC) to the block number on the disk to check.
; On return, (D) will contain the original bit position for
; this block number and (HL) will point to the address for it.
;
ckbitmap
	ld	a,c		;determine bit number of interest.
	and	07h		;compute (D)=(E)=(C and 7)+1.
	inc	a
	ld	e,a		;save particular bit number.
	ld	d,a
;
;   compute (BC)=(BC)/8.
;
	ld	a,c
	rrca			;now shift right 3 bits.
	rrca	
	rrca	
	and	1fh		;and clear bits 7,6,5.
	ld	c,a
	ld	a,b
	add	a,a		;now shift (B) into bits 7,6,5.
	add	a,a
	add	a,a
	add	a,a
	add	a,a
	or	c		;and add in (C).
	ld	c,a		;ok, (C) ha been completed.
	ld	a,b		;is there a better way of doing this?
	rrca	
	rrca	
	rrca	
	and	1fh
	ld	b,a		;and now (B) is completed.
;
;   use this as an offset into the disk space allocation
; table.
;
	ld	hl,(alocvect)
	add	hl,bc
	ld	a,(hl)		;now get correct byte.
ckbmap1 rlca			;get correct bit into position 0.
	dec	e
	jr	nz,ckbmap1
	ret	
;
;   Set or clear the bit map such that block number (BC) will be marked
; as used. On entry, if (E)=0 then this bit will be cleared, if it equals
; 1 then it will be set (don't use anyother values).
;
stbitmap

	push	de
	call	ckbitmap	;get the byte of interest.
	and	0feh		;clear the affected bit.
	pop	bc
	or	c		;and now set it acording to (C).
;
;  entry to restore the original bit position and then store
; in table. (A) contains the value, (D) contains the bit
; position (1-8), and (HL) points to the address within the
; space allocation table for this byte.
;
stbmap1:rrca			;restore original bit position.
	dec	d
	jr	nz,stbmap1
	ld	(hl),a		;and stor byte in table.
	ret	
;
;   Set/clear space used bits in allocation map for this file.
; On entry, (C)=1 to set the map and (C)=0 to clear it.
;
setfile call	fcb2hl		;get address of fcb
	ld	de,16
	add	hl,de		;get to block number bytes.
	push	bc
	ld	c,17		;check all 17 bytes (max) of table.
setfl1 	pop	de
	dec	c		;done all bytes yet?
	ret	z
	push	de
	ld	a,(bigdisk)	;check disk size for 16 bit block numbers.
	or	a
	jr	z,setfl2
	push	bc		;only 8 bit numbers. set (BC) to this one.
	push	hl
	ld	c,(hl)		;get low byte from table, always
	ld	b,0		;set high byte to zero.
	jp	setfl3
setfl2	dec	c		;for 16 bit block numbers, adjust counter.
	push	bc
	ld	c,(hl)		;now get both the low and high bytes.
	inc	hl
	ld	b,(hl)
	push	hl
setfl3	ld	a,c		;block used?
	or	b
	jr	z,setfl4
	ld	hl,(dsksize)	;is this block number within the
	ld	a,l		;space on the disk?
	sub	c
	ld	a,h
	sbc	a,b
	call	nc,stbitmap	;yes, set the proper bit.
SETFL4	pop	hl		;point to next block number in fcb.
	inc	hl
	pop	bc
	jr	setfl1
;
;   Construct the space used allocation bit map for the active
; drive. If a file name starts with '$' and it is under the
; current user number, then (STATUS) is set to minus 1. Otherwise
; it is not set at all.
;
bitmap	ld	hl,(dsksize)	;compute size of allocation table.
	ld	c,3
	call	shiftr		;(HL)=(HL)/8.
	inc	hl		;at lease 1 byte.
	ld	b,h
	ld	c,l		;set (BC) to the allocation table length.
;
;   Initialize the bitmap for this drive. Right now, the first
; two bytes are specified by the disk parameter block. However
; a patch could be entered here if it were necessary to setup
; this table in a special mannor. For example, the bios could
; determine locations of 'bad blocks' and set them as already
; 'used' in the map.
;
	ld	hl,(alocvect)	;now zero out the table now.
bitmap1 ld	(hl),0
	inc	hl
	dec	bc
	ld	a,b
	or	c
	jr	nz,bitmap1
	ld	hl,(alloc0)	;get initial space used by directory.
	ex	de,hl
	ld	hl,(alocvect)	;and put this into map.
	ld	(hl),e
	inc	hl
	ld	(hl),d
;
;   End of initialization portion.
;
	call	homedrv		;now home the drive.
	ld	hl,(scratch1)
	ld	(hl),3		;force next directory request to read
	inc	hl		;in a sector.
	ld	(hl),0
	call	stfilpos	;clear initial file position also.
bitmap2 ld	c,0ffh		;read next file name in directory
	call	nxentry		;and set checksum byte.
	call	ckfilpos	;is there another file?
	ret	z
	call	fcb2hl		;yes, get its address.
	ld	a,0e5h
	cp	(hl)		;empty file entry?
	jr	z,bitmap2
	ld	a,(userno)	;no, correct user number?
	cp	(hl)
	jr	nz,bitmap3
	inc	hl
	ld	a,(hl)		;yes, does name start with a '$'?
	sub	'$'
	jr	nz,bitmap3
	dec	a		;yes, set atatus to minus one.
	ld	(status),a
bitmap3 ld	c,1		;now set this file's space as used in bit map.
	call	setfile
	call	chknmbr		;keep (SCRATCH1) in bounds.
	jr	bitmap2
;
;   Set the status (STATUS) and return.
;
ststatus
	ld	a,(fndstat)
	jp	setstat
;
;   Check extents in (A) and (C). Set the zero flag if they
; are the same. The number of 16k chunks of disk space that
; the directory extent covers is expressad is (EXTMASK+1).
; No registers are modified.
;
samext	push	bc
	push	af
	ld	a,(extmask)	;get extent mask and use it to
	cpl			;to compare both extent numbers.
	ld	b,a		;save resulting mask here.
	ld	a,c		;mask first extent and save in (C).
	and	b
	ld	c,a
	pop	af		;now mask second extent and compare
	and	b		;with the first one.
	sub	c
	and	1fh		;(* only check buts 0-4 *)
	pop	bc		;the zero flag is set if they are the same.
	ret			;restore (BC) and return.
;
;   Search for the first occurence of a file name. On entry,
; register (C) should contain the number of bytes of the fcb
; that must match.
;
findfst ld	a,0ffh
	ld	(fndstat),a
	ld	hl,counter	;save character count.
	ld	(hl),c
	ld	hl,(params)	;get filename to match.
	ld	(savefcb),hl	;and save.
	call	stfilpos	;clear initial file position (set to 0ffffh).
	call	homedrv		;home the drive.
;
;   Entry to locate the next occurence of a filename within the
; directory. The disk is not expected to have been changed. If
; it was, then it will be write protected.
;
findnxt ld	c,0		;write protect the disk if changed.
	call	nxentry		;get next filename entry in directory.
	call	ckfilpos	;is file position = 0ffffh?
	jr	z,fndnxt6	;yes, exit now then.
	ld	hl,(savefcb)	;set (DE) pointing to filename to match.
	ex	de,hl
	ld	a,(de)
	cp	0e5h		;empty directory entry?
	jr	z,fndnxt1	;(* are we trying to reserect erased entries? *)
	push	de
	call	morefls		;more files in directory?
	pop	de
	jr	nc,fndnxt6	;no more. Exit now.
fndnxt1 call	fcb2hl		;get address of this fcb in directory.
	ld	a,(counter)	;get number of bytes (characters) to check.
	ld	c,a
	ld	b,0		;initialize byte position counter.
fndnxt2 ld	a,c		;are we done with the compare?
	or	a
	jr	z,fndnxt5
	ld	a,(de)		;no, check next byte.
	cp	'?'		;don't care about this character?
	jr	z,fndnxt4
	ld	a,b		;get bytes position in fcb.
	cp	13		;don't care about the thirteenth byte either.
	jr	z,fndnxt4
	cp	12		;extent byte?
	ld	a,(de)
	jr	z,fndnxt3
	sub	(hl)		;otherwise compare characters.
	and	7fh
	jr	nz,findnxt	;not the same, check next entry.
	jr	fndnxt4		;so far so good, keep checking.
fndnxt3 push	bc		;check the extent byte here.
	ld	c,(hl)
	call	samext
	pop	bc
	jr	nz,findnxt	;not the same, look some more.
;
;   So far the names compare. Bump pointers to the next byte
; and continue until all (C) characters have been checked.
;
fndnxt4 inc	de		;bump pointers.
	inc	hl
	inc	b
	dec	c		;adjust character counter.
	jr	fndnxt2
fndnxt5 ld	a,(filepos)	;return the position of this entry.
	and	03h
	ld	(status),a
	ld	hl,fndstat
	ld	a,(hl)
	rla	
	ret	nc
	xor	a
	ld	(hl),a
	ret	
;
;   Filename was not found. Set appropriate status.
;
fndnxt6	call	stfilpos	;set (FILEPOS) to 0ffffh.
	ld	a,0ffh		;say not located.
	jp	setstat
;
;   Erase files from the directory. Only the first byte of the
; fcb will be affected. It is set to (E5).
;
erafile call	chkwprt		;is disk write protected?
	ld	c,12		;only compare file names.
	call	findfst		;get first file name.
erafil1 call	ckfilpos	;any found?
	ret	z		;nope, we must be done.
	call	chkrofl		;is file read only?
	call	fcb2hl		;nope, get address of fcb and
	ld	(hl),0e5h	;set first byte to 'empty'.
	ld	c,0		;clear the space from the bit map.
	call	setfile
	call	dirwrite	;now write the directory sector back out.
	call	findnxt		;find the next file name.
	jr	erafil1		;and repeat process.
;
;   Look through the space allocation map (bit map) for the
; next available block. Start searching at block number (BC-1).
; The search procedure is to look for an empty block that is
; before the starting block. If not empty, look at a later
; block number. In this way, we return the closest empty block
; on either side of the 'target' block number. This will speed
; access on random devices. For serial devices, this should be
; changed to look in the forward direction first and then start
; at the front and search some more.
;
;   On return, (DE)= block number that is empty and (HL) =0
; if no empry block was found.
;
fndspace
	ld	d,b		;set (DE) as the block that is checked.
	ld	e,c
;
;   Look before target block. Registers (BC) are used as the lower
; pointer and (DE) as the upper pointer.
;
fndspa1 ld	a,c		;is block 0 specified?
	or	b
	jr	z,fndspa2
	dec	bc		;nope, check previous block.
	push	de
	push	bc
	call	ckbitmap
	rra			;is this block empty?
	jr	nc,fndspa3	;yes. use this.
;
;   Note that the above logic gets the first block that it finds
; that is empty. Thus a file could be written 'backward' making
; it very slow to access. This could be changed to look for the
; first empty block and then continue until the start of this
; empty space is located and then used that starting block.
; This should help speed up access to some files especially on
; a well used disk with lots of fairly small 'holes'.
;
	pop	bc		;nope, check some more.
	pop	de
;
;   Now look after target block.
;
fndspa2 ld	hl,(dsksize)	;is block (DE) within disk limits?
	ld	a,e
	sub	l
	ld	a,d
	sbc	a,h
	jr	nc,fndspa4
	inc	de		;yes, move on to next one.
	push	bc
	push	de
	ld	b,d
	ld	c,e
	call	ckbitmap	;check it.
	rra			;empty?
	jr	nc,fndspa3
	pop	de		;nope, continue searching.
	pop	bc
	jr	fndspa1
;
;   Empty block found. Set it as used and return with (HL)
; pointing to it (true?).
;
fndspa3 rla			;reset byte.
	inc	a		;and set bit 0.
	call	stbmap1		;update bit map.
	pop	hl		;set return registers.
	pop	de
	ret	
;
;   Free block was not found. If (BC) is not zero, then we have
; not checked all of the disk space.
;
fndspa4 ld	a,c
	or	b
	jr	nz,fndspa1
	ld	hl,0		;set 'not found' status.
	ret	
;
;   Move a complete fcb entry into the directory and write it.
;
fcbset	ld	c,0
	ld	e,32		;length of each entry.
;
;   Move (E) bytes from the fcb pointed to by (PARAMS) into
; fcb in directory starting at relative byte (C). This updated
; directory buffer is then written to the disk.
;
update	push	de
	ld	b,0		;set (BC) to relative byte position.
	ld	hl,(params)	;get address of fcb.
	add	hl,bc		;compute starting byte.
	ex	de,hl
	call	fcb2hl		;get address of fcb to update in directory.
	pop	bc		;set (C) to number of bytes to change.
	call	de2hl
update1 call	trksec		;determine the track and sector affected.
	jp	dirwrite	;then write this sector out.
;
;   Routine to change the name of all files on the disk with a
; specified name. The fcb contains the current name as the
; first 12 characters and the new name 16 bytes into the fcb.
;
chgnames
	call	chkwprt		;check for a write protected disk.
	ld	c,12		;match first 12 bytes of fcb only.
	call	findfst		;get first name.
	ld	hl,(params)	;get address of fcb.
	ld	a,(hl)		;get user number.
	ld	de,16		;move over to desired name.
	add	hl,de
	ld	(hl),a		;keep same user number.
chgnam1 call	ckfilpos	;any matching file found?
	ret	z		;no, we must be done.
	call	chkrofl		;check for read only file.
	ld	c,16		;start 16 bytes into fcb.
	ld	e,12		;and update the first 12 bytes of directory.
	call	update
	call	findnxt		;get te next file name.
	jr	chgnam1		;and continue.
;
;   Update a files attributes. The procedure is to search for
; every file with the same name as shown in fcb (ignoring bit 7)
; and then to update it (which includes bit 7). No other changes
; are made.
;
saveattr
	ld	c,12		;match first 12 bytes.
	call	findfst		;look for first filename.
savatr1 call	ckfilpos	;was one found?
	ret	z		;nope, we must be done.
	ld	c,0		;yes, update the first 12 bytes now.
	ld	e,12
	call	update		;update filename and write directory.
	call	findnxt		;and get the next file.
	jr	savatr1		;then continue until done.
;
;  Open a file (name specified in fcb).
;
openit 	ld	c,15		;compare the first 15 bytes.
	call	findfst		;get the first one in directory.
	call	ckfilpos	;any at all?
	ret	z
openit1 call	setext		;point to extent byte within users fcb.
	ld	a,(hl)		;and get it.
	push	af		;save it and address.
	push	hl
	call	fcb2hl		;point to fcb in directory.
	ex	de,hl
	ld	hl,(params)	;this is the users copy.
	ld	c,32		;move it into users space.
	push	de
	call	de2hl
	call	sets2b7		;set bit 7 in 's2' byte (unmodified).
	pop	de		;now get the extent byte from this fcb.
	ld	hl,12
	add	hl,de
	ld	c,(hl)		;into (C).
	ld	hl,15		;now get the record count byte into (B).
	add	hl,de
	ld	b,(hl)
	pop	hl		;keep the same extent as the user had originally.
	pop	af
	ld	(hl),a
	ld	a,c		;is it the same as in the directory fcb?
	cp	(hl)
	ld	a,b		;if yes, then use the same record count.
	jr	z,openit2
	ld	a,0		;if the user specified an extent greater than
	jr	c,openit2	;the one in the directory, then set record count to 0.
	ld	a,128		;otherwise set to maximum.
openit2 ld	hl,(params)	;set record count in users fcb to (A).
	ld	de,15
	add	hl,de		;compute relative position.
	ld	(hl),a		;and set the record count.
	ret	
;
;   Move two bytes from (DE) to (HL) if (and only if) (HL)
; point to a zero value (16 bit).
;   Return with zero flag set it (DE) was moved. Registers (DE)
; and (HL) are not changed. However (A) is.
;
moveword
	ld	a,(hl)		;check for a zero word.
	inc	hl
	or	(hl)		;both bytes zero?
	dec	hl
	ret	nz		;nope, just return.
	ld	a,(de)		;yes, move two bytes from (DE) into
	ld	(hl),a		;this zero space.
	inc	de
	inc	hl
	ld	a,(de)
	ld	(hl),a
	dec	de		;don't disturb these registers.
	dec	hl
	ret	
;
;   Get here to close a file specified by (fcb).
;
closeit xor	a		;clear status and file position bytes.
	ld	(status),a
	ld	(filepos),a
	ld	(filepos+1),a
	call	getwprt		;get write protect bit for this drive.
	ret	nz		;just return if it is set.
	call	gets2		;else get the 's2' byte.
	and	80h		;and look at bit 7 (file unmodified?).
	ret	nz		;just return if set.
	ld	c,15		;else look up this file in directory.
	call	findfst
	call	ckfilpos	;was it found?
	ret	z		;just return if not.
	ld	bc,16		;set (HL) pointing to records used section.
	call	fcb2hl
	add	hl,bc
	ex	de,hl
	ld	hl,(params)	;do the same for users specified fcb.
	add	hl,bc
	ld	c,16		;this many bytes are present in this extent.
closeit1
	ld	a,(bigdisk)	;8 or 16 bit record numbers?
	or	a
	jr	z,closeit4
	ld	a,(hl)		;just 8 bit. Get one from users fcb.
	or	a
	ld	a,(de)		;now get one from directory fcb.
	jr	nz,closeit2
	ld	(hl),a		;users byte was zero. Update from directory.
closeit2
	or	a
	jr	nz,closeit3
	ld	a,(hl)		;directories byte was zero, update from users fcb.
	ld	(de),a
closeit3
	cp	(hl)		;if neither one of these bytes were zero,
	jr	nz,closeit7	;then close error if they are not the same.
	jr	closeit5	;ok so far, get to next byte in fcbs.
closeit4
	call	moveword	;update users fcb if it is zero.
	ex	de,hl
	call	moveword	;update directories fcb if it is zero.
	ex	de,hl
	ld	a,(de)		;if these two values are no different,
	cp	(hl)		;then a close error occured.
	jr	nz,closeit7
	inc	de		;check second byte.
	inc	hl
	ld	a,(de)
	cp	(hl)
	jr	nz,closeit7
	dec	c		;remember 16 bit values.
closeit5
	inc	de		;bump to next item in table.
	inc	hl
	dec	c		;there are 16 entries only.
	jr	nz,closeit1	;continue if more to do.
	ld	bc,0ffech	;backup 20 places (extent byte).
	add	hl,bc
	ex	de,hl
	add	hl,bc
	ld	a,(de)
	cp	(hl)		;directory's extent already greater than the
	jr	c,closeit6	;users extent?
	ld	(hl),a		;no, update directory extent.
	ld	bc,3		;and update the record count byte in
	add	hl,bc		;directories fcb.
	ex	de,hl
	add	hl,bc
	ld	a,(hl)		;get from user.
	ld	(de),a		;and put in directory.
closeit6
	ld	a,0ffh		;set 'was open and is now closed' byte.
	ld	(closeflg),a
	jp	update1		;update the directory now.
closeit7
	ld	hl,status	;set return status and then return.
	dec	(hl)
	ret	
;
;   Routine to get the next empty space in the directory. It
; will then be cleared for use.
;
getempty
	call	chkwprt		;make sure disk is not write protected.
	ld	hl,(params)	;save current parameters (fcb).
	push	hl
	ld	hl,emptyfcb	;use special one for empty space.
	ld	(params),hl
	ld	c,1		;search for first empty spot in directory.
	call	findfst		;(* only check first byte *)
	call	ckfilpos	;none?
	pop	hl
	ld	(params),hl	;restore original fcb address.
	ret	z		;return if no more space.
	ex	de,hl
	ld	hl,15		;point to number of records for this file.
	add	hl,de
	ld	c,17		;and clear all of this space.
	xor	a
getmt1	ld	(hl),a
	inc	hl
	dec	c
	jr	nz,getmt1
	ld	hl,13		;clear the 's1' byte also.
	add	hl,de
	ld	(hl),a
	call	chknmbr		;keep (SCRATCH1) within bounds.
	call	fcbset		;write out this fcb entry to directory.
	jp	sets2b7		;set 's2' byte bit 7 (unmodified at present).
;
;   Routine to close the current extent and open the next one
; for reading.
;
getnext xor	a
	ld	(closeflg),a	;clear close flag.
	call	closeit		;close this extent.
	call	ckfilpos
	ret	z		;not there???
	ld	hl,(params)	;get extent byte.
	ld	bc,12
	add	hl,bc
	ld	a,(hl)		;and increment it.
	inc	a
	and	1fh		;keep within range 0-31.
	ld	(hl),a
	jr	z,gtnext1	;overflow?
	ld	b,a		;mask extent byte.
	ld	a,(extmask)
	and	b
	ld	hl,closeflg	;check close flag (0ffh is ok).
	and	(hl)
	jr	z,gtnext2	;if zero, we must read in next extent.
	jr	gtnext3		;else, it is already in memory.
gtnext1 ld	bc,2		;Point to the 's2' byte.
	add	hl,bc
	inc	(hl)		;and bump it.
	ld	a,(hl)		;too many extents?
	and	0fh
	jr	z,gtnext5	;yes, set error code.
;
;   Get here to open the next extent.
;
gtnext2 ld	c,15		;set to check first 15 bytes of fcb.
	call	findfst		;find the first one.
	call	ckfilpos	;none available?
	jr	nz,gtnext3
	ld	a,(rdwrtflg)	;no extent present. Can we open an empty one?
	inc	a		;0ffh means reading (so not possible).
	jr	z,gtnext5	;or an error.
	call	getempty	;we are writing, get an empty entry.
	call	ckfilpos	;none?
	jr	z,gtnext5	;error if true.
	jr	gtnext4		;else we are almost done.
gtnext3 call	openit1		;open this extent.
gtnext4 call	strdata		;move in updated data (rec #, extent #, etc.)
	xor	a		;clear status and return.
	jp	setstat
;
;   Error in extending the file. Too many extents were needed
; or not enough space on the disk.
;
gtnext5 call	ioerr1		;set error code, clear bit 7 of 's2'
	jp	sets2b7		;so this is not written on a close.
;
;   Read a sequential file.
;
rdseq	ld	a,1		;set sequential access mode.
	ld	(mode),a
rdseq1	ld	a,0ffh		;don't allow reading unwritten space.
	ld	(rdwrtflg),a
	call	strdata		;put rec# and ext# into fcb.
	ld	a,(savnrec)	;get next record to read.
	ld	hl,savnxt	;get number of records in extent.
	cp	(hl)		;within this extent?
	jr	c,rdseq2
	cp	128		;no. Is this extent fully used?
	jr	nz,rdseq3	;no. End-of-file.
	call	getnext		;yes, open the next one.
	xor	a		;reset next record to read.
	ld	(savnrec),a
	ld	a,(status)	;check on open, successful?
	or	a
	jr	nz,rdseq3	;no, error.
rdseq2	call	comblk		;ok. compute block number to read.
	call	chkblk		;check it. Within bounds?
	jr	z,rdseq3	;no, error.
	call	logical		;convert (BLKNMBR) to logical sector (128 byte).
	call	trksec1		;set the track and sector for this block #.
	call	doread		;and read it.
	jp	setnrec		;and set the next record to be accessed.
;
;   Read error occured. Set status and return.
;
rdseq3	jp	ioerr1
;
;   Write the next sequential record.
;
wtseq	ld	a,1		;set sequential access mode.
	ld	(mode),a
wtseq1	ld	a,0		;allow an addition empty extent to be opened.
	ld	(rdwrtflg),a
	call	chkwprt		;check write protect status.
	ld	hl,(params)
	call	ckrof1		;check for read only file, (HL) already set to fcb.
	call	strdata		;put updated data into fcb.
	ld	a,(savnrec)	;get record number to write.
	cp	128		;within range?
	jp	nc,ioerr1	;no, error(?).
	call	comblk		;compute block number.
	call	chkblk		;check number.
	ld	c,0		;is there one to write to?
	jr	nz,wtseq6	;yes, go do it.
	call	getblock	;get next block number within fcb to use.
	ld	(relblock),a	;and save.
	ld	bc,0		;start looking for space from the start
	or	a		;if none allocated as yet.
	jr	z,wtseq2
	ld	c,a		;extract previous block number from fcb
	dec	bc		;so we can be closest to it.
	call	extblk
	ld	b,h
	ld	c,l
wtseq2	call	fndspace	;find the next empty block nearest number (BC).
	ld	a,l		;check for a zero number.
	or	h
	jr	nz,wtseq3
	ld	a,2		;no more space?
	jp	setstat
wtseq3	ld	(blknmbr),hl	;save block number to access.
	ex	de,hl		;put block number into (DE).
	ld	hl,(params)	;now we must update the fcb for this
	ld	bc,16		;newly allocated block.
	add	hl,bc
	ld	a,(bigdisk)	;8 or 16 bit block numbers?
	or	a
	ld	a,(relblock)	;(* update this entry *)
	jr	z,wtseq4	;zero means 16 bit ones.
	call	adda2hl		;(HL)=(HL)+(A)
	ld	(hl),e		;store new block number.
	jr	wtseq5
wtseq4	ld	c,a		;compute spot in this 16 bit table.
	ld	b,0
	add	hl,bc
	add	hl,bc
	ld	(hl),e		;stuff block number (DE) there.
	inc	hl
	ld	(hl),d
wtseq5	ld	c,2		;set (C) to indicate writing to un-used disk space.
wtseq6	ld	a,(status)	;are we ok so far?
	or	a
	ret	nz
	push	bc		;yes, save write flag for bios (register C).
	call	logical		;convert (BLKNMBR) over to loical sectors.
	ld	a,(mode)	;get access mode flag (1=sequential,
	dec	a		;0=random, 2=special?).
	dec	a
	jr	nz,wtseq9
;
;   Special random i/o from function #40. Maybe for M/PM, but the
; current block, if it has not been written to, will be zeroed
; out and then written (reason?).
;
	pop	bc
	push	bc
	ld	a,c		;get write status flag (2=writing unused space).
	dec	a
	dec	a
	jr	nz,wtseq9
	push	hl
	ld	hl,(dirbuf)	;zero out the directory buffer.
	ld	d,a		;note that (A) is zero here.
wtseq7	ld	(hl),a
	inc	hl
	inc	d		;do 128 bytes.
	jp	p,wtseq7
	call	dirdma		;tell the bios the dma address for directory access.
	ld	hl,(logsect)	;get sector that starts current block.
	ld	c,2		;set 'writing to unused space' flag.
wtseq8	ld	(blknmbr),hL	;save sector to write.
	push	bc
	call	trksec1		;determine its track and sector numbers.
	pop	bc
	call	dowrite		;now write out 128 bytes of zeros.
	ld	hl,(blknmbr)	;get sector number.
	ld	c,0		;set normal write flag.
	ld	a,(blkmask)	;determine if we have written the entire
	ld	b,a		;physical block.
	and	l
	cp	b
	inc	hl		;prepare for the next one.
	jR	nz,wtseq8	;continue until (BLKMASK+1) sectors written.
	pop	hl		;reset next sector number.
	ld	(blknmbr),hl
	call	defdma		;and reset dma address.
;
;   Normal disk write. Set the desired track and sector then
; do the actual write.
;
wtseq9	call	trksec1		;determine track and sector for this write.
	pop	bc		;get write status flag.
	push	bc
	call	dowrite		;and write this out.
	pop	bc
	ld	a,(savnrec)	;get number of records in file.
	ld	hl,savnxt	;get last record written.
	cp	(hl)
	jr	c,wtseq10
	ld	(hl),a		;we have to update record count.
	inc	(hl)
	ld	c,2
;
;*   This area has been patched to correct disk update problem
;* when using blocking and de-blocking in the BIOS.
;
wtseq10	ld	hl,0		;was 'jnz wtseq99'
;
; *   End of patch.
;
	push	af
	call	gets2		;set 'extent written to' flag.
	and	7fh		;(* clear bit 7 *)
	ld	(hl),a
	pop	af		;get record count for this extent.
wtseq99 cp	127		;is it full?
	jr	nz,wtseq12
	ld	a,(mode)	;yes, are we in sequential mode?
	cp	1
	jp	nz,wtseq12
	call	setnrec		;yes, set next record number.
	call	getnext		;and get next empty space in directory.
	ld	hl,status	;ok?
	ld	a,(hl)
	or	a
	jp	nz,wtseq11
	dec	a		;yes, set record count to -1.
	ld	(savnrec),a
wtseq11 ld	(hl),0		;clear status.
wtseq12 jp	setnrec		;set next record to access.
;
;   For random i/o, set the fcb for the desired record number
; based on the 'r0,r1,r2' bytes. These bytes in the fcb are
; used as follows:
;
;       fcb+35            fcb+34            fcb+33
;  |     'r-2'      |      'r-1'      |      'r-0'     |
;  |7             0 | 7             0 | 7             0|
;  |0 0 0 0 0 0 0 0 | 0 0 0 0 0 0 0 0 | 0 0 0 0 0 0 0 0|
;  |    overflow   | | extra |  extent   |   record #  |
;  | ______________| |_extent|__number___|_____________|
;                     also 's2'
;
;   On entry, register (C) contains 0ffh if this is a read
; and thus we can not access unwritten disk space. Otherwise,
; another extent will be opened (for writing) if required.
;
position
	xor	a		;set random i/o flag.
	ld	(mode),a
;
;   Special entry (function #40). M/PM ?
;
positn1 push	bc		;save read/write flag.
	ld	hl,(params)	;get address of fcb.
	ex	de,hl
	ld	hl,33		;now get byte 'r0'.
	add	hl,de
	ld	a,(hl)
	and	7fh		;keep bits 0-6 for the record number to access.
	push	af
	ld	a,(hl)		;now get bit 7 of 'r0' and bits 0-3 of 'r1'.
	rla	
	inc	hl
	ld	a,(hl)
	rla	
	and	1fh		;and save this in bits 0-4 of (C).
	ld	c,a		;this is the extent byte.
	ld	a,(hl)		;now get the extra extent byte.
	rra	
	rra	
	rra	
	rra	
	and	0fh
	ld	b,a		;and save it in (B).
	pop	af		;get record number back to (A).
	inc	hl		;check overflow byte 'r2'.
	ld	l,(hl)
	inc	l
	dec	l
	ld	l,6		;prepare for error.
	jr	nz,positn5	;out of disk space error.
	ld	hl,32		;store record number into fcb.
	add	hl,de
	ld	(hl),a
	ld	hl,12		;and now check the extent byte.
	add	hl,de
	ld	a,c
	sub	(hl)		;same extent as before?
	jr	nz,positn2
	ld	hl,14		;yes, check extra extent byte 's2' also.
	add	hl,de
	ld	a,b
	sub	(hl)
	and	7fh
	jr	z,positn3	;same, we are almost done then.
;
;  Get here when another extent is required.
;
positn2 push	bc
	push	de
	call	closeit		;close current extent.
	pop	de
	pop	bc
	ld	l,3		;prepare for error.
	ld	a,(status)
	inc	a
	jr	z,positn4	;close error.
	ld	hl,12		;put desired extent into fcb now.
	add	hl,de
	ld	(hl),c
	ld	hl,14		;and store extra extent byte 's2'.
	add	hl,de
	ld	(hl),b
	call	openit		;try and get this extent.
	ld	a,(status)	;was it there?
	inc	a
	jr	nz,positn3
	pop	bc		;no. can we create a new one (writing?).
	push	bc
	ld	l,4		;prepare for error.
	inc	c
	jr	z,positn4	;nope, reading unwritten space error.
	call	getempty	;yes we can, try to find space.
	ld	l,5		;prepare for error.
	ld	a,(status)
	inc	a
	jr	z,positn4	;out of space?
;
;   Normal return location. Clear error code and return.
;
positn3 pop	bc		;restore stack.
	xor	a		;and clear error code byte.
	jp	setstat
;
;   Error. Set the 's2' byte to indicate this (why?).
;
positn4 push	hl
	call	gets2
	ld	(hl),0c0h
	pop	hl
;
;   Return with error code (presently in L).
;
positn5 pop	bc
	ld	a,l		;get error code.
	ld	(status),a
	jp	sets2b7
;
;   Read a random record.
;
readran ld	c,0ffh		;set 'read' status.
	call	position	;position the file to proper record.
	call	z,rdseq1	;and read it as usual (if no errors).
	ret	
;
;   Write to a random record.
;
writeran
	ld	c,0		;set 'writing' flag.
	call	position	;position the file to proper record.
	call	z,wtseq1	;and write as usual (if no errors).
	ret	
;
;   Compute the random record number. Enter with (HL) pointing
; to a fcb an (DE) contains a relative location of a record
; number. On exit, (C) contains the 'r0' byte, (B) the 'r1'
; byte, and (A) the 'r2' byte.
;
;   On return, the zero flag is set if the record is within
; bounds. Otherwise, an overflow occured.
;
comprand
	ex	de,hl		;save fcb pointer in (DE).
	add	hl,de		;compute relative position of record #.
	ld	c,(hl)		;get record number into (BC).
	ld	b,0
	ld	hl,12		;now get extent.
	add	hl,de
	ld	a,(hl)		;compute (BC)=(record #)+(extent)*128.
	rrca			;move lower bit into bit 7.
	and	80h		;and ignore all other bits.
	add	a,c		;add to our record number.
	ld	c,a
	ld	a,0		;take care of any carry.
	adc	a,b
	ld	b,a
	ld	a,(hl)		;now get the upper bits of extent into
	rrca			;bit positions 0-3.
	and	0fh		;and ignore all others.
	add	a,b		;add this in to 'r1' byte.
	ld	b,a
	ld	hl,14		;get the 's2' byte (extra extent).
	add	hl,de
	ld	a,(hl)
	add	a,a		;and shift it left 4 bits (bits 4-7).
	add	a,a
	add	a,a
	add	a,a
	push	af		;save carry flag (bit 0 of flag byte).
	add	a,b		;now add extra extent into 'r1'.
	ld	b,a
	push	af		;and save carry (overflow byte 'r2').
	pop	hl		;bit 0 of (L) is the overflow indicator.
	ld	a,l
	pop	hl		;and same for first carry flag.
	or	l		;either one of these set?
	and	01h		;only check the carry flags.
	ret	
;
;   Routine to setup the fcb (bytes 'r0', 'r1', 'r2') to
; reflect the last record used for a random (or other) file.
; This reads the directory and looks at all extents computing
; the largerst record number for each and keeping the maximum
; value only. Then 'r0', 'r1', and 'r2' will reflect this
; maximum record number. This is used to compute the space used
; by a random file.
;
ransize ld	c,12		;look thru directory for first entry with
	call	findfst		;this name.
	ld	hl,(params)	;zero out the 'r0, r1, r2' bytes.
	ld	de,33
	add	hl,de
	push	hl
	ld	(hl),d		;note that (D)=0.
	inc	hl
	ld	(hl),d
	inc	hl
	ld	(hl),d
ransiz1 call	ckfilpos	;is there an extent to process?
	jr	z,ransiz3	;no, we are done.
	call	fcb2hl		;set (HL) pointing to proper fcb in dir.
	ld	de,15		;point to last record in extent.
	call	comprand	;and compute random parameters.
	pop	hl
	push	hl		;now check these values against those
	ld	e,a		;already in fcb.
	ld	a,c		;the carry flag will be set if those
	sub	(hl)		;in the fcb represent a larger size than
	inc	hl		;this extent does.
	ld	a,b
	sbc	a,(hl)
	inc	hl
	ld	a,e
	sbc	a,(hl)
	jr	c,ransiz2
	ld	(hl),e		;we found a larger (in size) extent.
	dec	hl		;stuff these values into fcb.
	ld	(hl),b
	dec	hl
	ld	(hl),c
ransiz2 call	findnxt		;now get the next extent.
	jr	ransiz1		;continue til all done.
ransiz3 pop	hl		;we are done, restore the stack and
	ret			;return.
;
;   Function to return the random record position of a given
; file which has been read in sequential mode up to now.
;
setran	ld	hl,(params)	;point to fcb.
	ld	de,32		;and to last used record.
	call	comprand	;compute random position.
	ld	hl,33		;now stuff these values into fcb.
	add	hl,de
	ld	(hl),c		;move 'r0'.
	inc	hl
	ld	(hl),b		;and 'r1'.
	inc	hl
	ld	(hl),a		;and lastly 'r2'.
	ret	
;
;   This routine select the drive specified in (ACTIVE) and
; update the login vector and bitmap table if this drive was
; not already active.
;
logindrv
	ld	hl,(login)	;get the login vector.
	ld	a,(active)	;get the default drive.
	ld	c,a
	call	shiftr		;position active bit for this drive
	push	hl		;into bit 0.
	ex	de,hl
	call	select		;select this drive.
	pop	hl
	call	z,slcterr	;valid drive?
	ld	a,l		;is this a newly activated drive?
	rra	
	ret	c
	ld	hl,(login)	;yes, update the login vector.
	ld	c,l
	ld	b,h
	call	setbit
	ld	(login),hl	;and save.
	jp	bitmap		;now update the bitmap.
;
;   Function to set the active disk number.
;
setdsk	ld	a,(eparam)	;get parameter passed and see if this
	ld	hl,active	;represents a change in drives.
	cp	(hl)
	ret	z
	ld	(hl),a		;yes it does, log it in.
	jp	logindrv
;
;   This is the 'auto disk select' routine. The firsst byte
; of the fcb is examined for a drive specification. If non
; zero then the drive will be selected and loged in.
;
autosel ld	a,0ffh		;say 'auto-select activated'.
	ld	(auto),a
	ld	hl,(params)	;get drive specified.
	ld	a,(hl)
	and	1fh		;look at lower 5 bits.
	dec	a		;adjust for (1=A, 2=B) etc.
	ld	(eparam),a	;and save for the select routine.
	cp	1eh		;check for 'no change' condition.
	jr	nc,autosl1	;yes, don't change.
	ld	a,(active)	;we must change, save currently active
	ld	(olddrv),a	;drive.
	ld	a,(hl)		;and save first byte of fcb also.
	ld	(autoflag),a	;this must be non-zero.
	and	0e0h		;whats this for (bits 6,7 are used for
	ld	(hl),a		;something)?
	call	setdsk		;select and log in this drive.
autosl1 ld	a,(userno)	;move user number into fcb.
	ld	hl,(params)	;(* upper half of first byte *)
	or	(hl)
	ld	(hl),a
	ret			;and return (all done).
;
;   Function to return the current cp/m version number.
;
getver	ld	a,022h		;version 2.2
	jp	setstat
;
;   Function to reset the disk system.
;
rstdsk	ld	hl,0		;clear write protect status and log
	ld	(wrtprt),hl	;in vector.
	ld	(login),hl
	xor	a		;select drive 'A'.
	ld	(active),a
	ld	hl,tbuff	;setup default dma address.
	ld	(userdma),hl
	call	defdma
	jp	logindrv	;now log in drive 'A'.
;
;   Function to open a specified file.
;
openfil call	clears2		;clear 's2' byte.
	call	autosel		;select proper disk.
	jp	openit		;and open the file.
;
;   Function to close a specified file.
;
closefil
	call	autosel		;select proper disk.
	jp	closeit		;and close the file.
;
;   Function to return the first occurence of a specified file
; name. If the first byte of the fcb is '?' then the name will
; not be checked (get the first entry no matter what).
;
getfst	ld	c,0		;prepare for special search.
	ex	de,hl
	ld	a,(hl)		;is first byte a '?'?
	cp	'?'
	jr	z,getfst1	;yes, just get very first entry (zero length match).
	call	setext		;get the extension byte from fcb.
	ld	a,(hl)		;is it '?'? if yes, then we want
	cp	'?'		;an entry with a specific 's2' byte.
	call	nz,clears2	;otherwise, look for a zero 's2' byte.
	call	autosel		;select proper drive.
	ld	c,15		;compare bytes 0-14 in fcb (12&13 excluded).
getfst1 call	findfst		;find an entry and then move it into
	jp	movedir		;the users dma space.
;
;   Function to return the next occurence of a file name.
;
getnxt	ld	hl,(savefcb)	;restore pointers. note that no
	ld	(params),hl	;other dbos calls are allowed.
	call	autosel		;no error will be returned, but the
	call	findnxt		;results will be wrong.
	jp	movedir
;
;   Function to delete a file by name.
;
delfile call	autosel		;select proper drive.
	call	erafile		;erase the file.
	jp	ststatus	;set status and return.
;
;   Function to execute a sequential read of the specified
; record number.
;
readseq call	autosel		;select proper drive then read.
	jp	rdseq
;
;   Function to write the net sequential record.
;
wrtseq	call	autosel		;select proper drive then write.
	jp	wtseq
;
;   Create a file function.
;
fcreate call	clears2		;clear the 's2' byte on all creates.
	call	autosel		;select proper drive and get the next
	jp	getempty	;empty directory space.
;
;   Function to rename a file.
;
renfile call	autosel		;select proper drive and then switch
	call	chgnames	;file names.
	jp	ststatus
;
;   Function to return the login vector.
;
getlog	ld	hl,(login)
	jp	getprm1
;
;   Function to return the current disk assignment.
;
getcrnt ld	a,(active)
	jp	setstat
;
;   Function to set the dma address.
;
putdma	ex	de,hl
	ld	(userdma),hl	;save in our space and then get to
	jp	defdma		;the bios with this also.
;
;   Function to return the allocation vector.
;
getaloc ld	hl,(alocvect)
	jp	getprm1
;
;   Function to return the read-only status vector.
;
getrov	ld	hl,(wrtprt)
	jp	getprm1
;
;   Function to set the file attributes (read-only, system).
;
setattr call	autosel		;select proper drive then save attributes.
	call	saveattr
	jp	ststatus
;
;   Function to return the address of the disk parameter block
; for the current drive.
;
getparm ld	hl,(diskpb)
getprm1 ld	(status),hl
	ret	
;
;   Function to get or set the user number. If (E) was (FF)
; then this is a request to return the current user number.
; Else set the user number from (E).
;
getuser ld	a,(eparam)	;get parameter.
	cp	0ffh		;get user number?
	jr	nz,setuser
	ld	a,(userno)	;yes, just do it.
	jp	setstat
setuser and	1fh		;no, we should set it instead. keep low
	ld	(userno),a	;bits (0-4) only.
	ret	
;
;   Function to read a random record from a file.
;
rdrandom
	call	autosel		;select proper drive and read.
	jp	readran
;
;   Function to compute the file size for random files.
;
wtrandom
	call	autosel		;select proper drive and write.
	jp	writeran
;
;   Function to compute the size of a random file.
;
filesize
	call	autosel		;select proper drive and check file length
	jp	ransize
;
;   Function #37. This allows a program to log off any drives.
; On entry, set (DE) to contain a word with bits set for those
; drives that are to be logged off. The log-in vector and the
; write protect vector will be updated. This must be a M/PM
; special function.
;
logoff	ld	hl,(params)	;get drives to log off.
	ld	a,l		;for each bit that is set, we want
	cpl			;to clear that bit in (LOGIN)
	ld	e,a		;and (WRTPRT).
	ld	a,h
	cpl	
	ld	hl,(login)	;reset the login vector.
	and	h
	ld	d,a
	ld	a,l
	and	e
	ld	e,a
	ld	hl,(wrtprt)
	ex	de,hl
	ld	(login),hl	;and save.
	ld	a,l		;now do the write protect vector.
	and	e
	ld	l,a
	ld	a,h
	and	d
	ld	h,a
	ld	(wrtprt),hl	;and save. all done.
	ret	
;
;   Get here to return to the user.
;
goback	ld	a,(auto)	;was auto select activated?
	or	a
	jr	z,goback1
	ld	hl,(params)	;yes, but was a change made?
	ld	(hl),0		;(* reset first byte of fcb *)
	ld	a,(autoflag)
	or	a
	jr	z,goback1
	ld	(hl),a		;yes, reset first byte properly.
	ld	a,(olddrv)	;and get the old drive and select it.
	ld	(eparam),a
	call	setdsk
goback1 ld	hl,(usrstack)	;reset the users stack pointer.
	ld	sp,hl
	ld	hl,(status)	;get return status.
	ld	a,l		;force version 1.4 compatability.
	ld	b,h
	ret			;and go back to user.
;
;   Function #40. This is a special entry to do random i/o.
; For the case where we are writing to unused disk space, this
; space will be zeroed out first. This must be a M/PM special
; purpose function, because why would any normal program even
; care about the previous contents of a sector about to be
; written over.
;
wtspecl call	autoseL		;select proper drive.
	ld	a,2		;use special write mode.
	ld	(mode),a
	ld	c,0		;set write indicator.
	call	positn1		;position the file.
	call	z,wtseq1	;and write (if no errors).
	ret	
;
;**************************************************************
;*
;*     BDOS data storage pool.
;*
;**************************************************************
;
emptyfcb	db	0e5h	;empty directory segment indicator.
wrtprt		dw	0	;write protect status for all 16 drives.
login		dw	0	;drive active word (1 bit per drive).
userdma		dw	080H	;user's dma address (defaults to 80h).
;
;   Scratch areas from parameter block.
;
scratch1	dw	0	;relative position within dir segment for file (0-3).
scratch2	dw	0	;last selected track number.
scratch3	dw	0	;last selected sector number.
;
;   Disk storage areas from parameter block.
;
dirbuf		dw	0	;address of directory buffer to use.
diskpb		dw	0	;contains address of disk parameter block.
chkvect		dw	0	;address of check vector.
alocvect	dw	0	;address of allocation vector (bit map).
;
;   Parameter block returned from the bios.
;
sectors		dw	0	;sectors per track from bios.
blkshft		db	0	;block shift.
blkmask		db	0	;block mask.
extmask		db	0	;extent mask.
dsksize		dw	0	;disk size from bios (number of blocks-1).
dirsize		dw	0	;directory size.
alloc0		dw	0	;storage for first bytes of bit map (dir space used).
alloc1		dw	0
offset		dw	0	;first usable track number.
xlate		dw	0	;sector translation table address.
;
;
closeflg	db	0	;close flag (=0ffh is extent written ok).
rdwrtflg	db	0	;read/write flag (0ffh=read, 0=write).
fndstat		db	0	;filename found status (0=found first entry).
mode		db	0	;I/o mode select (0=random, 1=sequential, 2=special random).
eparam		db	0	;storage for register (E) on entry to bdos.
relblock	db	0	;relative position within fcb of block number written.
counter		db	0	;byte counter for directory name searches.
savefcb		dw	0,0	;save space for address of fcb (for directory searches).
bigdisk		db	0	;if =0 then disk is > 256 blocks long.
auto		db	0	;if non-zero, then auto select activated.
olddrv		db	0	;on auto select, storage for previous drive.
autoflag	db	0	;if non-zero, then auto select changed drives.
savnxt		db	0	;storage for next record number to access.
savext		db	0	;storage for extent number of file.
savnrec		dw	0	;storage for number of records in file.
blknmbr		dw	0	;block number (physical sector) used within a file or logical sect
logsect		dw	0	;starting logical (128 byte) sector of block (physical sector).
fcbpos		db	0	;relative position within buffer for fcb of file of interest.
filepos		dw	0	;files position within directory (0 to max entries -1).
;
;   Disk directory buffer checksum bytes. One for each of the
; 16 possible drives.
;
cksumtbl	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;
;   Extra space ?
;
		db	0,0,0,0
;
;**************************************************************
;*
;*        B I O S   J U M P   T A B L E
;*
;**************************************************************
;
boot	jp	0		;NOTE WE USE FAKE DESTINATIONS
wboot	jp	0
const	jp	0
conin	jp	0
conout	jp	0
list	jp	0
punch	jp	0
reader	jp	0
home	jp	0
seldsk	jp	0
settrk	jp	0
setsec	jp	0
setdma	jp	0
read	jp	0
write	jp	0
prstat	jp	0
sectrn	jp	0
;
;*
;******************   E N D   O F   C P / M   *****************
;*

	 end
