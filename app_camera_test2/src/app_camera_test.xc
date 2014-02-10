/* Additions:
 * struct for ports,
 */
#include <platform.h>
#include <print.h>

#include "i2c.h"

// For circle slot
on tile[1]: in port pix_clk = XS1_PORT_1J;
on tile[1]: in port frame_valid = XS1_PORT_1K;
on tile[1]: in port line_valid = XS1_PORT_1L;
on tile[1]: in buffered port:32 data_port = XS1_PORT_16B;
on tile[1]: r_i2c i2c_ports = { XS1_PORT_1H, XS1_PORT_1I, 1000};
on tile[1]: clock   clk1     = XS1_CLKBLK_1;
on tile[1]: clock clk2 = XS1_CLKBLK_2;
on tile[1]: out port sys_clk = XS1_PORT_1A;


#define DEV_ADDR 0x48   // Seven most sig bits of 0x90 for write, 0x91 for read
#define CHIP_CNTL_REG 0x07
#define READ_MODE_REG 0x0D
#define TEST_PAT_REG 0x7F
#define IMG_SIZE 752*480
#define DELAY 100000000/50000000


void generate_sysclk(){
    configure_clock_rate_at_least(clk1,100,5);
    configure_port_clock_output(sys_clk, clk1);
    start_clock(clk1);

//    while(1);   // Use this while if run on a separate tile

/*  // Run on separate tile if timer is used.
    timer t;
    unsigned state=1, time;

    t:>time;
    while (1){
       sys_clk <: state;
       time += DELAY;
       t when timerafter(time) :> void;
       state=!state;
    }
*/

}

void read_data(streaming chanend c){
	unsigned npix = 0, run=1;
	unsigned char dbytesR[2], dbytesW[2];
	unsigned data;
//	unsigned data[752];
//	unsigned * alias data_ptr;

 //   data_ptr = &data[0];

	generate_sysclk();

	i2c_master_read_reg(DEV_ADDR, CHIP_CNTL_REG, dbytesR, 2, i2c_ports);
	printhex(dbytesR[0]); // MS byte
	printhexln(dbytesR[1]); // LS byte

    dbytesW[0] = 0x03; // MS byte
    dbytesW[1] = 0x08; // LS byte for col binning of 4
    i2c_master_write_reg(DEV_ADDR, READ_MODE_REG, dbytesW, 2, i2c_ports);

    i2c_master_read_reg(DEV_ADDR, READ_MODE_REG, dbytesR, 2, i2c_ports);
    printhex(dbytesR[0]); // MS byte
    printhexln(dbytesR[1]); // LS byte


//    dbytesW[0] = 0x30; // MS byte; 0x30 for horizontal shade; 0x28 for vertical shade; 0x38 for diagonal shade;
//    dbytesW[1] = 0; // LS byte
    dbytesW[0] = 0x27; // MS byte; For fixed pattern
    dbytesW[1] = 0xFF; // LS byte
    i2c_master_write_reg(DEV_ADDR, TEST_PAT_REG, dbytesW, 2, i2c_ports);

    i2c_master_read_reg(DEV_ADDR, TEST_PAT_REG, dbytesR, 2, i2c_ports);
    printhex(dbytesR[0]); // MS byte
    printhexln(dbytesR[1]); // LS byte


	// Port clock setup
	configure_clock_src(clk2, pix_clk);
	configure_in_port_strobed_slave(data_port, line_valid, clk2);
	start_clock(clk2);

	// Input data of a frame
	frame_valid when pinseq(0) :> void;
	frame_valid when pinseq(1) :> void; // wait for a valid frame

//	for (unsigned r=0; r<10; r++)
	for (unsigned i=0; i<752; i++){
//	    data_port :> data[i];
//	    data_port :> *data_ptr++;
	    data_port :> data;
	    c <: data;
	}


/*
	while (run){
#pragma ordered
        select {
            case frame_valid when pinseq(0) :> void:
                run = 0;
            break;
            case data_port :> data:
                npix++;
            break;
        }
    }

    printstr("Number of pixels: ");
    printuintln(npix);
*/

}

#pragma unsafe arrays
void store_data(streaming chanend c){
    unsigned data[752];
//    unsigned * alias data_ptr;

//    data_ptr = &data[0];

//  for (unsigned r=0; r<10; r++)
    for (unsigned i=0; i<752; i++){
        c :> data[i];
//        c :> *data_ptr++;
    }

    for (unsigned i=0; i<752; i++){
        // print MS byte of 10 bits
 //       printintln((data[i]>>2)&0xFF);
 //       printintln((data[i]>>18)&0xFF);
        // print original 10 bit value
        printintln((data[i]>>16)&0x3FF);
        printintln(data[i]&0x3FF);
    }

}


int main(){
    streaming chan c_img_sen;

	par{
//        on tile[1]: generate_sysclk();
		on tile[1]: read_data(c_img_sen);
		on tile[0]: store_data(c_img_sen);
	}

	return 0;
}
