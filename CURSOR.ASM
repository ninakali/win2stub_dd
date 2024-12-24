	page	,132
;-----------------------------Module-Header-----------------------------;
; Module Name:	CURSOR.ASM
;
; This file contains the pointer shape routines required to draw the
; pointer shape on the EGA.
;
; Created: 23-Feb-1987
; Author:  **** ***** [*****]
;
; Copyright (c) 1983-1987 Microsoft Corporation
;
; Exported Functions:	none
;
; Public Functions:	move_cursors
;			draw_cursor
;			cursor_off
;
; Public Data:		x_cell
;			y_cell
;			cur_cursor
;			inquire_data
;			real_width
;			CUR_HEIGHT
;			CUR_ROUND_LEFT
;			CUR_ROUND_RIGHT
;			INIT_CURSOR_X
;			INIT_CURSOR_Y
;
;			EGAMem:current_brush
;			EGAMem:known_word
;			EGAMem:shadowed_mode
;			EGAMem:saved_latches
;			EGAMem:plane_index
;			EGAMem:enable_test
;			EGAMem:tonys_bar_n_grill
;
; General Description:
;
;   All display drivers must support a "cursor" for the pointing
;   device.  The cursor is a small graphics image which is allowed
;   to move around the screen independently of all other operations
;   to the screen, and is normally bound to the location of the
;   pointing device.  The cursor is non-destructive in nature, i.e.
;   the bits underneath the cursor image are not destroyed by its
;   presence.
;
;   A cursor consists of an AND mask and an XOR mask, which give
;   possible pixel colors of 0 (black), 1 (white), display, or
;   inverse display.
;
;		    AND XOR | DISPLAY
;		    ---------------------
;		     0	 0  |	  0
;		     0	 1  |	  1
;		     1	 0  |	Display
;		     1	 1  | Not Display
;
;   The cursor also has a "hot spot", which is the pixel of the
;   cursor image which is to be aligned with the actual pointing
;   device location.
;
;
;		  |	    For a cursor like this, the hot spot
;		  |	    would normally be the *, which would
;	       ---*---	    be aligned with the pointing device
;		  |	    position
;		  |
;
;   The cursor may be moved to any location on the screen, be
;   restricted to only a section of the screen, or be made invisible.
;   Part of the cursor image may be past the edge of the screen, and
;   in such a case only the visible part is displayed.
;
;
;
;   Logically, the cursor image isn't part of the physical display
;   surface.  When a drawing operation coincides with the cursor
;   image, the result is the same as if the cursor image wasn't
;   there.  In reality, if the cursor image is part of the display
;   surface it must be removed from memory before the drawing
;   operation occurs, and redrawn afterwards.
;
;   Exclusion of the cursor image is the responsibility of the
;   display driver.  Each output operation must decide whether
;   or not to remove the cursor from display memory, and, if yes,
;   to set a protection rectangle wherein the cursor must not be
;   displayed.  The cursor image drawing routine honors this
;   protection rectangle.
;
;
;
;   To reduce the amount of perceived flicker of the cursor,
;   a buffering scheme has been implemented where the cursor
;   update is performed off-screen.
;
;   To do this, a couple of buffers are maintained.  One buffer
;   contains the contents of the screen in an area around where
;   the cursor will go, and the other saves the contents of this
;   buffer where the actual cursor is to be drawn.  The region
;   of the screen where the cursor goes is read into the buffer,
;   the old cursor removed by copying the contents of the save
;   area over the old cursor, the area under the new cursor is
;   saved, and the new cursor written into the buffer.	The
;   buffer is then written back to the screen.	This has the
;   advantage that removal of the old cursor and writing of the
;   new happen at the same time on the screen.
;
;   Since the buffer is of a fixed size, it must be determined
;   if both the old and new cursors fit within. If they do not
;   both fit within the buffer, the old cursor is removed from
;   the screen by copying the save area directly to the screen.
;   The drawing of the cursor then proceeds normally, except
;   that there is no old cursor to remove from the buffer.
;
;
; Restrictions:
;
;   All routines herein assume protection either via cli/sti
;   or a semaphore at higher level code.
;
;-----------------------------------------------------------------------;


	.xlist
	include cmacros.inc
	include windefs.inc
	include cursor.inc		;Device specific constants
	include	macros.mac
	.list
	include egamemd.inc


	??_out	cursor


	externA ScreenSelector		;Segment of screen

	public	move_cursors
	public	draw_cursor
	public	cursor_off
	page
;	The SMALL_ROTATE flag conditionally assembles optimum code for
;	rotating cursor masks one or two bit positions.  This however
;	costs approximately 90 bytes of code space
;
;		0 = do not assemble the small rotate code
;		1 = do	   assemble the small rotate code

SMALL_ROTATE	 equ	 1


createSeg _BLUEMOON,BlueMoonSeg,word,public,CODE
sBegin	BlueMoonSeg

;	inquire_data contains information about mouse acceleration
;	which the window manager uses.

inquire_data	CURSORINFO   <X_RATE,Y_RATE>

sEnd	BlueMoonSeg



sBegin	Data

	externB enabled_flag		;Non-zero if output allowed

	public	x_cell			;Make all of these values available
	public	y_cell			;  to the other cursor routines
	public	cur_cursor
	public	inquire_data
	public	real_width
	public	CUR_HEIGHT
	public	CUR_ROUND_LEFT
	public	CUR_ROUND_RIGHT
	public	INIT_CURSOR_X
	public	INIT_CURSOR_Y



;	cur_cursor contains the cursor data structure (less the
;	actual bits) for the current cursor shape.

cur_cursor	cursorShape <,,,,,>


;	old_valid contains a flag which is used to indicate
;	whether or not the contents of the cursor save area
;	contains valid data.

old_valid	db	0		;True if old cursor contains valid data
OLD_IS_INVALID	equ	0		;  No cursor in save area
OLD_IS_VALID	equ	1		;  Cursor in save area



;	(x_cell,y_cell) is the location of the cursor on the screen.
;	These locations are only updated whenever a cursor is drawn.

x_cell		dw	0
y_cell		dw	0



;	rotation maintains the number of bits the cursor masks have
;	been rotated.  This value is always between 0 and 7

rotation	db	0



;	old_x_cell and old_y_cell contain the (X,Y) on the
;	screen to which the contents of the save_area is mapped.
;	These cells are only valid if old_valid = OLD_IS_VALID

old_x_cell	dw	0
old_y_cell	dw	0



;	x_buffer and y_buffer contain the (X,Y) of the upper left
;	hand corner of the screen locations which were copied into
;	screen_buf.  screen_pointer contains the offset in display
;	memory of (x_buffer, y_buffer).


x_buffer	dw	0
y_buffer	dw	0
screen_pointer	dw	0



;	buf_height contains the number of scans of valid information
;	in screen_buf.	This is set to the height of a cursor/icon
;	plus the overlap of the old and new cursor/icon.  Thus if
;	there is only 1 pixel difference in Y, only CUR_HEIGHT+1
;	scans must be processed.

buf_height	dw	MAX_BUF_HEIGHT



;	vc_buf_1 and vc_buf_2 are intermediate locations used
;	by copy_buffer_to_screen.  They contains the actual
;	number of bytes and scans which must be copied to the
;	screen (remember, we clip the cursor).

vc_buf_1	dw	0		;Bytes per line
vc_buf_2	dw	0		;Buffer height



;	real_width contains the width in bits of the currently
;	selected cursor/icon.  This is a holdover from the days
;	when cursors and icon were different widths.  It is used
;	by exclude_test for hit testing.

real_width	dw	CUR_ICON_WIDTH*8



;	The following are the masks which make up the cursor image.

cur_and_mask	db	MASK_LENGTH dup (?)
cur_xor_mask	db	MASK_LENGTH dup (?)

sEnd	Data

sBegin	Code
	assumes cs,Code

	page
;--------------------------Public-Routine-------------------------------;
; move_cursors
;
;   Move AND and XOR cursor masks
;
;   The AND and XOR cursor masks are stored in the cursor work areas.
;
; Entry:
;	DS:SI --> AND mask
;	ES     =  Data segment
; Returns:
;	None
; Error Returns:
;	None
; Registers Preserved:
;	DS,ES,BP
; Registers Destroyed:
;	AX,CX,DI,SI
; Calls:
;	none
; History:
;	Mon 23-Feb-1987 12:47:30 -by-  **** ***** [*****]
;	Created.
;-----------------------------------------------------------------------;


;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;


	assumes ds,nothing		;DS is pointing to user data
	assumes es,Data 		;ES was set up by SetCursor


move_cursors	proc	near

	ret

move_cursors	endp
	page
;--------------------------Public-Routine-------------------------------;
; draw_cursor
;
;   Draw a cursor based at x_cell, y_cell
;
;   The currently defined cursor/icon is drawn.  If the old
;   cursor/icon is currently on the screen, it is removed.
;
; Entry:
;	DS = Data
; Returns:
;	None
; Error Returns:
;	None
; Registers Preserved:
;	BP,DS
; Registers Destroyed:
;	AX,BX,CX,DX,SI,DI,ES,FLAGS
; Calls:
;	erase_old_cursor
;	copy_buffer_to_save
;	rotate_masks
;	put_cursor_in_buffer
;	copy_buffer_to_screen
; History:
;	Tue 18-Aug-1987 14:36:59 -by-  **** ***** [*****]
;	Added test of the disabled flag.
;
;	Mon 23-Feb-1987 12:47:30 -by-  **** ***** [*****]
;	Created.
;-----------------------------------------------------------------------;


;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;


	assumes ds,Data
	assumes es,nothing

draw_cursor	proc	near

	ret

draw_cursor	endp
	page

;--------------------------Public-Routine-------------------------------;
; cursor_off
;
;   Remove Cursor From Screen
;
;   The old cursor is removed from the screen if it currently
;   is on the screen.
;
; Entry:
;	DS = Data
; Returns:
;	None
; Error Returns:
;	None
; Registers Preserved:
;	BP,DS
; Registers Destroyed:
;	AX,BX,CX,DX,SI,DI,ES,FLAGS
; Calls:
;	copy_save_to_screen
; History:
;	Tue 18-Aug-1987 14:36:59 -by-  **** ***** [*****]
;	Added test of the disabled flag.
;
;	Mon 23-Feb-1987 12:47:30 -by-  **** ***** [*****]
;	Created.
;-----------------------------------------------------------------------;


;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;


	assumes ds,Data
	assumes es,nothing


cursor_off	proc	near

	ret

cursor_off	endp
	page
;--------------------------Private-Routine------------------------------;
; copy_save_to_screen
;
;   The contents of the save area (which contains the bits saved
;   from underneath the cursor or icon) are placed on the screen
;   where they came from.
;
; Entry:
;	DS = Data Segment
; Returns:
;	None
; Error Returns:
;	No error return.
; Registers Preserved:
;	DS
; Registers Destroyed:
;	AX,BX,CX,DX,SI,DI,BP,ES,FLAGS
; Calls:
;	compute_screen_pointer
;	buf_to_screen_10  (jumps to it)
; History:
;	Mon 23-Feb-1987 12:47:30 -by-  **** ***** [*****]
;	Created.
;-----------------------------------------------------------------------;


;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;

	assumes ds,Data
	assumes es,nothing

copy_save_to_screen proc near

	ret

copy_save_to_screen endp
	page
;--------------------------Private-Routine------------------------------;
; put_cursor_in_buffer
;
;   The current cursor/icon is ANDed and XORed into the
;   current local buffer.
;
; Entry:
;	DS = Data Segment
; Returns:
;	None
; Error Returns:
;	No error return.
; Registers Preserved:
;	DS
; Registers Destroyed:
;	AX,BX,CX,DX,SI,DI,BP,ES,FLAGS
; Calls:
;	map_xy
; History:
;	Mon 23-Feb-1987 12:47:30 -by-  **** ***** [*****]
;	Created.
;-----------------------------------------------------------------------;


;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;


	assumes ds,Data
	assumes es,nothing


put_cursor_in_buffer proc near

	ret

put_cursor_in_buffer endp
	page
;--------------------------Private-Routine------------------------------;
; rotate_masks
;
;   The cursor/icon masks are rotated to be aligned for the
;   new (x,y).	The rotate is performed as a single-bit shift
;   of the entire mask.
;
; Entry:
;	DS = Data
;	direction flag cleared
; Returns:
;	direction flag cleared
; Error Returns:
;	No error return.
; Registers Preserved:
;	DS
; Registers Destroyed:
;	AX,BX,CX,DX,SI,DI,BP,ES,FLAGS
; Calls:
;	None
; History:
;	Mon 23-Feb-1987 12:47:30 -by-  **** ***** [*****]
;	Created.
;-----------------------------------------------------------------------;


;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;


	assumes ds,Data
	assumes es,nothing


rotate_masks	proc near

	ret

rotate_masks	endp
	page
;--------------------------Private-Routine------------------------------;
; copy_buffer_to_save
;
;   The contents of the local buffer where the cursor or
;   icon will go is saved in the save area.
;
; Entry:
;	DS = Data
; Returns:
;	None
; Error Returns:
;	No error return.
; Registers Preserved:
;	DS
; Registers Destroyed:
;	AX,BX,CX,DX,SI,DI,BP,ES,FLAGS
; Calls:
;	map_xy
; History:
;	Mon 23-Feb-1987 12:47:30 -by-  **** ***** [*****]
;	Created.
;-----------------------------------------------------------------------;


;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;


	assumes ds,Data
	assumes es,nothing


copy_buffer_to_save proc near

	ret

copy_buffer_to_save endp
	page
;--------------------------Private-Routine------------------------------;
; copy_save_to_buf
;
;   The contents of the save area is copied into the local buffer,
;   removing the cursor.
;
; Entry:
;	DS = Data
; Returns:
;	None
; Error Returns:
;	No error return.
; Registers Preserved:
;	DS
; Registers Destroyed:
;	AX,BX,CX,DX,SI,DI,BP,ES,FLAGS
; Calls:
;	map_xy
; History:
;	Mon 23-Feb-1987 12:47:30 -by-  **** ***** [*****]
;	Created.
;-----------------------------------------------------------------------;


;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;


	assumes ds,Data
	assumes es,nothing

copy_save_to_buf proc near

	ret

copy_save_to_buf endp
	page
;--------------------------Private-Routine------------------------------;
; map_xy
;
;   Map X,Y into the local buffer
;
;   The given screen (x,y) coordinate is mapped to a pointer
;   into the local buffer.
;
; Entry:
;	AX = screen x coordinate
;	SI = screen y coordinate
;	DS = Data
; Returns:
;	CX = default cursor height
;	SI = pointer into the local buffer
; Error Returns:
;	No error return.
; Registers Preserved:
;	BX,DX,DI,BP,ES,DS
; Registers Destroyed:
;	AX,FLAGS
; Calls:
;	None
; History:
;	Mon 23-Feb-1987 12:47:30 -by-  **** ***** [*****]
;	Created.
;-----------------------------------------------------------------------;


;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;


	assumes ds,Data
	assumes es,nothing


map_xy	proc	near

	ret

map_xy	endp
	page
;--------------------------Private-Routine------------------------------;
; copy_buffer_to_screen
;
;   The contents of the local buffer is copied to the screen.
;   The contents are clipped to the screen as needed.
;   If the image is entirly off the screen, then no copy is
;   performed and the contents of the save area are invalidated.
;
; Entry:
;	DS = Data
; Returns:
;	None
; Error Returns:
;	No error return.
; Registers Preserved:
;	DS
; Registers Destroyed:
;	AX,BX,CX,DX,SI,DI,BP,ES,FLAGS
; Calls:
;	None
; History:
;	Mon 23-Feb-1987 12:47:30 -by-  **** ***** [*****]
;	Created.
;-----------------------------------------------------------------------;


;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;


	assumes ds,Data
	assumes es,nothing


copy_buffer_to_screen proc near

	ret

copy_buffer_to_screen endp
	page
;--------------------------Private-Routine------------------------------;
; erase_old_cursor
;
;   The old cursor is erased from the screen, and the local buffer
;   updated as needed.	This may be performed in a couple of different
;   ways:
;
;	If a cursor/icon isn't drawn on the screen, the local buffer
;	is filled from the screen in preperation of the forthcoming
;	draw.
;
;	If a cursor/icon is drawn on the screen and the new and old
;	cursors/icons will not fit within the buffer, the cursor/icon
;	is removed from the screen, and then the local buffer is
;	filled from the screen in preperation of the forthcoming draw.
;
;	If a cursor/icon is drawn on the screen and the new and old
;	cursors/icons will fit within the buffer, the local buffer is
;	filled from the screen (based at the new (x,y)) in preperation
;	of the forthcoming draw.
;
; Entry:
;	DS = Data
; Returns:
;	None
; Error Returns:
;	No error return.
; Registers Preserved:
;	DS
; Registers Destroyed:
;	AX,BX,CX,DX,SI,DI,BP,ES,FLAGS
; Calls:
;	compute_buffer_xy
;	copy_save_to_screen
;	copy_screen_to_buffer
;	copy_save_to_buf
; History:
;	Mon 23-Feb-1987 12:47:30 -by-  **** ***** [*****]
;	Created.
;-----------------------------------------------------------------------;


;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;


	assumes ds,Data
	assumes es,nothing


erase_old_cursor proc near

	ret


erase_old_cursor endp
	page
;--------------------------Private-Routine------------------------------;
; copy_screen_to_buffer
;
;   The contents of the given region of Regen RAM where the cursor/icon
;   is/will go are copied into the local buffer.
;
;   Since the height of the data to be copied is rounded UP to the
;   next multiple of two, the space allocated for the buffer must
;   take this into account and always be allocated according to:
;
;	    (MAX_BUF_HEIGHT + 1) and 1
;
; Entry:
;	screen_pointer	= offset of source in EGAMem
;	buf_height	= # of scanlines to transfer
;	DS		= Data
; Returns:
;	None
; Error Returns:
;	No error return.
; Registers Preserved:
;	BP,DS
; Registers Destroyed:
;	AX,BX,CX,DX,SI,DI,ES,FLAGS
; Calls:
;	None
; History:
;	Mon 23-Feb-1987 12:47:30 -by-  **** ***** [*****]
;	Created.
;-----------------------------------------------------------------------;


;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;


	assumes ds,Data
	assumes es,nothing


copy_screen_to_buffer proc near

	ret

copy_screen_to_buffer endp
	page
;--------------------------Private-Routine------------------------------;
; compute_buffer_xy
;
;   The (x,y) coordinate of the bounding box that can contain both
;   the old and new cursors within the local buffer is computed.
;   The (x,y) computed will be the upper left hand corner of this box.
;
;   If no box exists, then the (x,y) of the new cursor location will
;   be used and the caller given a flag indicating that both cursors
;   did not fit.
;
;   The screen address of this (x,y) is also computed.
;
; Entry:
;	DS = Data
; Returns:
;	BP = 0 if both cursors fit within the buffer
;	BP <> 0 if both cursors did not fit (or no old cursor)
; Error Returns:
;	No error return.
; Registers Preserved:
;	DS
; Registers Destroyed:
;	AX,BX,CX,DX,SI,DI,BP,ES,FLAGS
; Calls:
;	compute_screen_pointer
; History:
;	Mon 23-Feb-1987 12:47:30 -by-  **** ***** [*****]
;	Created.
;-----------------------------------------------------------------------;


;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;


	assumes ds,Data
	assumes es,nothing

compute_buffer_xy proc near

	ret

compute_buffer_xy endp
	page
;--------------------------Private-Routine------------------------------;
; compute_screen_pointer
;
;   The screen address of point (ax,si) is computed.
;
; Entry:
;	AX = screen x coordinate
;	SI = screen y coordinate
; Returns:
;	SI = screen pointer
; Error Returns:
;	No error return.
; Registers Preserved:
;	BX,CX,DX,DI,DS,ES
; Registers Destroyed:
;	AX,FLAGS
; Calls:
;	None
; History:
;	Mon 23-Feb-1987 12:47:30 -by-  **** ***** [*****]
;	Created.
;-----------------------------------------------------------------------;


;------------------------------Pseudo-Code------------------------------;
; {
; }
;-----------------------------------------------------------------------;


	assumes ds,nothing
	assumes es,nothing

compute_screen_pointer proc near

	ret

compute_screen_pointer endp

sEnd	Code

ifdef	PUBDEFS
	include CURSOR.PUB
endif
	end
