        page    ,132
;-----------------------------Module-Header-----------------------------;
; Module Name:	SCANLR.ASM
;
;   This module contains the ScanLR routine.
;
; Created: 22-Feb-1987
; Author:  **** ***** [*****]
;
; Copyright (c) 1984-1987 Microsoft Corporation
;
; Exported Functions:	ScanLR
;
; Public Functions:	none
;
; Public Data:		none
;
; General Description:
;
;   ScanLR is used to search a scanline for a pixel of the given
;   color or one which isn't of the given color.  This is usually
;   used by the floodfill simulation.
;
; Restrictions:
;
;-----------------------------------------------------------------------;


incDrawMode	= 1			;Include control for gdidefs.inc

	.xlist
	include cmacros.inc
	include gdidefs.inc
	include display.inc
	include macros.mac
	.list


;	Link time constants describing the size that the device
;	will be running in.

	externA ScreenSelector		;Selector to the screen
	externA SCREEN_WIDTH		;Screen width in pixels
	externA SCREEN_W_BYTES		;Screen width in bytes
	externA SCREEN_HEIGHT		;Screen height in scans


ifdef	EXCLUSION
	externFP exclude_far		;Exclude area from screen
	externFP unexclude_far		;Clear excluded area
endif


;	Define the flag values which control the direction
;	and type of the scan.

STEP_LEFT	equ	00000010b	;Flag values for DirStyle
STEP_RIGHT	equ	00000000b
FIND_COLOR	equ	00000001b
FIND_NOT_COLOR	equ	00000000b



;	Define the error conditions which will be returned

ERROR_CLIPPED	equ	8000h		;Cooridnate was clipped
ERROR_NOT_FOUND equ	-1		;Stop condition not reached


sBegin	Data

	externB enabled_flag		;Non-zero if output allowed

sEnd	Data


createSeg _BLUEMOON,BlueMoonSeg,word,public,CODE
sBegin	BlueMoonSeg
assumes cs,BlueMoonSeg

rot_bit_tbl	label	byte
		db	10000000b	;Table to map bit index into
		db	01000000b	;  a bit mask
		db	00100000b
		db	00010000b
		db	00001000b
		db	00000100b
		db	00000010b
		db	00000001b
page

;--------------------------Exported-Routine-----------------------------;
; ScanLR
;
;   ScanLR - Scan left or right
;
;   Starting at the given pixel and proceeding in the choosen direction,
;   the pixels are examined for the given color until one is found that
;   matches (or doesn't match depending on the style).  The X coordinate
;   is returned for the pixel that matched (or didn't match).
;
;   The physical device may be the screen or a monochrome bitmap.
;
; Entry:
; Returns:
;	AX = x location of sought pixel
; Error Returns:
;	AX = -1 if nothing found
;	AX = 8000h if clipped
; Registers Preserved:
;	SI,DI,DS,BP
; Registers Destroyed:
;	AX,BX,CX,DX,ES,FLAGS
; Calls:
;	exclude_far
;	unexclude_far
; History:
;	Tue 18-Aug-1987 14:50:37 -by-  **** ***** [*****]
;	Added test of the disabled flag.
;
;	Sun 22-Feb-1987 16:29:09 -by-  **** ***** [*****]
;	Created.
;-----------------------------------------------------------------------;


;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;


assumes ds,Data
assumes es,nothing


cProc	ScanLR,<FAR,PUBLIC,WIN,PASCAL>,<si,di>

	parmD	lp_device		;ptr to a physical device
	parmW	x			;x coordinate of search start
	parmW	y			;y coordinate of search start
	parmD	color			;color for the search
	parmW	dir_style		;control and search style

	localW	width_bits		;actual width of scan in bits
	localB	is_device		;set non-zero if the device

cBegin

	;mov ah, 0ah
    ;mov al, "R"
    ;mov bh, 0
    ;mov cx, 5
    ;int 10h

    mov ax, -1

cEnd






sEnd	BlueMoonSeg

	ifdef	PUBDEFS
	include scanlr.pub
	endif

end
