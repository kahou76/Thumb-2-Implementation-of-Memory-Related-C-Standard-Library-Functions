		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
HEAP_TOP	EQU		0x20001000
HEAP_BOT	EQU		0x20004FE0
MAX_SIZE	EQU		0x00004000		; 16KB = 2^14
MIN_SIZE	EQU		0x00000020		; 32B  = 2^5
	
MCB_TOP		EQU		0x20006800      ; 2^10B = 1K Space
MCB_BOT		EQU		0x20006BFE
MCB_ENT_SZ	EQU		0x00000002		; 2B per entry
MCB_TOTAL	EQU		512				; 2^9 = 512 entries
	
INVALID		EQU		-1				; an invalid id
	
count		EQU		0x4000


	
;
; Each MCB Entry
; FEDCBA9876543210
; 00SSSSSSSSS0000U					S bits are used for Heap size, U=1 Used U=0 Not Used

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory Control Block Initialization
; void _heap_init( )
; this routine must be called from Reset_Handler in startup_TM4C129.s
; before you invoke main( ) in driver_keil
		EXPORT	_heap_init
_heap_init
		; you must correctly set the value of each MCB block
		; complete your code
		;MOV		R0, #count
		;LDR		R1, =HEAP_TOP
		
		;MOV		R3, #0
;init1	CMP		R0, #0
		;BEQ		next
		;; array[ m2a( i ) ] = 0;
		;STRB	R3, [R4], #1
		;SUB		R0, R0, #1
		;B		init1
		
;next	
		LDR        R0, =MCB_TOP
        MOV        R1, #MAX_SIZE

        ;(short)&array[ m2a( mcb_top ) ] = max_size; 
        STR        R1, [R0] 

        LDR        R0, =0x20006804
        
        LDR        R3, =MCB_BOT
        MOV        R1, #0
init2   CMP        R0, R3
        BGT        break
        STRB    R1, [R0], #1
        B        init2


break
		BX		lr






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size )
		EXPORT	_kalloc
_kalloc
		; complete your code
		; return value should be saved into r0
		; R0 = size
		PUSH	{LR}
		LDR		R1, =MCB_TOP
		LDR		R2, =MCB_BOT
		MOV		R4, #MCB_ENT_SZ
		BL		_ralloc
		POP		{LR}
		;R12 is heap address which is the answer
		MOV		R0, R12
		
		BX 		LR
		

;helper
_ralloc
		PUSH		{LR}
		; int entire_mcb_addr_space = right_mcb_addr - left_mcb_addr + mcb_ent_sz;
		; R3 = entire_mcb_addr_space
		SUBS		R3, R2, R1
		ADDS		R3, R3, R4
		; int half_mcb_addr_space = entire_mcb_addr_space / 2;
		; R5 = half_mcb_addr_space
		ASRS		R5, R3, #1
		; int midpoint_mcb_addr = left_mcb_addr + half_mcb_addr_space;
		; R6 = midpoint_mcb_addr
		ADDS		R6, R1, R5
		; int heap_addr = 0; //initial heap address = 0
		; R12 = heap_addr
		MOV		R12, #0
		; int act_entire_heap_size = entire_mcb_addr_space * 16; 
		; R8 = act_entire_heap_size
		LSLS		R8, R3, #4
		; int act_half_heap_size = half_mcb_addr_space * 16;
		; R9 = act_half_heap_size
		LSLS		R9, R5, #4
		
		
		
		CMP		R0, R9
		BGT		else1
		
		;void* heap_addr = _ralloc(size, left_mcb_addr, midpoint_mcb_addr - mcb_ent_sz);
		PUSH	{R0-R9}
		SUBS	R2, R6, R4
		BL 		_ralloc
		POP		{R0-R9}
		
		CMP		R12, #0
		BEQ		al_right
		
		; if ((array[m2a(midpoint_mcb_addr)] & 0x01) == 0)
		LDR		R10, [R6]
		AND		R10, R10, #0x01
		CMP		R10, #0
		BEQ		function1
		
		; return heap_addr;
		;MOV		R0, R7
		BL			done	
		

		
else1		
		;//if yes, return 0 as invalid
		LDR		R10, [R1]
		AND		R10, R10, #0x01
		CMP		R10, #0
		BNE		invalid
		
		LDR		R10, [R1]
		CMP		R10, R8
		BLT		invalid
		
		; *(short*)& array[m2a(left_mcb_addr)] = act_entire_heap_size | 0x01;
		ORR		R10, R8, #0x01
		STR		R10, [R1]
		
		; return (void*)(heap_top + (left_mcb_addr - mcb_top) * 16);
		LDR		R10, =MCB_TOP
		LDR		R11, =HEAP_TOP
		SUB 	R1, R1, R10
		LSL		R1, R1, #4
		ADD		R11, R11, R1
		;MOV		R0, R11
		MOV		R12, R11
		BL		done


al_right
		;return _ralloc(size, midpoint_mcb_addr, right_mcb_addr);
		PUSH	{R0-R9}
		MOV		R1, R6
		BL		_ralloc
		POP		{R0-R9}
		BL		done

function1		
		 STR		R9, [R6]
		 
		 BL 			done
		 
		 
invalid
		MOV		R12, #0
		BL 		done
		
done
		POP 	{LR}
		BX		lr
		
		
		
		
		
		
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void *_kfree( void *ptr )	
		EXPORT	_kfree
_kfree
		; complete your code
		; return value should be saved into r0
		; R0 = *ptr
		PUSH	{LR}
		; //copy the address of the delocating pointer
		MOV		R1, R0
		
		;if ( addr < heap_top || addr > heap_bot )
		LDR		R2, =HEAP_TOP
		LDR		R3, =HEAP_BOT
		CMP		R1, R2
		BLT		return_null
		CMP		R1, R3
		BGT		return_null
		
		;//if not, get the MCB address related to delocating address by the formula below
	    ;int mcb_addr =  mcb_top + ( addr - heap_top ) / 16;
		LDR		R4, =MCB_TOP
		SUB		R5, R1, R2
		ASR		R6, R5, #4
		ADD		R6, R6, R4
		
		
		;Saving R0 to R10 first
		; MOV		R10, R0
		MOV		R0, R6
		;//if the helper function _rfree(MCB address) is 0 which means invalid
		;if ( _rfree( mcb_addr ) == 0 )
		PUSH	{R0-R12}
		;R0 = mcb_addr
		
		BL		_rfree
		POP		{R0-R12}
		;R0 = mcb_addr
		CMP		R0, #0
		BEQ		return_null
		
		;else return ptr;
		;MOV		R0, R10
		BL		over

return_null
		MOV		R0, #0
		BL		over
		
		
over
		POP		{LR}
		BX		lr
		








;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; helper
;int _rfree( int mcb_addr ) {
_rfree
		; PUSH	{LR}
		;R0 = mcb_addr

		PUSH	{LR}	
		; short mcb_contents = *(short *)&array[ m2a( mcb_addr ) ]; //get the content from MCB address
		LDR		R1, [R0]
		
		; int mcb_index = mcb_addr - mcb_top; //get the MCB index by MCB address - MCB top boundary
		LDR		R2, =MCB_TOP
		SUB		R3, R0, R2
		
		; int mcb_disp = ( mcb_contents /= 16 ); //get the MCB amount in which the index need to be displayed by MCB content divided by 16 bits
		ASR		R1, R1, #4
		MOV		R4, R1
		
		; int my_size = ( mcb_contents *= 16 ); //get the my_size by MCB content multiplied by 16
		LSL		R1, R1, #4
		MOV		R5, R1
		
		;// mcb_addr's used bit was cleared
		;*(short *)&array[ m2a( mcb_addr ) ] = mcb_contents;
		STR		R1, [R0]
		
		;PUSH	{R0-R12}
		;BL		help
		;POP		{R0-R12}
		
		;POP		{LR}
		;MOV		R0, R0
		;BX		LR
		
;helper	
;help	
		;PUSH	{LR}
		; R0 = mcb_addr
		;//check if the MCB index divided by MCB disp is left == 0 or right == 1
		;if ( ( mcb_index / mcb_disp ) % 2 == 0 ) {  
		SDIV	R6, R3, R4
		; R6 = ( mcb_index / mcb_disp )
		MOV		R10, #2
		SDIV	R11, R6, R10
		MLS		R12, R11, R10, R6
		CMP		R12, #0
		BEQ		if1
		;else1
		;//check if the MCB address - MCB disp is below MCB top size
		;if ( mcb_addr - mcb_disp < mcb_top )
		;R8 = mcb_addr - mcb_disp
		; LDR		R2,=MCB_TOP
		SUB		R8, R0, R4
		CMP		R8, R2
		BLT		return_zero
		
		;else
		;short mcb_buddy = *(short *)&array[ m2a( mcb_addr - mcb_disp ) ];
		LDR		R9, [R8]
		;if ( ( mcb_buddy & 0x0001 ) == 0 ) {
		MOV		R10, #0x0001
		AND		R11, R9, R10
		CMP		R11, #0
		BEQ		function5
		;else return mcb_address
		B		finish
		
		
		
if1				
		;if ( mcb_addr + mcb_disp >= mcb_bot )
		;	return 0; // my buddy is beyond mcb_bot!
		LDR		R8, =MCB_BOT
		ADDS	R12, R0, R4
		; R12 = mcb_addr + mcb_disp
		CMP		R12, R8
		BLT		else2
		;return 0
		MOV		R0, #0
		BL		finish
	
else2
		;// MCB buddy is the value of array[ mcb_addr + mcb_disp]
		;short mcb_buddy = *(short *)&array[ m2a( mcb_addr + mcb_disp ) ];   
		LDR		R9, [R12]
		
		;//check if the LSB is 0 by doing MCB buddy AND 0x0001
		;if ( ( mcb_buddy & 0x0001 ) == 0 ) {
		AND		R10, R9, #0x0001
		CMP		R10, #0
		BEQ		function3
		BL		finish
;back		
		
		
function3
		;// mcb_buddy/32 is the upper value of buddy system
		;mcb_buddy = ( mcb_buddy / 32 ) * 32;
		ASRS	R9, R9, #5
		LSLS	R9, R9, #5
		;B		back
		;//check if buddy size is same as my_size
		;if ( mcb_buddy == my_size ) {
		CMP		R9, R5
		BEQ		function4
		
		;else return mcb_addr;
		BL		finish

function4
		;//yes, clean the buddy content to 0
		;*(short *)&array[ m2a( mcb_addr + mcb_disp ) ] = 0;
		MOV		R10, #0
		STR		R10, [R12]
		
		;my_size *= 2;
		LSL		R5, R5, #1
		
		;*(short *)&array[ m2a( mcb_addr ) ] = my_size;
		STR		R5, [R0]
		
		;//recusively return the updated MCB address
		;return _rfree( mcb_addr );
		PUSH	{R0-R12}
		BL		_rfree
		POP		{R0-R12}
		BL		finish
		
		
function5
		;//clear bit 4-0 to re-initialize the MCB buddy
		;mcb_buddy = ( mcb_buddy / 32 ) * 32;
		ASR		R9, R9, #5
		LSL		R9, R9, #5
		;if ( mcb_buddy == my_size ) {
		CMP		R9, R5
		BEQ		function6
		;else return mcb address
		BL		finish
		
function6		
		;//same size, clean the content of index MCB address by setting the content to 0
		;*(short *)&array[ m2a( mcb_addr ) ] = 0;
		MOV		R10, #0
		STR		R10, [R0]
	
		;//multiplie my_size by 2
		;my_size *= 2;
		LSL		R5, R5, #1
		;//write my_size*2 to the conttent of array address of MCB address - MCB disp
		;*(short *)&array[ m2a( mcb_addr - mcb_disp ) ] = my_size;
		STR		R5, [R8]
		
		;//recursively return this address
		;return _rfree( mcb_addr - mcb_disp );
		PUSH	{R0-R12}
		SUBS	R0, R0, R4
		BL		_rfree
		POP		{R0-R12}
		BL		finish
		
		

return_zero
		MOV		R0, #0
		BL 		finish


finish
		POP		{LR}
		BX		LR
		
		
		END