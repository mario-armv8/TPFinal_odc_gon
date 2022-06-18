.ifndef engine_s

.include "data.s"
.include "draw_objects.s"

/*
	Esta sección se encarga de las cinemáticas
 */


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
    Las tres funciones modifican los arreglos de posiciones. Del piso, los pipes, nubes y cajas 
	Cada una de ellas parametrizables para que se puedan mover a distintas velocidades
	Las funciones agregan nuevos elementos a una distancia que se puede modificar, lo que hace que no termine
	No toman argumentos
 */
move_floor:
	sub sp, sp, #24
	str lr, [sp, #16]
	str x1, [sp, #8]
	str x2, [sp]
	ldr x1, floorSpeed
	adr x2, first_floor_position
	ldr x13, floor_b_size
	ldr x14, neg_floor_size
	mov x21, x3
	ldr x3, [x2] //x3 = posición en x primer ladrillo del piso
	sub x3, x3, x1 //resto la velocidad
	cmp x3, x14 //chequeo si el primer ladrillo sale completamente de la pantalla
	b.ge end_move_floor
	//si el ladrillo ya salió de la pantalla, actualizo la posición del primer ladrillo a la del siguiente
	add x3, x3, x13
	end_move_floor:
		str x3, [x2]
		mov x3, x21
		ldur lr, [sp, #16]
		ldur x1, [sp, #8]
		ldur x2, [sp]
		add sp, sp, #24
		br lr

move_bricks:
	sub sp, sp, #24
	str lr, [sp, #16]
	str x1, [sp, #8]
	str x2, [sp]
	ldr x1, bricksSpeed
	adr x2, array_of_bricks
	ldr x14, neg_brick_size 
	mov x27, x3
	ldr x13, brick_array_size
	sub x13, x13, #1 //x13 = array_size - 1
	ldr x3, [x2] //x3 = posición en x primer caja
	sub x3, x3, x1 //resto la velocidad
	cmp x3, x14 //chequeo si la primer caja sale completamente de la pantalla
	b.ge update_position //si no salió de la pantalla, actualizo todas las posiciones
	//si la caja ya salió de la pantalla, corro todas las posiciones a la derecha y agrego una nueva al final
	mov x15, #1
	switch_boxes_loop:
		cmp x15, x13 
		b.gt end_switch
		ldr x3, [x2, x15, lsl #3]  //leo el elemento n+1
		sub x15, x15, #1
		str x3, [x2, x15, lsl #3] //guardo el elemento en n
		add x15, x15, #2
		b switch_boxes_loop
	end_switch:
		ldr x16, new_brick_distance //distancia a colocar el próximo elemento (respecto al último)
		add x3, x3, x16
		sub x15, x15, #1
		str x3, [x2, x15, lsl #3] //guardo pos de nuevo elemento
	update_position:
		mov x15, #0
		update_position_loop:
			cmp x15, x13
			b.gt end_move_bricks
			ldr x3, [x2, x15, lsl #3]
			sub x3, x3, x1
			str x3, [x2, x15, lsl #3]
			add x15, x15, #1
			b update_position_loop
	end_move_bricks:
		mov x3, x27
		ldur lr, [sp, #16]
		ldur x1, [sp, #8]
		ldur x2, [sp]
		add sp, sp, #24
		br lr

move_pipes:
	sub sp, sp, #32
	str x8, [sp, #24]
	str lr, [sp, #16]
	str x1, [sp, #8]
	str x2, [sp]
	ldr x1, pipesSpeed
	adr x2, array_of_pipes
	ldr x14, neg_pipe_size 
	mov x27, x3
	ldr x13, pipes_array_size
	sub x13, x13, #1 //x13 = array_size - 1
	ldr x3, [x2] //x3 = posición en x primer pipe
	sub x3, x3, x1 //resto la velocidad
	cmp x3, x14 //chequeo si el primer pipe sale completamente de la pantalla
	b.ge update_position_p //si no salió de la pantalla, actualizo todas las posiciones
	//si el pipe ya salió de la pantalla, corro todas las posiciones a la derecha y agrego una nueva al final
	mov x8, #1
	switch_pipes_loop:
		cmp x8, x13 
		b.gt end_switch_p
		ldr x3, [x2, x8, lsl #3]  //leo el elemento n+1
		sub x8, x8, #1
		str x3, [x2, x15, lsl #3] //guardo el elemento en n
		add x8, x8, #2
		b switch_pipes_loop
	end_switch_p:
		ldr x16, new_pipe_distance //distancia a colocar el próximo elemento (respecto al último)
		add x3, x3, x16
		sub x8, x8, #1
		str x3, [x2, x8, lsl #3] //guardo pos de nuevo elemento
	update_position_p:
		mov x8, #0
		update_position_p_loop:
			cmp x8, x13
			b.gt end_move_pipes
			ldr x3, [x2, x8, lsl #3]
			sub x3, x3, x1
			str x3, [x2, x8, lsl #3]
			add x8, x8, #1
			b update_position_p_loop
	end_move_pipes:
		mov x3, x27
		ldur x8, [sp, #24]
		ldur lr, [sp, #16]
		ldur x1, [sp, #8]
		ldur x2, [sp]
		add sp, sp, #32
		br lr

move_clouds:
	sub sp, sp, #24
	str lr, [sp, #16]
	str x1, [sp, #8]
	str x2, [sp]
	ldr x1, cloudsSpeed
	adr x2, array_of_clouds
	ldr x14, neg_cloud_size
	mov x27, x3
	ldr x13, cloud_array_size
	sub x13, x13, #1 //x13 = array_size - 1
	ldr x3, [x2] //x3 = posición en x primera nube
	sub x3, x3, x1 //resto la velocidad
	cmp x3, x14 //chequeo si la primer nube sale completamente de la pantalla
	b.ge update_position_c
	//si la nube ya salió de la pantalla, corro todas las posiciones a la derecha y agrego una nueva al final
	mov x15, #1
	switch_clouds_loop:
		cmp x15, x13 
		b.gt end_switch_c
		ldr x3, [x2, x15, lsl #3]  //leo el elemento n+1
		sub x15, x15, #1
		str x3, [x2, x15, lsl #3] //guardo el elemento en n
		add x15, x15, #2
		b switch_clouds_loop
	end_switch_c:
		ldr x16, new_cloud_distance //distancia a colocar el próximo elemento (respecto al último)
		add x3, x3, x16
		sub x15, x15, #1
		str x3, [x2, x15, lsl #3] //guardo pos de nuevo elemento
	update_position_c:
		mov x15, #0
		update_position_c_loop:
			cmp x15, x13
			b.gt end_move_clouds
			ldr x3, [x2, x15, lsl #3]
			sub x3, x3, x1
			str x3, [x2, x15, lsl #3]
			add x15, x15, #1
			b update_position_c_loop
	end_move_clouds:
		mov x3, x27
		ldur lr, [sp, #16]
		ldur x1, [sp, #8]
		ldur x2, [sp]
		add sp, sp, #24
		br lr

move_fungi:
	sub sp, sp, #40
	str x5, [sp, #32]
	str x4, [sp, #24]
	str lr, [sp, #16]
	str x1, [sp, #8]
	str x2, [sp]
	ldr x1, fungiXSpeed
	ldr x5, fungiYSpeed
	adr x2, fungi_x_pos
	adr x4, fungi_y_pos
	mov x27, x3
	ldr x25, brick_size
	ldr x26, floor_heigh
	sub x26, x26, x25
	update_position_f:
		ldr x3, [x2]
		sub x3, x3, x1
		str x3, [x2]
		ldr x3, [x4]
		cmp x3, x26
		b.ge end_move_fungi
		sub x3, x3, x5
		str x3, [x4]
	end_move_fungi:
		mov x3, x27
		ldur x5, [sp, #32]
		ldur x4, [sp, #24]
		ldur lr, [sp, #16]
		ldur x1, [sp, #8]
		ldur x2, [sp]
		add sp, sp, #40
		br lr

delay:
	ldr x25, delay_amount
	delay_loop:
		cmp x25, xzr
		b.lt end_delay_loop
		sub x25, x25, #1
		b delay_loop
	end_delay_loop:
		br lr

	
.endif
