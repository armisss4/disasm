    .Unknown        db 'NEATPAZINTA',0
    .Mov            db 'mov',0
    .OneByte        db 'push ES',0,'ES',0,'pop ES',0,'push CS',0,'CS',0,'pop CS',0,'push SS',0,'SS',0,'pop SS',0,'push DS',0,'DS',0,'pop DS',0,'inc AX',0,'inc CX',0,'inc DX',0,'inc BX',0,'inc SP',0,'inc BP',0,'inc SI',0,'inc DI',0,'dec AX',0,'dec CX',0,'dec DX',0,'dec BX',0,'dec SP',0,'dec BP',0,'dec SI',0,'dec DI',0,'push AX',0,'push CX',0,'push DX',0,'push BX',0,'push SP',0,'push BP',0,'push SI',0,'push DI',0,'pop AX',0,'pop CX',0,'pop DX',0,'pop BX',0,'pop SP',0,'pop BP',0,'pop SI',0,'pop DI',0,'ret',0,'retf',0,'nop',0,'lodsb AL, byte ptr [SI]',0,'stosb byte ptr ES:[DI], AL',0
    .OneByteBytes   db 06h,26h,07h,0Eh,2Eh,0Fh,16h,36h,17h,1Eh,3Eh,1Fh,40h,41h,42h,43h,44h,45h,46h,47h,48h,49h,4Ah,4Bh,4Ch,4Dh,4Eh,4Fh,50h,51h,52h,53h,54h,55h,56h,57h,58h,59h,5Ah,5Bh,5Ch,5Dh,5Eh,5Fh,0C3h,0CBh,90h,0ACh,0AAh,0
    .JCombined      db ' jo',0,'jno',0,'jnae',0,'jae',0,'je',0,'jne',0,'jbe',0,'ja',0,'js',0,'jns',0,'jp',0,'jnp',0,'jl',0,'jge',0,'jle',0,'jg',0
    .Int            db 'int',0
    .Loop           db 'loop',0
    .Jcxz           db 'jcxz',0
    .Jmp            db 'jmp',0
    .Call           db 'call',0
    .Ret            db 'ret',0
    .Retf           db 'retf',0
    .Add            db 'add',0
    .Sub            db 'sub',0
    .Cmp            db 'cmp',0
    .Pop            db 'pop',0    
    .Mul            db 'mul',0    
    .Div            db 'div',0    
    .Push           db 'push',0    
    .Inc            db 'inc',0    
    .Dec            db 'dec',0  
    .Xor            db 'xor',0
    .Ax             db 'AX',0
    .Ah             db 'AH',0
    .Al             db 'AL',0    
    .BytePtr        db 'byte ptr [    ]',0
    .WordPtr        db 'word ptr [    ]',0
    .DWordPtr       db 'dword ptr [    ]',0
    .W0             db 'AL',0,'CL',0,'DL',0,'BL',0,'AH',0,'CH',0,'DH',0,'BH',0
    .W1             db 'AX',0,'CX',0,'DX',0,'BX',0,'SP',0,'BP',0,'SI',0,'DI',0
    .Rm             db 'BX+SI',0,'BX+DI',0,'BP+SI',0,'BP+DI',0,'SI',0,'DI',0,'BP',0,'BX',0
    .Sr             db 'ES',0,'CS',0,'SS',0,'DS',0
    
