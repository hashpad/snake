org 0x7c00
%define VIDEO_MEM 0xA000
%define WIDTH 320
%define HEIGHT 200


mov ax, 0x13
int 0x10


;; set up the interrupt routine at 0x1C
xor ax, ax
mov es, ax
mov WORD [es:0x1C * 4], main_loop
mov WORD [es:0x1C * 4 + 2], 0x00

jmp $

main_loop:

  call setup_vid_mem

  ;; clear the sceen before drawing
  call clear

  ;; move the head block, the rest of the body should follow
  ;; Note: only head coordinates are saved and number of block, the other blocks are just drawn
  call move_head

  xor cx, cx
  .draw_blocks:
    push cx
    ; next_tail_block_xy = block_xy - counter(cx) * block_dimension 

    ;; push y
    imul cx, word [block_height]
    mov bx, [block_y]
    sub bx, cx
    push bx
    ;; push x
    push word [block_x]
    ;; push color
    test cx, cx
    jz .head_color
    .tail_color:
      push 0xCFCF
      jmp .draw

    .head_color:
      push 0xAFAF

    .draw:
    call draw_block

    pop cx
    inc cx
    cmp cx, [num_of_blocks]
    jb .draw_blocks


  iret


setup_vid_mem:
  mov ax, VIDEO_MEM
  mov es, ax
  ret

draw_block:
  ; 4 -> color
  ; 6 -> x
  ; 8 -> y
  push bp
  mov bp, sp

  mov ax, word [bp + 8] ;; ax -> y
  mov bx, word [bp + 6] ;; bx -> x


  test bx, bx
  ;; make tail positive (by adding width)
  jle .add_width

  test ax, ax
  ;; make tail positive (by adding height)
  jle .add_height

  jmp .fill

  .add_width:
    mov cx, WIDTH
    sub cx, [block_width]
    add bx, cx
    jmp .fill

  .add_height:
    mov cx, HEIGHT
    sub cx, [block_height]
    add ax, cx

  .fill :
    mov dx, [block_width] ; -> x
    add dx, bx

    ;; cx -> dy
    mov cx, [block_height] ; -> y
    add cx, ax

    ;; si -> c
    mov si, [bp + 4]
    ;; cx -> dy
    ;; dx -> dx
    ;; ax -> y
    ;; bx -> x
    ;; si -> c
    call fill

  pop bp
  ret 6
move_head:

  ;; wrap x
  push word block_x
  push word WIDTH
  push word [block_width]
  push word [block_dx]
  push word [block_x]
  call wrap_xy

  ;; wrap y
  push word block_y
  push word HEIGHT
  push word [block_height]
  push word [block_dy]
  push word [block_y]
  call wrap_xy

  ret
wrap_xy:
  ; 4  -> block_xy
  ; 6  -> block_dxy
  ; 8  -> block_dimension 
  ; 10 -> DIMENSION
  ; 12 -> addr block_xy


  push bp
  mov bp, sp

  mov ax, word [bp + 4]
  test ax, ax
  jle .reset_xy_to_right_bottom

  push ax
  add ax, word [bp + 8]
  cmp ax, word [bp + 10]
  pop ax
  jge .reset_xy_to_left_top

  jmp .add_dxy
  
  .reset_xy_to_left_top:
    xor ax, ax
    jmp .add_dxy

  .reset_xy_to_right_bottom:
    mov ax, [bp + 10]
    sub ax, [bp + 8]

  .add_dxy:
    add ax, [bp + 6]

  mov bx, [bp + 12]
  mov [bx], ax

  pop bp
  ret 10

clear:
  xor ax, ax
  .clear:
    mov di, ax
    mov WORD [es:di], 0x1212
    inc ax
    cmp ax, 64000
    jb .clear
  ret
calculate_pix:
  ; 4 -> y
  ; 6 -> x
  ; 
  ; ax = bx*WIDTH+ax
  push bp
  mov bp, sp

  imul bx, word [bp + 4], WIDTH
  add bx, word [bp + 6]
  mov ax, bx


  pop bp
  ret 4

fill:
  ; bx -> x
  ; ax -> y
  ; dx -> [d_X] + x
  ; cx -> [d_Y] + y

  pusha
  call fill_pix
  popa

  cmp bx, dx
  jb .inc_x

  cmp ax, cx 
  jb .inc_y

  ret

  .inc_x: 
    inc bx
    jmp fill

  .inc_y: 
    push dx
    sub dx, [block_width]
    mov bx, dx
    pop dx
    inc ax
    jmp fill

fill_pix:
  ; x -> 4
  ; y -> 6
  ; c -> 8

  push bx
  push ax
  call calculate_pix


  mov di, ax
  mov WORD [es:di], si
  ret

block_x: dw 20
block_y: dw 20

block_dx: dw 0
block_dy: dw 3

num_of_blocks: dw 3

block_height: dw 4
block_width: dw 4


times 510 - ($ - $$) db 0

dw 0xaa55
