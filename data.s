
.ifndef data_s
.equ data_s, 0

.data
second_buffer: .skip BYTES_FRAMEBUFFER //reservo cantidad de bytes necesarios para el buffer secundario
array_of_bricks: .dword 100, 500, 1300//arreglo de posiciones de las cajas a pintar
array_of_pipes: .dword 100, 500
array_of_clouds: .dword 200, 420, 600
fungi_x_pos: .dword 80
fungi_y_pos: .dword BRICKS_HEIGH 
first_floor_position: .dword 0 //posición del primer ladrillo
mario_position: .dword 50
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

//pipes
pipes_array_size: .dword 2
new_pipe_distance: .dword 1000
pipe_heigh: .dword 280
neg_pipe_size: .dword -60

//Brick and boxes
.equ QUARTER_SQUARES_SIZE,      12
.equ SPACE_BRICKS,  3
.equ BRICKS_HEIGH, 200
.equ ARRAY_ELEMS, 3
brick_heigh: .dword 200
brick_size: .dword 4*QUARTER_SQUARES_SIZE
initial_br_pos: .dword 300
array_elem_distance: .dword 100
brick_array_size: .dword ARRAY_ELEMS
neg_brick_size: .dword -400
new_brick_distance: .dword 1000

//cloud
.equ CLOUD_FACTOR_X, 20
.equ CLOUD_FACTOR_Y, 5
.equ CLOUD_CIRCUNF, 7
neg_cloud_size: .dword -150
cloud_array_size: .dword 3
new_cloud_distance: .dword 700
cloud_heigh: .dword 70

//fungi
.equ FUNGI_DETAIL, 8
.equ FUNGI_SIZE, 12
.equ FUNGI_SPACE, 2
fungi_array_size: .dword 1
neg_fungi_size: .dword -20

//floor
.equ FLOOR_SIZE, 15
.equ FLOOR_SPACE, 6
.equ FLOOR_HEIGH, 380
.equ FLOOR_ELEMENTS, SCREEN_WIDTH/(4*FLOOR_SIZE) + 1
floor_heigh: .dword FLOOR_HEIGH
floor_size: .dword FLOOR_SIZE
neg_floor_size: .dword -(4*FLOOR_SIZE)
floor_elements: .dword FLOOR_ELEMENTS
floor_b_size: .dword 4*FLOOR_SIZE

//mario
marioSpeed: .dword 1


//velocidades y delay
delay_amount: .dword 0xFFFFFC
floorSpeed: .dword 3
bricksSpeed: .dword 3
pipesSpeed: .dword 3
cloudsSpeed: .dword 1
fungiXSpeed: .dword -4
fungiYSpeed: .dword -5






 
 
 
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
black: .dword 0x000000
red: .dword 0xFF0000
color_tubo: .dword 0xB2FF4B
color_interno_tubo: .dword 0x00C300
color_cielo: .dword 0x6E91FF
color_piel: .dword 0xFFAA3C
color_verde_oscu: .dword 0x666600
white: .dword 0xFFFFFF

.endif
