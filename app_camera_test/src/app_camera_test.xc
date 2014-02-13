/* Additions:
 * struct for ports,
 */

// Sensor operating in master mode, Display on LCD using display controller

#include <platform.h>
#include <print.h>
#include <stdint.h>

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
#define CHIP_CNTL_REG 0x07
#define READ_MODE_REG 0x0D
#define TEST_PAT_REG 0x7F
#define WIN_HEIGHT_REG 0x03
#define WIN_WIDTH_REG 0x04


inline void generate_sysclk(){
    configure_clock_rate_at_least(clk1,100,10);
    configure_port_clock_output(sys_clk, clk1);
    start_clock(clk1);

}

void config_sensor(){
    unsigned char dbytesR[2], dbytesW[2];

    // Sensor configuration
    i2c_master_read_reg(DEV_ADDR, CHIP_CNTL_REG, dbytesR, 2, i2c_ports);
    printhex(dbytesR[0]); // MS byte
    printhexln(dbytesR[1]); // LS byte

    dbytesW[0] = 0x01; // MS byte of height=272
    dbytesW[1] = 0x10; // LS byte
    i2c_master_write_reg(DEV_ADDR, WIN_HEIGHT_REG, dbytesW, 2, i2c_ports);

    i2c_master_read_reg(DEV_ADDR, WIN_HEIGHT_REG, dbytesR, 2, i2c_ports);
    printhex(dbytesR[0]); // MS byte
    printhexln(dbytesR[1]); // LS byte

    dbytesW[0] = 0x01; // MS byte of width=480
    dbytesW[1] = 0xE0; // LS byte
    i2c_master_write_reg(DEV_ADDR, WIN_WIDTH_REG, dbytesW, 2, i2c_ports);

    i2c_master_read_reg(DEV_ADDR, WIN_WIDTH_REG, dbytesR, 2, i2c_ports);
    printhex(dbytesR[0]); // MS byte
    printhexln(dbytesR[1]); // LS byte


/*
    dbytesW[0] = 0x03; // MS byte
    dbytesW[1] = 0x08; // LS byte for col binning of 4
    i2c_master_write_reg(DEV_ADDR, READ_MODE_REG, dbytesW, 2, i2c_ports);

    i2c_master_read_reg(DEV_ADDR, READ_MODE_REG, dbytesR, 2, i2c_ports);
    printhex(dbytesR[0]); // MS byte
    printhexln(dbytesR[1]); // LS byte
*/


    dbytesW[0] = 0x28; // MS byte; 0x30 for horizontal shade; 0x28 for vertical shade; 0x38 for diagonal shade;
    dbytesW[1] = 0; // LS byte
//    dbytesW[0] = 0x27; // MS byte; For fixed pattern white
//    dbytesW[1] = 0xFF; // LS byte
//    dbytesW[0] = 0x24; // MS byte; For fixed pattern black
//    dbytesW[1] = 0; // LS byte
    i2c_master_write_reg(DEV_ADDR, TEST_PAT_REG, dbytesW, 2, i2c_ports);

    i2c_master_read_reg(DEV_ADDR, TEST_PAT_REG, dbytesR, 2, i2c_ports);
    printhex(dbytesR[0]); // MS byte
    printhexln(dbytesR[1]); // LS byte

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

	// Wait for ready signal
	c :> unsigned;

	// Input data of a frame
	frame_valid when pinseq(0) :> void;
	frame_valid when pinseq(1) :> void; // wait for a valid frame

    setc(data_port);
	for (unsigned i=0; i<LCD_HEIGHT*LCD_ROW_WORDS; i++){
//    for (unsigned i=0; i<LCD_ROW_WORDS; i++){
	    unsigned data;
	    data = do_input(data_port);
	    c <: data;
//	    c <: 0xf800f800;
	}

}


#pragma unsafe arrays
//inline unsafe unsigned get_row(streaming chanend c, unsigned * unsafe dataPtr){
inline unsafe void get_row(streaming chanend c, unsigned * unsafe dataPtr){
//timer t; unsigned t1,t2;
//t:>t1;
    for (unsigned i=0; i<LCD_ROW_WORDS; i++){
        c :> *(dataPtr++);
    }
//t:>t2;
//return(t2-t1);
}


#pragma unsafe arrays
//inline unsafe unsigned store_row (chanend c_dc, unsigned row, unsigned frBuf, intptr_t buf){
inline unsafe void store_row (chanend c_dc, unsigned row, unsigned frBuf, intptr_t buf){
//    timer t; unsigned t1,t2;
//    t:>t1;
    display_controller_image_write_line_p(c_dc, row, frBuf, buf);
    display_controller_wait_until_idle_p(c_dc, buf);
//    t:>t2;
//    return(t2-t1);

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
//{
            (rgb565,unsigned short[])[j] = rgb888_to_rgb565(b[j], g[j], r[j]);
//printhexln((rgb565,unsigned short[])[j]);
//}
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
    unsigned frBuf;
//unsigned a,b,r=0;

    // Create frame buffer
    frBuf = display_controller_register_image(c_dc, LCD_ROW_WORDS, LCD_HEIGHT);

    //Send a ready signal for receiving data
    c <: (unsigned)READY;

    // Get frame & store
    unsafe {
        readBufPtr = data1; storeBufPtr = data2;
        get_row (c,readBufPtr);

        for (unsigned r=1; r<LCD_HEIGHT; r++){
            //swap data buffers for reading and storing
            tempPtr = readBufPtr;
            readBufPtr = storeBufPtr;
            storeBufPtr = tempPtr;

            par {
//                a = get_row (c,readBufPtr);
//                b = store_row (c_dc, r-1, frBuf, (intptr_t)storeBufPtr);
                get_row (c,readBufPtr);
                store_row(c_dc,r-1,frBuf,(intptr_t)storeBufPtr);
            }
//printintln(a); printintln(b);
        }

        store_row(c_dc,LCD_HEIGHT-1,frBuf,(intptr_t)readBufPtr);
    }

    // Color interpolation
    color_interpolation(c_dc, frBuf);

    // Display
    display_controller_frame_buffer_init(c_dc, frBuf);

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
