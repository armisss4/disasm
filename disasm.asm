;Paleidus disasemblerį su argumentu "/?", jis turi išmesti aprašą: atsiskaitančiojo vardas, pavardė, kursas, grupė, trumpas programos aprašymas.
;Visi parametrai disasembleriui turi būti paduodami komandine eilute, o ne prašant juos įvesti iš klaviatūros. Pvz.: disasm prog.com prog.asm.
;Disasemblerio rezultatas turi būti išvedamas į failą.
;Jeigu disasembleris paleistas be parametrų arba parametrai nekorektiški, reikia atspausdinti pagalbos pranešimą tokį patį, kaip paleidus disasemblerį su parametru "/?".
;Disasembleris turi apdoroti įvedimo išvedimo (ir kitokias) klaidas. Pavyzdžiui, nustačius, kad nurodytas failas neegzistuoja - jis turi išvesti pagalbos pranešimą ir baigti darbą.
;Failų skaitymo ar rašymo buferio dydis turi būti nemažesnis už 10 baitų.
;Failo dydis gali viršyti skaitymo ar rašymo buferio dydį.
;Su programa turi būti pateikiamas testinis com failas ir jo kodas asm faile.
;Rezultatų faile turi būti išvedama poslinkis nuo kodo segmento pradžios, komandos mašininis kodas ir pati komanda. Turėkite omenyje, kad pirmoji komanda com faile yra su poslinkiu 100h nuo segmento pradžios.
;Turi būti suprantamos ir disasembliuojamos šios komandos:
;Segmento keitimo prefiksas;
;Visi MOV variantai (6);
;Visi PUSH variantai (3);
;Visi POP variantai (3);
;Visi ADD variantai (3);
;Visi INC variantai (2);
;Visi SUB variantai (3);
;Visi DEC variantai (2);
;Visi CMP variantai (3);
;Komanda MUL;
;Komanda DIV;
;Visi CALL variantai (4);
;Visi RET variantai (4);
;Visi JMP variantai (5);
;Visos sąlyginio valdymo perdavimo komandos (17);
;Komanda LOOP;
;Komanda INT;
;Visi kitų komandų, kurios naudojamos testinėje programoje, variantai;
;Jei nuskaičius baitą nesugebama jo atpažinti, reikia jį praleisti (apie tai pažymint rezultatų faile) ir bandyti atpažinti po jo einantį baitą;


.model small
.stack 100h
JUMPS
.data
    info            db 'Arminas Petraitis, 2 kursas, INF4 grupe', 0Dh, 0Ah, 'Programa disasembliuoja failus, pateiktus komandineje eiluteje paleidziant programa', 0Dh, 0Ah, 'Naudojimas: disasm input.com output.asm', 0Dh, 0Ah, '$'
    readFile        db 12 dup (0)
    writeFile       db 12 dup (0)
    inBuffer        db 20 dup (?),0
    outBuffer       db 100 dup (?)
    readHandle      dw ?
    writeHandle     dw ?
    symbol          db ?
    temp            dw ?
    position        dw 100h
    tempPos         dw ?
    
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
    ;mov al, '$'
    ;stosb
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

Clr MACRO buffer 
LOCAL @@start, @@exit
    push Si
    xor Si, Si
    @@start:
    cmp si,100
    je @@exit
    mov buffer[si],20h
    inc si
    jmp @@start
    @@exit:
    pop Si
ENDM

Compare1 MACRO b, acode
LOCAL @@exit
cmp byte ptr ds:[inBuffer+si], b
jne @@exit
OutFill b, acode
@@exit:
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
    reread:
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
    Clr outBuffer
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
    call CompareOneByte
    call CompareJ
    cmp byte ptr ds:[inBuffer+si], 0CDh 
    je cmp_int
    cmp byte ptr ds:[inBuffer+si], 0EBh 
    je cmp_jmp
    cmp byte ptr ds:[inBuffer+si], 0E2h 
    je cmp_loop
    cmp byte ptr ds:[inBuffer+si], 0E3h 
    je cmp_jxcz
    
    ;Compare1 0B4h, MovAh
    
    OutFill ds:[inBuffer+si], .Unknown
    ret
check_byte ENDP

cmp_jmp_loop_jxcz:
    cmp_jmp:
    mov ax, 0
    jmp cmp_jmp_loop_jxcz_save
    cmp_loop:
    mov ax, 1
    jmp cmp_jmp_loop_jxcz_save
    cmp_jxcz:
    mov ax, 2
    cmp_jmp_loop_jxcz_save:
    push si
    mov si, 0
    jlja:
    cmp ax, si
    je jljc
    cmp byte ptr ds:[.JmpLoopJxcz+bx], 0
    je jljb
    inc bx
    jmp jlja
    jljb:
    inc bx
    inc si
    jmp jlja
    jljc:
    
    mov ax, @data
    mov es, ax
    mov si, 0
    MoveStrToBuf .JmpLoopJxcz+bx, outBuffer+24
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
    jb jljless
    mov ax, position
    mov tempPos, ax
    jljmore:
    dec tempPos
    inc bx
    cmp bx, 00FFh
    jbe jljmore
    Pos tempPos, outBuffer+si+25
    jmp jljexit
    jljless:
    add bx, position
    Pos bx, outBuffer+si+25   
    jljexit:
    
    pop si
    inc si
    jmp save
    
cmp_int:    
    mov ax, @data
    mov es, ax
    mov bx, si
    push si
    Pos position, outBuffer
    ToAscii ds:[inBuffer+bx], outBuffer+7
    ToAscii ds:[inBuffer+bx+1], outBuffer+9
    Move 68h, outBuffer+4
    Move 3Ah, outBuffer+5
    Move 20h, outBuffer+6 
    MoveStrToBuf .Int, outBuffer+24
    ToAscii ds:[inBuffer+bx+1], outBuffer+si+25
    Move 0Dh, outBuffer+98
    Move 0Ah, outBuffer+99
    inc position
    inc position
    pop si
    inc si
    jmp save

CompareOneByte PROC near
    mov bx, si
    push si
    cmp byte ptr ds:[inBuffer+bx], 0
    je exit
    mov si, 0
    a:
    mov al, ds:[.OneByteBytes+si]
    cmp byte ptr ds:[inBuffer+bx], al
    je b
    cmp al, 0
    je exit
    inc si
    jmp a
    
    b: 
    mov ax, 0
    mov bx, 0
    c:
    cmp ax, si
    je e
    cmp ds:[.OneByte+bx], 0
    je d
    inc bx
    jmp c
    d:
    inc ax
    inc bx
    jmp c
    e:
    OutFill ds:[.OneByteBytes+si], ds:[.OneByte+bx]
    exit:
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



MovAh:
OutFill 0B4h, .Mov

save:
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
