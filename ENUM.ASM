	page	,132
;-----------------------------Module-Header-----------------------------;
; Module Name:	ENUM.ASM
;
;   This module contains routines which enumerate a subset of the
;   objects which the device can enumerate.
;
; Created: 16-Feb-1987
; Author:  **** ***** [*****]
;
; Copyright (c) 1983-1987 Microsoft Corporation
;
; Exported Functions:	Control
;
; Public Functions:	none
;
; Public Data:		none
;
; General Description:
;
;   A subset of the fonts, pens, and brushes which this driver can
;   support are enumerated for the caller, until all objects of the
;   requested type have been enumerated or the caller aborts.
;
; Restrictions:
;
;-----------------------------------------------------------------------;


;

incLogical	= 1			;Include control for gdidefs.inc
incFont 	= 1			;Include control for gdidefs.inc

	.xlist
	include cmacros.inc
	include gdidefs.inc
	include macros.mac
	.list


	??_out	enum

	externA COLOR_TBL_SIZE		;# entries in the color table


createSeg _BLUEMOON,BlueMoonSeg,word,public,CODE
sBegin	BlueMoonSeg
assumes cs,BlueMoonSeg

	externD BlueMoonSeg_color_table ;Color table
page
;--------------------------Exported-Routine-----------------------------;
; EnumDeviceFonts
;
;   Enumerate Device Fonts is called to enumerate the fonts available
;   on a given device.	For each appropriate font, the callback function
;   is called with the information for that font.  The callback function
;   is called until there are no more fonts or the callback function
;   returns zero.
;
;   Since this driver has no fonts to enumerate, all that need be done
;   is return a success flag (1).
;
; Entry:
;	None
; Returns:
;	AX = 1
; Error Returns:
;	None
; Registers Preserved:
;	SI,DI,DS,BP
; Registers Destroyed:
;	None
; Calls:
;	None
; History:
;	Tue 17-Feb-1987 21:17:40 -by-  **** ***** [*****]
;	Created.
;-----------------------------------------------------------------------;


;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;


assumes ds,Data
assumes es,nothing


cProc	EnumDFonts,<FAR,PUBLIC,WIN,PASCAL>,<si,di>

	parmD	lp_device		;Physical device
	parmD	lp_face_name		;Face name
	parmD	lp_callback_func	;Callback function
	parmD	lp_client_data		;Data to pass the callback function

cBegin	<nogen>

	mov	ax,1			;This is a nop for this driver
	ret	16

cEnd	<nogen>
page
;--------------------------Exported-Routine-----------------------------;
; EnumObject
;
;   The given style of object is enumerated through a callback
;   facility.  Since there are only a few objects within this
;   particular driver, they will all be enumerated.
;
;   If the Callback function returns a zero, then the enumeration
;   will be terminated.
;
; Entry:
;	None
; Returns:
;	AX = last value returned from callback function.
;	AX = 1 if nothing was enumerated.
; Error Returns:
;	None
; Registers Preserved:
;	SI,DI,DS,BP
; Registers Destroyed:
;	AX,BX,CX,DX,ES,FLAGS
; Calls:
;	None
; History:
;	Tue 17-Feb-1987 21:17:40 -by-  **** ***** [*****]
;	Created.
;-----------------------------------------------------------------------;

;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;


assumes ds,Data
assumes es,nothing


cProc	EnumObj,<FAR,PUBLIC,WIN,PASCAL>,<si,di>

	parmD	lp_device
	parmW	style
	parmD	lp_callback_func
	parmD	lp_client_data

	localW	old_SP
	localV	obj_area,%(size LogBrush)
	errnz	<(SIZE LogBrush)-(SIZE LogPen)-2>	;Want the biggest!

cBegin

	mov	old_SP,sp		;Save SP for clean-up

	mov ax, 1
	jmp exit_enum_obj

	;cmp	style,OBJ_PEN		;Pen?
	;je	enum_pen		;  Yes
	;cmp	style,OBJ_BRUSH 	;Brush?
	;je	enum_brush		;  Yes
	;mov	ax,1

exit_enum_obj:
	mov	sp,old_SP		;Remove any return addresses from stack

cEnd


sEnd	BluseMoonSeg

	ifdef	PUBDEFS
	include enum.pub
	endif

end
