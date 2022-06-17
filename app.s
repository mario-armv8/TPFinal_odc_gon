 
.include "data.s"
.include "draw_objects.s"
.include "engine.s"
.globl main
main:
   // X0 contiene la direccion base del framebuffer
	mov x20, x0 // Save framebuffer base address to x20
   //---------------- CODE HERE ------------------------------------
  
  
prueba:
	adr x1, dir_framebuffer_ppal //guardo dirección del FB 
	str x0, [x1] //la guardo en la etiqueta
	ldr x0, =second_buffer //pongo en x0 la dirección del buffer secundario

	bl draw_backround
	//bl initialize_brick_array
	bl draw_bricks
	bl draw_floor
	mov x1, #100
	mov x2, #50
	bl standar_cloud
	
	ldr x0, =second_buffer
	bl refresh_framebuffer
	

   //---------------------------------------------------------------
   // Infinite Loop
 
InfLoop:
	b InfLoop

 