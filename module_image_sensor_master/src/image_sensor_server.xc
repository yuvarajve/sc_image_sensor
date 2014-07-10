// Copyright (c) 2014, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <platform.h>
#include "image_sensor_server.h"

typedef struct image_sensor_ports{
  in port pix_clk;
  in port frame_valid;
  in port line_valid;
  in buffered port:32 data_port;
  r_i2c i2c_ports;
  clock clk1;
}image_sensor_ports;

typedef struct img_snsr_slave_mode_ports{
   out port exposure;
   out port stfrm_out;
   out port stln_out;
   in port led_out; // not used
}img_snsr_slave_mode_ports;

// Port declaration
on tile[1] : image_sensor_ports imgports = { //circle slot
   XS1_PORT_1J, XS1_PORT_1K, XS1_PORT_1L, XS1_PORT_16B,
   {XS1_PORT_1H, XS1_PORT_1I, 1000}, XS1_CLKBLK_1
};

on tile[1] : img_snsr_slave_mode_ports imgports_slave = { // circle slot
  XS1_PORT_1E, XS1_PORT_1D, XS1_PORT_1P, XS1_PORT_1O
};

static inline void config_data_port(struct image_sensor_ports &imgports) {

    configure_clock_src(imgports.clk1, imgports.pix_clk);   // Port clock setup
    configure_in_port_strobed_slave(imgports.data_port, imgports.line_valid, imgports.clk1);
    start_clock(imgports.clk1);
}
/***************************************************************************//**
 * @brief
 *   Image Sensor Slave Mode Server.
 *
 * @param[in] None
 *
 * @return
 *  None.
 *
 ******************************************************************************/
void image_sensor_server(interface mgmt_interface server sensorif, interface pipeline_interface server apm_us) {

    char sensor_data_send_ptr_idx = 0;
    char sensor_ptr_release_idx = 0;
    unsigned sensor_line_buf_1[8];
    unsigned sensor_line_buf_2[8];
    unsigned sensor_line_buf_3[8];

    unsigned * movable sensor_if_ptr[3] = {&sensor_line_buf_1[0], &sensor_line_buf_2[0], &sensor_line_buf_3[0]};

    while(1){

        select {
            case sensorif.apm_mgmt(mgmt_intrf_commands_t command):
              if(command == SET_RESOLUTION)
                  printstrln("sensor_if: Resoultion received from mgmt_if");
              else if(command == START_OPERATION) {
                  printstrln("sensor_if: Start operation received from mgmt_if");
                  // start sending exposure, stfrm_out and get first line
                  fill(sensor_if_ptr[sensor_data_send_ptr_idx]);
              }

              sensorif.request_response();
              break;

            case sensorif.get_response(void) -> mgmt_intrf_status_t sensor_if_status:
              sensor_if_status = APM_MGMT_SUCCESS;
              break;

            case apm_us.get_new_line(unsigned * movable &line_buf_ptr): {
              line_buf_ptr = move(sensor_if_ptr[sensor_data_send_ptr_idx++]);
              sensor_data_send_ptr_idx %= 3;
              fill(sensor_if_ptr[sensor_data_send_ptr_idx]);
              }
              break;

            case apm_us.release_line_buf(unsigned * movable &line_buf_ptr):
              sensor_if_ptr[sensor_ptr_release_idx++] = move(line_buf_ptr);
              sensor_ptr_release_idx %= 3;
              break;
        }
    }
}
#if 0
void image_sensor_server(void) {

  config_data_port(imgports);
  if(CONFIG_SUCCESS == image_sensor_init(imgports.i2c_ports,CONFIG_IN_SLAVE)) {

    while(1) {

    } /**< Image sensor slave mode core functionality begins here... */
  } /**< Image sensor initialisation */
}
#endif
