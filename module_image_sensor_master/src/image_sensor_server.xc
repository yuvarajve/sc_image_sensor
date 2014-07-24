// Copyright (c) 2014, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>
#include <stdio.h>
#include <xs1.h>
#include <platform.h>
#include <print.h>
#include <string.h>

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
   XS1_CLKBLK_1
};

/**< global variables
 * Sensor will get configured with these global variables initially
 * Note: These configuration are compatible with LCD resolution (480x272)
 * */
unsigned lines_per_frame_g = CONFIG_WINDOW_HEIGHT;
unsigned words_per_line_g = CONFIG_WINDOW_WIDTH/4;
unsigned get_line_num_g = 0;

mgmt_resolution_param_t sensor_resolution_param_g = {
 136, 106, 94, 4, 10
};
mgmt_ROI_param_t sensor_hei_wid_param_g = {
  CONFIG_WINDOW_HEIGHT, CONFIG_WINDOW_WIDTH
};
mgmt_color_param_t sensor_color_param_g = {
 RGB
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
    unsigned sensor_line_buf_1[MT9V034_MAX_WIDTH];
    unsigned sensor_line_buf_2[MT9V034_MAX_WIDTH];
    unsigned sensor_line_buf_3[MT9V034_MAX_WIDTH];

    unsigned * movable sensor_if_ptr[3] = {&sensor_line_buf_1[0], &sensor_line_buf_2[0], &sensor_line_buf_3[0]};

    /**< Sensor configuraion array */
    unsigned short sensor_config_array[E_SIZE_OF_CONFIG_ARRAY] = {0};

    /* Initialise image senor ports, i2c interface */
    config_image_sensor_ports();
    /* configure sensor with the default paramaters */
    memcpy(sensor_config_array+0,&sensor_resolution_param_g,sizeof(mgmt_resolution_param_t));
    memcpy(sensor_config_array+5,&sensor_hei_wid_param_g,sizeof(mgmt_ROI_param_t));
    memcpy(sensor_config_array+7,&sensor_color_param_g,sizeof(unsigned short));

    if(CONFIG_SUCCESS == image_sensor_init(i2c_ports,sensor_config_array,CONFIG_IN_MASTER)) {
        sensor_if_status_l = APM_MGMT_SUCCESS;
    }

    while(1){

        select {
            case sensorif.apm_mgmt(mgmt_intrf_commands_t command, void * unsafe param):
              if( (command == SET_SCREEN_RESOLUTION) && (param != NULL) ){
                  printstrln("sensor_if: Resoultion received from mgmt_if");
                  sensor_resolution_param_g = *(mgmt_resolution_param_t *)param;
                  /* copy to sensor config array */
                  memcpy(sensor_config_array+0,&sensor_resolution_param_g,sizeof(mgmt_resolution_param_t));
              }
              else if( (command == SET_COLOR_MODE) && (param != NULL) ){
                  printstrln("sensor_if: Color Mode received from mgmt_if");
                  sensor_color_param_g = *(mgmt_color_param_t *)param;
                  /* copy to sensor config array */
                  memcpy(sensor_config_array+7,&sensor_color_param_g,sizeof(unsigned short));
              }
              else if( (command == SET_REGION_OF_INTEREST) && (param != NULL) ){
                  printstrln("sensor_if: Region of Interest received from mgmt_if");
                  sensor_hei_wid_param_g = *(mgmt_ROI_param_t *)param;
                  /* copy to sensor config array */
                  memcpy(sensor_config_array+5,&sensor_hei_wid_param_g,sizeof(mgmt_ROI_param_t));
              }
              else if( (command == START_OPERATION) && (param == NULL) ) {
                  printstrln("sensor_if: Start operation received from mgmt_if");
                  printstrln("sensor_if: Reconfiguring sensor....!!!");
                  sensor_if_status_l = APM_MGMT_FAILURE;
                  if(CONFIG_SUCCESS == image_sensor_init(i2c_ports,sensor_config_array,CONFIG_IN_MASTER)) {
                      sensor_if_status_l = APM_MGMT_SUCCESS;
                      operation_started = 1;
                      get_line_num_g = get_line(sensor_if_ptr[sensor_data_send_ptr_idx]);
                  }
              }
              else if(command == STOP_OPERATION)
                  operation_started = 0;

              sensorif.request_response();
              break;

            case sensorif.get_response(void) -> mgmt_intrf_status_t sensor_if_status:
              sensor_if_status = sensor_if_status_l;
              break;

            case operation_started => apm_us.get_new_line(unsigned * movable &line_buf_ptr, mgmt_ROI_param_t metadata) -> {unsigned line_num}: {
              // for every first line of a new frame, send metadata.
              if(get_line_num_g == 1)
                  line_num = get_line_num_g;
              else
                  line_num = 0;
              /* upstream interface should simply ignore this data if line_num is zero */

              metadata = sensor_hei_wid_param_g;
              line_buf_ptr = move(sensor_if_ptr[sensor_data_send_ptr_idx++]);
              sensor_data_send_ptr_idx %= 3;
              get_line_num_g = get_line(sensor_if_ptr[sensor_data_send_ptr_idx]);
              }
              break;

            case operation_started => apm_us.release_line_buf(unsigned * movable &line_buf_ptr):
              sensor_if_ptr[sensor_ptr_release_idx++] = move(line_buf_ptr);
              sensor_ptr_release_idx %= 3;
              break;
        }
    }
}

