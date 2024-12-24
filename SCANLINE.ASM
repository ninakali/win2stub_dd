        page    ,132
;-----------------------------Module-Header-----------------------------;
; Module Name:	SCANLINE.ASM
;
;   This module contains the scanline sub-function of Output.
;
; Created: 22-Feb-1987
; Author:  **** ***** [*****]
;
; Copyright (c) 1984-1987 Microsoft Corporation
;
; Exported Functions:	do_scanlines
;
; Public Functions:	none
;
; Public Data:		none
;
; General Description:
;
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
;
;	Since the stack-checking code is designed to work quickly
;	as a near subroutine, and normally resides in segment Code,
;	a duplicate is included in this segment.  To reach this, the
;	the macro ?CHKSTKNAME is defined.




?CHKSTK = 1
?CHKSTKPROC	macro
		endm
?CHKSTKNAME	macro
	call	ScanlineSeg_check_stack
		endm


incLogical	= 1			;Include control for gdidefs.inc
incDrawMode	= 1			;Include control for gdidefs.inc
incOutput	= 1			;Include control for gdidefs.inc


	.xlist
	include cmacros.inc
	include gdidefs.inc
	include display.inc
	include macros.mac
	.list

	??_out	scanline

;	Link time constants describing the size of the display

	externA ScreenSelector		;Selector to the screen
	externA SCREEN_W_BYTES		;Screen width in bytes


ifdef	EXCLUSION
	externFP exclude_far		;Exclude area from screen
	externFP unexclude_far		;Clear excluded area
endif



;	The cntrl_blk structure will contain the addresses of the
;	processor for the first and last byte, inner loop, and the
;	accelerator byte for skipping the operation.

cntrl_blk	struc
first_last_proc dw	?		;Adderss for first and last byte
inner_loop_proc dw	?		;Address for inner loop bytes
nop_flag	db	?		;D7 set if this is a nop
pattern 	db	?		;The pattern for the plane
cntrl_blk	ends

		errnz	<(size cntrl_blk) and 1>


;	The following equates are for the binary raster ops
;	which will be passed to this routine.  The values
;	shown are 0:15 since the rop is mapped upon entry
;	into this function.

ROP_DDX 	equ	0		;DDx
ROP_DPON	equ	1		;DPon
ROP_DPNA	equ	2		;DPna
ROP_PN		equ	3		;Pn
ROP_PDNA	equ	4		;PDna
ROP_DN		equ	5		;Dn
ROP_DPX 	equ	6		;DPx
ROP_DPAN	equ	7		;DPan
ROP_DPA 	equ	8		;DPa
ROP_DPXN	equ	9		;DPxn
ROP_D		equ	10		;D
ROP_DPNO	equ	11		;DPno
ROP_P		equ	12		;P
ROP_PDNO	equ	13		;PDno
ROP_DPO 	equ	14		;DPo
ROP_DDXN	equ	15		;DDxn


;	The following values will be set in another_tbl for
;	doing variuos accelerations on the raster op.
;
;	NO_OBJECT is the value used to indicate that the drawing
;	operation doesn't require a pen or brush.
;
;	NEG_PATTERN is used as a flag for special cased P and Pn
;	operations.  If this flag is set, then the pattern needs
;	to be negated before stored in EGA memory at current_brush.
;
;	ALT_NEG_PATTERN is used as a flag to indicated that the
;	pattern should be negated for word templates.

NEG_PATTERN	equ	10000000b
NO_OBJECT	equ	01000000b
ALT_NEG_PATTERN equ	00000001b


;	Define the flag to indicate cursor unexclusion required
;	before exiting.

CU_NONE		equ	00000000b
CU_EXCLUDE	equ	00000001b


;	The following are the values which will be stored
;	in some_flags.

INDEX_XPARENT	equ	00010000b	;Transparent operation


sBegin	Data

	externB enabled_flag		;Non-zero if output allowed

sEnd	Data


createSeg _SCANLINE,ScanlineSeg,word,public,CODE
sBegin	ScanlineSeg
assumes cs,ScanlineSeg

	externNP ScanlineSeg_check_stack
page

;--------------------------Exported-Routine-----------------------------;
; do_scanlines
;
; Entry:
;	None
; Return:
;	AX = Non-zero to show success
; Error Returns:
;	None
; Registers Preserved:
;	SI,DI,DS,BP
; Registers Destroyed:
;	AX,BX,CX,DX,ES,FLAGS
; Calls:
;	comp_scan
;	get_fill_data
;	comp_interval
;	unexclude_far
;	various drawing functions set up by other code
; History:
;	Wed 04-Mar-1987 12:25:32 -by-  **** ***** [*****]
;	Created.
;-----------------------------------------------------------------------;


;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;


	assumes ds,Data
	assumes es,nothing


cProc	do_scanlines,<FAR,PUBLIC,WIN,PASCAL>,<si,di>

	parmD	lp_dst_dev		;--> to the destination
	parmW	style			;Output operation
	parmW	count			;# of points
	parmD	lp_points		;--> to a set of points
	parmD	lp_phys_pen		;--> to physical pen
	parmD	lp_phys_brush		;--> to physical brush
	parmD	lp_draw_mode		;--> to a Drawing mode
	parmD	lp_clip_rect		;--> to a clipping rectange if <> 0


cBegin
	mov ax, 1

do_scans_exit:

cEnd


sEnd	ScanlineSeg

ifdef	PUBDEFS
	include SCANLINE.PUB
endif

end
