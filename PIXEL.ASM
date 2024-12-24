        page    ,132
;-----------------------------Module-Header-----------------------------;
; Module Name:	PIXEL.ASM
;
; This module contains the Set/Get Pixel routine.
;
; Created: 22-Feb-1987
; Author:  **** ***** [*****]
;
; Copyright (c) 1984-1987 Microsoft Corporation
;
; Exported Functions:	Pixel
;
; Public Functions:	none
;
; Public Data:		none
;
; General Description:
;
;   Pixel is used to either set a pixel to a given color with the
;   current binary raster operation, or to return the color of the
;   the pixel at the given location.
;
; Restrictions:
;
;-----------------------------------------------------------------------;


	??_out	Pixel

incDrawMode	= 1			;Include control for gdidefs.inc

	.xlist
	include cmacros.inc
	include gdidefs.inc
	include display.inc
	include macros.mac
	.list


	externA ScreenSelector		;Selector to the screen
	externA SCREEN_W_BYTES		;Screen width in bytes


ifdef	EXCLUSION
	externFP exclude_far		;Exclude area from screen
	externFP unexclude_far		;Clear excluded area
endif


sBegin	Data

	externB enabled_flag		;Non-zero if output allowed

sEnd	Data


createSeg _PIXEL,PixelSeg,word,public,CODE
sBegin	PixelSeg
assumes cs,PixelSeg


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
; Pixel
;
;   Set or Get a Given Pixel
;
;   The given pixel is set to the given color or the given pixel's
;   physical color is returned.
;
;   The physical device may be the screen or a monochrome bitmap.
;
;   If lp_draw_mode is NULL, then the physical color of the pixel is
;   returned.  If lp_draw_mode isn't NULL, then the pixel will be set
;   to the physical color passed in, combined with the pixel already
;   at that location according to the raster-op in lp_draw_mode.  Pixel
;   doesn't pay attention to the background mode.
;
;   No clipping of the input value is required.  GDI clips the
;   coordinate before it is passed in, for both Set and Get.
;
; Entry:
; Returns:
;	DX:AX = physical color if get pixel
;	DX:AX = positive if no error and set was OK.
; Error Returns:
;	DX:AX = 8000:0000H if error occured
; Registers Preserved:
;	SI,DI,DS,BP
; Registers Destroyed:
;	AX,BX,CX,DX,ES,FLAGS
; Calls:
;	exclude_far
;	unexclude_far
; History:
;	Sat 31-Oct-1987 00:21:06 -by-  **** ***** [*****]
;	Added clipping of the (X,Y)
;
;	Tue 18-Aug-1987 14:50:37 -by-  **** ***** [*****]
;	Added test of the disabled flag.
;
;	Tue 03-Mar-1987 20:42:07 -by-  **** ****** [******]
;	Moved a mov instruction in EGA ROP handling code.
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


cProc	Pixel,<FAR,PUBLIC,WIN,PASCAL>,<si,di>

	parmD	lp_device		;Pointer to device
	parmW	x			;X coordinate of pixel
	parmW	y			;Y coordinate of pixel
	parmD	p_color 		;Physical color to set pixel to
	parmD	lp_draw_mode		;Drawing mode to use, or null if Get


cBegin

	mov ax, 1
	mov dx, 1

pixel_exit:

cEnd



ifdef	PUBDEFS
	include pixel.pub
endif

sEnd	PixelSeg
end
