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
    
include opcodes.asm

.code

Sje MACRO location
LOCAL @@exit
    jne @@exit
    jmp location
@@exit:
ENDM

Sjc MACRO location
LOCAL @@exit
    jnc @@exit
    jmp location
@@exit:
ENDM

OutFill MACRO mcode, acode
    mov ax, @data
    mov es, ax
    Pos position, outBuffer
    ToAscii mcode, outBuffer+7
    Move 68h, outBuffer+4
    Move 3Ah, outBuffer+5
    Move 20h, outBuffer+6 
    MoveStrToBuf acode, outBuffer+24
    Move 0Dh, outBuffer+98
    Move 0Ah, outBuffer+99
    inc position
    jmp save
ENDM

OutFillDisplacement MACRO mcode,mcode2, acode
LOCAL @@exit, @@less, @@less1, @@more
    mov ax, @data
    mov es, ax
    push bx
    Pos position, outBuffer
    ToAscii mcode, outBuffer+7
    ToAscii mcode2, outBuffer+9
    Move 68h, outBuffer+4
    Move 3Ah, outBuffer+5
    Move 20h, outBuffer+6 
    MoveStrToBuf acode, outBuffer+24
    Move 0Dh, outBuffer+98
    Move 0Ah, outBuffer+99
    inc position
    inc position
    mov bl, mcode2
    cmp bl, 80h
    jb @@less1
    jmp @@more
    @@less1:
    jmp @@less
    @@more:
    
    Pos position-bx, outBuffer+si+1
    jmp @@exit
    @@less:
    Pos position+bx, outBuffer+si+1    
    @@exit:
    pop si
    inc si
    pop bx
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
    push si
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
LOCAL @@exit, @@start,@@exit1
cmp byte ptr ds:[inBuffer+si], b
jne @@exit1
jmp @@start
@@exit1:
jmp @@exit
@@start:
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
    Sje print_info
        
    mov ax, word ptr ds:[si]
    cmp ax, 3F2Fh
    Sje print_info

    Get_file readFile
    Get_file writeFile

    mov ax, @data
    mov ds, ax
    mov	dx, offset readFile
	mov	ah, 3Dh
	mov	al, 00h
	int	21h
    Sjc print_info
	mov	readHandle, ax   
    mov ax, @data
    mov ds, ax
    mov	dx, offset writeFile
	mov	ah, 3Ch
	xor	cx, cx
	int	21h
    Sjc print_info
    mov ah, 3Dh
    mov al, 01h
    int 21h
    Sjc print_info
	mov	writeHandle, ax
    
    reread:
    mov	bx, readHandle
	mov	dx, offset inBuffer       ; address of buffer in dx
	mov	cx, 20         		; kiek baitu nuskaitysim
	mov	ah, 3fh         	; function 3Fh - read from file
	int	21h
    mov temp, ax
    mov si, 0
    dec si
    cmp temp, 00h
    Sje finish
    startCycle:
    inc si
    cmp si,temp
    jae reread
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
    check_begin:
    Compare1 06h, .PushES
    Compare1 0Eh, .PushCS
    Compare1 16h, .PushSS
    Compare1 1Eh, .PushDS
    Compare1 07h, .PopES
    Compare1 0Fh, .PopCS
    Compare1 17h, .PopSS
    Compare1 1Fh, .PopDS
    Compare1 07h, .PopES
    Compare1 0Fh, .PopCS
    Compare1 17h, .PopSS
    Compare1 1Fh, .PopDS
    Compare1 40h, .IncAX
    Compare1 44h, .IncSP
    Compare1 43h, .IncBX
    Compare1 47h, .IncDI
    Compare1 41h, .IncCX
    Compare1 45h, .IncBP
    Compare1 42h, .IncDX
    Compare1 46h, .IncSI
    Compare1 48h, .DecAX
    Compare1 4Ch, .DecSP
    Compare1 4Bh, .DecBX
    Compare1 4Fh, .DecDI
    Compare1 49h, .DecCX
    Compare1 4Dh, .DecBP
    Compare1 4Ah, .DecDX
    Compare1 4Eh, .DecSI
    Compare1 50h, .PushAX
    Compare1 54h, .PushSP
    Compare1 53h, .PushBX
    Compare1 57h, .PushDI
    Compare1 51h, .PushCX
    Compare1 55h, .PushBP
    Compare1 52h, .PushDX
    Compare1 56h, .PushSI
    Compare1 58h, .PopAX
    Compare1 5Ch, .PopSP
    Compare1 5Bh, .PopBX
    Compare1 5Fh, .PopDI
    Compare1 59h, .PopCX
    Compare1 5Dh, .PopBP
    Compare1 5Ah, .PopDX
    Compare1 5Eh, .PopSI

    call CompareJ

    
    ;Compare1 0B4h, MovAh
    
    OutFill ds:[inBuffer+si], .Unknown
    ret
check_byte ENDP

CompareJ PROC near
    cmp byte ptr ds:[inBuffer+si], 70h
    jae JCombined
    jmp JCombinedSkip
    JCombined:
    cmp byte ptr ds:[inBuffer+si], 7Fh
    jbe JCombined2
    jmp JCombinedSkip
    JCombined2:
    push ax
    push bx
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
    OutFillDisplacement ds:[inBuffer+si],ds:[inBuffer+si+1],[.JCombined+bx] 
    pop bx
    pop ax
    
    
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
