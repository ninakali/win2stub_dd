        page    ,132
;-----------------------------Module-Header-----------------------------;
; Module Name:	FB.ASM
;
;   This module contains code for the FastBorder function.
;
; Created: 27-May-1987
; Author:  *** ****** [******]
;
; Copyright (c) 1984-1987 Microsoft Corporation
;
; Exported Functions:	FastBorder
;
; Public Functions:	none
;
; Public Data:		none
;
; General Description:
;
;	This subroutine draws the four edges of a window border.  It
;	clips the border to the clipping rectangle passed in.
;
;	The following is a legend of symbols used in this file:
;
;		corners for input rect: 	(x1,y1), (x2,y2)
;		border thickness horizontally:	bth
;		  (i.e. the width of the left
;		   and right segments of the
;		   border)
;		border thickness vertically:	btv
;		  (i.e. the height of the top
;		   and bottom segments of the
;		   border)
;		corners of clipping region:	(u1,v1), (u2,v2)
;		top left corner of blt:		(destx,desty)
;		width of blt:			xext
;		height of blt:			yext
;
;
;	The shapes of the edges drawn are shown below. If no clipping
;	is necessary, the edges are drawn in the order top, bottom,
;	right, left.  Otherwise, they are drawn in the order top, right,
;	bottom, left.  The latter order is more visually pleasing, but
;	the former order is faster because some blt parameters do not
;	change between successive calls to do_blt.
;
;
	page
;			+-----------------------+---+
;			|			|   |
;			|			|   |
;			+---+-------------------+   |
;			|   |			|   |
;			|   |			|   |
;			|   |			|   |
;			|   |			|   |
;			|   |			|   |
;			|   |			|   |
;			|   |			|   |
;			|   +-------------------+---+
;			|   |			    |
;			|   |			    |
;			+---+-----------------------+
;
;
;
; Restrictions:
;
;	The clipping rectangle (hRaoClip) is a SIMPLEREGION.
;	Rectangle corners have been sorted.
;
;-----------------------------------------------------------------------

;	This function will perform private stack checking.  In order for
;	private stack checking to occur, two symbols must be defined
;	prior to the inclusion of cmacros.inc.  ?CHKSTK must be defined
;	if the cmacros are to perform stack checking on procedures with
;	local parameters.  ?CHKSTKPROC must be defined if private stack
;	checking will be used.
;
;	The actual macro body for ?CHKSTKPROC will be defined later.


?CHKSTK = 1
?CHKSTKPROC	macro
		endm

	.xlist
	include cmacros.inc
	include gdidefs.inc
	include macros.mac
	.list


	externFP BitBlt

sBegin	Code
assumes cs,Code
assumes ds,nothing
assumes es,nothing
page

;--------------------------Exported-Routine-----------------------------;
; FastBorder
;
;   Draw a border inside a rectangle, clipping to a second rectangle.
;
; Entry:
;	See parameter definitions below.
; Returns:
;	AX = ~0
; Error Returns:
;	AX = 0, if stack overflows allocating local variables
; Registers Preserved:
;	SI,DI,DS,BP
; Registers Destroyed:
;	AX,BX,CX,DX,ES,FLAGS
; Calls:
;	do_blt
; History:
;	Wed 27-May-1987 16:29:09 -by-  *** ****** [******]
;	 Created.
;	Thu 11-Jun-1987 19:49:30 -by-  *** ****** [******]
;	 Cleaned up comments.
;-----------------------------------------------------------------------;

;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;


cProc	FastBorder,<FAR,PUBLIC,WIN,PASCAL>,<si,di>

	parmD	lprect			;--> rectangle to frame
	parmW	bth			;border thickness horizontally
	parmW	btv			;border thickness vertically
	parmD	rop			;raster op
	parmD	lpPDevice		;--> physical device structure
	parmD	lpPBrush		;--> physical brush structure
	parmD	lpDrawMode		;--> drawing mode structure
	parmD	lprectclip		;--> clipping rectangle


cBegin
	mov ax, 1

fb_exit:

cEnd
page

;---------------------------Private-Routine-----------------------------;
; do_blt
;
;   Shovel parameters to BitBlt.
;
; Entry:
;	None
; Returns:
;	AX = return value from BitB t
; Registers Preserved:
;	SI,DI,BP
; Registers Destroyed:
;	BX,CX,DX,DS,ES,FLAGS (inside BitBlt)
; Calls:
;	BitBlt
; History:
;	Wed 27-May-1987 16:29:09 -by-  *** ****** [******]
;	 Created.
;	Thu 11-Jun-1987 19:49:30 -by-  *** ****** [******]
;	 Cleaned up comments.  
;-----------------------------------------------------------------------;

do_blt	proc	near

	xor	ax,ax			;generic null-parameter

;	arg	<lpPDevice,destx,desty,ax,ax,ax,ax,xext,yext,rop,lpPBrush,lpDrawMode>
	cCall	BitBlt

	ret

do_blt	endp


ifdef	PUBDEFS
	include fb.pub
endif

sEnd	Code
end
