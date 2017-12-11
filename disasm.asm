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
    inBuffer        db 20 dup (?)
    outBuffer       db 100 dup (0)
    readHandle      dw ?
    writeHandle     dw ?
    symbol          db ?
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

Move MACRO a,b
    mov ah, [a]
    mov [b], ah
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
	mov	cx, 00h
	int	21h
    Sjc print_info
    mov ah, 3Dh
    mov al, 01h
    int 21h
    Sjc print_info
	mov	writeHandle, ax
    
    mov	bx, readHandle
	mov	dx, offset inBuffer       ; address of buffer in dx
	mov	cx, 20         		; kiek baitu nuskaitysim
	mov	ah, 3fh         	; function 3Fh - read from file
	int	21h
    call check_byte
    
    jmp save
    
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
    cmp byte ptr ds:[inBuffer], 0B4h
    Sje print_info
    ret
check_byte ENDP

save:
    mov ax, @data
    mov ds, ax
    mov bx, writeHandle
    mov cx, 20
    ;mov dx, inBuffer+2
    Move inBuffer+5,outBuffer+1
 ;   mov outBuffer, inBuffer+2
    mov dx, offset outBuffer
  ;  mov outBuffer+5, inBuffer
    mov ah, 40h
    int 21h

finish:
    mov ax, 4C00h
    int 21h
end start