 
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

mov x15, #50
mov x16, #100
bl draw_pipe
bl refresh_framebuffer
	
loop_principal:
	bl draw_backround
	bl draw_clouds
	bl draw_bricks
	bl draw_floor
	//bl draw_pipe
	bl draw_fungi
	bl refresh_framebuffer
	bl move_floor
	bl move_bricks
	bl move_clouds
	bl move_fungi
	bl delay
	b loop_principal
	

   //---------------------------------------------------------------
   // Infinite Loop
 
InfLoop:
	b InfLoop

 