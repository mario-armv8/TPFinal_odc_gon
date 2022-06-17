 
.include "data.s"
.include "draw_objects.s"
.globl main
main:
   // X0 contiene la direccion base del framebuffer
	mov x20, x0 // Save framebuffer base address to x20
   //---------------- CODE HERE ------------------------------------
  
 
b prueba


/*
	Buffer secundario a framebuffer
	La siguiente función copia el contenido del buffer secundario en el principal
	
	Como tengo instrucciones para manejar double word y cada pixel ocupa una word,
	puedo traer e ir copiando de a dos píxeles por vez
	x0: dirección buffer secundario
 */
refresh_framebuffer:
	ldr x11, dir_framebuffer_ppal //cargo la dirección del framebuffer en x1 (definida como 0)
	ldr x13, half_screen_pixels //como agarro de a dos elementos voy a iterar la mitad de veces
	sub x13, x13, #1 
	loop_copy_2pixel:
		cmp x13, xzr
		b.lt end_loop_copy_2pixel
		ldr x14, [x0, x13, lsl #3] // dir de los dos píxeles a leer = =second_buffer + 8*nro_del_par_de_pixeles (4Bytes c/u )
		str x14, [x11, x13, lsl #3] // guardo en la posición equivalente pero del framebuffer
		sub x13, x13, #1
		b loop_copy_2pixel
	end_loop_copy_2pixel:
		br lr
	

 

 
 
 
prueba:
	adr x1, dir_framebuffer_ppal
	str x0, [x1]
	ldr x0, =second_buffer

	mov x1, #0
	mov x2, #0
	mov x4, SCREEN_WIDTH
	mov x5, SCREEN_HEIGH
	ldr w3, colorBlueSky
	bl draw_rectangle		//fondo
	mov x1, #180
	mov x2, #200
	mov x9, QUARTER_SQUARES_SIZE
	lsl x9, x9, #2
	bl brown_box
	add x1, x1, x9
	bl complex_brick
	add x1, x1, x9
	bl complex_brick
	add x1, x1, x9
	bl random_box
	sub x2, x2, x9
	bl fungi_shape
	mov x1, #-15
	mov x2, #400
	mov x13, #8
	mov x14, FLOOR_SIZE
	floor_loop:
		cbz x13, end_floor_loop
		bl floor_brick
		add x1, x1, x14, lsl #2
		sub x13, x13, #1
		b floor_loop
	end_floor_loop:
	mov x1, #100
	mov x2, #50
	bl standar_cloud
	
	ldr x0, =second_buffer
	bl refresh_framebuffer
	

   //---------------------------------------------------------------
   // Infinite Loop
 
InfLoop:
	b InfLoop

 