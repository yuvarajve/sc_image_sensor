#include <timer.h>
#include <print.h>  //TODO: remove later

#include "image_sensor.h"
#include "image_sensor_defines.h"
#include "i2c.h"


static void config_registers(image_sensor_ports &imgports, unsigned mode, unsigned height, unsigned width){
    unsigned char i2c_data[2];
    unsigned horBlank, rowStart, colStart;

    i2c_master_init(imgports.i2c_ports);


    i2c_data[0] = height >> 8; // MS byte of height
    i2c_data[1] = height & 0xff; // LS byte
    i2c_master_write_reg(DEV_ADDR, WIN_HEIGHT_REG, i2c_data, 2, imgports.i2c_ports);
    delay_milliseconds(1);

    i2c_data[0] = width >> 8; // MS byte of width
    i2c_data[1] = width & 0xff; // LS byte
    i2c_master_write_reg(DEV_ADDR, WIN_WIDTH_REG, i2c_data, 2, imgports.i2c_ports);
    delay_milliseconds(1);

    // Total row time should be 690 cols for correct operation of ADC. If not, add horizontal blanking pulses.
    if (width<700) {
        horBlank = 700-width;

        i2c_data[0] = horBlank >> 8; // MS byte of width
        i2c_data[1] = horBlank & 0xff; // LS byte
        i2c_master_write_reg(DEV_ADDR, HOR_BLANK_REG, i2c_data, 2, imgports.i2c_ports);
    }

    // Align the capture window to the center of sensor's resolution
    rowStart = (MAX_HEIGHT-height)/2;
    colStart = (MAX_WIDTH-width)/2;

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
    if (mode==SNAPSHOT)
        i2c_data[1] |= (0x03 << 3); // Set bits 3,4 for snapshot mode
    i2c_master_write_reg(DEV_ADDR, CHIP_CNTL_REG, i2c_data, 2, imgports.i2c_ports);
    delay_milliseconds(1);


}

static inline void config_data_port(image_sensor_ports &imgports){

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


void image_sensor_server(image_sensor_interface server inf, image_sensor_ports &imgports, streaming chanend c_imgSensor){

    while (1){

        select {
            case inf.setup_sensor(unsigned mode, unsigned height, unsigned width):
                config_registers(imgports, mode, height, width);
                config_data_port(imgports);
            break;

            case inf.rx_frames(unsigned height, unsigned width):
                  while(1){
                      imgports.frame_valid when pinseq(0) :> void;
                      imgports.frame_valid when pinseq(1) :> void; // wait for a valid frame

                      setc(imgports.data_port);
                      for (unsigned i=0; i<height*width/2; i++){
                          unsigned data;
                          data = do_input(imgports.data_port);
                          c_imgSensor <: data;
                      }
                  }
            break;

            case inf.get_frame(unsigned height, unsigned width):
                imgports.exposure <: 1;
                delay_milliseconds(1);
                imgports.exposure <: 0;

                imgports.frame_valid when pinseq(0) :> void;
                imgports.frame_valid when pinseq(1) :> void; // wait for a valid frame

                setc(imgports.data_port);
                for (unsigned i=0; i<height*width/2; i++){
                    unsigned data;
                    data = do_input(imgports.data_port);
                    c_imgSensor <: data;
                }
            break;
        }

    }
}
