
.ifndef draw_objects_s
.equ draw_objects_s, 0

.include "data.s"

/*
   X0 : dirección base del FB
   X1 : coordenada x del pixel
   X2 : coordenada y del pixel
   W3 : color
   utiliza x27
   */
draw_pixel:
	mov x27, SCREEN_WIDTH
	cmp x1, x27 //veo si el x está en el rango
	b.hs skip
	cmp x2, SCREEN_HEIGH //veo si el y está en rango
	b.hs skip
	madd x27, x2, x27, x1   //x17 = x + (y*screen_width)
	str w3, [x0, x27, lsl #2] //guardo color(w3) en x0 + 4*[x + (y*screen_width)]
	skip:
	br lr //return

/*
   Dibujar linea horizontal (draw_hline)
   Dibujar linea vertical (draw_vline) usan los mismos parámetros:
   x0 : dirección base del FB
   x1 : x inicial linea
   x2 : y inicial linea
   w3 : color
   x4 : largo en píxeles */
draw_hline:
	sub sp, sp, #24
	str lr, [sp, #16]   //guardo direc de retorno
	str x1, [sp, #8]    //guardo x inicial
	str x4, [sp]    //guardo ancho
	draw_hline_loop:
	cmp x4, xzr   //pixeles que faltan pintar
	b.le end_hline_loop //si llega a 0 termino el loop
	bl draw_pixel
	sub x4, x4, #1
	add x1, x1, #1
	b draw_hline_loop
	end_hline_loop:
		ldur x4, [sp]   //recupero ancho
		ldur x1, [sp, #8]
		ldur lr, [sp, #16] //recupero direc de salto
		add sp, sp, #24
		br lr   //return
 
/*
   Dibujar rectángulo:
   x0: dirección base del FB
   x1: x esquina izquierda superior
   x2: y esquina izquierda superior
   w3: color
   x4: ancho en píxeles
   x5: alto en píxeles
*/
draw_rectangle:
	sub sp, sp, #24
	str lr, [sp, #16]
	str x2, [sp, #8]
	str x5, [sp]
	draw_rectangle_loop:
		cmp x5, xzr
		b.lt draw_rectangle_loop_end
		bl draw_hline
		add x2, x2, #1 //aumento el y de la linea que se va a pintar
		sub x5, x5, #1 //decremento la cantidad de lineas por pintar
		b draw_rectangle_loop
	draw_rectangle_loop_end:
		ldur x5, [sp]
		ldur x2, [sp, #8]
		ldur lr, [sp, #16]
		add sp, sp, #24
		br lr
 
/*  Dibujar círculo
   usando la fórmula del círculo en el plano (x-a)^2 +(y-b)^2 <= r^2
   donde a (coord x centro), b (coord y centro), r (radio)
   despejando: sqrt[(x-a)^2 +(y-b)^2]<=r
       x0 : dirección FB
       x1 : coordenada x centro
       x2 : coordenada y centro
       x3 : color
       x4 : radio*/
draw_circle:
	sub sp, sp, #16
	str lr, [sp, #8]
	str x5, [sp]
	mul x5, x4, x4  // x5 = r^2
	mov x9, x1 // guardo x centro
	mov x10, x2 // guardo y centro
	add x11, x1, x4 // x max = x centro + r
	add x12, X2, x4 // y max = y centro + r
	sub x1, x1, x4 // x inicial

	cicle_loop_x:
		cmp x1, x11  //comparo x con xmax
		b.ge end_circle_loop_x
		sub x2, x10, x4 // reinicio y a posición inicial

		circle_loop_y: //avanza en y
			cmp x2, x12
			b.ge end_circle_loop_y
			sub x13, x1, x9 // (x-a)
			smull x13, w13, w13 // (x-a)^2
			sub x14, x2, x10 // (y-b)
			smull x14, w14, w14 // (y-b)^2
			add x13, x13, x14 // (x-a)^2 + (y-b)^2
			cmp x13, x5 // comparo con r^2
			b.ge skip_pixel
			bl draw_pixel
			
			skip_pixel:
			add x2, x2, #1 //avanzo y
			b circle_loop_y
      
    	end_circle_loop_y:
			add x1, x1, #1 //avanzo x
			b cicle_loop_x
	end_circle_loop_x:
		mov x1, x9
		mov x2, x10
		ldur lr, [sp, #8]
		ldur x5, [sp]
		add sp, sp, #16
		br lr
 
/*
   Dibuja bloques cuadrados de ladrillos
   x1: x esquina izquierda sup
   x2: y esquina izquiera sup
   w3: color
*/
complex_brick:
	sub sp, sp, #24
	str lr, [sp, #16]
	str x4, [sp, #8]
	str x5, [sp]

	mov x17, x1 //guardo valores iniciales
	mov x18, x2
	bl half_brick
	mov x5, SPACE_BRICKS
	mov x4, QUARTER_SQUARES_SIZE
	lsl x4, x4, #2
	ldr w3, colorGrey2
	bl draw_rectangle
	mov x5, QUARTER_SQUARES_SIZE
	lsl x5, x5, #1
	add x2, x2, x5
	bl half_brick

	ldur lr, [sp, #16]
	ldur x4, [sp, #8]
	ldur x5, [sp]
	add sp, sp, #24
	br lr

half_brick:
	sub sp, sp, #24
	str lr, [sp, #16]
	str x4, [sp, #8]
	str x5, [sp]

	mov x5, QUARTER_SQUARES_SIZE
	lsl x5, x5, #1
	lsl x4, x5, #1
	ldr w3, colorBlack
	//fondo negro
	bl draw_rectangle
	ldr w3, colorBrick
	mov x19, SPACE_BRICKS //1 espacio
	lsl x22, x19, #1 // 2 espacios
	sub x4, x4, x22
	mov x21, x4  //guardo x total menos espacios
	lsr x4, x4, #1
	sub x5, x5, x22
	lsr x5, x5, #1
	bl draw_rectangle
	add x1, x1, x4
	add x1, x19, x1
	bl draw_rectangle

	mov x1, x17
	add x2, x19, x2
	add x2, x2, x5
	mov x22, x5
	lsr x4, x4, #1
	bl draw_rectangle
	add x1, x19, x1
	add x1, x1, x4
	bl draw_rectangle
	add x1, x4, x1
	bl draw_rectangle
	add x1, x1, x19
	add x1, x1, x4
	bl draw_rectangle
	mov x1, x17
	mov x2, x18
	ldur lr, [sp, #16]
	ldur x4, [sp, #8]
	ldur x5, [sp]
	add sp, sp, #24
	
	br lr
 
question_mark:
	sub sp, sp, #24
	str lr, [sp, #16]
	str x17, [sp, #8]
	str x18, [sp]
	mov x23, QUARTER_SQUARES_SIZE
	lsr x23, x23, #1 //2 cuadrados
	lsr x24, x23, #1 //1 cuadrado
	mov x17, x1
	mov x18, x2
	add x1, x1, x23 
	add x4, x23, x24
	mov x5, x24
	bl draw_rectangle
	sub x1, x1, x24
	add x2, x2, x24
	mov x4, x24
	mov x5, x23
	bl draw_rectangle
	add x26, x23, x23
	add x1, x1, x26
	add x5, x5, x24
	bl draw_rectangle
	sub x1, x1, x24
	add x2, x2, x23
	mov x4, x23
	mov x5, x24
	bl draw_rectangle
	sub x1, x1, x24
	add x2, x2, x24
	mov x4, x24
	bl draw_rectangle
	add x2, x2, x23
	bl draw_rectangle

	mov x1, x17
	mov x2, x18
	ldur lr, [sp, #16]
	ldur x17, [sp, #8]
	ldur x18, [sp]
	add sp, sp, #24
	br lr
 
 
random_box:
	sub sp, sp, #24
	str lr, [sp, #16]
	str x4, [sp, #8]
	str x5, [sp]

	mov x17, x1
	mov x18, x2
	mov x4, QUARTER_SQUARES_SIZE
	lsl x4, x4, #2
	sub x4, x4, SPACE_BRICKS
	mov x5, x4
	ldr w3, colorBrick
	bl draw_rectangle
	add x1, x1, SPACE_BRICKS
	add x2, x2, SPACE_BRICKS
	ldr w3, colorBlack
	bl draw_rectangle
	sub x4, x4, SPACE_BRICKS
	sub x5, x5, SPACE_BRICKS
	ldr w3, colorLBrown
	bl draw_rectangle

	mov x13, QUARTER_SQUARES_SIZE
	lsr x13, x13, #3
	add x1, x17, QUARTER_SQUARES_SIZE
	add x2, x18, QUARTER_SQUARES_SIZE
	add x1, x1, x13
	add x2, x2, x13
	ldr w3, colorBlack
	bl question_mark
	sub x1, x1, x13
	sub x1, x1, x13
	sub x2, x2, x13
	ldr w3, colorBrick
	bl question_mark

	mov x1, x17
	mov x2, x18
	ldr w3, colorBlack
	mov x4, SPACE_BRICKS
	mov x5, SPACE_BRICKS
	lsl x13, x5, #1 //x13 = 2xSPACE_B
	add x1, x1, x13
	add x2, x2, x13
	bl draw_rectangle
	mov x14, QUARTER_SQUARES_SIZE
	lsl x14, x14, #2 //x14 = 4xQUARTER
	add x1, x17, x14
	add x15, x4, x13
	sub x1, x1, x15
	bl draw_rectangle
	mov x1, x17
	add x1, x13, x1
	add x2, x18, x14
	sub x2, x2, x15
	bl draw_rectangle
	add x1, x17, x14
	sub x1, x1, x15
	bl draw_rectangle
	mov x1, x17
	mov x2, x18
	ldur lr, [sp, #16]
	ldur x4, [sp, #8]
	ldur x5, [sp]
	add sp, sp, #24
	br lr
  
brown_box:
	sub sp, sp, #24
	str lr, [sp, #16]
	str x4, [sp, #8]
	str x5, [sp]
	mov x17, x1
	mov x18, x2
	mov x15, QUARTER_SQUARES_SIZE //x15 = quarter_square
	ldr w3, colorBlack
	//detalle superior
	add x1, x1, SPACE_BRICKS
	lsl x4, x15, #2
	sub x4, x4, SPACE_BRICKS
	sub x4, x4, SPACE_BRICKS
	mov x5, SPACE_BRICKS
	bl draw_rectangle
	//detalle inferior
	lsl x13, x15, #2
	sub x13, x13, SPACE_BRICKS
	add x2, x2, x13
	bl draw_rectangle
	//fondo negro
	mov x1, x17
	mov x2, x18
	add x2, x2, SPACE_BRICKS
	lsl x4, x15, #2
	lsl x5,x15, #2
	sub x5, x5, SPACE_BRICKS
	sub x5, x5, SPACE_BRICKS
	bl draw_rectangle
	add x1, x1, SPACE_BRICKS
	mov x4, x5
	ldr w3, colorBrick
	bl draw_rectangle

	mov x1, x17
	mov x2, x18
	ldr w3, colorBlack
	mov x4, SPACE_BRICKS
	mov x5, SPACE_BRICKS
	lsl x13, x5, #1 //x13 = 2xSPACE_B
	add x1, x1, x13
	add x2, x2, x13
	bl draw_rectangle
	//puntos negros
	mov x14, QUARTER_SQUARES_SIZE
	lsl x14, x14, #2 //x14 = 4xQUARTER
	add x1, x17, x14
	add x15, x4, x13
	sub x1, x1, x15
	bl draw_rectangle
	mov x1, x17
	add x1, x13, x1
	add x2, x18, x14
	sub x2, x2, x15
	bl draw_rectangle
	add x1, x17, x14
	sub x1, x1, x15
	bl draw_rectangle

	mov x1, x17
	mov x2, x18
	ldur lr, [sp, #16]
	ldur x4, [sp, #8]
	ldur x5, [sp]
	add sp, sp, #24
	br lr
 
/*  
   Pinta un conjunto de círculos parametrizables, para que la figura final sea deformable
   Se usa para construir otras figuras como nubes y arbustos
   x1: x inicial
   x2 : y inicial
   x21 : factor de estiramiento en x
   x22 : factor de estiramiento en y
   x23 : radio de circunferencia promedio en píxeles
   w24 : color ppal
*/
cloud_1:
	mov x17, x1
	mov x18, x2
	sub sp, sp, #16
	str lr, [sp, #8]
	str x4, [sp]

	mov x25, #4
	//ciculos supperiores
	loop_circles1:
		cbz x25, end_circles1
		bl draw_circle
		add x1, x1, CLOUD_FACTOR_X
		add x4, x4, CLOUD_FACTOR_Y
		sub x2, x2, CLOUD_FACTOR_Y
		sub x25, x25, #1
		b loop_circles1
	end_circles1:
		add x1, x17, CLOUD_FACTOR_X
		sub x2, x18, CLOUD_FACTOR_Y
		sub x2, x2, CLOUD_FACTOR_Y
		sub x4, x4, CLOUD_FACTOR_Y
		sub x2, x2, CLOUD_FACTOR_Y
		bl draw_circle
		
		add x1, x1, CLOUD_FACTOR_X
		add x2, x2, CLOUD_FACTOR_Y
		add x2, x2, CLOUD_FACTOR_Y
		bl draw_circle
		add x1, x1, CLOUD_FACTOR_X
		add x1, x1, CLOUD_FACTOR_X
		sub x2, x2, CLOUD_FACTOR_Y
		bl draw_circle

		add x4, x4, CLOUD_FACTOR_Y
		mov x25, #3
		sub x4, x4, CLOUD_FACTOR_Y
		loop_circles2:
			cbz x25, end_circles2
			bl draw_circle
			add x1, x1, CLOUD_FACTOR_X
			sub x4, x4, CLOUD_FACTOR_Y
			add x2, x2, CLOUD_FACTOR_Y
			sub x25, x25, #1
			b loop_circles2
		end_circles2:
		mov x1, x17
		mov x2, x18

		ldur lr, [sp, #8]
		ldur x4, [sp]
		add sp, sp, #16
		br lr
 
/*
    Agrega una segunda y detalles a cloud_1
    Se utiliza para crear otras figuras como nubes y arbustos
   x1: x inicial
   x2: y inicial
   w3: color principal
   x4: tamaño circunferencia inicial
   x5: factor de estiramiento en x
   x6: factor de estiramiento en y
   w7: color secundario
   w8: color detalle
 
*/
complex_cloud:
	sub sp, sp, #48
	str lr, [sp, #40]
	str x1, [sp, #32]
	str x2, [sp, #24]
	str x4, [sp, #16]
	str x8, [sp, #8]
	str w3, [sp]
	mov w3, w7
	bl cloud_1
	ldr w3, colorGrey2
	sub x4, x4, SPACE_BRICKS
	bl cloud_1
	sub x4, x4, SPACE_BRICKS
	sub x4, x4, SPACE_BRICKS
	mov w3, w8
	bl cloud_1
	sub x2, x2, SPACE_BRICKS
	ldur w3, [sp]
	bl cloud_1

	ldur lr, [sp, #40]
	ldur x1, [sp, #32]
	ldur x2, [sp, #24]
	ldur x4, [sp, #16]
	ldur x8, [sp, #8]
	add sp, sp, #48
	br lr

/*
    Dibuja una nube estándar 
    parámetros  x1: x inicial, x2: y inicial
 */
standar_cloud:
	sub sp, sp, #48
	str lr, [sp, #40]
	str x4, [sp, #32]
	str x5, [sp, #24]
	str x6, [sp, #16]
	str x7, [sp, #8]
	str x8, [sp]
	mov w22, w3
	ldr w3, colorGrey2
	mov x4, CLOUD_CIRCUNF
	mov x5, CLOUD_FACTOR_X
	mov x6, CLOUD_FACTOR_Y
	ldr w7, colorBlack
	ldr w8, colorBlueSky
	bl complex_cloud
	mov w3, w22
	ldur lr, [sp, #40]
	ldur x4, [sp, #32]
	ldur x5, [sp, #24]
	ldur x6, [sp, #16]
	ldur x7, [sp, #8]
	ldur x8, [sp]
	add sp, sp, #48
	br lr

/*
    Dibuja honguito parametrizable en las coordenadas (x1,x2) (esquina superior derecha)
 */
fungi_shape:
	sub sp, sp, #32
	str lr, [sp, #24]
	str x4, [sp, #16]
	str x5, [sp, #8]
	str x3, [sp]

	mov x17, x1 //guardo x e y iniciales
	mov x18, x2
	mov x19, FUNGI_SIZE
	lsr x20, x19, #1 // guardo x19 = quarter, x20 = quarter/2 y x21 = 2*quarter
	lsl x21, x19, #1
	lsr x25, x19, #2
	//detalle circular izquierdo
	add x2, x2, x21
	add x2, x2, x19
	add x1, x1, x20
	mov x4, x20
	ldr w3, colorRed
	bl draw_circle
	//tronco hongo
	add x1, x1, x20
	mov x4, x21
	mov x5, x19
	ldr w3, colorGrey2
	bl draw_rectangle
	//detalle tronco
	ldr w3, colorGrey1
	add x1, x1, FUNGI_SIZE
	add x1, x1, x25
	add x2, x2, x20
	mov x4, x25
	mov x5, x20
	bl draw_rectangle
	//detalle circular derecho
	mov x1, x17
	mov x2, x18
	add x1, x1, FUNGI_SIZE
	add x2, x2, x21
	add x2, x2, FUNGI_SIZE
	add x1, x1, x21
	add x1, x1, x20
	mov x4, x20
	ldr w3, colorRed
	bl draw_circle
	//parte superior hongo
	mov x1, x17
	mov x2, x18
	add x2, x2, x21
	mov x22, FUNGI_DETAIL
	lsl x4, x19, #2
	mov x5, FUNGI_SIZE
	loop_fungi:                    
		bl draw_rectangle
		cbz x22, end_fungi_loop
		sub x22, x22, #1
		sub x2, x2, FUNGI_SPACE
		sub x4, x4, FUNGI_SPACE
		sub x4, x4, FUNGI_SPACE
		add x1, x1, FUNGI_SPACE
		b loop_fungi
	end_fungi_loop:
	//detalles superiores
	ldr w3, colorGrey2
	lsr x4, x4, #1
	add x1, x1, x4
	mov x5, FUNGI_SPACE
	add x5, x5, FUNGI_SPACE
	add x5, x5, FUNGI_SPACE
	bl draw_rectangle
	//detalles finos
	add x2, x2, FUNGI_SPACE
	mov x5, FUNGI_SPACE
	add x5, x5, FUNGI_SPACE
	add x4, x4, FUNGI_SPACE
	bl draw_rectangle
	ldr w3, colorGrey2
	mov x1, x17
	mov x2, x18
	add x2, x2, x21
	add x1, x1, x20
	mov x4, FUNGI_SIZE
	mov x5, x20
	bl draw_rectangle
	//cruz sobre el hongo
	add x1, x1, x25
	sub x2, x2, x25
	mov x5, FUNGI_SIZE
	mov x4, x20
	bl draw_rectangle
	//detalles oscuros
	mov x1, x17
	mov x2, x18
	add x2, x2, x21
	add x2, x2, x20
	add x2, x2, x20
	add x1, x1, x20
	mov x4, x20
	add x4, x4, x25
	mov x5, x20
	ldr w3, colorDRed
	bl draw_rectangle
	add x1, x1, x21
	add x1, x1, x25
	bl draw_rectangle

	mov x1, x17
	mov x2, x18
	ldur lr, [sp, #24]
	ldur x4, [sp, #16]
	ldur x5, [sp, #8]
	ldur x3, [sp]
	add sp, sp, #32
	br lr

/*
Dibuja un ladrillo del suelo de tamaño modificable
parámetros: x1 y x2, coordenadas de la esquina superior izquierda x e y respectivamente
 */
floor_brick:
	mov x17, x1
	mov x18, x2
	sub sp, sp, #24
	str lr, [sp, #16]
	str x4, [sp, #8]
	str x5, [sp]

	mov x19, FLOOR_SIZE
	mov x20, FLOOR_SPACE
	//piso
	add x4, xzr, x19, lsl #2
	add x5, xzr, x19, lsl #2
	ldr w3, colorGrey2
	bl draw_rectangle
	add x1, x1, x19, lsr #2
	add x2, x2, x19, lsr #2
	sub x4, x4, x19, lsr #1
	sub x5, x5, x19, lsr #1
	ldr w3, colorBrick
	bl draw_rectangle
	//detalles piso
	mov x1, x17
	mov x2, x18
	add x2, x2, x19, lsl #1
	add x2, x2, x19, lsr #1
	ldr w3, colorBlack //primero negro
	add x4, xzr, x19, lsr #1
	add x5, xzr, x19, lsr #2
	bl draw_rectangle
	add x2, x2, x5
	ldr w3, colorGrey2 //primero blanco
	bl draw_rectangle
	add x1, x1, x4
	ldr w3, colorBlack //segundo negro
	bl draw_rectangle
	add x2, x2, x5
	ldr w3, colorGrey2
	bl draw_rectangle
	add x1, x1, x4
	lsl x4, x4, #1
	ldr w3, colorBlack
	bl draw_rectangle
	add x2, x2, x5
	ldr w3, colorGrey2
	bl draw_rectangle
	add x1, x1, x19, lsr #1
	add x1, x1, x19, lsr #2
	mov x4, x5
	add x5, xzr, x19, lsr #1
	ldr w3, colorBlack
	bl draw_rectangle
	sub x1, x1, x19
	sub x1, x1, x19, lsr #2
	add x2, x2, x19, lsr #1
	add x5, xzr, x19, lsr #2
	add x4, xzr, x19
	add x4, x4, x19, lsr #1
	bl draw_rectangle
	//detalles centrales
	mov x1, x17
	mov x2, x18
	add x1, x1, x19, lsl #1
	add x1, x1, x19, lsr #1
	add x4, xzr, x19, lsr #1
	add x5, xzr, x19, lsl #1
	add x5, x5, x19, lsr #1
	ldr w3, colorGrey2
	bl draw_rectangle
	add x4, xzr, x19, lsr #2
	ldr w3, colorBlack
	bl draw_rectangle
	sub x1, x1, x19, lsr #1
	add x2, x2, x19, lsl #1
	add x2, x2, x19, lsr #1
	add x4, xzr, x19, lsr #1
	add x5, xzr, x19, lsr #1
	ldr w3, colorGrey2
	bl draw_rectangle
	add x4, xzr, x19, lsr #2
	ldr w3, colorBlack
	bl draw_rectangle
	//detalles lado izquierdo
	mov x1, x17
	mov x2, x18
	add x1, x1, x19, lsl #1
	add x1, x1, x19
	add x1, x1, x19, lsr #1
	add x2, x2, x19, lsr #2
	add x5, xzr, x19, lsl #1
	add x5, x5, x19
	bl draw_rectangle
	sub x1, x1, x19, lsr #2
	add x2, x2, x19, lsl #1
	add x2, x2, x19
	add x4, xzr, x19, lsr #1
	add x5, xzr, x19, lsr #2
	bl draw_rectangle
	mov x4, x5
	add x5, x5, x19, lsr #2 //
	bl draw_rectangle
	sub x1, x1, x19
	add x1, x1, x19, lsr #2
	add x2, x2, x19, lsr #2
	bl draw_rectangle
	mov x4, x19
	add x5, xzr, x19, lsr #2
	bl draw_rectangle
	mov x1, x17
	mov x2, x18
	add x1, x1, x19, lsl #1
	add x1, x1, x19
	add x2, x2, x19
	add x4, xzr, x19, lsr #1
	mov x5, x4
	ldr w3, colorGrey2
	bl draw_rectangle
	add x5, xzr, x19, lsr #2
	ldr w3, colorBlack
	bl draw_rectangle
	//detalles color ladrillo
	add x1, x1, x4
	add x2, x2, x19, lsl #1
	add x2, x2, x19, lsr #1
	mov x5, x4
	ldr w3, colorBrick
	bl draw_rectangle
	mov x1, x17
	mov x2, x18
	add x2, x2, x19, lsl #2
	sub x2, x2, x19, lsr #1
	bl draw_rectangle
	mov x2, x18
	add x5, xzr, x19, lsr #2
	bl draw_rectangle
	add x2, x2, x19
	mov x4, x5
	bl draw_rectangle
	mov x2, x18
	add x1, x1, x19, lsl #2
	sub x1, x1, x19, lsr #1
	add x4, x4, x4
	bl draw_rectangle
	mov x1, x17
	mov x2, x18

	ldur lr, [sp, #16]
	ldur x4, [sp, #8]
	ldur x5, [sp]
	add sp, sp, #24
	br lr

double_floor_brick:
	sub sp, sp, #16
	str lr, [sp, #8]
	str x4, [sp]
	ldr x4, floor_size
	bl floor_brick
	lsl x4, x4, #2
	add x2, x2, x4
	bl floor_brick
	sub x2, x2, x4
	ldur lr, [sp, #8]
	ldur x4, [sp]
	add sp, sp, #16
	br lr
	

draw_backround:
	sub sp, sp, #40
	str lr, [sp, #32]
	str x1, [sp, #24]
	str x2, [sp, #16]
	str x4, [sp, #8]
	str x5, [sp]
	mov x21, x3
	ldr x3, colorBlueSky
	mov x1, #0
	mov x2, #0
	mov x4, SCREEN_WIDTH
	mov x5, SCREEN_HEIGH
	bl draw_rectangle
	ldur lr, [sp, #32]
	ldur x1, [sp, #24]
	ldur x2, [sp, #16]
	ldur x4, [sp, #8]
	ldur x5, [sp]
	add sp, sp, #40
	mov x3, x21
	br lr

/*
	Usa las posiciones del arreglo de bricks para pintarlos
 */
draw_bricks:
	sub sp, sp, #40
	str lr, [sp, #32]
	str x1, [sp, #24]
	str x2, [sp, #16]
	str x6, [sp, #8]
	str x7, [sp]
	ldr x6, =array_of_bricks
	ldr x7, brick_array_size
	sub x7, x7, #1
	ldr x2, brick_heigh
	draw_brick_loop:
		cmp x7, #0
		b.lt end_draw_brick_loop
		ldr x1, [x6, x7, lsl #3]
		bl mult_boxes
		sub x7, x7, #1
		b draw_brick_loop
	end_draw_brick_loop:
		ldur lr, [sp, #32]
		ldur x1, [sp, #24]
		ldur x2, [sp, #16]
		ldur x6, [sp, #8]
		ldur x7, [sp]
		add sp, sp, #40
		br lr

draw_floor:
	sub sp, sp, #40
	str lr, [sp, #32]
	str x1, [sp, #24]
	str x2, [sp, #16]
	str x6, [sp, #8]
	str x7, [sp]
	adr x6, first_floor_position
	ldr x7, floor_elements
	ldr x2, floor_heigh
	ldr x1, [x6]
	ldr x6, floor_b_size
	draw_floor_loop:
		cmp x7, #0
		b.lt end_draw_floor_loop
		bl double_floor_brick
		sub x7, x7, #1
		add x1, x1, x6
		b draw_floor_loop
	end_draw_floor_loop:
		ldur lr, [sp, #32]
		ldur x1, [sp, #24]
		ldur x2, [sp, #16]
		ldur x6, [sp, #8]
		ldur x7, [sp]
		add sp, sp, #40
		br lr

/*draw_pipes:
	sub sp, sp, #40
	str lr, [sp, #32]
	str x1, [sp, #24]
	str x2, [sp, #16]
	str x6, [sp, #8]
	str x7, [sp]
	ldr x6, =array_of_pipes
	ldr x7, pipes_array_size
	sub x7, x7, #1
	draw_pipe_loop:
		cmp x7, #0
		b.lt end_draw_pipe_loop
		ldr x15, [x6, x7, lsl #3]
		ldr x16, pipe_heigh
		bl draw_pipe
		sub x7, x7, #1
		b draw_pipe_loop
	end_draw_pipe_loop:
		ldur lr, [sp, #32]
		ldur x1, [sp, #24]
		ldur x2, [sp, #16]
		ldur x6, [sp, #8]
		ldur x7, [sp]
		add sp, sp, #40
		br lr*/

draw_clouds:
	sub sp, sp, #40
	str lr, [sp, #32]
	str x1, [sp, #24]
	str x2, [sp, #16]
	str x6, [sp, #8]
	str x7, [sp]
	ldr x6, =array_of_clouds
	ldr x7, cloud_array_size
	sub x7, x7, #1
	ldr x2, cloud_heigh
	draw_cloud_loop:
		cmp x7, #0
		b.lt end_draw_cloud_loop
		ldr x1, [x6, x7, lsl #3]
		bl standar_cloud
		sub x7, x7, #1
		b draw_cloud_loop
	end_draw_cloud_loop:
		ldur lr, [sp, #32]
		ldur x1, [sp, #24]
		ldur x2, [sp, #16]
		ldur x6, [sp, #8]
		ldur x7, [sp]
		add sp, sp, #40
		br lr

draw_fungi:
	sub sp, sp, #40
	str lr, [sp, #32]
	str x1, [sp, #24]
	str x2, [sp, #16]
	str x6, [sp, #8]
	str x7, [sp]
	ldr x6, =fungi_x_pos
	ldr x7, fungi_array_size
	sub x7, x7, #1
	ldr x2, fungi_y_pos
	ldr x1, [x6, x7, lsl #3]
	bl fungi_shape
		ldur lr, [sp, #32]
		ldur x1, [sp, #24]
		ldur x2, [sp, #16]
		ldur x6, [sp, #8]
		ldur x7, [sp]
		add sp, sp, #40
		br lr


/* Parametros:
    x15: x inferior izquierdo
    x16: y inferior izquierdo
    x6: if(x6 == 0) -> draw_mario_mov: 
        else        -> draw_mario_paso
    */
mario_movement:
    sub sp, sp, #32
    str lr, [sp, #24]
    str x15, [sp,#16]
    str x16, [sp,#8]
    str x6, [sp]

	cmp x6,1
	b.eq mario_pos_1
    b mario_pos_0
	
    mario_pos_1:
		sub x6,x6,1
		bl draw_mario_mov
        b end_loop_movement
	mario_pos_0:
		add x6,x6,1
		bl draw_mario_paso
		b end_loop_movement
	end_loop_movement:
        ldur lr, [sp, #24]
        ldur x15, [sp,#16]
        ldur x16, [sp,#8]
        ldur x6, [sp]
        add sp, sp, #32
        br lr
//////////////////

mult_boxes:
	sub sp, sp, #32
	str lr, [sp, #24]
	str x1, [sp, #16]
	str x2, [sp, #8]
	str x5, [sp]
	ldr x5,brick_size
	loop_mult_boxes:
		bl brown_box
		add x1,x1,x5
		bl random_box
		sub x2,x2,x5
		bl fungi_shape
		add x2,x2,x5
		add x1,x1,x5
		bl complex_brick

	ldur lr, [sp, #24]
	ldur x1, [sp, #16]
	ldur x2, [sp, #8]
	ldur x5, [sp]
	add sp, sp, #32
	br lr


/*
Parametros:
	x15: x esquina superior izquierda
	x16: y esquina superior izquierda
	*/

//TUBO
draw_pipe:
	sub sp, sp, #56
	str lr, [sp, #48]   //guardo direc de retorno
	str x15, [sp, #40]   //guardo x inicial
	str x16, [sp, #32]    	
	str x1, [sp, #24]    	
	str x2, [sp, #16]    	
	str x3, [sp, #8]    	
	str x9, [sp]     	 

	//Tubo arriba
	.equ ancho_tubo_arriba, ANCHO_TUBO_ARRIBA	// x = 90
	.equ altura_tubo_arriba, ALTURA_TUBO_ARRIBA	// y = 40
	bl get_pixel
	ldr w1,color_tubo
	mov x2,ancho_tubo_arriba
	mov x3,altura_tubo_arriba
	bl pintar_rectangulo

	//Tubo abajo
	.equ ancho_tubo_abajo, ANCHO_TUBO_ABAJO		// x = 80
	.equ altura_tubo_abajo, ALTURA_TUBO_ABAJO	// y = 60
	add x15,x15,5
	add x16,x16,40
	bl get_pixel
	mov x2,ancho_tubo_abajo
	mov x3,altura_tubo_abajo
	bl pintar_rectangulo

	//Sombreado interno
	.equ ancho_linea_fina, 2							// x = 2
	.equ ancho_linea_gruesa, 4							// x = 4
	.equ ancho_linea_gruesa_2, QUARTER_SQUARES_SIZE*2	// x = 20
	.equ ancho_linea_gruesa_3, QUARTER_SQUARES_SIZE+5	// x = 15
	.equ altura_linea_arriba, QUARTER_SQUARES_SIZE*3+5	// y = 35
	.equ altura_linea_abajo, QUARTER_SQUARES_SIZE*5-1		// y = 60
	.equ largo_linea_fina1, QUARTER_SQUARES_SIZE		// x = 10
	.equ largo_linea_fina2, QUARTER_SQUARES_SIZE*3	// x = 37
	
	sub x15,x15,5
	sub x16,x16,35
	bl get_pixel
	ldr w1,color_interno_tubo
	mov x2,largo_linea_fina1
	mov x3,ancho_linea_fina
	bl pintar_rectangulo
	
	add x15,x15,10
	bl get_pixel
	mov x2,ancho_linea_gruesa
	mov x3,altura_linea_arriba
	bl pintar_rectangulo

	add x15,x15,40
	bl get_pixel
	mov x2,largo_linea_fina2
	mov x3,ancho_linea_fina
	bl pintar_rectangulo

	bl get_pixel
	mov x2,ancho_linea_fina
	mov x3,altura_linea_arriba
	bl pintar_rectangulo
	
	add x15,x15,10
	bl get_pixel
	mov x2,ancho_linea_gruesa_2
	mov x3,altura_linea_arriba
	bl pintar_rectangulo
	
	sub x15,x15,45
	add x16,x16,35
	bl get_pixel
	mov x2,ancho_linea_gruesa
	mov x3,altura_linea_abajo
	bl pintar_rectangulo
	
	add x15,x15,38
	bl get_pixel
	mov x2,ancho_linea_fina
	mov x3,altura_linea_abajo
	bl pintar_rectangulo
	
	add x15,x15,9
	bl get_pixel
	mov x2,ancho_linea_gruesa_3
	mov x3,altura_linea_abajo
	bl pintar_rectangulo

	//Borde arriba
	.equ linea_arriba, 2
	sub x15,x15,62
	sub x16,x16,40
	bl get_pixel	
	ldr w1,black
	mov x2,ancho_tubo_arriba
	mov x3,linea_arriba
	bl pintar_rectangulo

	//Borde arriba laterales
	.equ linea_arriba_laterales, 2
	bl get_pixel
	mov x2,linea_arriba_laterales
	mov x3,altura_tubo_arriba
	bl pintar_rectangulo

	add x15,x15,88
	bl get_pixel	
	mov x2,linea_arriba_laterales
	mov x3,altura_tubo_arriba
	bl pintar_rectangulo

	//Borde abajo laterales
	.equ linea_arriba_laterales, 2
	sub x15,x15,83
	add x16,x16,40
	bl get_pixel	
	mov x2,linea_arriba_laterales
	mov x3,altura_tubo_abajo
	bl pintar_rectangulo

	add x15,x15,78
	bl get_pixel	
	mov x2,linea_arriba_laterales
	mov x3,altura_tubo_abajo
	bl pintar_rectangulo

	//Borde medio arriba
	.equ linea_medio_arriba, 2
	sub x15,x15,83
	sub x16,x16,2
	bl get_pixel	
	mov x2,ancho_tubo_arriba
	mov x3,linea_medio_arriba
	bl pintar_rectangulo
	
	//Borde medio abajo
	.equ linea_medio_abajo, 1
	add x15,x15,5
	add x16,x16,2
	bl get_pixel	
	mov x2,ancho_tubo_abajo
	mov x3,linea_medio_abajo
	bl pintar_rectangulo

	ldur lr, [sp, #48] 	//recupero direc de salto
	ldur x15, [sp, #40]
	ldur x16, [sp, #32]  	 //recupero y 
	ldur w1, [sp, #24]  	 //recupero y 
	ldur x2, [sp, #16]  	 //recupero y 
	ldur x3, [sp, #8]  	 //recupero y 
	ldur x9, [sp]  	 
	add sp, sp, #56
	br lr   			//return
////////////////////////////





/*
Parametros:
	x15: x esquina inferior izquierda
	x16: y esquina inferior izquierda
	*/

//MARIO ESTATICO
draw_mario:

	sub sp, sp, #56
	str lr, [sp, #48]   //guardo direc de retorno
	str x15, [sp, #40]   //guardo x inicial
	str x16, [sp, #32]    	
	str w1, [sp, #24]    	
	str x2, [sp, #16]    	
	str x3, [sp, #8]    	
	str x9, [sp]     	 


  //Botas
	.equ ancho_botas_suela, QUARTER_SQUARES_SIZE * 2 // x = 20
	.equ altura_botas_suela, 4						 // y = 4
	.equ ancho_botas, QUARTER_SQUARES_SIZE + 5		 // x = 15
	.equ altura_botas, 3							 // y = 3
	//izq
	bl get_pixel
	ldr w1,color_verde_oscu
	mov x2,ancho_botas_suela
	mov x3,altura_botas_suela
	bl pintar_rectangulo

	add x15,x15,5
	sub x16,x16,4
	bl get_pixel
	mov x2,ancho_botas
	mov x3,altura_botas
	bl pintar_rectangulo

	//der
	add x15,x15,35
	add x16,x16,4
	bl get_pixel
	mov x2,ancho_botas_suela
	mov x3,altura_botas_suela
	bl pintar_rectangulo
	
	sub x16,x16,4
	bl get_pixel
	mov x2,ancho_botas
	mov x3,altura_botas
	bl pintar_rectangulo

  //Traje
	.equ ancho_centro_traje, QUARTER_SQUARES_SIZE + 5 // x = 15
	.equ altura_centro_traje, QUARTER_SQUARES_SIZE	  // y = 10
	sub x15,x15,30
	sub x16,x16,11
	bl get_pixel
	ldr w1,red
	mov x2,ancho_centro_traje
	mov x3,altura_centro_traje
	bl pintar_rectangulo
	
	add x15,x15,25
	bl get_pixel
	mov x2,ancho_centro_traje
	mov x3,altura_centro_traje
	bl pintar_rectangulo

	.equ ancho_centro_traje_2, QUARTER_SQUARES_SIZE * 3 // x = 30
	.equ altura_centro_traje_2, QUARTER_SQUARES_SIZE	// y = 10
	sub x15,x15,20
	sub x16,x16,5
	bl get_pixel
	mov x2,ancho_centro_traje_2
	mov x3,altura_centro_traje_2
	bl pintar_rectangulo
	
	add x15,x15,1
	sub x16,x16,5
	bl get_pixel
	mov x2,4
	mov x3,altura_centro_traje_2
	bl pintar_rectangulo
	
	add x15,x15,25
	bl get_pixel
	mov x2,4
	mov x3,altura_centro_traje_2
	bl pintar_rectangulo

	.equ ancho_arriba_traje, QUARTER_SQUARES_SIZE 		// x = 10
	.equ altura_arriba_traje, QUARTER_SQUARES_SIZE * 2	// y = 20
	sub x15,x15,16
	sub x16,x16,5
	bl get_pixel
	mov x2,ancho_arriba_traje
	mov x3,altura_arriba_traje
	bl pintar_rectangulo

	.equ ancho_arriba_traje_2, QUARTER_SQUARES_SIZE * 3 - 6		// x = 24
	.equ altura_arriba_traje_2, QUARTER_SQUARES_SIZE - 5		// y = 5
	sub x15,x15,7
	bl get_pixel
	mov x2,ancho_arriba_traje_2
	mov x3,altura_arriba_traje_2
	bl pintar_rectangulo
	
	.equ ancho_tiras, QUARTER_SQUARES_SIZE - 6	// x = 4
	.equ altura_tiras, QUARTER_SQUARES_SIZE		// y = 10
	sub x16,x16,10
	bl get_pixel
	mov x2,ancho_tiras
	mov x3,altura_tiras
	bl pintar_rectangulo
	
	add x15,x15,20
	bl get_pixel
	mov x2,ancho_tiras
	mov x3,altura_tiras
	bl pintar_rectangulo

//Brazos
	.equ ancho_brazo, QUARTER_SQUARES_SIZE			// x = 10
	.equ altura_brazo, QUARTER_SQUARES_SIZE + 5		// y = 15
	//izq
	sub x15,x15,38
	add x16,x16,15
	bl get_pixel
	ldr w1,color_piel
	mov x2,ancho_brazo
	mov x3,altura_brazo
	bl pintar_rectangulo
	
	add x15,x15,20
	bl get_pixel
	ldr w1,white
	mov x2,4
	mov x3,4
	bl pintar_rectangulo

	//der
	add x15,x15,30
	bl get_pixel
	ldr w1,color_piel
	mov x2,ancho_brazo
	mov x3,altura_brazo
	bl pintar_rectangulo
	
	sub x15,x15,14
	bl get_pixel
	ldr w1,white
	mov x2,4
	mov x3,4
	bl pintar_rectangulo

//Pulgares
	.equ ancho_pulgar, QUARTER_SQUARES_SIZE - 5 	// x = 5
	.equ altura_pulgar, QUARTER_SQUARES_SIZE - 5	// y = 5
	//izq
	sub x15,x15,26
	add x16,x16,5
	bl get_pixel
	ldr w1,color_piel
	mov x2,ancho_pulgar
	mov x3,altura_pulgar
	bl pintar_rectangulo
	
	//der
	add x15,x15,35
	bl get_pixel
	mov x2,ancho_pulgar
	mov x3,altura_pulgar
	bl pintar_rectangulo

//Parte verde
	.equ ancho_verde, QUARTER_SQUARES_SIZE - 5		// x = 5
	.equ altura_verde, QUARTER_SQUARES_SIZE - 6		// y = 4

  //cerca pulgares
	//izq
	sub x15,x15,35
	sub x16,x16,5
	bl get_pixel
	ldr w1,color_verde_oscu
	mov x2,ancho_verde
	mov x3,altura_verde
	bl pintar_rectangulo
	
	//der
	add x15,x15,35
	bl get_pixel
	mov x2,ancho_verde
	mov x3,altura_verde
	bl pintar_rectangulo

  //cerca traje
	.equ ancho_verde, QUARTER_SQUARES_SIZE *2 - 3	// x = 17
	.equ altura_verde, QUARTER_SQUARES_SIZE - 6		// y = 4

	//izq
	sub x15,x15,45
	sub x16,x16,5
	bl get_pixel
	mov x2,ancho_verde
	mov x3,altura_verde
	bl pintar_rectangulo

	//der	
	add x15,x15,43
	bl get_pixel
	mov x2,ancho_verde
	mov x3,altura_verde
	bl pintar_rectangulo

	//izq
	.equ ancho_verde_2, QUARTER_SQUARES_SIZE + 2	 // x = 12
	sub x15,x15,38
	sub x16,x16,5
	bl get_pixel
	mov x2,ancho_verde_2
	mov x3,altura_verde
	bl pintar_rectangulo
	
	add x15,x15,5
	sub x16,x16,5
	bl get_pixel
	mov x2,7
	mov x3,altura_verde
	bl pintar_rectangulo

	//der	
	add x15,x15,33
	add x16,x16,5
	bl get_pixel
	mov x2,ancho_verde_2
	mov x3,altura_verde
	bl pintar_rectangulo

	//centro 
	.equ ancho_centro_verde, QUARTER_SQUARES_SIZE + 4	 // x = 14
	.equ altura_centro_verde, QUARTER_SQUARES_SIZE - 1	 // y = 9
	sub x15,x15,20
	sub x16,x16,5
	bl get_pixel
	mov x2,ancho_centro_verde
	mov x3,altura_centro_verde
	bl pintar_rectangulo

//Cabeza
	//centro
	.equ ancho_centro_cabeza, QUARTER_SQUARES_SIZE * 2 + 2	 // x = 22
	.equ altura_centro_cabeza, QUARTER_SQUARES_SIZE 	 	 // x = 10
	sub x15,x15,8
	sub x16,x16,10
	bl get_pixel
	ldr w1, color_piel
	mov x2,ancho_centro_cabeza
	mov x3,altura_centro_cabeza
	bl pintar_rectangulo

	.equ ancho_menton, QUARTER_SQUARES_SIZE 	  // x = 10
	.equ altura_menton, QUARTER_SQUARES_SIZE - 5  // y = 5
	add x15,x15,23
	add x16,x16,5
	bl get_pixel
	mov x2,ancho_menton
	mov x3,altura_menton
	bl pintar_rectangulo

	sub x15,x15,28
	sub x16,x16,20
	bl get_pixel
	mov x2,6
	mov x3,20
	bl pintar_rectangulo

	.equ ancho_centro_cabeza_2, QUARTER_SQUARES_SIZE + 6	 // x = 16
	.equ altura_centro_cabeza_2, QUARTER_SQUARES_SIZE + 5	 // x = 15
	add x15,x15,11
	bl get_pixel
	mov x2,ancho_centro_cabeza_2
	mov x3,altura_centro_cabeza_2
	bl pintar_rectangulo

	add x15,x15,16
	add x16,x16,9
	bl get_pixel
	mov x2,5
	mov x3,5
	bl pintar_rectangulo

	//Bigote
	.equ ancho_bigote, QUARTER_SQUARES_SIZE * 2 - 1  // x = 19
	.equ altura_bigote, QUARTER_SQUARES_SIZE - 5	 // y = 5
	add x15,x15,1
	add x16,x16,5
	bl get_pixel
	ldr w1, color_verde_oscu
	mov x2,ancho_bigote
	mov x3,altura_bigote
	bl pintar_rectangulo
	
	add x15,x15,5
	sub x16,x16,5
	bl get_pixel
	mov x2,5
	mov x3,5
	bl pintar_rectangulo
	
	//Ojo
	.equ ancho_ojo, QUARTER_SQUARES_SIZE - 6	// x = 4
	.equ altura_ojo, QUARTER_SQUARES_SIZE - 1	// y = 9
	sub x15,x15,5
	sub x16,x16,9
	bl get_pixel
	ldr w1,color_verde_oscu
	mov x2,ancho_ojo
	mov x3,altura_ojo
	bl pintar_rectangulo
	
	add x15,x15,5
	add x16,x16,9
	bl get_pixel
	mov x2,5
	mov x3,5
	bl pintar_rectangulo
	
	//Nariz
	.equ ancho_nariz, QUARTER_SQUARES_SIZE - 2	// x = 8
	.equ altura_nariz, QUARTER_SQUARES_SIZE 	// x = 10
	add x15,x15,6
	sub x16,x16,5
	bl get_pixel
	ldr w1,color_piel
	mov x2,ancho_nariz
	mov x3,altura_nariz
	bl pintar_rectangulo
	
	add x15,x15,9
	add x16,x16,5
	bl get_pixel
	mov x2,5
	mov x3,5
	bl pintar_rectangulo
	
	sub x15,x15,15
	sub x16,x16,9
	bl get_pixel
	mov x2,5
	mov x3,10
	bl pintar_rectangulo

	//Pelo
	.equ ancho_pelo, QUARTER_SQUARES_SIZE - 5	// x = 5
	.equ altura_pelo, QUARTER_SQUARES_SIZE + 4	// y = 14
	sub x15,x15,28
	bl get_pixel
	ldr w1,color_verde_oscu
	mov x2,ancho_pelo
	mov x3,altura_pelo
	bl pintar_rectangulo
	
	sub x15,x15,5
	bl get_pixel
	mov x2,5
	mov x3,5
	bl pintar_rectangulo

	sub x15,x15,6
	add x16,x16,5
	bl get_pixel
	mov x2,5
	mov x3,10
	bl pintar_rectangulo
	
	add x15,x15,6
	add x16,x16,10
	bl get_pixel
	mov x2,4
	mov x3,5
	bl pintar_rectangulo

	//Sombrero
	.equ ancho_sombrero, QUARTER_SQUARES_SIZE * 5 - 5	// x = 45
	.equ altura_sombrero, QUARTER_SQUARES_SIZE - 5		// y = 5
	add x15,x15,5
	sub x16,x16,20
	bl get_pixel
	ldr w1,red
	mov x2,ancho_sombrero
	mov x3,altura_sombrero
	bl pintar_rectangulo
	
	.equ ancho_sombrero_2, QUARTER_SQUARES_SIZE * 3 	// x = 30
	.equ altura_sombrero_2, QUARTER_SQUARES_SIZE - 3	// x = 7
	add x15,x15,5
	sub x16,x16,7
	bl get_pixel
	mov x2,ancho_sombrero_2
	mov x3,altura_sombrero_2
	bl pintar_rectangulo

	ldur lr, [sp, #48] 	//recupero direc de salto
	ldur x15, [sp, #40]
	ldur x16, [sp, #32]  	 //recupero y 
	ldur w1, [sp, #24]  	 //recupero y 
	ldur x2, [sp, #16]  	 //recupero y 
	ldur x3, [sp, #8]  	 //recupero y 
	ldur x9, [sp]  	 
	add sp, sp, #56
	br lr   			//return
////////////////////////////

	

//////////////////////////////////////////////	




/*
Parametros:
	x15: x esquina inferior izquierda
	x16: y esquina inferior izquierda
	*/

//MARIO EN MOVIMIENTO
draw_mario_mov:

	sub sp, sp, #56
	str lr, [sp, #48]   //guardo direc de retorno
	str x15, [sp, #40]   //guardo x inicial
	str x16, [sp, #32]    	
	str w1, [sp, #24]    	
	str x2, [sp, #16]    	
	str x3, [sp, #8]    	
	str x9, [sp]     	 

  //Botas
	.equ ancho_botas_suela, QUARTER_SQUARES_SIZE +1  // x = 11
	.equ altura_botas_suela, 4						 // y = 4
	.equ ancho_botas, QUARTER_SQUARES_SIZE	+2 		 // x = 12
	.equ altura_botas, QUARTER_SQUARES_SIZE -3		 // y = 7

	//izq
	bl get_pixel
	ldr w1,color_verde_oscu
	mov x2,ancho_botas_suela
	mov x3,altura_botas_suela
	bl pintar_rectangulo

	sub x15,x15,5
	sub x16,x16,8
	bl get_pixel
	mov x2,ancho_botas
	mov x3,altura_botas
	bl pintar_rectangulo

	//der
	.equ ancho_botas_2, QUARTER_SQUARES_SIZE-2	// x = 8
	.equ altura_botas_2, QUARTER_SQUARES_SIZE	// y = 10
	add x15,x15,51
	sub x16,x16,12
	bl get_pixel
	mov x2,ancho_botas_2
	mov x3,altura_botas_2
	bl pintar_rectangulo
	
	add x15,x15,4
	sub x16,x16,4
	bl get_pixel
	mov x2,4
	mov x3,4
	bl pintar_rectangulo

  //Traje
	.equ ancho_centro_traje, QUARTER_SQUARES_SIZE + 5 	  // x = 15
	.equ altura_centro_traje, QUARTER_SQUARES_SIZE - 2	  // y = 8
	.equ ancho_centro_traje_2, QUARTER_SQUARES_SIZE * 4 	  // x = 40
	.equ altura_centro_traje_2, QUARTER_SQUARES_SIZE - 4	  // y = 6
	
	sub x15,x15,50
	add x16,x16,9
	bl get_pixel
	ldr w1,red
	mov x2,ancho_centro_traje
	mov x3,altura_centro_traje
	bl pintar_rectangulo
	
	add x15,x15,5
	sub x16,x16,5
	bl get_pixel
	mov x2,ancho_centro_traje_2
	mov x3,altura_centro_traje_2
	bl pintar_rectangulo

	.equ ancho_centro_traje_3, QUARTER_SQUARES_SIZE 	// x = 12
	.equ altura_centro_traje_3, QUARTER_SQUARES_SIZE 	// y = 12
	add x15,x15,30
	bl get_pixel
	mov x2,ancho_centro_traje_3
	mov x3,altura_centro_traje_3
	bl pintar_rectangulo

	.equ ancho_centro_traje_4, QUARTER_SQUARES_SIZE *3		// x = 30
	.equ altura_centro_traje_4, QUARTER_SQUARES_SIZE + 3	// y = 13
	sub x15,x15,25
	sub x16,x16,8
	bl get_pixel
	mov x2,ancho_centro_traje_4
	mov x3,altura_centro_traje_4
	bl pintar_rectangulo

	.equ ancho_tiras_traje, QUARTER_SQUARES_SIZE - 2	// x = 8
	.equ altura_tiras_traje, QUARTER_SQUARES_SIZE *2 	// y = 20
	add x15,x15,10
	sub x16,x16,17
	bl get_pixel
	mov x2,ancho_tiras_traje
	mov x3,altura_tiras_traje
	bl pintar_rectangulo

	.equ ancho_arriba_traje, QUARTER_SQUARES_SIZE + 5		// x = 15
	.equ altura_arriba_traje, QUARTER_SQUARES_SIZE - 4	// y = 5
	add x15,x15,5
	add x16,x16,10
	bl get_pixel
	mov x2,ancho_arriba_traje
	mov x3,altura_arriba_traje
	bl pintar_rectangulo

	.equ ancho_arriba_traje_2, QUARTER_SQUARES_SIZE - 7		// x = 4
	.equ altura_arriba_traje_2, QUARTER_SQUARES_SIZE - 7	// y = 4
	add x15,x15,4
	sub x16,x16,4
	bl get_pixel
	mov x2,ancho_arriba_traje_2
	mov x3,altura_arriba_traje_2
	bl pintar_rectangulo

	.equ ancho_parte_verde, QUARTER_SQUARES_SIZE * 2 -1	// x = 19
	.equ altura_parte_verde, QUARTER_SQUARES_SIZE 		// y = 10
	sub x15,x15,29
	sub x16,x16,6
	bl get_pixel
	ldr w1,color_verde_oscu
	mov x2,ancho_parte_verde
	mov x3,altura_parte_verde
	bl pintar_rectangulo

	.equ ancho_parte_verde_2, QUARTER_SQUARES_SIZE -1		// x = 9
	.equ altura_parte_verde_2, QUARTER_SQUARES_SIZE -5		// y = 5
	add x15,x15,10
	add x16,x16,11
	bl get_pixel
	ldr w1,color_verde_oscu
	mov x2,ancho_parte_verde_2
	mov x3,altura_parte_verde_2
	bl pintar_rectangulo

	.equ ancho_parte_verde_3, QUARTER_SQUARES_SIZE 			// x = 10
	.equ altura_parte_verde_3, 5							// y = 5
	add x15,x15,19
	sub x16,x16,11
	bl get_pixel
	ldr w1,color_verde_oscu
	mov x2,ancho_parte_verde_3
	mov x3,altura_parte_verde_3
	bl pintar_rectangulo

	.equ ancho_parte_verde_4, QUARTER_SQUARES_SIZE +3		// x = 13
	.equ altura_parte_verde_4, 4							// y = 4
	add x15,x15,4
	add x16,x16,6
	bl get_pixel
	ldr w1,color_verde_oscu
	mov x2,ancho_parte_verde_4
	mov x3,altura_parte_verde_4
	bl pintar_rectangulo

	.equ ancho_parte_verde_5, QUARTER_SQUARES_SIZE 			// x = 10
	.equ altura_parte_verde_5, 3							// y = 4
	add x15,x15,8
	add x16,x16,5
	bl get_pixel
	ldr w1,color_verde_oscu
	mov x2,ancho_parte_verde_5
	mov x3,altura_parte_verde_5
	bl pintar_rectangulo

//Brazos
	//izq
	.equ ancho_brazo_izq, QUARTER_SQUARES_SIZE	-2		// x = 8
	.equ altura_brazo_izq, QUARTER_SQUARES_SIZE + 5		// y = 15
	sub x15,x15,50
	sub x16,x16,6
	bl get_pixel
	ldr w1,color_piel
	mov x2,ancho_brazo_izq
	mov x3,altura_brazo_izq
	bl pintar_rectangulo
		
	add x15,x15,9
	add x16,x16,6
	bl get_pixel
	mov x2,4
	mov x3,4
	bl pintar_rectangulo


	//der
	.equ ancho_brazo_der, QUARTER_SQUARES_SIZE + 3		// x = 13
	.equ altura_brazo_der, QUARTER_SQUARES_SIZE - 6		// y = 4
	add x15,x15,46
	sub x16,x16,5
	bl get_pixel
	mov x2,ancho_brazo_der
	mov x3,altura_brazo_der
	bl pintar_rectangulo

	.equ ancho_brazo_der_2, QUARTER_SQUARES_SIZE - 2		// x = 8
	.equ altura_brazo_der_2, QUARTER_SQUARES_SIZE - 6		// y = 4
	add x15,x15,5
	add x16,x16,4
	bl get_pixel
	mov x2,ancho_brazo_der_2
	mov x3,altura_brazo_der_2
	bl pintar_rectangulo

//Cabeza
	//centro
	.equ ancho_centro_cabeza, QUARTER_SQUARES_SIZE * 2 + 2	 // x = 22
	.equ altura_centro_cabeza, QUARTER_SQUARES_SIZE 	 	 // x = 10

	sub x15,x15,37
	sub x16,x16,21
	bl get_pixel
	ldr w1, color_piel
	mov x2,ancho_centro_cabeza
	mov x3,altura_centro_cabeza
	bl pintar_rectangulo

	.equ ancho_menton, QUARTER_SQUARES_SIZE 		 // x = 10
	.equ altura_menton, QUARTER_SQUARES_SIZE - 5	 // y = 5
	add x15,x15,23
	add x16,x16,5
	bl get_pixel
	mov x2,ancho_menton
	mov x3,altura_menton
	bl pintar_rectangulo
	
	sub x15,x15,28
	sub x16,x16,20
	bl get_pixel
	mov x2,6
	mov x3,20
	bl pintar_rectangulo

	.equ ancho_centro_cabeza_2, QUARTER_SQUARES_SIZE + 6	 // x = 16
	.equ altura_centro_cabeza_2, QUARTER_SQUARES_SIZE + 5	 // x = 15
	add x15,x15,11
	bl get_pixel
	mov x2,ancho_centro_cabeza_2
	mov x3,altura_centro_cabeza_2
	bl pintar_rectangulo
	
	add x15,x15,16
	add x16,x16,9
	bl get_pixel
	mov x2,5
	mov x3,5
	bl pintar_rectangulo

	//Bigote
	.equ ancho_bigote, QUARTER_SQUARES_SIZE * 2 - 1  // x = 19
	.equ altura_bigote, QUARTER_SQUARES_SIZE - 5	 // y = 5
	add x15,x15,1
	add x16,x16,5
	bl get_pixel
	ldr w1, color_verde_oscu
	mov x2,ancho_bigote
	mov x3,altura_bigote
	bl pintar_rectangulo
	
	add x15,x15,5
	sub x16,x16,5
	bl get_pixel
	mov x2,5
	mov x3,5
	bl pintar_rectangulo
	
	//Ojo
	.equ ancho_ojo, QUARTER_SQUARES_SIZE - 6	// x = 4
	.equ altura_ojo, QUARTER_SQUARES_SIZE - 1	// y = 9
	sub x15,x15,5
	sub x16,x16,9
	bl get_pixel
	ldr w1,color_verde_oscu
	mov x2,ancho_ojo
	mov x3,altura_ojo
	bl pintar_rectangulo
	
	add x15,x15,5
	add x16,x16,9
	bl get_pixel
	mov x2,5
	mov x3,5
	bl pintar_rectangulo
	
	//Nariz
	.equ ancho_nariz, QUARTER_SQUARES_SIZE - 2	// x = 8
	.equ altura_nariz, QUARTER_SQUARES_SIZE 	// x = 10
	add x15,x15,6
	sub x16,x16,5
	bl get_pixel
	ldr w1,color_piel
	mov x2,ancho_nariz
	mov x3,altura_nariz
	bl pintar_rectangulo
	
	add x15,x15,9
	add x16,x16,5
	bl get_pixel
	mov x2,5
	mov x3,5
	bl pintar_rectangulo
	
	sub x15,x15,15
	sub x16,x16,9
	bl get_pixel
	mov x2,5
	mov x3,10
	bl pintar_rectangulo

	//Pelo
	.equ ancho_pelo, QUARTER_SQUARES_SIZE - 5	// x = 5
	.equ altura_pelo, QUARTER_SQUARES_SIZE + 4	// y = 14
	sub x15,x15,28
	bl get_pixel
	ldr w1,color_verde_oscu
	mov x2,ancho_pelo
	mov x3,altura_pelo
	bl pintar_rectangulo
	
	sub x15,x15,5
	bl get_pixel
	mov x2,5
	mov x3,5
	bl pintar_rectangulo

	sub x15,x15,6
	add x16,x16,5
	bl get_pixel
	mov x2,5
	mov x3,10
	bl pintar_rectangulo

	add x15,x15,6
	add x16,x16,10
	bl get_pixel
	mov x2,4
	mov x3,5
	bl pintar_rectangulo

	//Sombrero
	.equ ancho_sombrero, QUARTER_SQUARES_SIZE * 5 - 5	// x = 45
	.equ altura_sombrero, QUARTER_SQUARES_SIZE - 5		// y = 5
	add x15,x15,5
	sub x16,x16,20
	bl get_pixel
	ldr w1,red
	mov x2,ancho_sombrero
	mov x3,altura_sombrero
	bl pintar_rectangulo
	
	.equ ancho_sombrero_2, QUARTER_SQUARES_SIZE * 3 	// x = 30
	.equ altura_sombrero_2, QUARTER_SQUARES_SIZE - 3	// x = 7
	add x15,x15,5
	sub x16,x16,7
	bl get_pixel
	mov x2,ancho_sombrero_2
	mov x3,altura_sombrero_2
	bl pintar_rectangulo

	add x15,x15,6
	add x16,x16,53
	bl get_pixel
	ldr w1,white
	mov x2,4
	mov x3,4
	bl pintar_rectangulo

	ldur lr, [sp, #48] 	//recupero direc de salto
	ldur x15, [sp, #40]
	ldur x16, [sp, #32]  	 //recupero y 
	ldur w1, [sp, #24]  	 //recupero y 
	ldur x2, [sp, #16]  	 //recupero y 
	ldur x3, [sp, #8]  	 //recupero y 
	ldur x9, [sp]  	 
	add sp, sp, #56
	br lr   			//return
////////////////////////////





/*
Parametros:
	x15: x esquina inferior izquierda
	x16: y esquina inferior izquierda
	*/

//MARIO SALTANDO
draw_mario_salto:

	sub sp, sp, #56
	str lr, [sp, #48]   //guardo direc de retorno
	str x15, [sp, #40]   //guardo x inicial
	str x16, [sp, #32]    	
	str w1, [sp, #24]    	
	str x2, [sp, #16]    	
	str x3, [sp, #8]    	
	str x9, [sp]     	 


  //Botas
	.equ ancho_botas_suela, QUARTER_SQUARES_SIZE - 6  // x = 3
	.equ altura_botas_suela, QUARTER_SQUARES_SIZE 	  // y = 5
	.equ ancho_botas, QUARTER_SQUARES_SIZE - 5 		  // x = 5
	.equ altura_botas, QUARTER_SQUARES_SIZE + 2		  // y = 12

	//izq
	bl get_pixel
	ldr w1,color_verde_oscu
	mov x2,ancho_botas_suela
	mov x3,altura_botas_suela
	bl pintar_rectangulo
	
	add x15,x15,4
	sub x16,x16,7
	bl get_pixel
	mov x2,ancho_botas
	mov x3,altura_botas
	bl pintar_rectangulo

	//der
	.equ ancho_botas_2, QUARTER_SQUARES_SIZE-2	// x = 8
	.equ altura_botas_2, QUARTER_SQUARES_SIZE	// y = 10
	add x15,x15,51
	sub x16,x16,5
	bl get_pixel
	mov x2,ancho_botas_2
	mov x3,altura_botas_2
	bl pintar_rectangulo
	
	add x15,x15,4
	sub x16,x16,5
	bl get_pixel
	mov x2,4
	mov x3,4
	bl pintar_rectangulo

  //Traje
	.equ ancho_centro_traje, QUARTER_SQUARES_SIZE + 5 	  // x = 15
	.equ altura_centro_traje, QUARTER_SQUARES_SIZE *2	  // y = 20
	sub x15,x15,49
	add x16,x16,3
	bl get_pixel
	ldr w1,red
	mov x2,ancho_centro_traje
	mov x3,altura_centro_traje
	bl pintar_rectangulo

	.equ ancho_centro_traje_2, QUARTER_SQUARES_SIZE  	  // x = 10
	.equ altura_centro_traje_2, QUARTER_SQUARES_SIZE *2-4 // y = 18
	add x15,x15,16
	bl get_pixel
	mov x2,ancho_centro_traje_2
	mov x3,altura_centro_traje_2
	bl pintar_rectangulo

	.equ ancho_centro_traje_3, QUARTER_SQUARES_SIZE *2	// x = 20
	.equ altura_centro_traje_3, QUARTER_SQUARES_SIZE *2-2 	// y = 18
	add x15,x15,4
	sub x16,x16,6
	bl get_pixel
	mov x2,ancho_centro_traje_3
	mov x3,altura_centro_traje_3
	bl pintar_rectangulo

	.equ ancho_centro_traje_4, QUARTER_SQUARES_SIZE -5	// x = 5
	.equ altura_centro_traje_4, QUARTER_SQUARES_SIZE 	// y = 10
	add x15,x15,20
	add x16,x16,8
	bl get_pixel
	mov x2,ancho_centro_traje_4
	mov x3,altura_centro_traje_4
	bl pintar_rectangulo

	.equ ancho_tiras_traje, QUARTER_SQUARES_SIZE - 6	// x = 4
	.equ altura_tiras_traje, QUARTER_SQUARES_SIZE *2 	// y = 20
	sub x15,x15,25
	sub x16,x16,18
	bl get_pixel
	mov x2,ancho_tiras_traje
	mov x3,altura_tiras_traje
	bl pintar_rectangulo

	add x15,x15,21
	bl get_pixel
	mov x2,ancho_tiras_traje
	mov x3,altura_tiras_traje
	bl pintar_rectangulo

	.equ ancho_parte_verde, QUARTER_SQUARES_SIZE +5		// x = 15
	.equ altura_parte_verde, QUARTER_SQUARES_SIZE+5		// y = 15
	sub x15,x15,16
	bl get_pixel
	ldr w1,color_verde_oscu
	mov x2,ancho_parte_verde
	mov x3,altura_parte_verde
	bl pintar_rectangulo

	.equ ancho_parte_verde_2, QUARTER_SQUARES_SIZE *2		// x = 20
	.equ altura_parte_verde_2, QUARTER_SQUARES_SIZE +3		// y = 13
	sub x15,x15,26
	bl get_pixel
	mov x2,ancho_parte_verde_2
	mov x3,altura_parte_verde_2
	bl pintar_rectangulo

	.equ ancho_parte_verde_3, 5 			// x = 5
	.equ altura_parte_verde_3, 5			// y = 5
	sub x15,x15,4
	add x16,x16,4
	bl get_pixel
	mov x2,ancho_parte_verde_3
	mov x3,altura_parte_verde_3
	bl pintar_rectangulo

	.equ ancho_parte_verde_4, QUARTER_SQUARES_SIZE +3		// x = 13
	.equ altura_parte_verde_4, QUARTER_SQUARES_SIZE + 5		// y = 15
	add x15,x15,50
	sub x16,x16,33
	bl get_pixel
	ldr w1,color_verde_oscu
	mov x2,ancho_parte_verde_4
	mov x3,altura_parte_verde_4
	bl pintar_rectangulo

//Brazos
	.equ ancho_brazo_izq, QUARTER_SQUARES_SIZE-3		// x = 8
	.equ altura_brazo_izq, QUARTER_SQUARES_SIZE 		// y = 10
	//izq
	sub x15,x15,54
	add x16,x16,36
	bl get_pixel
	ldr w1,color_piel
	mov x2,ancho_brazo_izq
	mov x3,altura_brazo_izq
	bl pintar_rectangulo

	add x15,x15,4
	add x16,x16,10
	bl get_pixel
	mov x2,4
	mov x3,4
	bl pintar_rectangulo

	add x15,x15,4
	sub x16,x16,5
	bl get_pixel
	mov x2,4
	mov x3,4
	bl pintar_rectangulo

	.equ ancho_brazo_der, QUARTER_SQUARES_SIZE+3	// x = 13
	.equ altura_brazo_der, QUARTER_SQUARES_SIZE +5	// y = 15
	//der
	add x15,x15,46
	sub x16,x16,58
	bl get_pixel
	mov x2,ancho_brazo_der
	mov x3,altura_brazo_der
	bl pintar_rectangulo

//Cabeza
	//centro
	.equ ancho_centro_cabeza, QUARTER_SQUARES_SIZE * 2 + 2	 // x = 22
	.equ altura_centro_cabeza, QUARTER_SQUARES_SIZE 	 	 // x = 10
	sub x15,x15,35
	add x16,x16,35
	bl get_pixel
	ldr w1, color_piel
	mov x2,ancho_centro_cabeza
	mov x3,altura_centro_cabeza
	bl pintar_rectangulo

	.equ ancho_menton, QUARTER_SQUARES_SIZE 	  // x = 10
	.equ altura_menton, QUARTER_SQUARES_SIZE - 5  // y = 5
	add x15,x15,23
	add x16,x16,5
	bl get_pixel
	mov x2,ancho_menton
	mov x3,altura_menton
	bl pintar_rectangulo

	sub x15,x15,28
	sub x16,x16,20
	bl get_pixel
	mov x2,6
	mov x3,20
	bl pintar_rectangulo

	.equ ancho_centro_cabeza_2, QUARTER_SQUARES_SIZE + 6	 // x = 16
	.equ altura_centro_cabeza_2, QUARTER_SQUARES_SIZE + 5	 // x = 15
	add x15,x15,11
	bl get_pixel
	mov x2,ancho_centro_cabeza_2
	mov x3,altura_centro_cabeza_2
	bl pintar_rectangulo
	
	add x15,x15,16
	add x16,x16,9
	bl get_pixel
	mov x2,5
	mov x3,5
	bl pintar_rectangulo

	//Bigote
	.equ ancho_bigote, QUARTER_SQUARES_SIZE * 2 - 1  // x = 19
	.equ altura_bigote, QUARTER_SQUARES_SIZE - 5	 // y = 5
	add x15,x15,1
	add x16,x16,5
	bl get_pixel
	ldr w1, color_verde_oscu
	mov x2,ancho_bigote
	mov x3,altura_bigote
	bl pintar_rectangulo
	
	add x15,x15,5
	sub x16,x16,5
	bl get_pixel
	mov x2,5
	mov x3,5
	bl pintar_rectangulo
	
	//Ojo
	.equ ancho_ojo, QUARTER_SQUARES_SIZE - 6	// x = 4
	.equ altura_ojo, QUARTER_SQUARES_SIZE - 1	// y = 9
	sub x15,x15,5
	sub x16,x16,9
	bl get_pixel
	ldr w1,color_verde_oscu
	mov x2,ancho_ojo
	mov x3,altura_ojo
	bl pintar_rectangulo
	
	add x15,x15,5
	add x16,x16,9
	bl get_pixel
	mov x2,5
	mov x3,5
	bl pintar_rectangulo
	
	//Nariz
	.equ ancho_nariz, QUARTER_SQUARES_SIZE - 2	// x = 8
	.equ altura_nariz, QUARTER_SQUARES_SIZE 	// x = 10
	add x15,x15,6
	sub x16,x16,5
	bl get_pixel
	ldr w1,color_piel
	mov x2,ancho_nariz
	mov x3,altura_nariz
	bl pintar_rectangulo
	
	add x15,x15,9
	add x16,x16,5
	bl get_pixel
	mov x2,5
	mov x3,5
	bl pintar_rectangulo

	sub x15,x15,15
	sub x16,x16,9
	bl get_pixel
	mov x2,5
	mov x3,10
	bl pintar_rectangulo

	//Pelo
	.equ ancho_pelo, QUARTER_SQUARES_SIZE - 5	// x = 5
	.equ altura_pelo, QUARTER_SQUARES_SIZE + 4	// y = 14
	sub x15,x15,28
	bl get_pixel
	ldr w1,color_verde_oscu
	mov x2,ancho_pelo
	mov x3,altura_pelo
	bl pintar_rectangulo
		
	sub x15,x15,5
	bl get_pixel
	mov x2,5
	mov x3,5
	bl pintar_rectangulo
	
	sub x15,x15,6
	add x16,x16,5
	bl get_pixel
	mov x2,5
	mov x3,10
	bl pintar_rectangulo

	add x15,x15,6
	add x16,x16,10
	bl get_pixel
	mov x2,4
	mov x3,5
	bl pintar_rectangulo

	//Sombrero
	.equ ancho_sombrero, QUARTER_SQUARES_SIZE * 5 - 5	// x = 45
	.equ altura_sombrero, QUARTER_SQUARES_SIZE - 5		// y = 5
	add x15,x15,5
	sub x16,x16,20
	bl get_pixel
	ldr w1,red
	mov x2,ancho_sombrero
	mov x3,altura_sombrero
	bl pintar_rectangulo
	
	.equ ancho_sombrero_2, QUARTER_SQUARES_SIZE * 3 	// x = 30
	.equ altura_sombrero_2, QUARTER_SQUARES_SIZE - 3	// x = 7
	add x15,x15,5
	sub x16,x16,7
	bl get_pixel
	mov x2,ancho_sombrero_2
	mov x3,altura_sombrero_2
	bl pintar_rectangulo


	ldur lr, [sp, #48] 	//recupero direc de salto
	ldur x15, [sp, #40]
	ldur x16, [sp, #32]  	 //recupero y 
	ldur w1, [sp, #24]  	 //recupero y 
	ldur x2, [sp, #16]  	 //recupero y 
	ldur x3, [sp, #8]  	 //recupero y 
	ldur x9, [sp]  	 
	add sp, sp, #56
	br lr   			//return
////////////////////////////





/*
Parametros:
	x15: x esquina inferior izquierda
	x16: y esquina inferior izquierda
	*/

//MARIO CAMINANDO
draw_mario_paso:

	sub sp, sp, #56
	str lr, [sp, #48]   //guardo direc de retorno
	str x15, [sp, #40]   //guardo x inicial
	str x16, [sp, #32]    	
	str w1, [sp, #24]    	
	str x2, [sp, #16]    	
	str x3, [sp, #8]    	
	str x9, [sp]     	 
 
  //Botas
	.equ ancho_botas_suela, QUARTER_SQUARES_SIZE *2   // x = 20
	.equ altura_botas_suela, QUARTER_SQUARES_SIZE-5   // y = 5
	.equ ancho_botas, QUARTER_SQUARES_SIZE + 5 		  // x = 15
	.equ altura_botas, QUARTER_SQUARES_SIZE - 5		  // y = 5

	//izq
	bl get_pixel
	ldr w1,color_verde_oscu
	mov x2,ancho_botas_suela
	mov x3,altura_botas_suela
	bl pintar_rectangulo
	
	sub x16,x16,6
	bl get_pixel
	mov x2,ancho_botas
	mov x3,altura_botas
	bl pintar_rectangulo

	//der
	.equ ancho_botas_suela_2, QUARTER_SQUARES_SIZE *2   // x = 20
	.equ altura_botas_suela_2, QUARTER_SQUARES_SIZE-5   // y = 5
	.equ ancho_botas_2, QUARTER_SQUARES_SIZE + 5 		  // x = 15
	.equ altura_botas_2, QUARTER_SQUARES_SIZE - 5		  // y = 5
	add x15,x15,15
	bl get_pixel
	mov x2,ancho_botas_suela_2
	mov x3,altura_botas_suela_2
	bl pintar_rectangulo
	
	sub x16,x16,5
	bl get_pixel
	mov x2,ancho_botas_2
	mov x3,altura_botas_2
	bl pintar_rectangulo


  //Traje
	.equ ancho_centro_traje, QUARTER_SQUARES_SIZE + 5 	  // x = 15
	.equ altura_centro_traje, QUARTER_SQUARES_SIZE -5	  // y = 5
	sub x15,x15,15
	bl get_pixel
	ldr w1,red
	mov x2,ancho_centro_traje
	mov x3,altura_centro_traje
	bl pintar_rectangulo

	.equ ancho_centro_traje_2, QUARTER_SQUARES_SIZE +4 	  // x = 14
	.equ altura_centro_traje_2, QUARTER_SQUARES_SIZE -5   // y = 5
	add x15,x15,16
	sub x16,x16,6
	bl get_pixel
	mov x2,ancho_centro_traje_2
	mov x3,altura_centro_traje_2
	bl pintar_rectangulo


	.equ ancho_centro_traje_3, QUARTER_SQUARES_SIZE-1 		// x = 9
	.equ altura_centro_traje_3, QUARTER_SQUARES_SIZE +5 	// y = 15
	add x15,x15,5
	sub x16,x16,15
	bl get_pixel
	mov x2,ancho_centro_traje_3
	mov x3,altura_centro_traje_3
	bl pintar_rectangulo

	.equ ancho_centro_traje_4, QUARTER_SQUARES_SIZE -6	// x = 4
	.equ altura_centro_traje_4, QUARTER_SQUARES_SIZE 	// y = 10
	add x15,x15,10
	add x16,x16,5
	bl get_pixel
	mov x2,ancho_centro_traje_4
	mov x3,altura_centro_traje_4
	bl pintar_rectangulo

	.equ ancho_centro_traje_5, QUARTER_SQUARES_SIZE 	// x = 10
	.equ altura_centro_traje_5, QUARTER_SQUARES_SIZE +4	// y = 14
	sub x15,x15,20
	sub x16,x16,10
	bl get_pixel
	mov x2,ancho_centro_traje_5
	mov x3,altura_centro_traje_5
	bl pintar_rectangulo


//Brazos
	.equ ancho_brazo_izq, QUARTER_SQUARES_SIZE -5	// x = 5
	.equ altura_brazo_izq, QUARTER_SQUARES_SIZE 	// y = 10
	//izq
	add x16,x16,15
	bl get_pixel
	ldr w1,color_piel
	mov x2,ancho_brazo_izq
	mov x3,altura_brazo_izq
	bl pintar_rectangulo

	add x15,x15,6
	bl get_pixel
	mov x2,4
	mov x3,4
	bl pintar_rectangulo

	//der
	.equ ancho_brazo_der, QUARTER_SQUARES_SIZE-5	// x = 5
	.equ altura_brazo_der, QUARTER_SQUARES_SIZE -5	// y = 5
	add x15,x15,13
	sub x16,x16,10
	bl get_pixel
	mov x2,ancho_brazo_der
	mov x3,altura_brazo_der
	bl pintar_rectangulo


//Parte Verde
	.equ ancho_parte_verde, QUARTER_SQUARES_SIZE-1	// x = 9
	.equ altura_parte_verde, QUARTER_SQUARES_SIZE-5	// y = 5
	sub x15,x15,10
	sub x16,x16,5
	bl get_pixel
	ldr w1, color_verde_oscu
	mov x2,ancho_parte_verde
	mov x3,altura_parte_verde
	bl pintar_rectangulo

	.equ ancho_parte_verde_2, QUARTER_SQUARES_SIZE*3-2	// x = 30
	.equ altura_parte_verde_2, QUARTER_SQUARES_SIZE-5	// y = 5
	sub x15,x15,23
	sub x16,x16,5
	bl get_pixel
	mov x2,ancho_parte_verde_2
	mov x3,altura_parte_verde_2
	bl pintar_rectangulo

	.equ ancho_parte_verde_3, QUARTER_SQUARES_SIZE*2-2	// x = 18
	.equ altura_parte_verde_3, QUARTER_SQUARES_SIZE*2	// y = 20
	sub x15,x15,4
	add x16,x16,5
	bl get_pixel
	mov x2,ancho_parte_verde_3
	mov x3,altura_parte_verde_3
	bl pintar_rectangulo

	.equ ancho_parte_verde_4, QUARTER_SQUARES_SIZE-5	// x = 5
	.equ altura_parte_verde_4, QUARTER_SQUARES_SIZE-5	// y = 5
	add x15,x15,13
	add x16,x16,20
	bl get_pixel
	mov x2,ancho_parte_verde_4
	mov x3,altura_parte_verde_4
	bl pintar_rectangulo

	.equ ancho_parte_roja, QUARTER_SQUARES_SIZE-5	// x = 5
	.equ altura_parte_roja, QUARTER_SQUARES_SIZE-5	// y = 5
	sub x15,x15,6
	bl get_pixel
	ldr w1,red
	mov x2,ancho_parte_roja
	mov x3,altura_parte_roja
	bl pintar_rectangulo

	.equ ancho_parte_roja_2, QUARTER_SQUARES_SIZE-4		// x = 6
	.equ altura_parte_roja_2, QUARTER_SQUARES_SIZE-5	// y = 5
	sub x15,x15,7
	sub x16,x16,5
	bl get_pixel
	ldr w1,red
	mov x2,ancho_parte_roja_2
	mov x3,altura_parte_roja_2
	bl pintar_rectangulo


//Cabeza
	//centro
	.equ ancho_centro_cabeza, QUARTER_SQUARES_SIZE * 2 + 2	 // x = 22
	.equ altura_centro_cabeza, QUARTER_SQUARES_SIZE 	 	 // x = 10
	add x15,x15,10
	sub x16,x16,31
	bl get_pixel
	ldr w1, color_piel
	mov x2,ancho_centro_cabeza
	mov x3,altura_centro_cabeza
	bl pintar_rectangulo

	.equ ancho_menton, QUARTER_SQUARES_SIZE 	  // x = 10
	.equ altura_menton, QUARTER_SQUARES_SIZE - 5  // y = 5
	add x15,x15,23
	add x16,x16,5
	bl get_pixel
	mov x2,ancho_menton
	mov x3,altura_menton
	bl pintar_rectangulo

	sub x15,x15,28
	sub x16,x16,20
	bl get_pixel
	mov x2,6
	mov x3,20
	bl pintar_rectangulo

	.equ ancho_centro_cabeza_2, QUARTER_SQUARES_SIZE + 6	 // x = 16
	.equ altura_centro_cabeza_2, QUARTER_SQUARES_SIZE + 5	 // x = 15
	add x15,x15,11
	bl get_pixel
	mov x2,ancho_centro_cabeza_2
	mov x3,altura_centro_cabeza_2
	bl pintar_rectangulo
	
	add x15,x15,16
	add x16,x16,9
	bl get_pixel
	mov x2,5
	mov x3,5
	bl pintar_rectangulo

	//Bigote
	.equ ancho_bigote, QUARTER_SQUARES_SIZE * 2 - 1  // x = 19
	.equ altura_bigote, QUARTER_SQUARES_SIZE - 5	 // y = 5
	add x15,x15,1
	add x16,x16,5
	bl get_pixel
	ldr w1, color_verde_oscu
	mov x2,ancho_bigote
	mov x3,altura_bigote
	bl pintar_rectangulo
	
	add x15,x15,5
	sub x16,x16,5
	bl get_pixel
	mov x2,5
	mov x3,5
	bl pintar_rectangulo
	
	//Ojo
	.equ ancho_ojo, QUARTER_SQUARES_SIZE - 6	// x = 4
	.equ altura_ojo, QUARTER_SQUARES_SIZE - 1	// y = 9
	sub x15,x15,5
	sub x16,x16,9
	bl get_pixel
	ldr w1,color_verde_oscu
	mov x2,ancho_ojo
	mov x3,altura_ojo
	bl pintar_rectangulo
	
	add x15,x15,5
	add x16,x16,9
	bl get_pixel
	mov x2,5
	mov x3,5
	bl pintar_rectangulo
	
	//Nariz
	.equ ancho_nariz, QUARTER_SQUARES_SIZE - 2	// x = 8
	.equ altura_nariz, QUARTER_SQUARES_SIZE 	// x = 10
	add x15,x15,6
	sub x16,x16,5
	bl get_pixel
	ldr w1,color_piel
	mov x2,ancho_nariz
	mov x3,altura_nariz
	bl pintar_rectangulo
	
	add x15,x15,9
	add x16,x16,5
	bl get_pixel
	mov x2,5
	mov x3,5
	bl pintar_rectangulo

	sub x15,x15,15
	sub x16,x16,9
	bl get_pixel
	mov x2,5
	mov x3,10
	bl pintar_rectangulo

	//Pelo
	.equ ancho_pelo, QUARTER_SQUARES_SIZE - 5	// x = 5
	.equ altura_pelo, QUARTER_SQUARES_SIZE + 4	// y = 14
	sub x15,x15,28
	bl get_pixel
	ldr w1,color_verde_oscu
	mov x2,ancho_pelo
	mov x3,altura_pelo
	bl pintar_rectangulo
		
	sub x15,x15,5
	bl get_pixel
	mov x2,5
	mov x3,5
	bl pintar_rectangulo
	
	sub x15,x15,6
	add x16,x16,5
	bl get_pixel
	mov x2,5
	mov x3,10
	bl pintar_rectangulo

	add x15,x15,6
	add x16,x16,10
	bl get_pixel
	mov x2,4
	mov x3,5
	bl pintar_rectangulo

	//Sombrero
	.equ ancho_sombrero, QUARTER_SQUARES_SIZE * 5 - 5	// x = 45
	.equ altura_sombrero, QUARTER_SQUARES_SIZE - 5		// y = 5
	add x15,x15,5
	sub x16,x16,20
	bl get_pixel
	ldr w1,red
	mov x2,ancho_sombrero
	mov x3,altura_sombrero
	bl pintar_rectangulo
	
	.equ ancho_sombrero_2, QUARTER_SQUARES_SIZE * 3 	// x = 30
	.equ altura_sombrero_2, QUARTER_SQUARES_SIZE - 3	// x = 7
	add x15,x15,5
	sub x16,x16,7
	bl get_pixel
	mov x2,ancho_sombrero_2
	mov x3,altura_sombrero_2
	bl pintar_rectangulo


	ldur lr, [sp, #48] 	//recupero direc de salto
	ldur x15, [sp, #40]
	ldur x16, [sp, #32]  	 //recupero y 
	ldur w1, [sp, #24]  	 //recupero y 
	ldur x2, [sp, #16]  	 //recupero y 
	ldur x3, [sp, #8]  	 //recupero y 
	ldur x9, [sp]  	 
	add sp, sp, #56
	br lr   			//return
////////////////////////////





//Figuras

  /*Rectangulo
  	  Parametros:
		x25 = coordenada inicial
		w1 = color
		x2 = base del cuadrado
		x3 = altura del cuadrado
	*/

  pintar_rectangulo:
		sub sp, sp, #24
		str lr, [sp, #16]
		str x3, [sp, #8]

		add x11, xzr,xzr // x11 = 0
		loop_pintar_rectangulo: 
			bl pintar_linea_horizontal 	//salto a pintar_linea_horizontal y guardo la siguiente instruccion en link register
			add x25,x25,2560 				// salto eje y + 1
			add x11,x11,1 				//  x11 = x11 + 1
			cmp x3, x11 				// if x3 >= x11
			b.ge loop_pintar_rectangulo
			ldur lr, [sp, #16]
			ldur x3, [sp,#8]
			add sp, sp, #24
			br lr
////////////////


  /*Linea horizontal
  	  Parametros:
		x25 = coordenada inicial
		w1 = color
		x2 = largo de la linea
	*/

  pintar_linea_horizontal:
  		sub sp, sp, #24
		str lr, [sp, #16]
		str x2, [sp, #8]

		add x12, xzr, x25 // x12 = x25
		add x13, xzr, xzr // x13 = 0
		
		loop_pintar_linea_horizontal:
			stur w1, [x12]	// 
			add x12, x12, #4 // siguiente pixel
			add x13, x13, 1 // x13 = x13 + 1
			cmp x2, x13	// if x13 >= w1
			b.ge loop_pintar_linea_horizontal 
			ldur lr, [sp, #16]
			ldur x2, [sp, #8]
			add sp, sp, #24
			br lr
////////////////
.equ SQUARES_SIZE,  10
.equ ANCHO_TUBO_ARRIBA,  90
.equ ALTURA_TUBO_ARRIBA,  40
.equ ANCHO_TUBO_ABAJO,  80
.equ ALTURA_TUBO_ABAJO,  60
.equ TUBO_X, 500
.equ TUBO_Y, 280

//Un pixel
	/*Parametros:
			x15 = eje x
			x16 = eje y
			 */

  get_pixel:
		sub sp, sp, #32
		str x0, [sp, #24]
		str lr, [sp, #16]
		str x15, [sp, #8]
		str x16, [sp]

		mov x20, x0
		mov x25,x20		
		mov x9,SCREEN_WIDTH
		mov x18,4
		madd x9,x16,x9,x15 // x9 = (x16 * 640) + x15
		mul x9,x9,x18 // x9 = 4*x9
		add x25,x25,x9
		ldur x0, [sp, #24]
		ldur lr, [sp, #16] //recupero direc de salto
		ldur x15, [sp, #8]
		ldur x16, [sp]   //recupero ancho
		add sp, sp, #32
		br lr   //return
/////////////
.endif
