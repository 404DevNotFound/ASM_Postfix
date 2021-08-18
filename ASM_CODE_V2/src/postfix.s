.section .data

invalid:
    .string "Invalid\0"

flag:
    .byte 0

.section .text
    .global postfix
     
postfix:
    # salvo il valore di ebp e copio esp in ebp per accedere allo stack con 
    # offset rispetto a questo punto.
    pushl %ebp
    movl %esp, %ebp

    # salvo i registri
    pushl %eax
    pushl %ebx
    pushl %ecx
    pushl %edx
    pushl %esi
    pushl %edi

    # azzero i registri
    xorl %eax, %eax 
    xorl %ecx, %ecx 
    xorl %edx, %edx 
    xorl %ebx, %ebx
                    
    # recupero i parametri
    movl 8(%ebp), %esi # Stringa input
    movl 12(%ebp), %edi  # stringa output

    movl $7, %edx # n° push

scorri_stringa:
  movb (%ecx, %esi), %al
  testb %al, %al # se carattere '\0' stringa vuota
  jz fine

  operatori:
  	# Verifica se il carattere letto è un operatore valido per il programma.
    cmp $32, %al # spazio -> va ingorato
    je spazio
	cmp $42, %al # simbolo '*'
	je moltiplicazione
	cmp $43, %al # simbolo '+'
	je addizione
	cmp $45, %al # simbolo '-'
	je rileva_negativo
	cmp $47, %al # simbolo '/'
    je divisione
  jmp atoi

  spazio:
    incl %ecx 
    jmp scorri_stringa

  rileva_negativo:
	# In caso di riscontro con il segno '-' prima di considerarlo operatore verifico che
	# i caratteri successivi non siano cifre.
	incl %ecx
	movb (%ecx, %esi), %al 
	# se dopo il 'meno' è presente il terminatore il meno è un operatore
	testb %al, %al 
	jz sottrazione
	# se il carattere successivo è uno spazio il meno è un operatore
	cmp $32, %eax # 'spazio'
	je sottrazione
	# ELSE: verifico se si tratta di un numero. Utilizzo una variabile come flag per
	# impostare il negativo.
	movl $1, flag
   
  atoi:
    # Controllo se il primo simbolo non è un numero: trasformo il carattere letto in intero
    # e verifico che sia maggiore o uguale a 0, se è verificata questa condizione, verifico che il 
    # carattere convertito ad intero sia minore o uguale a 9. Nel caso in cui il carattere convertito
    # non rientri nell'intervallo, output stringa non valida.
    # Eccezione in caso di carattere '-' -> gestione dei numeri negativi.
    subl $48, %eax
    cmp $0, %eax 
    jge maggiore_zero
    jmp str_invalid
    maggiore_zero:
      cmp $9, %eax 
      jle operando
      jmp str_invalid
      operando:
        #movl $10, %edx 
        moltiplica:
          incl %ecx 
          movb (%ecx, %esi), %bl 
          subl $48, %ebx 
          cmp $-16, %ebx 
          je push_numero
          cmp $0, %ebx 
          jge cfr2_maggiore_zero
          jmp str_invalid
          cfr2_maggiore_zero:
            cmp $9, %ebx 
            jle continua_conversione
            jmp str_invalid
          continua_conversione:
          pushl %edx # salvo il contatore push/pop
          movl $10, %edx
          mull %edx
          popl %edx # ripristino il contatore push/pop
          addl %ebx, %eax 
          jmp moltiplica
  incl %ecx 
jmp scorri_stringa

push_numero:
	# se il flag è a 1, prima di effettuare il salvataggio nello stack rendo negativo il
	# numero in %EAX moltiplicando per '-1'.
	incl %ecx # "saltiamo" lo spazio
    xorl %ebx, %ebx 
    cmp $1, flag 
	je negativo
    	# se il flag non è impostato a 1 salvo %EAX nello stack e torno alla stringa di input.
	pushl %eax 
    incl %edx 
    xorl %eax, %eax
    jmp scorri_stringa

	negativo:
		negl %eax 
		pushl %eax 
        incl %edx 
        # azzero i registri prima di tornare a scorrere la stringa.
        xorl %eax, %eax 
        xorl %ebx, %ebx 
        # resetto la flag per il numero negativo
        movl $0, flag
	jmp scorri_stringa

str_invalid:
    leal invalid, %esi
    movl $7, %ecx 
    # azzeriamo eax per evitare errori di trascrizione dei caratteri della 
    # stringa "Invalid"
    stampa_invalid:
        xorl %eax, %eax 
        movb (%ecx, %esi), %al
        movb %al, (%ecx, %edi)
        decl %ecx 
        cmp $0, %ecx 
        jge stampa_invalid
jmp stampa_errore

addizione:
    cmp $2, %edx
    jl str_invalid 
    popl %eax
    decl %edx  
    popl %ebx 
    decl %edx
    addl %eax, %ebx
    pushl %ebx 
    incl %edx 
    xorl %eax, %eax
    xorl %ebx, %ebx
    incl %ecx
    jmp scorri_stringa

sottrazione:
    cmp $2, %edx 
    jl str_invalid
    popl %eax 
    decl %edx 
    popl %ebx 
    decl %edx 
    subl %eax, %ebx 
    pushl %ebx 
    incl %edx 
    xorl %eax, %eax
    xorl %ebx, %ebx 
    #incl %ecx
jmp scorri_stringa

moltiplicazione:
    cmp $2, %edx 
    jl str_invalid
    popl %ebx # secondo fattore
    decl %edx 
    popl %eax # primo fattore
    decl %edx 
    pushl %edx 
    imul %ebx #eax = ebx * eax
    popl %edx 
    pushl %eax 
    incl %edx 
    xorl %eax,%eax
    xorl %ebx, %ebx 
    incl %ecx
jmp scorri_stringa

divisione:
    cmp $2, %edx 
    jl str_invalid
    popl %ebx # <- divisore
    decl %edx 
    popl %eax # <- dividendo
    decl %edx 
    pushl %edx # salvo il contatore push/pop
    xorl %edx, %edx # azzero edx
    idivl %ebx # eax = edx&eax / ebx ---> RESTO in edx
    popl %edx   # ripristino il contatore push/pop
    pushl %eax 
    incl %edx 
    xorl %eax, %eax 
    xorl %ebx, %ebx 
    incl %ecx
jmp scorri_stringa

fine:
    # stampa del risultato su file
    popl %eax 
    decl %edx 
    movl $10, %ebx
    movl $0, %ecx 
    pushl %edx # salvo il conteggio pop/push
    cmp $0, %eax
    jl res_neg
    jmp itoa
    res_neg:
        negl %eax  # rendo positivo il numero per la trasformazione a caratteri
        movl $1, flag # flag per numero negativo
    
    itoa:
        xorl %edx, %edx 
        divl %ebx # int_to_char carattere per carattere
        addl $48, %edx 
        reverse_str:
            pushl %edx 
            incl %ecx # - contatore caratteri pushati
            test %al, %al # se al nullo
            jz stampa_risultato
        jmp itoa

        stampa_risultato:
            movl $0, %ebx 
            cmp $0, %ebx 
            je controlla_flag 
        continua_a_stampare:
            popl %edx 
            movb %dl, (%ebx, %edi)
            decl %ecx
            incl %ebx 
            cmp $0, %ecx 
            je ripristina_reg
        jmp continua_a_stampare
        controlla_flag:
            cmp $1, flag # se flag == 1
            jne continua_a_stampare
            movb $45, (%ebx, %edi)
            incl %ebx 
            movl $0, flag 
        jmp continua_a_stampare
            
    ripristina_reg:
    movb $0, (%ebx, %edi) # terminatore stringa
    
    stampa_errore:
    popl %edx

    # ripristino i registri allo stato della Call.
    popl %edi
    popl %esi
    popl %edx 
    popl %ecx 
    popl %ebx 
    popl %eax 
    popl %ebp 

    ret

