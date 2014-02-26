#include <timer.h>

#include "image_sensor.h"
#include "image_sensor_defines.h"


static void config_registers(image_sensor_ports ports, unsigned mode, unsigned height, unsigned width){
    unsigned char i2c_data[2];
    unsigned horBlank;

    i2c_master_init(ports.i2c_ports);

    i2c_master_read_reg(DEV_ADDR, RESET_REG, i2c_data, 2, ports.i2c_ports);
    i2c_data[1] |= 0x03;
    i2c_master_write_reg(DEV_ADDR, RESET_REG, i2c_data, 2, i2c_ports);
    delay_milliseconds(1);


    i2c_master_read_reg(DEV_ADDR, CHIP_CNTL_REG, i2c_data, 2, ports.i2c_ports);
    i2c_data[0] &= 0b11111101;  // Clearing bit 9 for normal operation
    if (mode==SNAPSHOT)
        i2c_data[1] |= (0x03 << 3); // Set bits 3,4 for snapshot mode
    i2c_master_write_reg(DEV_ADDR, CHIP_CNTL_REG, i2c_data, 2, ports.i2c_ports);
    delay_milliseconds(1);


    i2c_data[0] = WIN_HEIGHT >> 8; // MS byte of height
    i2c_data[1] = WIN_HEIGHT & 0xff; // LS byte
    i2c_master_write_reg(DEV_ADDR, WIN_HEIGHT_REG, i2c_data, 2, ports.i2c_ports);
    delay_milliseconds(1);

    i2c_data[0] = WIN_WIDTH >> 8; // MS byte of width
    i2c_data[1] = WIN_WIDTH & 0xff; // LS byte
    i2c_master_write_reg(DEV_ADDR, WIN_WIDTH_REG, i2c_data, 2, ports.i2c_ports);
    delay_milliseconds(1);

    // Total row time should be 690 cols for correct operation of ADC. If not, add horizontal blanking pulses.
    if (width<700) {
        horBlank = 700-width;

        i2c_data[0] = horBlank >> 8; // MS byte of width
        i2c_data[1] = horBlank & 0xff; // LS byte
        i2c_master_write_reg(DEV_ADDR, HOR_BLANK_REG, i2c_data, 2, ports.i2c_ports);
    }

}

static inline void config_data_port(image_sensor_ports ports){

    // Port clock setup
    configure_clock_src(ports.clk1, ports.pix_clk);
    configure_in_port_strobed_slave(ports.data_port, ports.line_valid, ports.clk1);
    start_clock(ports.clk1);

}

static inline void setc(in buffered port:32 data_port) {
  asm volatile("setc res[%0], 1" ::"r"(data_port)); }

static inline unsigned do_input(in buffered port:32 data_port) {
  unsigned data;
  asm volatile("in %0, res[%1]":"=r"(data):"r"(data_port));
  return data;
}


void image_sensor_server(image_sensor_interface server inf, image_sensor_ports ports, streaming chanend c_imgSensor){

    while (1){

        select {
            case inf.setup_sensor(unsigned mode, unsigned height, unsigned width):
                config_registers(ports, mode, height, width);
                config_data_port(ports);
            break;

            case inf.get_frame(unsigned mode, unsigned height, unsigned width):
                if (mode==SNAPSHOT){
                    ports.exposure <: 1;
                    delay_milliseconds(1);
                    ports.exposure <: 0;
                }

                frame_valid when pinseq(0) :> void;
                frame_valid when pinseq(1) :> void; // wait for a valid frame

                setc(ports.data_port);
                for (unsigned i=0; i<height*width/2; i++){
                    unsigned data;
                    data = do_input(ports.data_port);
                    c_imgSensor <: data;
                }
            break;
        }

    }
}
