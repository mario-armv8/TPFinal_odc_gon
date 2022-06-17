
.ifndef data_s
.equ data_s, 0

.data
second_buffer: .skip BYTES_FRAMEBUFFER //reservo cantidad de bytes necesarios para el buffer secundario
array_of_bricks: .dword 440, 550 //arreglo de posiciones de las cajas a pintar
array_of_floor: .dword 0, 80, 160, 240, 320, 400, 480, 560, 640
.equ SCREEN_WIDTH,      640
.equ SCREEN_HEIGH,      480
.equ BITS_PER_PIXEL,    32
.equ BYTES_FRAMEBUFFER, (SCREEN_WIDTH*SCREEN_HEIGH*BITS_PER_PIXEL)/8
.equ HALF_BYTES_FRAMEBUFFER, BYTES_FRAMEBUFFER/2
.equ SCREEN_PIXELS, SCREEN_HEIGH*SCREEN_WIDTH
.equ BYTES_ARRAY_SIZE, 8*ARRAY_ELEMS
dir_framebuffer_ppal: .dword 0
half_bytes_framebuffer: .dword HALF_BYTES_FRAMEBUFFER
half_screen_pixels: .dword SCREEN_PIXELS/2

//Brick and boxes
.equ QUARTER_SQUARES_SIZE,      12
.equ SPACE_BRICKS,  3
.equ BRICKS_HEIGH, 200
.equ ARRAY_ELEMS, 2
brick_heigh: .dword 200
initial_br_pos: .dword 300
array_elem_distance: .dword 100
brick_array_size: .dword ARRAY_ELEMS

//cloud
.equ CLOUD_FACTOR_X, 20
.equ CLOUD_FACTOR_Y, 5
.equ CLOUD_CIRCUNF, 7
//fungi
.equ FUNGI_DETAIL, 8
.equ FUNGI_SIZE, 12
.equ FUNGI_SPACE, 2
//floor
.equ FLOOR_SIZE, 20
.equ FLOOR_SPACE, 6
.equ FLOOR_HEIGH, 350
.equ FLOOR_ELEMENTS, SCREEN_WIDTH/(4*FLOOR_SIZE) + 1
floor_heigh: .dword FLOOR_HEIGH
floor_array_size: .dword FLOOR_ELEMENTS
floor_size: .dword FLOOR_SIZE


//velocidades
.equ brick_speed, 5

        //    contador 1 al 3 
        //

 
 
 
colorChair1: .word 0x202020
colorGrey2: .word 0xC0C0C0
colorBlack: .word 0x0
colorBrick: .word 0xCC6600
colorBlueSky: .word 0x3E92D2
colorLBrown: .word 0xFFB266
colorRed: .word 0xCC0000
colorDRed: .word 0x990000
colorGrey1: .word 0xA0A0A0
colorWhite: .word 0xFFFFFF

.endif
