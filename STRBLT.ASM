	page	,132
;-----------------------------Module-Header-----------------------------;
; Module Name:	STRBLT.ASM
;
;   This module contains the strblt function and the ExtendedTextOut
;   function.
;
; Created: 17-Mar-1987
; Author:  **** ***** [*****]
;
; Copyright (c) 1984-1987 Microsoft Corporation
;
; Exported Functions:	Strblt
;
; Public Functions:	none
;
; Public Data:		none
;
; General Description:
;
; Restrictions:
;
;-----------------------------------------------------------------------;



;	This function will perform private stack checking.  In order for
;	private stack checking to occur, two symbols must be defined
;	prior to the inclusion of cmacros.inc.	?CHKSTK must be defined
;	if the cmacros are to perform stack checking on procedures with
;	local parameters.  ?CHKSTKPROC must be defined if private stack
;	checking will be used.
;
;	The actual macro body for ?CHKSTKPROC will be defined later.


?CHKSTK = 1
?CHKSTKPROC	macro
		endm


incFont 	= 1			;Include control for gdidefs.inc
incDrawMode	= 1			;Include control for gdidefs.inc


	.xlist
	include cmacros.inc
	include gdidefs.inc
	include display.inc
	include egamem.inc
	include macros.mac
	include strblt.inc
	include fontseg.inc
	.list


	??_out	strblt

;	Link time constants describing the size that the EGA will
;	be running in.

	externA ScreenSelector		;Selector to the screen
	externA SCREEN_W_BYTES		;Screen width in bytes
	externA SCREEN_WIDTH		;Screen width in pixels


;	Other functions required for strblt.

;	externNP fixed_pitch_strblt	;Fixed pitch 8 wide font code
;	externNP build_string		;All other font code

ifdef	 EXCLUSION
	externNP exclude		;Exclude area from screen
	externNP unexclude		;Clear excluded area
endif


sBegin	Data

	externB enabled_flag		;Non-zero if output allowed

sEnd	Data


sBegin	Code
assumes cs,Code
page
;--------------------------Exported-Routine-----------------------------;
; Strblt
;
; This is the old strblt entry point.  Null parameters are pushed
; for the ExtTextOut's extra parameters, and control given to
; ExtTextOut.
;
; Entry:
;	EGA registers in default state
; Returns:
;	DX = Y extent of string if extent call
;	AX = X extent of string if extent call
;	EGA registers in default state
; Error Returns:
;	DX:AX = 8000:0000H
; Registers Preserved:
;	SI,DI,DS,BP
; Registers Destroyed:
;	AX,BX,CX,DX,ES,FLAGS
; Calls:
;	See ExtTextOut
; History:
;	Thu 09-Apr-1987 13:36:08 -by-  **** ***** [*****]
;	Created.
;-----------------------------------------------------------------------;

;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;


assumes ds,Data
assumes es,nothing


cProc	Strblt,<FAR,PUBLIC,WIN,PASCAL>,<si,di>

	parmD	lp_device		;Destination device
	parmW	x			;Left origin of string
	parmW	y			;Top  origin of string
	parmD	lp_clip_rect		;Clipping rectangle
	parmD	lp_string		;The string itself
	parmW	count			;Number of characters in the string
	parmD	lp_font 		;Font to use
	parmD	lp_draw_mode		;Drawmode structure to use
	parmD	lp_xform		;Current text transform

;	ExtTextOut parameters we have to dummy up.
;
;	parmD	lp_dx			;Widths for the characters
;	parmD	lp_opaque_rect		;Opaquing rectangle
;	parmW	eto_options		;ExtTextOut options

cBegin	<nogen>

	pop	cx			;Save caller's return address
	pop	bx
	xor	ax,ax
	push	ax			;Push null for lp_dx
	push	ax
	push	ax			;Push null for lp_opaque_rect
	push	ax
	push	ax			;Push null for options
	push	bx			;Restore return address
	push	cx
;	jmp	ExtTextOut
	errn$	ExtTextOut

cEnd	<nogen>
page
;--------------------------Exported-Routine-----------------------------;
; ExtTextOut
;
; Entry:
;	EGA registers in default state
; Returns:
;	DX = Y extent of string if extent call
;	AX = X extent of string if extent call
;	EGA registers in default state
; Error Returns:
;	DX:AX = 8000:0000H
; Registers Preserved:
;	SI,DI,DS,BP
; Registers Destroyed:
;	AX,BX,CX,DX,ES,FLAGS
; Calls:
;	exclude
;	unexclude
;	......
; History:
;	Tue 18-Aug-1987 16:30:43 -by-  **** ***** [*****]
;	Added saving enabled_flag.
;
;	Thu 09-Apr-1987 13:36:08 -by-  **** ***** [*****]
;	Created.
;-----------------------------------------------------------------------;

;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;


	assumes ds,Data
	assumes es,nothing

	define_frame ExtTextOut 	;Define frame

cBegin

;	mov ah, 09h
;	mov al, "S"
 ;       mov bl, 04Dh
;	mov cx, 3
;	int 10h
	

exit_strblt_null:
	xor	ax,ax			;Return DX:AX = 0000:0000
	cwd				;  to show success

exit_strblt:

cEnd


	ifdef	PUBDEFS
	include strblt.pub
	endif

sEnd	code
end
