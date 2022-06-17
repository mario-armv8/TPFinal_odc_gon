.ifndef engine_s

.include "data.s"
.include "draw_objects.s"

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

/*
    Mueve el piso 
 */

.endif
