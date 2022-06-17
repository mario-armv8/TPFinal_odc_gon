
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
	Inicializa arreglo donde figuran las posiciones iniciales en x de los distintos grupos de cajas
 
initialize_brick_array:
	ldr x13, =array_of_bricks
	ldr x14, initial_br_pos //posición inicial del primer bloque
	ldr x15, array_elem_distance
	ldr x16, brick_array_size
	initialize_b_loop:
		cmp x16, #0
		b.le end_initialize_b_loop
		str x14, [x13, x16, lsl #3] //guardo posición en x de las cajas a pintar
		add x14, x14, x15  //sumo la distancia a la siguiente caja
		sub x16, x16, #1
		b initialize_b_loop
	end_initialize_b_loop:
		br lr
*/

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
		bl random_box
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
	ldr x6, =array_of_floor
	ldr x7, floor_array_size
	ldr x2, floor_heigh
	draw_floor_loop:
		cmp x7, #0
		b.lt end_draw_floor_loop
		ldr x1, [x6, x7, lsl #3]
		bl double_floor_brick
		sub x7, x7, #1
		b draw_floor_loop
	end_draw_floor_loop:
		ldur lr, [sp, #32]
		ldur x1, [sp, #24]
		ldur x2, [sp, #16]
		ldur x6, [sp, #8]
		ldur x7, [sp]
		add sp, sp, #40
		br lr



.endif
