/*
 * app_camera_test.xc
 *
 *  Created on: Dec 3, 2013
 *      Author: Sudha
 */

#include <platform.h>
#include <print.h>

#include "i2c.h"

// For circle slot
on tile[1]: in port pix_clk = XS1_PORT_1J;
on tile[1]: in port frame_valid = XS1_PORT_1K;
on tile[1]: in buffered port:1 line_valid = XS1_PORT_1L;
on tile[1]: in buffered port:32 data_port = XS1_PORT_16B;
on tile[1]: r_i2c i2c_ports = { XS1_PORT_1H, XS1_PORT_1I, 1000};

on tile[1]: clock clk1 = XS1_CLKBLK_1;
on tile[1]: out port sys_clk = XS1_PORT_1A;


#define DEV_ADDR 0x48   // Seven most sig bits of 0x90 for write, 0x91 for read
#define CHIP_VER_REG 0x00
#define CHIP_CNTL_REG 0x07
#define CLK_FREQ_DIV_FACT 100


void app(){
	timer t;
	unsigned time, run=1, frames = 0, lines = 0, cols = 0;
	int x;
//	unsigned data[5000];
	unsigned char dbytes[2];

	// Generate sys clk for sensor
    configure_clock_rate_at_least(clk1,100,CLK_FREQ_DIV_FACT);  // clk freq set to 100/CLK_FREQ_DIV_FACT MHz
    configure_port_clock_output(sys_clk, clk1);
    start_clock(clk1);


	i2c_master_read_reg(DEV_ADDR, CHIP_CNTL_REG, dbytes, 2, i2c_ports);
	printhex(dbytes[0]); // MS byte
	printhexln(dbytes[1]); // LS byte

	// Frame rate
	frame_valid :> x;
	t :> time;

	while (run){
		select {
			case t when timerafter(time+XS1_TIMER_HZ) :> void:	//one second wait
					run = 0;
			break;
			case frame_valid when pinsneq(x) :> x:	//check for transitions
				frames++;
			break;
		}
	}

    printstr("Number of frames captured in a sec: ");
    printuintln(frames/2);

	// Lines per frame
	frame_valid when pinseq(0) :> void;
	frame_valid when pinseq(1) :> void;
	run = 1;
	line_valid :> x;

	while (run){
	    select {
	        case frame_valid when pinseq(0) :> void:
	            run = 0;
	        break;
	        case line_valid when pinsneq(x) :> x:
	            lines++;
	        break;
	    }
	}

    printstr("Number of lines in a frame: ");
    printuintln(lines/2);

    //cols per line
    line_valid when pinseq(0) :> void;
    line_valid when pinseq(1) :> void;
    run = 1;
    pix_clk :> x;


    while (run){
#pragma ordered
        select {
            case line_valid when pinseq(0) :> void:
                run = 0;
            break;
            case pix_clk when pinsneq(x) :> x:
//                data_port :> data[cols];
                cols++;
            break;
        }
    }

    printstr("Number of cols in a line: ");
    printuintln(cols/2);

//    for (unsigned i=0; i<752; i++)
//        printhexln(data[i]);

}



int main(){
	par{
		on tile[1]: app();
	}

	return 0;
}
