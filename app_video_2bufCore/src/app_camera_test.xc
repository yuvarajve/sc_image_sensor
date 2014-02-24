
// Sensor operating in master mode, Display on LCD using display controller

#include <platform.h>
#include <print.h>
#include <stdint.h>
#include <timer.h>

#include "i2c.h"
#include "lcd.h"
#include "sdram.h"
#include "display_controller.h"


// Port declaration
// Image sensor ports on circle slot
on tile[1]: in port pix_clk = XS1_PORT_1J;
on tile[1]: in port frame_valid = XS1_PORT_1K;
on tile[1]: in port line_valid = XS1_PORT_1L;
on tile[1]: in buffered port:32 data_port = XS1_PORT_16B;
on tile[1]: r_i2c i2c_ports = { XS1_PORT_1H, XS1_PORT_1I, 1000};
on tile[1]: clock   clk1     = XS1_CLKBLK_1;
on tile[1]: clock clk2 = XS1_CLKBLK_2;
on tile[1]: out port sys_clk = XS1_PORT_1A;
// LCD and SDRAM ports
on tile[0] : lcd_ports lcdports = { //triangle slot
  XS1_PORT_1I, XS1_PORT_1L, XS1_PORT_16B, XS1_PORT_1J, XS1_PORT_1K, XS1_CLKBLK_1 };
on tile[0] : sdram_ports sdramports = { //star slot
  XS1_PORT_16A, XS1_PORT_1B, XS1_PORT_1G, XS1_PORT_1C, XS1_PORT_1F, XS1_CLKBLK_2 };


// Sensor registers
#define DEV_ADDR 0x48   // Seven most sig bits of 0x90 for write, 0x91 for read
#define RESET_REG 0x0C
#define CHIP_CNTL_REG 0x07
#define READ_MODE_REG 0x0D
#define TEST_PAT_REG 0x7F
#define WIN_HEIGHT_REG_A 0x03
#define WIN_WIDTH_REG_A 0x04
#define HOR_BLANK_REG_A 0x05
#define WIN_HEIGHT_REG_B 0xCB
#define WIN_WIDTH_REG_B 0xCC
#define HOR_BLANK_REG_B 0xCD

#define WIN_HEIGHT 272
#define WIN_WIDTH 480


#if (WIN_WIDTH<700)     // Total row time should be 690 cols for correct operation of ADC
#define HOR_BLANK (700-WIN_WIDTH)
#endif

//#define HOR_BLANK 700

inline void generate_sysclk(){
    configure_clock_rate_at_most(clk1,100,4);
    configure_out_port(sys_clk, clk1, 0);
    configure_port_clock_output(sys_clk, clk1);
    start_clock(clk1);

}

void config_sensor(){
    unsigned char i2c_data[2];

    i2c_master_init(i2c_ports);

    i2c_master_read_reg(DEV_ADDR, RESET_REG, i2c_data, 2, i2c_ports);
    i2c_data[1] |= 0x03;
    i2c_master_write_reg(DEV_ADDR, RESET_REG, i2c_data, 2, i2c_ports);
    delay_milliseconds(1);


    i2c_master_read_reg(DEV_ADDR, CHIP_CNTL_REG, i2c_data, 2, i2c_ports);
    i2c_data[0] &= 0b11111101;
    i2c_master_write_reg(DEV_ADDR, CHIP_CNTL_REG, i2c_data, 2, i2c_ports);
    delay_milliseconds(1);


    i2c_data[0] = WIN_HEIGHT >> 8; // MS byte of height
    i2c_data[1] = WIN_HEIGHT & 0xff; // LS byte
    i2c_master_write_reg(DEV_ADDR, WIN_HEIGHT_REG_A, i2c_data, 2, i2c_ports);
    delay_milliseconds(1);
    i2c_master_write_reg(DEV_ADDR, WIN_HEIGHT_REG_B, i2c_data, 2, i2c_ports);
    delay_milliseconds(1);

    i2c_data[0] = WIN_WIDTH >> 8; // MS byte of width
    i2c_data[1] = WIN_WIDTH & 0xff; // LS byte
    i2c_master_write_reg(DEV_ADDR, WIN_WIDTH_REG_A, i2c_data, 2, i2c_ports);
    delay_milliseconds(1);
    i2c_master_write_reg(DEV_ADDR, WIN_WIDTH_REG_B, i2c_data, 2, i2c_ports);
    delay_milliseconds(1);

    i2c_data[0] = HOR_BLANK >> 8; // MS byte of width
    i2c_data[1] = HOR_BLANK & 0xff; // LS byte
    i2c_master_write_reg(DEV_ADDR, HOR_BLANK_REG_A, i2c_data, 2, i2c_ports);
    delay_milliseconds(1);
    i2c_master_write_reg(DEV_ADDR, HOR_BLANK_REG_B, i2c_data, 2, i2c_ports);
    delay_milliseconds(1);

}

inline void config_port(){

    // Port clock setup
    configure_clock_src(clk2, pix_clk);
    configure_in_port_strobed_slave(data_port, line_valid, clk2);
    start_clock(clk2);

}

static inline void setc(in buffered port:32 data_port) {
  asm volatile("setc res[%0], 1" ::"r"(data_port)); }

static inline unsigned do_input(in buffered port:32 data_port) {
  unsigned data;
  asm volatile("in %0, res[%1]":"=r"(data):"r"(data_port));
  return data;
}


void read_data(streaming chanend c){

	// Configure sensor registers, clock and port
    generate_sysclk();
	config_sensor();
	config_port();

	while(1){

        // Wait for ready signal
        c :> unsigned;

        // Input data of a frame
        frame_valid when pinseq(0) :> void;
        frame_valid when pinseq(1) :> void; // wait for a valid frame


        setc(data_port);
        for (unsigned i=0; i<LCD_HEIGHT*LCD_ROW_WORDS; i++){
            unsigned data;
            data = do_input(data_port);
            c <: data;
        }

	}
}


#pragma unsafe arrays
inline unsafe void get_row(streaming chanend c, unsigned * unsafe dataPtr){
    for (unsigned i=0; i<LCD_ROW_WORDS; i++){
        c :> *(dataPtr++);
    }
}


#pragma unsafe arrays
inline unsafe void store_row (chanend c_dc, unsigned row, unsigned frBuf, intptr_t buf){
    display_controller_image_write_line_p(c_dc, row, frBuf, buf);
    display_controller_wait_until_idle_p(c_dc, buf);
}

inline unsigned short rgb888_to_rgb565(char b, char g, char r) {
  return (unsigned short)((r >> 3) & 0x1F) | ((unsigned short)((g >> 2) & 0x3F) << 5) | ((unsigned short)((b >> 3) & 0x1F) << 11);
}


void color_interpolation(chanend c_dc, unsigned frBuf){
    unsigned buf[3][LCD_ROW_WORDS], rgb565[LCD_ROW_WORDS];
    char r[2*LCD_ROW_WORDS], g[2*LCD_ROW_WORDS], b[2*LCD_ROW_WORDS];

    // Read first two rows
    display_controller_image_read_line(c_dc, 0, frBuf, buf[0]);
    display_controller_wait_until_idle(c_dc, buf[0]);
    display_controller_image_read_line(c_dc, 1, frBuf, buf[1]);
    display_controller_wait_until_idle(c_dc, buf[1]);

    // Store first row with 0s
    for (unsigned j=0; j<LCD_ROW_WORDS; j++)
        rgb565[j]=0;
    display_controller_image_write_line(c_dc, 0, frBuf, rgb565);
    display_controller_wait_until_idle(c_dc, rgb565);

    // Find missing color components
    for (unsigned i=2; i<LCD_HEIGHT-1; i++){
        unsigned row = i-1;

        display_controller_image_read_line(c_dc, i, frBuf, buf[i%3]);
        display_controller_wait_until_idle(c_dc, buf[i%3]);

        if (row&1){
            for (unsigned j=2; j<2*LCD_ROW_WORDS-1; j+=2){    // odd row, even col, green pix
                g[j] = ((buf[row%3],short[])[j])>>2 & 0xff;
                unsigned b_top = ((buf[(row-1)%3],short[])[j])>>2 & 0xff;
                unsigned b_bot = ((buf[(row+1)%3],short[])[j])>>2 & 0xff;
                b[j] = (b_top+b_bot)/2;
                unsigned r_left = ((buf[row%3],short[])[j-1])>>2 & 0xff;
                unsigned r_right = ((buf[row%3],short[])[j+1])>>2 & 0xff;
                r[j] = (r_left+r_right)/2;
            }
            for (unsigned j=1; j<2*LCD_ROW_WORDS-1; j+=2){    // odd row, odd col, red pix
                r[j] = ((buf[row%3],short[])[j])>>2 & 0xff;
                unsigned b_diag1 = ((buf[(row-1)%3],short[])[j-1])>>2 & 0xff;
                unsigned b_diag2 = ((buf[(row-1)%3],short[])[j+1])>>2 & 0xff;
                unsigned b_diag3 = ((buf[(row+1)%3],short[])[j-1])>>2 & 0xff;
                unsigned b_diag4 = ((buf[(row+1)%3],short[])[j+1])>>2 & 0xff;
                b[j] = (b_diag1+b_diag2+b_diag3+b_diag4)/4;
                unsigned g_adj1 = ((buf[(row-1)%3],short[])[j])>>2 & 0xff;
                unsigned g_adj2 = ((buf[(row-1)%3],short[])[j])>>2 & 0xff;
                unsigned g_adj3 = ((buf[row%3],short[])[j-1])>>2 & 0xff;
                unsigned g_adj4 = ((buf[row%3],short[])[j+1])>>2 & 0xff;
                g[j] = (g_adj1+g_adj2+g_adj3+g_adj4)/4;
            }
        }
        else {
            for (unsigned j=2; j<2*LCD_ROW_WORDS-1; j+=2){    // even row, even col, blue pix
                b[j] = ((buf[row%3],short[])[j])>>2 & 0xff;
                unsigned r_diag1 = ((buf[(row-1)%3],short[])[j-1])>>2 & 0xff;
                unsigned r_diag2 = ((buf[(row-1)%3],short[])[j+1])>>2 & 0xff;
                unsigned r_diag3 = ((buf[(row+1)%3],short[])[j-1])>>2 & 0xff;
                unsigned r_diag4 = ((buf[(row+1)%3],short[])[j+1])>>2 & 0xff;
                r[j] = (r_diag1+r_diag2+r_diag3+r_diag4)/4;
                unsigned g_adj1 = ((buf[(row-1)%3],short[])[j])>>2 & 0xff;
                unsigned g_adj2 = ((buf[(row-1)%3],short[])[j])>>2 & 0xff;
                unsigned g_adj3 = ((buf[row%3],short[])[j-1])>>2 & 0xff;
                unsigned g_adj4 = ((buf[row%3],short[])[j+1])>>2 & 0xff;
                g[j] = (g_adj1+g_adj2+g_adj3+g_adj4)/4;
            }
            for (unsigned j=1; j<2*LCD_ROW_WORDS-1; j+=2){    // even row, odd col, green pix
                g[j] = ((buf[row%3],short[])[j])>>2 & 0xff;
                unsigned b_left = ((buf[(row-1)%3],short[])[j])>>2 & 0xff;
                unsigned b_right = ((buf[(row+1)%3],short[])[j])>>2 & 0xff;
                b[j] = (b_left+b_right)/2;
                unsigned r_top = ((buf[row%3],short[])[j-1])>>2 & 0xff;
                unsigned r_bot = ((buf[row%3],short[])[j+1])>>2 & 0xff;
                r[j] = (r_top+r_bot)/2;
            }
        }

        // RGB565 conversion and write row
        for (unsigned j=1; j<2*LCD_ROW_WORDS-1; j++)
            (rgb565,unsigned short[])[j] = rgb888_to_rgb565(b[j], g[j], r[j]);

        (rgb565,unsigned short[])[0] = 0;
        (rgb565,unsigned short[])[2*LCD_ROW_WORDS-1] = 0;

        display_controller_image_write_line(c_dc, row, frBuf, rgb565);
        display_controller_wait_until_idle(c_dc, rgb565);
    }

    // Store last row with 0s
    for (unsigned j=0; j<LCD_ROW_WORDS; j++)
        rgb565[j]=0;
    display_controller_image_write_line(c_dc, LCD_HEIGHT-1, frBuf, rgb565);
    display_controller_wait_until_idle(c_dc, rgb565);

}



enum handshake {READY};
#pragma unsafe arrays
void store_data(streaming chanend c, chanend c_dc){
    unsigned data1[LCD_ROW_WORDS], data2[LCD_ROW_WORDS];
    unsigned * unsafe tempPtr, * unsafe readBufPtr, * unsafe storeBufPtr;
    unsigned frBuf[2], frBufIndex=0;

    // Create frame buffer
    frBuf[0] = display_controller_register_image(c_dc, LCD_ROW_WORDS, LCD_HEIGHT);
    frBuf[1] = display_controller_register_image(c_dc, LCD_ROW_WORDS, LCD_HEIGHT);
    display_controller_frame_buffer_init(c_dc, frBuf[0]);

    while (1){

        frBufIndex = 1-frBufIndex;
        //Send a ready signal for receiving data
        c <: (unsigned)READY;

        // Get frame & store
        unsafe {
            readBufPtr = data1; storeBufPtr = data2;    // pointers to manage double buffer
            get_row (c,readBufPtr);

            for (unsigned r=1; r<LCD_HEIGHT; r++){
                //swap data buffers for reading and storing
                tempPtr = readBufPtr;
                readBufPtr = storeBufPtr;
                storeBufPtr = tempPtr;

                par {
                    get_row (c,readBufPtr);
                    store_row(c_dc,r-1,frBuf[frBufIndex],(intptr_t)storeBufPtr);
                }
            }

            store_row(c_dc,LCD_HEIGHT-1,frBuf[frBufIndex],(intptr_t)readBufPtr);
        }

        // Color interpolation
        color_interpolation(c_dc, frBuf[frBufIndex]);    // TODO: Try on-the-fly color interpolation

        // Display
        display_controller_frame_buffer_commit(c_dc, frBuf[frBufIndex]);
        delay_milliseconds(10);   // To remove flicker
    }

}


int main(){
    chan c_dc, c_lcd, c_sdram;
    streaming chan c_img_sen;

	par{
		on tile[1]: read_data(c_img_sen);
		on tile[0]: store_data(c_img_sen,c_dc);
        on tile[0]: display_controller(c_dc,c_lcd,c_sdram);
        on tile[0]: lcd_server(c_lcd,lcdports);
        on tile[0]: sdram_server(c_sdram,sdramports);

//        on tile[1]: par(int i=0;i<7;i++)
//                        while (1) {
//                          set_core_fast_mode_on();
//                        }
	}

	return 0;
}
