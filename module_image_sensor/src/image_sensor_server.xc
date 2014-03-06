#include <timer.h>

#include "image_sensor.h"
#include "image_sensor_conf.h"
#include "image_sensor_defines.h"
#include "i2c.h"


static void config_registers(struct image_sensor_ports &imgports){
    unsigned char i2c_data[2];
    unsigned horBlank, rowStart, colStart;

    i2c_master_init(imgports.i2c_ports);

    i2c_master_read_reg(DEV_ADDR, RESET_REG, i2c_data, 2, imgports.i2c_ports);
    i2c_data[1] |= 0x03;
    i2c_master_write_reg(DEV_ADDR, RESET_REG, i2c_data, 2, imgports.i2c_ports);
    delay_milliseconds(1);

    i2c_data[0] = WIN_HEIGHT >> 8; // MS byte of height
    i2c_data[1] = WIN_HEIGHT & 0xff; // LS byte
    i2c_master_write_reg(DEV_ADDR, WIN_HEIGHT_REG, i2c_data, 2, imgports.i2c_ports);
    delay_milliseconds(1);


    i2c_data[0] = WIN_WIDTH >> 8; // MS byte of width
    i2c_data[1] = WIN_WIDTH & 0xff; // LS byte
    i2c_master_write_reg(DEV_ADDR, WIN_WIDTH_REG, i2c_data, 2, imgports.i2c_ports);
    delay_milliseconds(1);

    // Total row time should be 690 cols for correct operation of ADC. If not, add horizontal blanking pulses.
    if (WIN_WIDTH<700) {
        horBlank = 700-WIN_WIDTH;

        i2c_data[0] = horBlank >> 8; // MS byte of width
        i2c_data[1] = horBlank & 0xff; // LS byte
        i2c_master_write_reg(DEV_ADDR, HOR_BLANK_REG, i2c_data, 2, imgports.i2c_ports);
    }

    // Align the capture window to the center of sensor's resolution
    rowStart = (MAX_HEIGHT-WIN_HEIGHT)/2;
    colStart = (MAX_WIDTH-WIN_WIDTH)/2;

    i2c_data[0] = rowStart >> 8; // MS byte of row start
    i2c_data[1] = rowStart & 0xff; // LS byte
    i2c_master_write_reg(DEV_ADDR, ROW_START_REG, i2c_data, 2, imgports.i2c_ports);
    delay_milliseconds(1);

    i2c_data[0] = colStart >> 8; // MS byte of col start
    i2c_data[1] = colStart & 0xff; // LS byte
    i2c_master_write_reg(DEV_ADDR, COL_START_REG, i2c_data, 2, imgports.i2c_ports);
    delay_milliseconds(1);

    i2c_master_read_reg(DEV_ADDR, CHIP_CNTL_REG, i2c_data, 2, imgports.i2c_ports);
    delay_milliseconds(1);
    i2c_data[0] &= 0b11111101;  // Clearing bit 9 for normal operation
    i2c_master_write_reg(DEV_ADDR, CHIP_CNTL_REG, i2c_data, 2, imgports.i2c_ports);
    delay_milliseconds(1);

    i2c_data[0] = 0xDE; // MS byte
    i2c_data[1] = 0xAD; // LS byte
    i2c_master_write_reg(DEV_ADDR, LOCK_REG, i2c_data, 2, imgports.i2c_ports);
    delay_milliseconds(1);


}

static inline void config_data_port(struct image_sensor_ports &imgports){

    // Port clock setup
    configure_clock_src(imgports.clk1, imgports.pix_clk);
    configure_in_port_strobed_slave(imgports.data_port, imgports.line_valid, imgports.clk1);
    start_clock(imgports.clk1);

}

static inline void setc(in buffered port:32 data_port) {
  asm volatile("setc res[%0], 1" ::"r"(data_port)); }

static inline unsigned do_input(in buffered port:32 data_port) {
  unsigned data;
  asm volatile("in %0, res[%1]":"=r"(data):"r"(data_port));
  return data;
}


void image_sensor_server(struct image_sensor_ports &imgports, streaming chanend c_imgSensor){

    config_registers(imgports);
    config_data_port(imgports);


    while (1){

                c_imgSensor :> unsigned;

                imgports.frame_valid when pinseq(0) :> void;
                imgports.frame_valid when pinseq(1) :> void; // wait for a valid frame

                setc(imgports.data_port);
                for (unsigned i=0; i<WIN_HEIGHT*WIN_WIDTH/2; i++){
                    unsigned data = do_input(imgports.data_port);
                    c_imgSensor <: data;
                }

    }

}
