// Copyright (c) 2014, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <platform.h>
#include <print.h>

#include "pipeline_interface.h"
#include "image_sensor_config.h"
#include "image_sensor_server.h"

typedef struct image_sensor_ports{
  in port pix_clk;
  in port frame_valid;
  in port line_valid;
  in buffered port:32 data_port;
  clock clk1;
}image_sensor_ports;

// Port declaration
on tile[1] : r_i2c i2c_ports = { XS1_PORT_1H, XS1_PORT_1I, 1000};

on tile[1] : image_sensor_ports imgports = { //circle slot
   XS1_PORT_1J, XS1_PORT_1K, XS1_PORT_1L, XS1_PORT_8C,
   {XS1_PORT_1H, XS1_PORT_1I, 1000}, XS1_CLKBLK_1
};

/****************************************************************************************
 *
 ***************************************************************************************/
static inline void config_image_sensor_ports(void) {

    configure_clock_src(imgports.clk1, imgports.pix_clk);   // Port clock setup
    configure_in_port_strobed_slave(imgports.data_port, imgports.line_valid, imgports.clk1);
    start_clock(imgports.clk1);
}
/****************************************************************************************
 *
 ***************************************************************************************/
static inline unsigned do_input(in buffered port:32 data_port) {
  unsigned data;
  asm volatile("in %0, res[%1]":"=r"(data):"r"(data_port));
  return data;
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

    char operation_started = 0;
    char sensor_data_send_ptr_idx = 0;
    char sensor_ptr_release_idx = 0;
    mgmt_intrf_status_t sensor_if_status_l = APM_MGMT_FAILURE;
    unsigned sensor_line_buf_1[CONFIG_WINDOW_WIDTH+8];
    unsigned sensor_line_buf_2[CONFIG_WINDOW_WIDTH+8];
    unsigned sensor_line_buf_3[CONFIG_WINDOW_WIDTH+8];

    unsigned * movable sensor_if_ptr[3] = {&sensor_line_buf_1[0], &sensor_line_buf_2[0], &sensor_line_buf_3[0]};

    /* Initialise image senor ports, i2c interface */
    config_image_sensor_ports();
    if(CONFIG_SUCCESS == image_sensor_init(i2c_ports,CONFIG_IN_MASTER)) {
        sensor_if_status_l = APM_MGMT_SUCCESS;
    }

    while(1){

        select {
            case sensorif.apm_mgmt(mgmt_intrf_commands_t command):
              if(command == SET_SCREEN_RESOLUTION)
                  printstrln("sensor_if: Resoultion received from mgmt_if");
              else if(command == START_OPERATION) {
                  printstrln("sensor_if: Start operation received from mgmt_if");
                  operation_started = 1;
                  // TODO: Start filling the SDRAM frame buffer
              }
              else if(command == STOP_OPERATION)
                  operation_started = 0;

              sensorif.request_response();
              break;

            case sensorif.get_response(void) -> mgmt_intrf_status_t sensor_if_status:
              sensor_if_status = sensor_if_status_l;
              break;

            case operation_started => apm_us.get_new_line(unsigned * movable &line_buf_ptr): {
              line_buf_ptr = move(sensor_if_ptr[sensor_data_send_ptr_idx++]);
              sensor_data_send_ptr_idx %= 3;
              // TODO: get line from SDRAM
              }
              break;

            case operation_started => apm_us.release_line_buf(unsigned * movable &line_buf_ptr):
              sensor_if_ptr[sensor_ptr_release_idx++] = move(line_buf_ptr);
              sensor_ptr_release_idx %= 3;
              break;
        }
    }
}
