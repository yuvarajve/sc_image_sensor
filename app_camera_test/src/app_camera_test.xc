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
    configure_clock_rate_at_least(clk1,100,4);
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

/*
    dbytesW[0] = 0x38; // MS byte; 0x30 for horizontal shade; 0x28 for vertical shade; 0x38 for diagonal shade;
    dbytesW[1] = 0; // LS byte
//    dbytesW[0] = 0x27; // MS byte; For fixed pattern white
//    dbytesW[1] = 0xFF; // LS byte
//    dbytesW[0] = 0x24; // MS byte; For fixed pattern black
//    dbytesW[1] = 0; // LS byte
    i2c_master_write_reg(DEV_ADDR, TEST_PAT_REG, dbytesW, 2, i2c_ports);

    i2c_master_read_reg(DEV_ADDR, TEST_PAT_REG, dbytesR, 2, i2c_ports);
    printhex(dbytesR[0]); // MS byte
    printhexln(dbytesR[1]); // LS byte
*/
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
//	for (unsigned i=0; i<LCD_HEIGHT*LCD_ROW_WORDS; i++){
    for (unsigned i=0; i<LCD_ROW_WORDS; i++){
	    unsigned data;
	    data = do_input(data_port);
	    c <: data;
	}

}

#pragma unsafe arrays
inline unsafe unsigned get_row(streaming chanend c, unsigned * unsafe dataPtr){
timer t; unsigned t1,t2;
t:>t1;
    for (unsigned i=0; i<LCD_ROW_WORDS; i++){
        c :> *(dataPtr++);
    }
t:>t2;
return(t2-t1);
}


#pragma unsafe arrays
inline unsafe unsigned store_row (chanend c_dc, unsigned row, unsigned frBuf, intptr_t buf){
    timer t; unsigned t1,t2;
    t:>t1;
    display_controller_image_write_line_p(c_dc, row, frBuf, buf);
    display_controller_wait_until_idle_p(c_dc, buf);
    t:>t2;
    return(t2-t1);

}


enum handshake {READY};
#pragma unsafe arrays
void store_data(streaming chanend c, chanend c_dc){
    unsigned data1[LCD_ROW_WORDS], data2[LCD_ROW_WORDS], frBuf;
    unsigned * unsafe tempPtr, * unsafe readBufPtr, * unsafe storeBufPtr;
unsigned a,b,r=0;

    // Create frame buffer
    frBuf = display_controller_register_image(c_dc, LCD_ROW_WORDS, LCD_HEIGHT);

    //Send a ready signal for receiving data
    c <: (unsigned)READY;

    // Get frame & store
    unsafe {
        readBufPtr = &data1[0]; storeBufPtr = &data2[0];
//        get_row (c,readBufPtr);

//        for (unsigned r=1; r<LCD_HEIGHT; r++){
            //swap data buffers for reading and storing
            tempPtr = readBufPtr;
            readBufPtr = storeBufPtr;
            storeBufPtr = tempPtr;

            par {
                a = get_row (c,readBufPtr);
                b = store_row (c_dc, r-1, frBuf, (intptr_t)storeBufPtr);
            }
printintln(a); printintln(b);
//        }

//        store_row(c_dc,LCD_HEIGHT-1,frBuf,(intptr_t)readBufPtr);
    }

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
