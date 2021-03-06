.model small
.stack 100h
JUMPS
.data
    info            db 'Arminas Petraitis, 2 kursas, INF4 grupe', 0Dh, 0Ah, 'Programa disasembliuoja failus, pateiktus parametrus komandineje eiluteje paleidziant programa', 0Dh, 0Ah, 'Naudojimas: disasm input.com output', 0Dh, 0Ah, '$'
    readFile        db 12 dup (0)
    writeFile       db 12 dup (0)
    inBuffer        db 20 dup (?),0
    outBuffer       db 100 dup (?)
    readHandle      dw ?
    writeHandle     dw ?
    temp            dw ?
    position        dw 100h
    tempPos         dw ?
    tempBuff        db 10 dup (?)
    tempBuff1       db 30 dup (?)
    tempBuff2       db 30 dup (?)
    storage         db 7 dup (?) ;1baitas 2baitas 2baito2bitas 2baito1bitas mod reg r/m
    isX8_1          db 0
    isXF            db 0
    offsetSize      dw 0
    prefix          db 0,0
    prefixByte      db 0
    prefixPosition  dw 0
include opcodes.asm

.code

OutFill MACRO mcode, acode
    mov ax, @data
    mov es, ax
    push si
    Pos position, outBuffer
    ToAscii mcode, outBuffer+7
    Move 68h, outBuffer+4
    Move 3Ah, outBuffer+5
    Move 20h, outBuffer+6 
    MoveStrToBuf acode, outBuffer+24
    Move 0Dh, outBuffer+98
    Move 0Ah, outBuffer+99
    inc position
    pop si
    jmp save
ENDM

CASCA MACRO acode, acode2, jmppos 
    push si
    MoveStrToBuf acode, outBuffer+24
    mov bx, si 
    inc bx
    MoveStrToBuf acode2, outBuffer+bx+24
    add bx, si 
    mov outBuffer+bx+24, ','
    inc bx
    mov si, bx
    jmp jmppos
ENDM

Move MACRO a,b
    push ax
    mov ah, a
    mov b, ah
    pop ax
ENDM

MoveStrToBuf MACRO a,b 
LOCAL @@start,@@exit
    push ax
    xor si, si
    @@start:
        mov ah, a[si]
        cmp ah, 00h
        je @@exit
        mov b[si], ah
        inc si
        jmp @@start
    @@exit:
        pop ax
ENDM

Pos MACRO a,b
    push ax
    push bx
    mov ax, a
    ToAscii ah,b
    ToAscii al,b+2
    pop bx
    pop ax
ENDM

ToAscii MACRO a,b
    push ax
    push bx
    mov al, a
    xor ah, ah
    mov bl, 10h
    div bl
    mov b, al
    mov b+1, ah
    ToAscii2 [b]
    ToAscii2 [b+1]
    pop bx
    pop ax
ENDM

ToAscii2 MACRO var
LOCAL @@letter, @@exit
    cmp var, 09h
    ja @@letter
    add var, 30h
    jmp @@exit
    @@letter:
        add var, 37h
    @@exit:
ENDM

Get_file MACRO file
LOCAL @@start,@@end,@@exit,@@loop,@@exit2
    lea di, [file]
    push ax
    call space_check
    @@start:
        cmp byte ptr ds:[si], 0Dh
        je @@end
        cmp byte ptr ds:[si], ' '
        jne @@loop
    @@end:
        pop ax
        jmp @@exit
    @@loop:
        lodsb
        stosb
        jmp @@start
    @@exit:
        cmp byte ptr es:[file], '$'
        jne @@exit2
        jmp print_info
    @@exit2:
ENDM

Clr MACRO buffer, bSize
LOCAL @@start, @@exit
    push Si
    xor Si, Si
    @@start:
        cmp si, bSize
        je @@exit
        mov buffer[si],20h
        inc si
        jmp @@start
    @@exit:
        pop Si
ENDM

start:
    mov ax, @data
    mov es, ax

    mov si, 81h
    call space_check
    
    mov al, byte ptr ds:[si]
    cmp al, 0Dh
    je print_info
        
    mov ax, word ptr ds:[si]
    cmp ax, 3F2Fh
    je print_info

    Get_file readFile
    Get_file writeFile

    mov ax, @data
    mov ds, ax
    mov	dx, offset readFile
	mov	ah, 3Dh
	mov	al, 00h
	int	21h
    jc print_info
	mov	readHandle, ax   
    mov ax, @data
    mov ds, ax
    mov	dx, offset writeFile
	mov	ah, 3Ch
	xor	cx, cx
	int	21h
    jc print_info
    mov ah, 3Dh
    mov al, 01h
    int 21h
    jc print_info
	mov	writeHandle, ax
    
    startCycle:
        mov	bx, readHandle
        mov ax, 4200h
        mov dx, position
        sub dx, 100h
        xor cx, cx
        int 21h
        mov	dx, offset inBuffer       ; address of buffer in dx
        mov	cx, 20         		; kiek baitu nuskaitysim
        mov	ah, 3fh         	; function 3Fh - read from file
        int	21h
        mov temp, ax
        mov si, 0
        cmp temp, 00h
        je finish
        Clr outBuffer, 100
        Clr tempBuff, 10
        Clr tempBuff1, 30
        Clr tempBuff2, 30
        call check_byte
        jmp startCycle
    
print_info:
    mov ax, @data
    mov ds, ax
    mov dx, offset info
    mov ah, 09h
    int 21h
    jmp finish

space_check PROC near
    space_begin:
        cmp byte ptr ds:[si], 20h
        jne space_return
        inc si
        jmp space_begin
    space_return:
        ret
space_check ENDP

check_byte PROC near
    call ComparePrefix
    call CompareOneByte
    call CompareJ
    call CompareMovAccumulator
    call CompareAddSubCmpAccumulator
    call CompareMovImmediate
    cmp byte ptr ds:[inBuffer+si], 0CDh 
    je cmp_int
    cmp byte ptr ds:[inBuffer+si], 0EBh 
    je cmp_jlj_jmp
    cmp byte ptr ds:[inBuffer+si], 0E2h 
    je cmp_jlj_loop
    cmp byte ptr ds:[inBuffer+si], 0E3h 
    je cmp_jlj_jcxz
    cmp byte ptr ds:[inBuffer+si], 0E9h 
    je cmp_jmp
    cmp byte ptr ds:[inBuffer+si], 0E8h 
    je cmp_crr_call
    cmp byte ptr ds:[inBuffer+si], 0C2h 
    je cmp_crr_ret
    cmp byte ptr ds:[inBuffer+si], 0CAh 
    je cmp_crr_retf
    cmp byte ptr ds:[inBuffer+si], 0EAh 
    je cmp_jmp_outside_direct
    cmp byte ptr ds:[inBuffer+si], 09Ah 
    je cmp_call_outside_direct
    call cmp_mod_rm
    
    OutFill ds:[inBuffer], .Unknown
    ret
check_byte ENDP

ComparePrefix PROC near
    cmp byte ptr ds:[inBuffer+si], 2Eh 
    je CP_CS
    cmp byte ptr ds:[inBuffer+si], 36h 
    je CP_SS
    cmp byte ptr ds:[inBuffer+si], 3Eh 
    je CP_DS
    cmp byte ptr ds:[inBuffer+si], 26h 
    je CP_ES
    ComparePrefixExit:
    ret
    
    CP_CS:
    mov prefix, 'C'
    mov prefix+1, 'S'
    mov prefixByte, 2Eh
    mov ax, position
    mov prefixPosition, ax
    inc position
    jmp startCycle

    CP_SS:
    mov prefix, 'S'
    mov prefix+1, 'S'
    mov prefixByte, 36h
    mov ax, position
    mov prefixPosition, ax
    inc position
    jmp startCycle

    CP_DS:
    mov prefix, 'D'
    mov prefix+1, 'S'
    mov prefixByte, 3Eh
    mov ax, position
    mov prefixPosition, ax
    inc position
    jmp startCycle

    CP_ES:
    mov prefix, 'E'
    mov prefix+1, 'S'
    mov prefixByte, 26h
    mov ax, position
    mov prefixPosition, ax
    inc position
    jmp startCycle

    
ComparePrefix ENDP

cmp_mod_rm PROC near
    push si
    
    mov al, inBuffer+0
    shr al, 4
    mov storage+0, al       ;storage+0 1baitas
    mov al, inBuffer+0
    and al, 0Fh
    mov storage+1, al       ;storage+1 2baitas
    and al, 02h
    shr al, 1
    mov storage+2, al       ;storage+2 2baito 2bitas
    mov al, storage+1
    and al, 01h
    mov storage+3, al       ;storage+3 2baito 1bitas
    mov al, inBuffer+1
    shr al, 06h
    mov storage+4, al       ;storage+4 mod
    mov al, inBuffer+1
    and al, 38h
    shr al, 03h
    mov storage+5, al       ;storage+5 reg
    mov al, inBuffer+1
    and al, 07h
    mov storage+6, al       ;storage+6 r/m
    
    cmp byte ptr ds:[storage+0], 00h ;jei ne [0 2 3 8 C F] tai skip
    je x0
    cmp byte ptr ds:[storage+0], 02h 
    je x2
    cmp byte ptr ds:[storage+0], 03h 
    je x3
    cmp byte ptr ds:[storage+0], 08h 
    je x8
    cmp byte ptr ds:[storage+0], 0Ch 
    je xC
    cmp byte ptr ds:[storage+0], 0Fh 
    je xF
    jmp xExit
    
    xC:
        mov al, storage+1
        and al, 0Eh
        cmp al, 06h
        je xC_0
        jmp xExit
        
        xC_0:
            mov al, storage+5
            cmp al, 00h
            jne xExit

            MoveStrToBuf .Mov, outBuffer+24
            mov tempPos, si
            mov isXF, 3
            mov storage+2, 0
            jmp x0_template
        
        
    
    xF:
        mov al, storage+1
        and al, 0Eh
        cmp al, 06h
        je xF_0
        mov al, storage+1
        cmp al, 0Fh
        je xF_1
        cmp al, 0Eh
        je xF_2

        jmp xExit
                
        xF_0:
            mov al, storage+5
            cmp al, 04h
            je xF_0_0

            cmp al, 06h
            je xF_0_1

            jmp xExit
        
            xF_0_0:
                MoveStrToBuf .Mul, outBuffer+24
                mov tempPos, si
                inc isXF
                jmp x0_template
            
            xF_0_1:
                MoveStrToBuf .Div, outBuffer+24
                mov tempPos, si
                inc isXF
                jmp x0_template        

        xF_1:
            mov al, storage+5
            cmp al, 06h
            je xF_1_0
            cmp al, 00h
            je xF_1_1
            cmp al, 01h
            je xF_1_2
            cmp al, 02h
            je xF_1_3
            cmp al, 03h
            je xF_1_4
            cmp al, 04h
            je xF_1_5
            cmp al, 05h
            je xF_1_6
            jmp xExit

            
            xF_1_0:
                MoveStrToBuf .Push, outBuffer+24
                mov tempPos, si
                inc isXF
                jmp x0_template

            xF_1_1:
                MoveStrToBuf .Inc, outBuffer+24
                mov tempPos, si
                inc isXF
                jmp x0_template

            xF_1_2:
                MoveStrToBuf .Dec, outBuffer+24
                mov tempPos, si
                inc isXF
                jmp x0_template

            xF_1_3:
                MoveStrToBuf .Call, outBuffer+24
                mov tempPos, si
                inc isXF
                jmp x0_template
            
            xF_1_4:
                MoveStrToBuf .Call, outBuffer+24
                mov tempPos, si
                mov isXF, 02h
                jmp x0_template

            xF_1_5:
                MoveStrToBuf .Jmp, outBuffer+24
                mov tempPos, si
                inc isXF
                jmp x0_template

            xF_1_6:
                MoveStrToBuf .Jmp, outBuffer+24
                mov tempPos, si
                mov isXF, 02h
                jmp x0_template
        
        xF_2:
            mov al, storage+5
            cmp al, 00h
            je xF_1_1
            cmp al, 01h
            je xF_1_2
            jmp xExit
    
    x2:
        mov al, storage+1
        and al, 0Ch
        cmp al, 08h
        jne xExit
        MoveStrToBuf .Sub, outBuffer+24
        mov tempPos, si
        jmp x0_template
    
    x3:
        mov al, storage+1
        and al, 0Ch
        cmp al, 08h
        je x3_0

        mov al, storage+1
        and al, 0Ch
        cmp al, 00h
        je x3_1
        jmp xExit
        
        x3_0:
            MoveStrToBuf .Cmp, outBuffer+24
            mov tempPos, si
            jmp x0_template

        x3_1:
            MoveStrToBuf .Xor, outBuffer+24
            mov tempPos, si
            jmp x0_template
        
    x8:
        mov al, storage+1
        and al, 0Ch
        cmp al, 08h
        je x8_0
        
        mov al, storage+1
        and al, 0Dh
        cmp al, 0Ch
        je x8_1
        
        mov al, storage+1
        cmp al, 0Fh
        je x8_2
        
        and al, 0Ch
        cmp al, 00h
        je x8_3
        
        jmp xExit

        x8_0:
            MoveStrToBuf .Mov, outBuffer+24
            mov tempPos, si
            jmp x0_template
        
        x8_1:
            mov storage+3, 01h
            MoveStrToBuf .Mov, outBuffer+24
            mov tempPos, si
            inc isX8_1
            jmp x0_template
            
            x8_1_sr:
                push bx
                mov ah, 0
                mov bx, 0
                x8_1_sr_0:
                    cmp byte ptr ds:[storage+5], ah
                    je x8_1_sr_2
                    cmp byte ptr ds:[.sr+bx], 00h
                    je x8_1_sr_1
                    inc bx
                    jmp x8_1_sr_0
                x8_1_sr_1:
                    inc bx
                    inc ah
                    jmp x8_1_sr_0
                x8_1_sr_2:
                    MoveStrToBuf .sr+bx, tempBuff1
                    mov tempBuff1+si, 0

                    pop bx
                    mov isX8_1, 0 
                    jmp x0_save
                    
        x8_2:
            mov al, storage+5
            cmp al, 00h
            jne xExit
            
            MoveStrToBuf .Pop, outBuffer+24
            mov tempPos, si
            inc isXF
            jmp x0_template
        
        x8_3:
            mov al, storage+5
            cmp al, 00h
            je x8_3_0

            cmp al, 05h
            je x8_3_1

            cmp al, 07h
            je x8_3_2
            
            jmp xExit
        
            x8_3_0:
                MoveStrToBuf .Add, outBuffer+24
                mov tempPos, si
                mov isXF, 3
                jmp x0_template

            x8_3_1:
                MoveStrToBuf .Sub, outBuffer+24
                mov tempPos, si
                mov isXF, 3
                jmp x0_template

            x8_3_2:
                MoveStrToBuf .Cmp, outBuffer+24
                mov tempPos, si
                mov isXF, 3
                jmp x0_template
            
    x0:
        mov al, storage+1
        and al, 0Ch
        cmp al, 00h
        jne xExit
        mov tempPos, 00h
        MoveStrToBuf .Add, outBuffer+24
        mov tempPos, si
        
        x0_template:
            mov offsetSize, 00h
            Pos position, outBuffer
            ToAscii ds:[inBuffer], outBuffer+7
            ToAscii ds:[inBuffer+1], outBuffer+9
            inc position
            inc position

            mov outBuffer+4, 68h
            mov outBuffer+5, 3Ah
            mov outBuffer+6, 20h
            mov outBuffer+98, 0Dh
            mov outBuffer+99, 0Ah
            mov bx, 00h
            mov ah, 00h

            x0_0:
                cmp byte ptr ds:[storage+5], ah
                je x0_0_2
                cmp byte ptr ds:[.w0+bx], 00h
                je x0_0_1
                inc bx
                jmp x0_0
                x0_0_1:
                    inc bx
                    inc ah
                    jmp x0_0
                
                x0_0_2:
                    cmp byte ptr ds:[storage+3], 01h ;jei 1 word
                    je x0_1
                    
                    MoveStrToBuf .w0+bx, tempBuff1
                    mov tempBuff1+si, 0
                    MoveStrToBuf .BytePtr, tempBuff2
                    mov bx, 00h
                    mov ah, 00h

                    jmp x0_a
            
            x0_1:
                MoveStrToBuf .w1+bx, tempBuff1
                mov tempBuff1+si, 0
                
                cmp byte ptr ds:[isXF], 02h
                je x0_1_dword

                MoveStrToBuf .WordPtr, tempBuff2
                mov bx, 00h
                mov ah, 00h
                jmp x0_a
                
                x0_1_dword:
                    MoveStrToBuf .DWordPtr, tempBuff2
                    mov bx, 00h
                    mov ah, 00h
            
            x0_a:
                cmp byte ptr ds:[storage+6], ah
                je x0_a_2
                cmp byte ptr ds:[.rm+bx], 00h
                je x0_a_1
                inc bx
                jmp x0_a
                x0_a_1:
                    inc bx
                    inc ah
                    jmp x0_a
                x0_a_2:
                    cmp byte ptr ds:[isXF], 02h
                    je x0_a_2_dword
                    MoveStrToBuf .rm+bx, tempBuff2+10
                    jmp x0_a_2_next
                    x0_a_2_dword:
                        MoveStrToBuf .rm+bx, tempBuff2+11
                    x0_a_2_next:
                        cmp byte ptr ds:[storage+4], 00h ;be poslinkio
                        je x0_b
                        cmp byte ptr ds:[storage+4], 01h ;1 bito poslinkis
                        je x0_c
                        cmp byte ptr ds:[storage+4], 02h ;2 bitu poslinkis
                        je x0_d
                    
                        mov bx, 00h
                        mov ah, 00h
            x0_0_a:
                cmp byte ptr ds:[storage+6], ah
                je x0_0_2_a
                cmp byte ptr ds:[.w0+bx], 00h
                je x0_0_1_a
                inc bx
                jmp x0_0_a
                x0_0_1_a:
                    inc bx
                    inc ah
                    jmp x0_0_a
                x0_0_2_a:            
                    cmp byte ptr ds:[storage+3], 01h ;jei 1 word
                    je x0_1_a
                    
                    MoveStrToBuf .w0+bx, tempBuff2
                    mov tempBuff2+si, 0
                    jmp x0_save
                    
                x0_1_a:
                    MoveStrToBuf .w1+bx, tempBuff2
                    mov tempBuff2+si, 0
                    jmp x0_save
            
            x0_b:
                cmp byte ptr ds:[storage+6], 06h ; mod 00 rm 110 exception
                je x0_b_exception
                cmp byte ptr ds:[isXF], 02h
                je x0_b_dword
                mov tempBuff2+10+si, ']'
                mov tempBuff2+11+si, 00h
                jmp x0_b_next
                x0_b_dword:
                    mov tempBuff2+11+si, ']'
                    mov tempBuff2+12+si, 00h
                x0_b_next:
                    jmp x0_save
                
                x0_b_exception:
                    cmp byte ptr ds:[isXF], 02h
                    je x0_b_exception_dword
                    toascii ds:[inBuffer+3], tempBuff2+10
                    toascii ds:[inBuffer+2], tempBuff2+12
                    mov tempBuff2+14, ']'
                    mov tempBuff2+15, 00h
                    jmp x0_b_exception_next
                
                    x0_b_exception_dword:
                        toascii ds:[inBuffer+3], tempBuff2+11
                        toascii ds:[inBuffer+2], tempBuff2+13
                        mov tempBuff2+15, ']'
                        mov tempBuff2+16, 00h

                    x0_b_exception_next:
                        ToAscii ds:[inBuffer+2], outBuffer+11
                        ToAscii ds:[inBuffer+3], outBuffer+13
                        mov offsetSize, 2
                        inc position
                        inc position
                        jmp x0_save
            
            x0_c:
                cmp byte ptr ds:[inBuffer+2], 80h 
                jb x0_c_less
                mov al, inBuffer+2
                sub al, 80h
                mov ah, 80h
                sub ah, al
                cmp byte ptr ds:[isXF], 02h
                je x0_c_dword
                toascii ah, tempBuff2+11+si
                mov tempBuff2+10+si, '-'
                mov tempBuff2+13+si, ']'
                mov tempBuff2+14+si, 00h
                jmp x0_c_next
            
                x0_c_dword:
                    toascii ah, tempBuff2+12+si
                    mov tempBuff2+11+si, '-'
                    mov tempBuff2+14+si, ']'
                    mov tempBuff2+15+si, 00h
                
                x0_c_next:
                    ToAscii ds:[inBuffer+2], outBuffer+11
                    mov offsetSize, 1
                    inc position
                    jmp x0_save
                    
                x0_c_less:
                    cmp byte ptr ds:[isXF], 02h
                    je x0_c_less_dword

                    toascii ds:[inBuffer+2], tempBuff2+11+si
                    mov tempBuff2+10+si, '+'
                    mov tempBuff2+13+si, ']'
                    mov tempBuff2+14+si, 00h
                    jmp x0_c_less_next
                
                    x0_c_less_dword:
                        toascii ds:[inBuffer+2], tempBuff2+12+si
                        mov tempBuff2+11+si, '+'
                        mov tempBuff2+14+si, ']'
                        mov tempBuff2+15+si, 00h
                    
                    x0_c_less_next:
                        ToAscii ds:[inBuffer+2], outBuffer+11
                        mov offsetSize, 1
                        inc position
                        jmp x0_save
            
            x0_d:
                cmp byte ptr ds:[inBuffer+3], 80h 
                jb x0_d_less
                push bx
                mov bl, inBuffer+2
                mov bh, inBuffer+3
                sub bh, 80h
                mov ax, 8000h
                sub ax, bx
                pop bx
                cmp byte ptr ds:[isXF], 02h
                je x0_d_dword

                Pos ax, tempBuff2+11+si
                mov tempBuff2+10+si, '-'
                mov tempBuff2+15+si, ']'
                mov tempBuff2+16+si, 00h
                jmp x0_d_next
                
                x0_d_dword:
                    Pos ax, tempBuff2+12+si
                    mov tempBuff2+11+si, '-'
                    mov tempBuff2+16+si, ']'
                    mov tempBuff2+17+si, 00h
                    
                x0_d_next:
                    ToAscii ds:[inBuffer+2], outBuffer+11
                    ToAscii ds:[inBuffer+3], outBuffer+13
                    mov offsetSize, 2
                    inc position
                    inc position
                    jmp x0_save

                x0_d_less:
                    cmp byte ptr ds:[isXF], 02h
                    je x0_d_less_dword

                    toascii ds:[inBuffer+3], tempBuff2+11+si
                    toascii ds:[inBuffer+2], tempBuff2+13+si
                    mov tempBuff2+10+si, '+'
                    mov tempBuff2+15+si, ']'
                    mov tempBuff2+16+si, 00h
                    jmp x0_d_less_next
                    
                    x0_d_less_dword:
                        toascii ds:[inBuffer+3], tempBuff2+12+si
                        toascii ds:[inBuffer+2], tempBuff2+14+si
                        mov tempBuff2+11+si, '+'
                        mov tempBuff2+16+si, ']'
                        mov tempBuff2+17+si, 00h
                    x0_d_less_next:
                        
                        ToAscii ds:[inBuffer+2], outBuffer+11
                        ToAscii ds:[inBuffer+3], outBuffer+13
                        mov offsetSize, 2
                        inc position
                        inc position
                        jmp x0_save
            
            x0_save:
                cmp byte ptr ds:[isX8_1], 01h
                je x8_1_sr
                cmp byte ptr ds:[isXF], 00h
                ja xF_save
                
                cmp byte ptr ds:[storage+2], 01h
                je x0_save_dir1
                mov bx, tempPos
                MoveStrToBuf tempBuff2, outBuffer+25+bx
                add bx, si
                mov outBuffer+25+bx, ','
                MoveStrToBuf tempBuff1, outBuffer+27+bx
                jmp x0_save_exit
                
                x0_save_dir1:
                    mov bx, tempPos
                    MoveStrToBuf tempBuff1, outBuffer+25+bx
                    add bx, si
                    mov outBuffer+25+bx, ','
                    MoveStrToBuf tempBuff2, outBuffer+27+bx
                    
                x0_save_exit:
                    pop si
                    jmp save
            
        xF_save:
            cmp byte ptr ds:[isXF], 03h
            je xF_bojb_save
            mov bx, tempPos
            mov isXF, 00h
            MoveStrToBuf tempBuff2, outBuffer+25+bx
            pop si
            jmp save
        
        xF_bojb_save:
            mov isXF, 00h
            cmp byte ptr ds:[storage+3], 01h ;ar w = 1
            jne xf_bojb_save_1
            cmp byte ptr ds:[storage+2], 01h ;ar s = 1
            je xf_bojb_save_2
            jmp xf_bojb_save_3
        
            xf_bojb_save_1: ;w=0, s - nesvarbu (is vieno baito)
                mov bx, tempPos
                MoveStrToBuf tempBuff2, outBuffer+25+bx
                add si, bx
                mov outBuffer+25+si, ','
                mov di, offsetSize

                toascii ds:[inBuffer+di+2], outBuffer+27+si
                
                mov si, offsetSize
                add si, offsetSize
                toascii ds:[inBuffer+di+2], outBuffer+11+si
                inc position
                pop si
                jmp save
            
            xf_bojb_save_2: ;w=1, s=1 (reikia praplesti)
                mov bx, tempPos
                MoveStrToBuf tempBuff2, outBuffer+25+bx
                add si, bx
                mov outBuffer+25+si, ','
                mov di, offsetSize
                cmp byte ptr ds:[inBuffer+di+2], 80h
                jae xf_bojb_save_2_1 
                toascii ds:[inBuffer+di+2], outBuffer+27+si
                mov si, offsetSize
                add si, offsetSize
                toascii ds:[inBuffer+di+2], outBuffer+11+si
                inc position
                pop si
                jmp save

                xf_bojb_save_2_1:
                    toascii 0ffh, outBuffer+27+si
                    toascii ds:[inBuffer+di+2], outBuffer+29+si
                    mov si, offsetSize
                    add si, offsetSize
                    toascii ds:[inBuffer+di+2], outBuffer+11+si
                    inc position
                    pop si
                    jmp save

            
            xf_bojb_save_3: ;w=1, s=0 (is dvieju baitu)
                mov bx, tempPos
                MoveStrToBuf tempBuff2, outBuffer+25+bx
                add si, bx
                mov outBuffer+25+si, ','
                mov di, offsetSize

                toascii ds:[inBuffer+di+2], outBuffer+29+si
                toascii ds:[inBuffer+di+3], outBuffer+27+si
                
                mov si, offsetSize
                add si, offsetSize
                toascii ds:[inBuffer+di+2], outBuffer+11+si
                toascii ds:[inBuffer+di+3], outBuffer+13+si
                inc position
                inc position 
                pop si
                jmp save
        
    xExit:
        pop si
        ret
cmp_mod_rm ENDP

cmp_jmp_outside_direct:
    push si
    MoveStrToBuf .Jmp, outBuffer+24
    mov outBuffer+si+29, 3Ah
    jmp cmp_save_outside_direct
    
cmp_call_outside_direct:    
    push si
    MoveStrToBuf .Call, outBuffer+24
    mov outBuffer+si+25, 3Ah
    jmp cmp_save_outside_direct

    
cmp_save_outside_direct:
    Pos position, outBuffer
    inc position
    inc position
    inc position
    inc position
    ToAscii ds:[inBuffer], outBuffer+7
    ToAscii ds:[inBuffer+1], outBuffer+9
    ToAscii ds:[inBuffer+2], outBuffer+11
    ToAscii ds:[inBuffer+3], outBuffer+13
    ToAscii ds:[inBuffer+4], outBuffer+15

    mov outBuffer+4, 68h
    mov outBuffer+5, 3Ah
    mov outBuffer+6, 20h
    mov outBuffer+98, 0Dh
    mov outBuffer+99, 0Ah
    mov al, ds:[inBuffer+1]
    mov ah, ds:[inBuffer+2]
    Pos ax, outBuffer+si+30
    mov al, ds:[inBuffer+3]
    mov ah, ds:[inBuffer+4]
    Pos ax, outBuffer+si+25

    inc position
    pop si
    inc si
    inc si
    inc si
    inc si
    jmp save
    

CompareMovImmediate PROC near
    mov al, ds:[inBuffer+si]
    xor ah, ah
    mov bl, 10h
    div bl
    mov bl, ah
    mov ah, al
    mov al, bl
    cmp ah, 0Bh
    jne CMIexit
    cmp al, 08h
    jae CMIw1_0
    
    mov bx, 00h
    mov ah, 00h
        CMIw0:
        cmp al, ah
        je CMIw0_save
        cmp byte ptr ds:[.w0+bx], 00h
        je CMIw0_1
        inc bx
        jmp CMIw0
        CMIw0_1:
            inc bx
            inc ah
            jmp CMIw0
    
    CMIw1_0:
        mov bx, 00h
        mov ah, 00h
        sub al, 08h
        CMIw1:
            cmp al, ah
            je CMIw1_save
            cmp byte ptr ds:[.w1+bx], 00h
            je CMIw1_1
            inc bx
            jmp CMIw1
        CMIw1_1:
            inc bx
            inc ah
            jmp CMIw1
    
    CMIw0_save:
        MoveStrToBuf .w0+bx, tempBuff
        mov tempBuff+si, 0
        CASCA .Mov, tempBuff, cmp_save_a_position

    CMIw1_save:
        MoveStrToBuf .w1+bx, tempBuff
        mov tempBuff+si, 0
        CASCA .Mov, tempBuff, cmp_save_b_a_position

    
    CMIexit:
    ret
CompareMovImmediate ENDP

CompareAddSubCmpAccumulator PROC near
    cmp byte ptr ds:[inBuffer+si], 04h 
    jb CASCAexit
    cmp byte ptr ds:[inBuffer+si], 3Dh 
    ja CASCAexit
    cmp byte ptr ds:[inBuffer+si], 04h 
    je CASCA1
    cmp byte ptr ds:[inBuffer+si], 04h 
    je CASCA2
    cmp byte ptr ds:[inBuffer+si], 2Ch 
    je CASCA3
    cmp byte ptr ds:[inBuffer+si], 2Dh 
    je CASCA4
    cmp byte ptr ds:[inBuffer+si], 3Ch 
    je CASCA5
    cmp byte ptr ds:[inBuffer+si], 3Dh 
    je CASCA6
    
    jmp CASCAexit ;GRRRRRRR.....
    
    CASCA1:
        CASCA .Add, .Al, cmp_save_a_position
    
    CASCA2:
        CASCA .Add, .Ax, cmp_save_b_a_position

    CASCA3:
        CASCA .Sub, .Al, cmp_save_a_position
    
    CASCA4:
        CASCA .Sub, .Ax, cmp_save_b_a_position
    
    CASCA5:
        CASCA .Cmp, .Al, cmp_save_a_position
    
    CASCA6:
        CASCA .Cmp, .Ax, cmp_save_b_a_position
    
    CASCAexit:
        ret 
CompareAddSubCmpAccumulator ENDP

CompareMovAccumulator PROC near
    cmp byte ptr ds:[inBuffer+si], 0A0h 
    jb CMAexit
    cmp byte ptr ds:[inBuffer+si], 0A3h 
    ja CMAexit
    mov al, 0A0h
    cmp byte ptr ds:[inBuffer+si], al 
    je b00
    inc al
    cmp byte ptr ds:[inBuffer+si], al 
    je b01
    inc al
    cmp byte ptr ds:[inBuffer+si], al 
    je b10
    inc al
    cmp byte ptr ds:[inBuffer+si], al 
    je b11
    b00:
        push si
        MoveStrToBuf .Mov, outBuffer+24
        mov bx, si
        add bx, 1
        MoveStrToBuf .Al, outBuffer+bx+24
        add bx, si 
        mov outBuffer+bx+24, ','
        add bx, 2
        MoveStrToBuf .BytePtr, outBuffer+bx+24
        add bx, si
        sub bx, 6
        mov si, bx
        jmp cmp_save_b_a_position
    
    b01:
        push si
        MoveStrToBuf .Mov, outBuffer+24
        mov bx, si
        add bx, 1
        MoveStrToBuf .Ax, outBuffer+bx+24
        add bx, si 
        mov outBuffer+bx+24, ','
        add bx, 2
        MoveStrToBuf .WordPtr, outBuffer+bx+24
        add bx, si
        sub bx, 6
        mov si, bx
        jmp cmp_save_b_a_position

    b10:
        push si
        MoveStrToBuf .Mov, outBuffer+24
        mov bx, si
        add bx, 1
        MoveStrToBuf .BytePtr, outBuffer+bx+24
        add bx, si 
        mov outBuffer+bx+24, ','
        add bx, 2
        MoveStrToBuf .Al, outBuffer+bx+24
        sub bx, 8
        mov si, bx
        jmp cmp_save_b_a_position

    b11:
        push si
        MoveStrToBuf .Mov, outBuffer+24
        mov bx, si
        add bx, 1
        MoveStrToBuf .WordPtr, outBuffer+bx+24
        add bx, si 
        mov outBuffer+bx+24, ','
        add bx, 2
        MoveStrToBuf .Ax, outBuffer+bx+24
        sub bx, 8
        mov si, bx
        jmp cmp_save_b_a_position

    CMAexit:
        ret
CompareMovAccumulator ENDP

cmp_crr_call:
    push si
    MoveStrToBuf .Call, outBuffer+24
    jmp cmp_save_b_a_offset

cmp_crr_ret:
    push si
    MoveStrToBuf .Ret, outBuffer+24
    jmp cmp_save_b_a_position

cmp_crr_retf:
    push si
    MoveStrToBuf .Retf, outBuffer+24
    jmp cmp_save_b_a_position    
    
cmp_jmp:
    push si
    MoveStrToBuf .Jmp, outBuffer+24
    jmp cmp_save_b_a_offset
    
cmp_save_b_a_position:
    Pos position, outBuffer
    inc position
    inc position
    ToAscii ds:[inBuffer], outBuffer+7
    ToAscii ds:[inBuffer+1], outBuffer+9
    ToAscii ds:[inBuffer+2], outBuffer+11
    mov outBuffer+4, 68h
    mov outBuffer+5, 3Ah
    mov outBuffer+6, 20h
    mov outBuffer+98, 0Dh
    mov outBuffer+99, 0Ah
    mov al, ds:[inBuffer+1]
    mov ah, ds:[inBuffer+2]
    Pos ax, outBuffer+si+25
    inc position
    pop si
    inc si
    inc si
    jmp save

cmp_save_a_position:
    Pos position, outBuffer
    inc position
    inc position
    ToAscii ds:[inBuffer], outBuffer+7
    ToAscii ds:[inBuffer+1], outBuffer+9
    mov outBuffer+4, 68h
    mov outBuffer+5, 3Ah
    mov outBuffer+6, 20h
    mov outBuffer+98, 0Dh
    mov outBuffer+99, 0Ah
    ToAscii ds:[inBuffer+1], outBuffer+si+25
    pop si
    inc si
    inc si
    jmp save
    
cmp_save_b_a_offset:
    Pos position, outBuffer
    inc position
    inc position
    ToAscii ds:[inBuffer], outBuffer+7
    ToAscii ds:[inBuffer+1], outBuffer+9
    ToAscii ds:[inBuffer+2], outBuffer+11
    mov outBuffer+4, 68h
    mov outBuffer+5, 3Ah
    mov outBuffer+6, 20h
    mov outBuffer+98, 0Dh
    mov outBuffer+99, 0Ah
    mov al, ds:[inBuffer+1]
    mov ah, ds:[inBuffer+2]
    add ax, position
    inc ax
    Pos ax, outBuffer+si+25
    inc position
    pop si
    inc si
    inc si
    jmp save
    
cmp_save_a_offset:
    Pos position, outBuffer
    ToAscii ds:[inBuffer], outBuffer+7
    ToAscii ds:[inBuffer+1], outBuffer+9

    mov bx, 00h
    mov bl, ds:[inBuffer+1]
    mov outBuffer+4, 68h
    mov outBuffer+5, 3Ah
    mov outBuffer+6, 20h
    mov outBuffer+98, 0Dh
    mov outBuffer+99, 0Ah
    inc position
    inc position
    cmp bx, 80h
    jb a_offset_less
    mov ax, position
    mov tempPos, ax
    a_offset_more:
        dec tempPos
        inc bx
        cmp bx, 00FFh
        jbe a_offset_more
        Pos tempPos, outBuffer+si+25
        jmp a_offset_exit
    a_offset_less:
        add bx, position
        Pos bx, outBuffer+si+25   
    a_offset_exit:
        pop si
        inc si
        jmp save

cmp_jlj_jmp:
    push si
    MoveStrToBuf .Jmp, outBuffer+24
    jmp cmp_save_a_offset

cmp_jlj_loop:
    push si
    MoveStrToBuf .Loop, outBuffer+24
    jmp cmp_save_a_offset
    
cmp_jlj_jcxz:
    push si
    MoveStrToBuf .Jcxz, outBuffer+24
    jmp cmp_save_a_offset
    
cmp_int:    
    mov ax, @data
    mov es, ax
    mov bx, si
    push si
    Pos position, outBuffer
    ToAscii ds:[inBuffer+bx], outBuffer+7
    ToAscii ds:[inBuffer+bx+1], outBuffer+9
    mov outBuffer+4, 68h
    mov outBuffer+5, 3Ah
    mov outBuffer+6, 20h
    mov outBuffer+98, 0Dh
    mov outBuffer+99, 0Ah
    MoveStrToBuf .Int, outBuffer+24
    ToAscii ds:[inBuffer+bx+1], outBuffer+si+25
    inc position
    inc position
    pop si
    inc si
    jmp save

CompareOneByte PROC near
    mov bx, si
    push si
    cmp byte ptr ds:[inBuffer+bx], 0
    je COBexit
    mov si, 0
    COBa:
        mov al, ds:[.OneByteBytes+si]
        cmp byte ptr ds:[inBuffer+bx], al
        je COBb
        cmp al, 0
        je COBexit
        inc si
        jmp COBa
    
    COBb: 
        mov ax, 0
        mov bx, 0
    COBc:
        cmp ax, si
        je COBe
        cmp ds:[.OneByte+bx], 0
        je COBd
        inc bx
        jmp COBc
    COBd:
        inc ax
        inc bx
        jmp COBc
    COBe:
        OutFill ds:[.OneByteBytes+si], ds:[.OneByte+bx]
    COBexit:
        pop si
CompareOneByte ENDP

CompareJ PROC near
    cmp byte ptr ds:[inBuffer+si], 70h
    jae JCombined
    jmp JCombinedSkip
    JCombined:
        cmp byte ptr ds:[inBuffer+si], 7Fh
        jbe JCombined2
        jmp JCombinedSkip
    JCombined2:
        mov al, ds:[inBuffer+si]
        xor ah, ah
        mov bl, 10h
        div bl
        mov bx, 00h
        inc ah
    JCombined3:
        dec ah
        inc bx
        cmp ah, 00h
        je JCombined5
    JCombined4:
        mov al, [.JCombined+bx]
        cmp al, 00h
        je JCombined3
        inc bx
        jmp JCombined4
    JCombined5:

        mov ax, @data
        mov es, ax
        push di
        mov di, si
        push si
        MoveStrToBuf .JCombined+bx, outBuffer+24
        push bx
        Pos position, outBuffer
        ToAscii ds:[inBuffer+di], outBuffer+7
        ToAscii ds:[inBuffer+di+1], outBuffer+9

        mov bx, 00h
        mov bl, ds:[inBuffer+di+1]
        mov outBuffer+4, 68h
        mov outBuffer+5, 3Ah
        mov outBuffer+6, 20h
        mov outBuffer+98, 0Dh
        mov outBuffer+99, 0Ah
        inc position
        inc position
        cmp bx, 80h
        jb CJless
        mov ax, position
        mov tempPos, ax
        CJmore:
            dec tempPos
            inc bx
            cmp bx, 00FFh
            jbe CJmore
            Pos tempPos, outBuffer+si+25
            jmp CJexit
        CJless:
            add bx, position
            Pos bx, outBuffer+si+25   
        CJexit:
            pop bx    
            pop si
            pop di
            inc si

        jmp save
    
    JCombinedSkip:
    ret
CompareJ ENDP

prefix_save:
    pos prefixPosition, outBuffer
    mov bx, 90
    prefix_save_1:
        cmp byte ptr ds:[outBuffer+bx],'[' 
        je prefix_save_2
        mov al, outBuffer+bx
        mov outBuffer+bx+3, al
        dec bx
        jmp prefix_save_1
    prefix_save_2:
        mov al, outBuffer+bx
        mov outBuffer+bx+3, al
        mov outBuffer+bx+2, ':'
        mov al, prefix+1
        mov outBuffer+bx+1, al
        mov al, prefix
        mov outBuffer+bx, al
        mov bx, 21
    prefix_save_3:
        cmp bx, 6 
        je prefix_save_4
        mov al, outBuffer+bx
        mov outBuffer+bx+2, al
        dec bx
        jmp prefix_save_3
    prefix_save_4:
        ToAscii ds:[prefixByte], outBuffer+7
        
    prefix_save_exit:
        mov prefix, 0
        mov prefix+1, 0
        mov prefixByte, 0
save:
    cmp byte ptr ds:[prefixByte], 00h
    ja prefix_save
    mov ax, @data
    mov ds, ax
    mov bx, writeHandle
    mov cx, 100
    mov dx, offset outBuffer
    mov ah, 40h
    int 21h
    jmp startCycle

finish:
    mov	bx, writeHandle
	mov	ah, 3eh			
	int	21h
    mov	bx, readHandle
	mov	ah, 3eh			
	int	21h
    mov ax, 4C00h
    int 21h
end start
