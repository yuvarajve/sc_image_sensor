#ifndef IMAGE_SENSOR_H_
#define IMAGE_SENSOR_H_

#include "i2c.h"

typedef struct image_sensor_ports{
  in port pix_clk;
  in port frame_valid;
  in port line_valid;
  in buffered port:32 data_port;
  out port ?exposure;   // for snapshot mode
  r_i2c i2c_ports;
  clock clk1;
}image_sensor_ports;

typedef interface image_sensor_interface {
    void setup_sensor(unsigned mode, unsigned height, unsigned width);
    void rx_frames(unsigned height, unsigned width);
    void get_frame(unsigned height, unsigned width);
}image_sensor_interface;


// Function prototypes
void image_sensor_server(image_sensor_interface server inf, image_sensor_ports &imgports, streaming chanend c_imgSensor);
void image_sensor_setup_master_mode(image_sensor_interface client inf, unsigned height, unsigned width);
void image_sensor_setup_snapshot_mode(image_sensor_interface client inf, unsigned height, unsigned width);
void image_sensor_master_mode_start_rx(image_sensor_interface client inf, unsigned height, unsigned width);
void image_sensor_master_mode_rx_frame(streaming chanend c_imgSensor, unsigned height, unsigned width, chanend c_dispCont, unsigned frBuf);
void image_sensor_snapshot_mode_get_frame(image_sensor_interface client inf, streaming chanend c_imgSensor, unsigned height, unsigned width, chanend c_dispCont, unsigned frBuf);



#endif /* IMAGE_SENSOR_H_ */
