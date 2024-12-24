	page	,132
;-----------------------------Module-Header-----------------------------;
; Module Name:	ROBJECT.ASM
;
; This module contains the code which realizes the objects required
; by GDI.
;
; Created: 19-Feb-1987
; Author:  **** ***** [*****]
;
; Copyright (c) 1983-1987 Microsoft Corporation
;
; Exported Functions:	RealizeObject
;
; Public Functions:	sum_RGB_colors_alt
;
; Public Data:		none
;
; General Description:
;
; Restrictions:
;
;-----------------------------------------------------------------------;

	??_out	robject


	.xlist
	include cmacros.inc
incLogical = 1				;Include control for gdidefs.inc
	include gdidefs.inc
	include display.inc
	include macros.mac
	.list



sBegin	Code
	assumes cs,Code

;	public	sum_RGB_colors_alt	;Alternate entry point
;	public	sum_RGB_alt_far		;Alternate far entry point

	externNP dither 		;Brush dithering code
	externA  BW_THRESHOLD		;Where black becomes white


;	The following are the definitions for the hatch patterns.
;	They are defined by each individual driver base on its
;	resolution.

	externA < H_HATCH_BR_0, H_HATCH_BR_1, H_HATCH_BR_2, H_HATCH_BR_3>
	externA < H_HATCH_BR_4, H_HATCH_BR_5, H_HATCH_BR_6, H_HATCH_BR_7>
	externA < V_HATCH_BR_0, V_HATCH_BR_1, V_HATCH_BR_2, V_HATCH_BR_3>
	externA < V_HATCH_BR_4, V_HATCH_BR_5, V_HATCH_BR_6, V_HATCH_BR_7>
	externA <D1_HATCH_BR_0,D1_HATCH_BR_1,D1_HATCH_BR_2,D1_HATCH_BR_3>
	externA <D1_HATCH_BR_4,D1_HATCH_BR_5,D1_HATCH_BR_6,D1_HATCH_BR_7>
	externA <D2_HATCH_BR_0,D2_HATCH_BR_1,D2_HATCH_BR_2,D2_HATCH_BR_3>
	externA <D2_HATCH_BR_4,D2_HATCH_BR_5,D2_HATCH_BR_6,D2_HATCH_BR_7>
	externA <CR_HATCH_BR_0,CR_HATCH_BR_1,CR_HATCH_BR_2,CR_HATCH_BR_3>
	externA <CR_HATCH_BR_4,CR_HATCH_BR_5,CR_HATCH_BR_6,CR_HATCH_BR_7>
	externA <DC_HATCH_BR_0,DC_HATCH_BR_1,DC_HATCH_BR_2,DC_HATCH_BR_3>
	externA <DC_HATCH_BR_4,DC_HATCH_BR_5,DC_HATCH_BR_6,DC_HATCH_BR_7>
	page
;--------------------------Exported-Routine-----------------------------;
; RealizeObject
;
;   RealizeObject - Logical to Physical Object Realization
;
;   RealizeObject performs the task of converting logical objects
;   into physical objects that this driver can manipulate to per-
;   form the various functions requested of it.
;
;   The size needed to realize an object will be returned if the
;   pointer to where the physical realization is to be stored is
;   NULL.
;
;   In some cases where the driver cannot realize the requested object,
;   a solid color pen must be realized which GDI will use when it
;   performs the nessacary simulations.  In other cases, punt.
;
; Entry:
;	None
; Returns:
;	AX = object size if ok
; Error Returns:
;	AX = 0	if error or object unrealizable
; Registers Preserved:
;	SI,DI,DS,BP
; Registers Destroyed:
;	AX,BX,CX,DX,ES,FLAGS
; Calls:
;
; History:
;	Mon 16-Feb-1987 18:09:09 -by-  **** ***** [*****]
;	Created.
;-----------------------------------------------------------------------;


;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;


	assumes ds,Data
	assumes es,nothing


cProc	RealizeObject,<FAR,PUBLIC,WIN,PASCAL>,<si,di>

	parmD	lp_device		;Pointer to Device structure
	parmW	style			;Style of realization
	parmD	lp_in_obj		;Pointer to input (logical) object
	parmD	lp_out_obj		;Pointer to output (physical) object
	parmD	lp_text_xform		;Pointer to a text transformation
					;  or (x,y) for brush realization
					;  Segment = y, Offset = x

	localB	brush_accel		;Temp brush accelerator


cBegin

	cld				;Following code assumes this
	mov	ax,1			;Assume good exit
	jmp realize_exit

realize_exit:

cEnd

sEnd	Code

ifdef	PUBDEFS
	include ROBJECT.PUB
endif

	end
