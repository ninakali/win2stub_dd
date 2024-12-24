	page	,132
;----------------------------Module-Header------------------------------;
; Module Name: polyline.asm
;
; Brief Description: Polyline drawing device driver.
;
; Created: 3/3/87
; Author: **** ******	(******)
;
; Copyright (c) 1983 - 1987  Microsoft Corporation
;
; Given a set of points, draw a set of polylines connecting adjoining
; points.  If writing to the EGA, then exclude the cursor from the line
; of pixels. Solid and styled lines are handled. Small (<= 64k bytes)
; and huge bitmaps are supported. A run length slice algorithm is used
; to determine the pixels used to draw each line.  The algorithm is
; explained later on.  
;
; The line drawing code is slightly different depending on whether
; we are drawing solid or styled lines.  For the sake of speed, a
; different set of line drawing routines is called for each case.
; Only the case we are using will be brought into memory. In almost
; every case, only one of these destinations at a time will be used.
;
; There are sixteen raster operations (sets of logical operations) performed
; on the data written out. All raster operations are done in one pass at
; memory. Depending on the raster operation and the color of the pen, it
; is easily determined whether we set bits to zeros, set bits to ones,
; invert bits or do nothing.
;
; Styled lines are drawn in two passes.  The first pass draws the line color.
; The second pass draws the gap color. Styled lines are drawn one pixel at
; a time.  There is no efficient way around this due to the rotating style
; error term which has to be updated with each bit output. It unfortunately
; depends on the value of the bit, which makes outputting a byte at a time
; expensive to set up.
;
; All lines, except vertical, are drawn from left to right.
;-----------------------------------------------------------------------;


;	This function will perform private stack checking.  In order for
;	private stack checking to occur, two symbols must be defined
;	prior to the inclusion of cmacros.inc.  ?CHKSTK must be defined
;	if the cmacros are to perform stack checking on procedures with
;	local parameters.  ?CHKSTKPROC must be defined if private stack
;	checking will be used.
;
;	The actual macro body for ?CHKSTKPROC will be defined later.
;
;	Since the stack-checking code is designed to work quickly
;	as a near subroutine, and normally resides in segment Code, a
;	duplicate is included in the segment _LINES.  To reach this,
;	the macro ?CHKSTKNAME is defined.


?CHKSTK = 1
?CHKSTKPROC	macro
		endm

?CHKSTKNAME	macro
	call	LineSeg_check_stack
		endm


incLogical	= 1			;Include GDI Logical object definitions
incDrawMode	= 1			;Include GDI DrawMode definitions
incOutput	= 1			;Include GDI Output definitions

	.xlist
	include cmacros.inc
	include gdidefs.inc
	include display.inc
	include egamem.inc
	include macros.mac
	include polyline.inc   		; polyline equates file.
	.list


	??_out	polyline


	externA	SCREEN_WIDTH
	externA	SCREEN_HEIGHT
	externA	HYPOTENUSE
	externA	Y_MAJOR_DIST
	externA	X_MAJOR_DIST
	externA	Y_MINOR_DIST
	externA	X_MINOR_DIST
	externA	MAX_STYLE_ERR

	externFP LineSeg_check_stack

ifdef	EXCLUSION
	externFP exclude_far   		; exclude area from screen.
	externFP unexclude_far 		; clear excluded area.
endif


sBegin	Data

	externB enabled_flag		;Non-zero if output allowed

sEnd	Data


createSeg _LINES,LineSeg,word,public,CODE
sBegin	LineSeg
assumes cs,LineSeg


;	The following external routines draw solid lines to a small
;	bitmap. They are all located in POLYBITM.ASM. There are special
;	case routines depending on the direction of the line to be drawn.

;	externNP	bitmap_draw_x_axial_segments
;	externNP	bitmap_draw_y_axial_segments
;	externNP	bitmap_draw_diag_x_major_segments
;	externNP	bitmap_draw_diag_y_major_segments
;	externNP	bitmap_draw_horizontal_line
;	externNP	bitmap_draw_vertical_line
;	externNP	bitmap_draw_diagonal_line
;	externNP	bitmap_set_to_one	; routine to set bits to ones.
;	externNP	bitmap_set_to_zero	; routine to set bits to zeros.
;	externNP	bitmap_not_dest		; routine to invert bits.

;	The following external routines check for segment overflow of
;	huge bitmaps.  The address of the proper routine is loaded into
;	OverflowProc.

;	externNP	dont_check_overflow	; simply returns.
;	externNP	check_segment_overflow	; checks for and handles overflow.

;	The following external routines draw styled lines. These are
;	all located in POLYSTYL.ASM.  There are special case routines
;	depending on the direction of the line to be drawn.

;	externNP	styled_draw_x_axial_segments
;	externNP	styled_draw_y_axial_segments
;	externNP	styled_draw_diag_x_major_segments
;	externNP	styled_draw_diag_y_major_segments
;	externNP	styled_draw_horizontal_line
;	externNP	styled_draw_vertical_line
;	externNP	styled_draw_diagonal_line
;	externNP	styled_bitmap_line_pixel ; output routine for bitmap line.
;	externNP	styled_bitmap_gap_pixel	; output routine for bitmap gap.

;	public	bit_offset_table
;	public	LineSeg_rot_bit_tbl

;	The rotating bit table is used to fetch the initial mask to use
;	for the line code.  The mask is based on D2..D0 of the X coordinate.

LineSeg_rot_bit_tbl	label	byte
		db	10000000b
		db	01000000b
		db	00100000b
		db	00010000b
		db	00001000b
		db	00000100b
		db	00000010b
		db	00000001b



;	The table bit_offset_table contains 64 bytes.  Only eight of
;	these bytes have any meaning: zero, one, two, four, eight,
;	sixteen, thirty-two, and sixty-four.  A rotating bitmask, with
;	one bit set, is used to index into this table.  Depending on
;	which bit is set, the number of bits to rotate a byte is returned.
;	Because of the sparse nature of this table, and to save space,
;	several other tables have been embedded into it at otherwise
;	non-meaningful locations.

bit_offset_table   label   byte
	db	7			; zero
bit_offset_one:
	db	6			; one
bit_offset_two:
	db	5			; two
	db	1 dup (?)
bit_offset_four:
	db	4			; four
	db	3 dup (?)

bit_offset_eight:
	db	3			; eight
	db	1 dup (?)

;	Table style_table contains style masks used for the different
;	line styles while drawing styled lines.

style_table	label	 byte
	db	11111111B		;Solid line
	db	11100111B		;Dashed
	db	10101010B		;Dotted
	db	11100100B		;Dot-dash
	db	11101010B		;Dash-dot-dot
	db	00000000B		;No line

bit_offset_sixteen:
	db	2			; sixteen
	db	7 dup (?)

	dw	4 dup (?)

bit_offset_thirty_two:
	db	1			; thirty-two
	db	7 dup (?)

	dw	4 dup (?)

;	Tables bitmap_standard_routines and bitmap_simple_routines
;	contain addresses of routines used to draw solid lines on
;	a small bitmap.

bitmap_standard_routines       label   word
;	dw	bitmap_draw_x_axial_segments
;	dw	bitmap_draw_y_axial_segments
;	dw	bitmap_draw_diag_x_major_segments
;	dw	bitmap_draw_diag_y_major_segments

bitmap_simple_routines label   word
;	dw	bitmap_draw_horizontal_line
;	dw	bitmap_draw_vertical_line
;	dw	bitmap_draw_diagonal_line
;	dw	bitmap_draw_diagonal_line

bit_offset_sixty_four:
;	db	0			; sixty-four

;	This is the end of bit_offset_table.

;	errnz	bit_offset_one-bit_offset_table-1
;	errnz	bit_offset_two-bit_offset_table-2
;	errnz	bit_offset_four-bit_offset_table-4
;	errnz	bit_offset_eight-bit_offset_table-8
;	errnz	bit_offset_sixteen-bit_offset_table-16
;	errnz	bit_offset_thirty_two-bit_offset_table-32
;	errnz	bit_offset_sixty_four-bit_offset_table-64


;	Tables styled_standard_routines and styled_simple_routines
;	contain addresses of routines used to draw styled lines.

styled_standard_routines	label   word
;	dw	styled_draw_x_axial_segments
;	dw	styled_draw_y_axial_segments
;	dw	styled_draw_diag_x_major_segments
;	dw	styled_draw_diag_y_major_segments

styled_simple_routines	label   word
;	dw	styled_draw_horizontal_line
;	dw	styled_draw_vertical_line
;	dw	styled_draw_diagonal_line
;	dw	styled_draw_diagonal_line
		     	
;	The table bitmap_procedure_table contains addresses of routines
;	used for bitmap output operations.  Depending on the raster
;	operation and the color, we determine which of these routines
;	should be used, and load its address into BitmapProc, located
;	above.

bitmap_procedure_table	 label	 word
;	dw	bitmap_set_to_zero
;	dw	bitmap_not_dest
;	dw	BITMAP_DO_NOTHING
;	dw	bitmap_set_to_one
page

;--------------------------Public-Routine-------------------------------;
; do_polylines(lp_dst_dev,style,count,lp_points,lp_phys_pen,lp_phys_brush,
;	       lp_draw_mode,lp_clip_rect)
;
; DWORD lp_dst_dev 			// pointer to destination.
; short	style				// output operation.
; short count				// number of points.
; DWORD lp_points			// pointer to set of points.
; DWORD lp_phys_pen			// pointer to physical pen.
; DWORD lp_phys_brush			// pointer to physical brush.
; DWORD	lp_draw_mode			// pointer to drawing mode.
; DWORD lp_clip_rect			// pointer to clipping rect if <> 0.
;
; do_polylines initializes things for the line drawing routines.  If
; the lines are being drawn to the EGA, the exclusion area is handled.
; Necessary tables and pointers are set up depending on line style.
; When all of the necessary initialization is complete, we jump to
; polyline_loop which does the DDA and the line drawing.
;
; Entry: per parameters.
;
; Returns: AX = 1 if polylines drawn.
;
; Error Returns: AX = 0 if polylines not drawn.
;
; Registers Destroyed: AX,BX,CX,DX,DS,flags.
;
; Registers Preserved: DI,SI.
;
; Calls: exclude_far
;	 unexclude_far
;
; History:
;  Tue 18-Aug-1987 14:50:37 -by-	**** *****	    [*****]
; Added test of the disabled flag.
;
;  Thu 30-Apr-1987 13:20:00	-by-	**** ******	    [******]
; Added huge bitmap handling.
;
;  Wed 08-Apr-1987 10:32:33	-by-	**** ******	    [******]
; Modified to draw all lines moving right.
;
;  Mon 23-Feb-1987 12:56:41	-by-	**** ******	    [******]
; Major re-write.
;
;  Tue 28-Oct-1986 16:05:04	-by-    **** ********	    [*****]
; Created.
;-----------------------------------------------------------------------;

;---------------------------Pseudo-Code---------------------------------;
; do_polylines(lp_dst_dev,style,count,lp_points,lp_phys_pen,lp_phys_brush,
;	       lp_draw_mode,lp_clip_rect)
;
; DWORD lp_dst_dev 			// pointer to destination.
; short	style				// output operation.
; short count				// number of points.
; DWORD lp_points			// pointer to set of points.
; DWORD lp_phys_pen			// pointer to physical pen.
; DWORD lp_phys_brush			// pointer to physical brush.
; DWORD	lp_draw_mode			// pointer to drawing mode.
; DWORD lp_clip_rect			// pointer to clipping rect if <> 0.
;
; {
;    if (style is not a polyline)
;        return(0);			// return that line is not drawn.
;
;    if (destination is bitmap)
;        jump to get_bitmap_info;
;
;    // handle exclusion area on the screen.
;
;#ifdef EXCLUSION
;    assume exclusion area is entire screen;
;
;    if (passed a clipping rectangle)
;        set exclusion to passed clipping rectangle;
;
;    exclude_far();			// exclude scan from the screen.
;#endif
;
;get_bitmap_info:
;    // the following group of information is found from the current
;    // bitmap structure.
;
;    BitmapSegment = starting segment of bitmap;
;    NextScan = index to next scan line;
;    BitmapOffset = starting offset of bitmap;
;
;    // check to see if small or huge bitmap.  if it is huge, this is a
;    // good time to load huge bitmap information.
;
;    if (small bitmap)
;        jump to load_color_info;
;
;    // load huge bitmap information.
;
;    DeviceFlags |= DEST_IS_HUGE;
;
;    SegIndex = index to the next segment;
;    FillBytes = number of fill bytes at end of segment;
;    ScansSeg = scan lines per segment;
;
;    // load the pen and line style information.
;
;load_color_info:
;    TmpColor = current pen color;
;    get current line style;
;
;    if (line style > MaxLineStyle)
;        return(0);			// exit with error.
;
;    if (line style == 0)
;        return(1);			// do nothing.
;
;    // get raster operation from draw mode structure.
;
;    DrawModwIndex = raster operation;
;
;    index = current line style;
;    CurStyle = style mask indexed in style_table;
;
;    if (styled line)
;    {
;        // get the background mode and store it as the high byte of
;        // StyleFlags and store CurByte as the low byte.  also, get the
;        // gap color and set the rotating style information.
;
;        BackMode = background mode;
;        BackColor.SPECIAL = background color;
;        high byte of StyleFlags = BackMode;
;        low byte of StyleFlags = CurStyle;
;        StyleLength = MAX_STYLE_ERR;
;    }
;
;    if (solid line)
;    {
;	 DDAstandardProcTable = LineSegOFFSET bitmap_standard_routines;
;	 DDAsimpleProcTable = LineSegOFFSET bitmap_simple_routines;
;    }
;    else
;    {
;        StyledProc => styled_bitmap_line_pixel; // bitmap line routine.
;	 DDAstandardProcTable = LineSegOFFSET styled_standard_routines;
;	 DDAsimpleProcTable = LineSegOFFSET styled_simple_routines;
;    }
;
;set_up_loop:
;    // assume destination is not huge bitmap.
;
;    OverflowProc = LineSegOFFSET dont_check_overflow;
;
;    get first polyline point;
;
;    point CurByte at that point;
;    if (destination is huge bitmap)
;    {
;        // we have a huge bitmap.  compute which segment the Y coordinate
;        // is in. set up SegmentNum to show which segment number this
;        // point is in. set SEG_CurByte to the segment which the point is in.
;
;        SegmentNum = current segment number;
;        SEG_CurByte = current segment;
;    }
;
;    index = x coordinate;
;    index &= PARTIAL_BYTE_MASK;	// get bit offset.
;    BL = LineSeg_rot_bit_tbl + index;	// get rotating bitmask in BL.
;
;    jump to polyline loop;
;
;exit_polyline:
;#ifdef EXCLUSION
;    if (destination is EGA)
;        unexclude_far();		// free up the exclusion area.
;#endif
;
;    return(1);				// indicate success.
; }
;-----------------------------------------------------------------------;

	assumes ds,Data
	assumes es,nothing

cProc	do_polylines,<FAR,PUBLIC,WIN,PASCAL>,<si,di>

	include plylocal.inc

cBegin

	mov ax, 1

poly_fini:

cEnd


sEnd	LineSeg

ifdef	PUBDEFS
	include polyline.pub
endif

end
