/*
 * test.xc
 *
 *  Created on: Jan 30, 2014
 *      Author: bala
 */
#include <platform.h>
#include <print.h>



// For circle slot
on tile[1]: in port pix_clk = XS1_PORT_1J;
on tile[1]: in port frame_valid = XS1_PORT_1K;
on tile[1]: in port line_valid = XS1_PORT_1L;
on tile[1]: in buffered port:32 data_port = XS1_PORT_16A;
on tile[1]: clock   clk     = XS1_CLKBLK_1;

on tile[0]: out port lval = XS1_PORT_1L;
on tile[0]: out buffered port:32 pclk = XS1_PORT_1J;
on tile[0]: out port fval = XS1_PORT_1K;
on tile[0]: out buffered port:32 pix = XS1_PORT_16A;
on tile[0]: clock clk25m = XS1_CLKBLK_1;
on tile[0]: clock clk50m = XS1_CLKBLK_2;


#define DEV_ADDR 0x48   // Seven most sig bits of 0x90 for write, 0x91 for read
#define CHIP_CNTL_REG 0x07
#define READ_MODE_REG 0x0D
#define TEST_PAT_REG 0x7F
#define IMG_SIZE 752*480

void fake_img_sensor()
{
    timer t;
    unsigned tim;
    set_port_clock(lval,clk25m);
    set_port_clock(fval,clk25m);
    set_port_clock(pclk,clk50m);
    set_port_clock(pix,clk25m);

    set_clock_div(clk25m,2);    // Division by 4
    set_clock_div(clk50m,1);    // Division by 2
    start_clock(clk25m);
    start_clock(clk50m);

    t :> tim;
    t when timerafter (tim+50) :> void;
    fval <: 1;
    lval <: 1;

 //   while(1)
    for (unsigned i=0;i<47;i++) // 47*16=752
    {
        pclk <: 0xAAAAAAAA;

        pix <:  0x11112222;
        pix <:  0x33334444;
        pix <:  0x55556666;
        pix <:  0x77778888;
        pix <:  0x9999AAAA;
        pix <:  0xBBBBCCCC;
        pix <:  0xDDDDEEEE;
        pix <:  0xFFFF0000;
 //       pclk <: 0x0;

    }


}


//#pragma unsafe arrays
void read_data(streaming chanend c){

  unsigned data_val;

//  unsigned data[376];
//  unsigned * alias data_ptr;
//   data_ptr = &data[0];


    // Port clock setup
    configure_clock_src(clk, pix_clk);
    configure_in_port_strobed_slave(data_port, line_valid, clk);
    start_clock(clk);

    // Input data of a frame
    frame_valid when pinseq(0) :> void;
    frame_valid when pinseq(1) :> void; // wait for a valid frame

    asm volatile("setc res[%0], 1" ::"r"(data_port));
    for (unsigned i=0; i< 376; i++){
        asm volatile("in %0, res[%1]":"=r"(data_val):"r"(data_port));
        c <: data_val;
    }
/*
#pragma loop unroll(376)  //752/2=376
    for (unsigned i=0; i< 376; i++){
//      data_port :> data[i];
//      data_port :> *data_ptr++;
        data_port :> data_val;
        c <: data_val;
    }

    data_ptr = &data[0];
    for (unsigned i=0; i<376; i++)
    {
        printhexln(*data_ptr++);

    }
*/


}

//#pragma unsafe arrays
void store_data(streaming chanend c){
    unsigned data[376];
//    unsigned * alias data_ptr;

//    data_ptr = &data[0];

//#pragma loop unroll(376)
    for (unsigned i=0; i<376; i++){
        c :> data[i];
//        c :> *data_ptr++;
    }

    for (unsigned i=0; i<376; i++)
    {
        printhexln(data[i]);

    }

}


int main(){
    streaming chan c_img_sen;

    par{
        on tile[1]: read_data(c_img_sen);
        on tile[0]: store_data(c_img_sen);
        on tile[0]: fake_img_sensor();

        on tile[1]: par(int i=0;i<7;i++)
                        while (1) {
                          set_core_fast_mode_on();
                        }

    }

    return 0;
}

