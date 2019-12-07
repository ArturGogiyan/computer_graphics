section .text

deltax:          dw	0
deltay:          dw	0
error:           dw	0
dirx: 	         dw	0
circle_radius_sq:dw 0
circle_radius:   dw 0
;circle_top_x:    dw 0
;circle_top_y:    dw 0
;circle_left_x:   dw 0
;circle_left_y:   dw 0
;circle_right_x:  dw 0
;circle_right_y:  dw 0
;circle_bottom_x: dw 0
;circle_bottom_y: dw 0


%define x0 100
%define y0 300
%define x1 110
%define y1 200


%define x00 200
%define y00 300
%define x10 210
%define y10 200  

%define xLeft 300
%define yLeft 200
%define xRight 500
%define yRight 200  
%define xTop 400  
%define yTop 100  
%define xBottom 400  
%define yBottom 300  


.start:
	mov ax,010h				; EGA mode
	int 10h 				; 640 x 350 16 colors.

	mov dx, 3C4h
	mov al, 2
	out dx, al
	inc dx
	mov al, 1001b			; 1 - intensity, 0 - red, 0 - green, 1 - blue
	out dx, al

	;2) 57h = 87, 9 = 00001001b
	mov al, 00001001b
	mov di, 57h
	mov si, 0A000h
	mov es, si
	mov [es:di], al 		; две точки рисуются, но их фиг разглядишь

	;3) x = 303, y = 150, c кодом цвета 1010B
	mov dx, 3C5h
	mov al, 1010b
	out dx, al 				; color

	mov bx, 303
	mov ax, 150
	call .draw_point

	;4),5),6)
	xor ax, ax
	call .draw_letter_g

	mov ax, y1 + 1
	mov bx, x1 + 1
	call .fill
	
	call .draw_letter_g
	
    ;7)
    mov ax, 400 ; - borderX
	mov bx, 100 ; - borderY
	mov cx, 400 ; - centerX
	mov dx, 200 ; - centerY

	call .draw_circle
	
	
.kek:
	xor ax,ax				;ожидание нажатия клавиши
	int 16h

	mov ax,4c00h			;выход из графики с возвратом
	int 21h					;в предыдущий режим

	; ax - y
	; bx - x
	; return value in di
.xy_to_num:
	shr bx, 3;		; байтовое смещение от начала линии

	; y*80 = y*64+y*16
	mov dx, ax
	sal ax, 2 	; y*4
	add ax, dx 	; y*4+y
	sal ax, 4	; (y*4+y)*16 = y*80

	add ax, bx ; s = y*80 + x/8 ; смещение в байтах от начала, просто начала
	mov di, ax
	ret

	; bx - x координата
.bit_mask:
	xor cx, cx
	mov cx, bx
	and cl, 07h			; смещение в битах от начала байта

	xor bx, bx
	mov bl, 10000000b 	; маска изначально 
	shr bl, cl			; сдвигаем на нужную позицию
	; установка маски
	xor ax, ax
	mov al, bl

	ret

	; ax - y
	; bx - x
.draw_point:
	push cx

	push ax
	push bx
	call .xy_to_num
	pop bx
	pop ax
	push di        
	call .bit_mask
	pop si
	push si
	push ax

	; head
	; ax
	; di

	call .readbyte
	pop bx
	or ax, bx
	pop di

	; рисуем...
	mov si, 0A000h
	mov es, si
	mov [es:di], al
	pop cx
	ret

	; ax - y
	; bx - x
	; cx - len
.hor_line:
	push ax
	push bx
	call .draw_point
	pop bx
	pop ax

	inc bx
	loop .hor_line
	ret

.ver_line:
	push ax
	push bx
	call .draw_point
	pop bx
	pop ax

	inc ax
	loop .ver_line
	ret

	; ax - y
	; bx - x
	; cx - lucky number
.fill:
	; just fill current point
	push bx
	push ax
	call .draw_point
	pop ax
	pop bx  

	; process x,y+1
	inc ax
	call .process_point
	dec ax

	; check x, y - 1
	dec ax
	call .process_point
	inc ax

	; check x + 1, y
	inc bx
	call .process_point
	dec bx

	; check x - 1, y
	dec bx
	call .process_point
	inc bx

.out_fill:
	ret


	; ax - y
	; bx - x
	; doesn't save bx, ax
.process_point:
	push bx
	push ax

	call .xy_to_num ; result in di
	pop ax
	pop bx
	push bx
	push ax
	push di ; save

	call .bit_mask          ; return bit_mask in ax
	pop si                  ; mov di to si
	push ax                 ; save bit_mask
	call .readbyte          ; byte in ax

	pop bx                  ; mov bit_mask to bx
	and ax, bx              ; and byte from mem and mask
	test ax, ax
	jnz .out

	; call fill	; x+1, y
	pop ax
	pop bx
	push bx
	push ax
	call .fill			; рекурсия для точки
.out:
	pop ax
	pop bx
	ret


	;--------------------------------------------
	;Read one byte in the video memory
	;call : SI byte address
	;answer : al,ah,bl,bh -> bl,gr,rood,inten
	;--------------------------------------------
.readbyte:
	push cx
	push dx
	push si
	push es
	mov ax,0A000h
	mov es,ax
	mov dx,03ceh 
	mov ax,0005h
	out dx,ax
	mov ax,0304h ;AH = bitplane, AL = read modus
	out dx,ax ;go to read mode 
	mov bh,[es:si] ;read the blue byte
	dec ah
	out dx,ax ;AH = green
	mov bl,[es:si] ;read the green byte
	dec ah
	out dx,ax ;AH = red
	mov ch,[es:si] ;read the red byte
	dec ah 
	out dx,ax ;AH = intensity
	mov cl,[es:si] ;read the intensity byte
	mov ax,cx

	;al,ah,bl,bh -> bl,gr,rood,inten => or all to al
	or ax, bx
	xor bx, bx
	mov bl, ah
	or ax, bx

	pop es
	pop si
	pop dx
	pop cx
	ret


.sign:
	push bx
	sar ax, 15
	mov bx, ax
	neg bx
	dec bx
	sub ax, bx
	pop bx
	ret

.abs:
	push bx

	mov bx, ax
	sar bx, 15
	xor ax, bx
	sub ax, bx

	pop bx
	ret

	; ax - x0
	; bx - y0
	; cx - x1
	; dx - y1
.draw_line:
	push ax
	push bx
	push cx
	push dx

	; deltax = abs(x1 - x0);
	sub cx, ax
	mov ax, cx
	call .abs
	mov [deltax], ax

	mov ax, cx
	call .sign
	mov [dirx], ax

	; deltay = abs(y1 - y0);
	sub dx, bx
	mov ax, dx
	call .abs
	mov [deltay], ax

	;mov ax, dx
	;call .sign
	;mov [dirx], ax

	xor ax, ax
	mov [error], ax;
	pop dx
	pop cx
	pop bx
	pop ax


.while:
	cmp bx, dx
	jle .exit
	push ax
	push bx

	xor ax, bx ; comment from this!
	xor bx, ax ; костыль который меняет местами ax, bx потому что в .draw_point x, y поменяны местами
	xor ax, bx ; to this

	push cx
	push dx

	call .draw_point
	pop dx
	pop cx
	pop bx
	pop ax
	push dx
	push cx

	; error = error + deltax
	mov dx, [error]
	add dx, [deltax]
	mov [error], dx

	sal dx, 2
	cmp dx, [deltay]
	jl .end_while
	add ax, [dirx]
	mov dx, [error]
	sub dx, [deltay]
	mov [error], dx

.end_while:
	pop cx
	pop dx
	dec bx
	jmp .while

.exit:
	ret

.draw_letter_g:
	test ax, ax
	jnz .right

	mov bx, x1 + 60
	mov ax, y1
	mov cx, 20
	call .ver_line

	mov bx, x0
	mov ax, y0
	mov cx, 10
	call .hor_line

	mov bx, x1
	mov ax, y1
	mov cx, 60
	call .hor_line

	mov bx, x1 + 20
	mov ax, y1 + 20
	mov cx, 40
	call .hor_line

	mov ax, x0
	mov bx, y0
	mov cx, x1
	mov dx, y1
	call .draw_line

	mov ax, x0 + 10
	mov bx, y0
	mov cx, x1 + 20
	mov dx, y1 + 20
	call .draw_line

	jmp .out_g
.right:
	mov bx, x10 + 60
	mov ax, y10
	mov cx, 20
	call .ver_line

	mov bx, x00
	mov ax, y00
	mov cx, 10
	call .hor_line

	mov bx, x10
	mov ax, y10
	mov cx, 60
	call .hor_line

	mov bx, x10 + 20
	mov ax, y10 + 20
	mov cx, 40
	call .hor_line

	mov ax, x00
	mov bx, y00
	mov cx, x10
	mov dx, y10
	call .draw_line

	mov ax, x00 + 10
	mov bx, y00	; ax - x0
	; bx - y0
	; cx - xCenter
	; dx - yCenter
	mov cx, x10 + 20
	mov dx, y10 + 20
	call .draw_line
.out_g:
	ret
	
	
	
    ; ax - x0
	; bx - y0
	; cx - xCenter
	; dx - yCenter
.draw_circle:
    

    push ax
	push bx
	push cx
	push dx
	
	sub dx, bx
	mov [circle_radius], dx
	mov ax, dx
	mul ax
	mov [circle_radius_sq], ax
	
    pop dx
	pop cx
	pop bx
	pop ax
	
    
	;mov [circle_top_x], ax
	;mov [circle_top_y], bx
    ;mov [circle_left_y], dx
    ;mov [circle_right_y], dx
    ;mov [circle_bottom_x], ax
    

    
    ;push ax
	;push bx
	;push cx
	;push dx

	;mov ax, [circle_radius]
	;add cx, ax
	;mov [circle_right_x], cx
	;sub cx, ax
	;sub cx, ax
	;mov [circle_left_x], cx
	;add dx, ax
	;mov [circle_bottom_y], dx
	
    ;pop dx
	;pop cx
	;pop bx
	;pop ax
	
    call .circle_top
    call .circle_bottom
    call .circle_left
    call .circle_right
    
    ret

.circle_right:
    push ax
	push bx
	push cx
	push dx
	
    mov ax, yRight
    mov bx, xRight
    call .draw_point
    
    pop dx
	pop cx
	pop bx
	pop ax
    
    ret

.circle_left:
    push ax
	push bx
	push cx
	push dx
	
    mov ax, yLeft
    mov bx, xLeft
    call .draw_point
    
    pop dx
	pop cx
	pop bx
	pop ax

    ret
    

.circle_top:
    push ax
	push bx
	push cx
	push dx
	
    mov ax, yTop
    mov bx, xTop
    
.top_cycle:
    push ax
    push bx
    call .draw_point
    pop bx
    pop ax
    call .map_down_right
    call .map_up_left
    call .map_down_left
    call .find_next_cell_top
    mov cx, yRight
    mov dx, xRight

    cmp ax, cx
    jne .top_cycle
    cmp bx, dx
    jne .top_cycle
    
    pop dx
	pop cx
	pop bx
	pop ax
    
    ret
    
    
    ;ax - y 
    ;bx - x
.find_next_cell_top:
	push cx
	push dx
	
	inc ax
	call .calculate_distance
	mov dx, cx
	inc bx
	call .calculate_distance
	sub cx, [circle_radius_sq]
	sub dx, [circle_radius_sq]
	
	push ax
	push bx
	
	mov ax, cx
	call .abs
	mov cx, ax
	mov ax, dx
	call .abs
	mov dx, ax
	
    pop bx
	pop ax
	
	cmp cx, dx
	jg .swap_args_top
    mov [deltax], bx
    mov [deltay], ax
    jmp .find_nex_cell_top_continue
    
.swap_args_top: 
    dec bx
    mov [deltax], bx
    mov [deltay], ax
    mov cx, dx
    inc bx
    jmp .find_nex_cell_top_continue
    
.find_nex_cell_top_continue:
	dec ax
	mov dx, cx
    call .calculate_distance
    sub cx, [circle_radius_sq]
    
    push ax
    
    mov ax, cx
    call .abs
    mov cx, ax
    
    pop ax
    
    cmp cx, dx
    jg .swap_args_top_2
    jmp .end_find_next_cell
    
.swap_args_top_2:
    mov ax, [deltay]
    mov bx, [deltax]
    jmp .end_find_next_cell
    
 .end_find_next_cell:   
    pop dx
	pop cx
    ret

.map_down_right:
    push ax
	push bx
	push cx
	push dx
	
    mov cx, yRight
    add cx, cx
    sub cx, ax
    mov ax, cx
    call .draw_point
    
    pop dx
	pop cx
	pop bx
	pop ax
    ret
    
.map_up_left:
    push ax
	push bx
	push cx
	push dx
	
    mov cx, xTop
    add cx, cx
    sub cx, bx
    mov bx, cx
    call .draw_point
    
    pop dx
	pop cx
	pop bx
	pop ax
    ret
    
.map_down_left:
    push ax
	push bx
	push cx
	push dx
	
    mov cx, yRight
    add cx, cx
    sub cx, ax
    mov ax, cx
    
    mov cx, xTop
    add cx, cx
    sub cx, bx
    mov bx, cx
    call .draw_point
    
    pop dx
	pop cx
	pop bx
	pop ax
    ret
    
    
.circle_bottom:
    push ax
	push bx
	push cx
	push dx
	
    mov ax, yBottom
    mov bx, xBottom
    call .draw_point
    
    pop dx
	pop cx
	pop bx
	pop ax
	
    ret

    
    ;ax - y
    ;bx - x
    ;cx - distance 
.calculate_distance:
    push ax
	push bx
	push dx
    
    mov cx, yLeft ; center coordinates
    sub ax, cx
    call .abs
    mul ax
    mov cx, ax
    mov dx, xBottom
    mov ax, bx
    sub ax, dx
    call .abs
    mul ax
    add cx, ax
    
    pop dx
	pop bx
	pop ax
    ret
    
