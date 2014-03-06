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


enum handshake {GET_FRAME};

// Function prototypes
void image_sensor_server(image_sensor_ports &imgports, streaming chanend c_imgSensor);
void image_sensor_get_frame(streaming chanend c_imgSensor, chanend c_dispCont, unsigned frBuf);



#endif /* IMAGE_SENSOR_H_ */
