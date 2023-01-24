		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _bzero( void *s, int n )
; Parameters
;	s 		- pointer to the memory location to zero-initialize
;	n		- a number of bytes to zero-initialize
; Return value
;   none
		EXPORT	_bzero
_bzero
		; r0 = s
		; r1 = n
		
		PUSH {r1-r12,lr}		
		; you need to add some code here for part 1 implmentation
		MOV		R2, #0
loop	CMP		R1, #0
		BEQ		break
		STRB	R2, [R0], #1
		SUB		R1, R1, #1
		
		B		loop
break
		POP {r1-r12,lr}	
		BX		lr



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; char* _strncpy( char* dest, char* src, int size )
; Parameters
;   dest 	- pointer to the buffer to copy to
;	src		- pointer to the zero-terminated string to copy from
;	size	- a total of n bytes
; Return value
;   dest
		EXPORT	_strncpy
_strncpy
		; r0 = dest = String B
		; r1 = src = String A
		; r2 = size = n
		
		PUSH {r1-r12,lr}		
		; will add some code here after part 1 implmentation
		
strloop	CMP		R2, #0
		BEQ		strbreak
		LDRB	R4, [R1], #1
		STRB	R4, [R0], #1
		SUB		R2, R2, #1
		
		B		strloop
strbreak
		
		POP {r1-r12,lr}	
		BX		lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DO NOT UPDATE THIS CODE
;
; void* _malloc( int size )
; Parameters
;	size	- #bytes to allocate
; Return value
;   void*	a pointer to the allocated space
		EXPORT	_malloc
_malloc 
		PUSH 	{r1-r12,lr}		
		
		MOV		r7, #0x1			; r7 specifies system call number
        SVC     #0x0				; system call
		
		POP 	{r1-r12,lr}
		
		BX		lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DO NOT UPDATE THIS CODE
;
; void _free( void* addr )
; Parameters
;	size	- the address of a space to deallocate
; Return value
;   none
		EXPORT	_free
_free
		PUSH 	{r1-r12,lr}		
		
		MOV		r7, #0x2			; r7 specifies system call number
        SVC     #0x0				; system call
		
		POP 	{r1-r12,lr}
		
		BX 		lr
		
		END