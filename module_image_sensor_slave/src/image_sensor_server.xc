// Copyright (c) 2014, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>
#include <stdio.h>
#include <xs1.h>
#include <platform.h>
#include <print.h>
#include <string.h>
#include <timer.h>

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

typedef struct img_snsr_slave_mode_ports{
   out port exposure;
   out port stfrm_out;
   out port stln_out;
   in port led_out; // not used
}img_snsr_slave_mode_ports;

// Port declaration
on tile[0] : r_i2c i2c_ports = { XS1_PORT_1H, XS1_PORT_1I, 1000};

on tile[0] : image_sensor_ports imgports = { //circle slot
   XS1_PORT_1J, XS1_PORT_1K, XS1_PORT_1L, XS1_PORT_8C,
   XS1_CLKBLK_1
};

on tile[0] : img_snsr_slave_mode_ports imgports_slave = { // circle slot
  XS1_PORT_1E, XS1_PORT_1D, XS1_PORT_1P, XS1_PORT_1O
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

    configure_out_port(imgports_slave.stln_out, imgports.clk1,0);
    configure_clock_src(imgports.clk1, imgports.pix_clk);   // Port clock setup
    configure_in_port(imgports.data_port,imgports.clk1);
    configure_in_port(imgports.line_valid,imgports.clk1);
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
/********************************************************************************************
 * As per datasheet (Page No. 49,Figure 18) slave mode operation is carried out based on the
 * clock cycles at which the input pins of the sensor is triggered.
 * Pins used : EXPOSURE, STFRM_OUT, STLN_OUT
 * As mentioned in datasheet Vertical Blank (context A) is set to 4.
 * STLN_OUT is maintained as much as near to LINE_VALID values.i.e similary to it.
 * EXPOSURE : |```````````````|___________________________________________
 * STFRM_OUT: ______________________________|````````````````|___________
 * STLN_OUT : ________________________________________|``````````````|__|``````````````|__|```
 *
 *          : |<------- Integration Time --------->|<------- Vertical Blanking --------- >|
 * ---------------------------------------------------------------------------------------- *
 * Pixel Integration Control (Page No. 52)
 * Total Integration Time = (No. of rows of integration x row time) +
 *                          (No. of pixels of integration x pixel time)
 * No. of rows of integration = R0x0B => Coarse Shutter Width 1 Context A = 480
 * No. of pixels of Integration = R0xD5 => Fine Shutter Width Total Context A = 0
 * Row Timing = (R0x04 + R0x05) master clock periods = (480 + 220) = 700 master clock periods
 * pixel time = pixel clock = 25MHz = 40nSec
 * Integration Time = (480 x 846) + (0 x 40nSec) = (406080) master clock period = 16243.2uSec
 * ---------------------------------------------------------------------------------------- *
 * STLN_OUT time is approximately equal to LINE_VALID time (Page No. 13, Figure 8, Table 4)
 * Row Timing = (R0x04 + R0x05) master clock periods = (752 + 94) = 846 master clock periods
 * Active data time (ON Time) = 752 pixel clocks = 30.08uSec = 3008 ticks
 * Horizontal blanking (OFF Time) = 94 pixel clocks = 3.76uSec = 376 ticks
 * ---------------------------------------------------------------------------------------- *
 * Consider EXPOSURE Time (half of Integration Time) = (16243.2/2) = 8121.6uSec = 812160 ticks
 * Assuimng STFRM_OUT Time as 25% Integration Time = (16243.2x0.25) = 4060.8uSec = 406080 ticks
 *******************************************************************************************/
static inline void trigger_exposure_stfrm_out(void)
{

    imgports_slave.exposure  <: 1;
    i2c_ports.sda <: 1;  //added for SDATA_Exposure on same i/o

    delay_ticks(812160);
    imgports_slave.exposure  <: 0;
    i2c_ports.sda <: 0;  //added for SDATA_Exposure on same i/o

    delay_ticks(609120);
    imgports_slave.stfrm_out <: 1;

    delay_ticks(404576);
    imgports_slave.stln_out  <: 1; // vertical blanking period

    delay_ticks(1504);
    imgports_slave.stfrm_out <: 0;

    delay_ticks(1504);
    imgports_slave.stln_out  <: 0;

    delay_ticks(880);
    for(int i = 0; i < 5; i++) {
      imgports_slave.stln_out  <: 1;
      delay_ticks(3008);

      imgports_slave.stln_out  <: 0;
      delay_ticks(880);
    }
}
/****************************************************************************************
 *
 ***************************************************************************************/
static inline unsigned get_line(line_buf_union_t buffer[]) {

   static unsigned no_of_lines = 0;

   // trigger exposure and stfrm_out for the very first of line of each frame.
   if(!no_of_lines){
       imgports_slave.stln_out <: 0;
       i2c_ports.sda <: 0; //added for SDATA_Exposure on same i/o
       trigger_exposure_stfrm_out();
   }

   // trigger stln_out high
   imgports_slave.stln_out <: 1;
   delay_ticks(690);

   for(unsigned idx = 0; idx < words_per_line_g; idx++){
       buffer[idx].pixel_word = do_input(imgports.data_port);
   }

   // trigger stln_out low
   imgports_slave.stln_out <: 0;
   delay_ticks(2000);

   no_of_lines++;
   no_of_lines %= lines_per_frame_g;

   return no_of_lines;

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
    line_buf_union_t sensor_line_buf_1[MT9V034_MAX_WIDTH/4];
    line_buf_union_t sensor_line_buf_2[MT9V034_MAX_WIDTH/4];
    line_buf_union_t sensor_line_buf_3[MT9V034_MAX_WIDTH/4];

    line_buf_union_t * movable sensor_if_ptr[3] = {&sensor_line_buf_1[0], &sensor_line_buf_2[0], &sensor_line_buf_3[0]};

    /**< Sensor configuraion array */
    unsigned short sensor_config_array[E_SIZE_OF_CONFIG_ARRAY] = {0};

    /* Initialise image senor ports, i2c interface */
    config_image_sensor_ports();
    /* configure sensor with the default paramaters */
    memcpy(sensor_config_array+0,&sensor_resolution_param_g,sizeof(mgmt_resolution_param_t));
    memcpy(sensor_config_array+5,&sensor_hei_wid_param_g,sizeof(mgmt_ROI_param_t));
    memcpy(sensor_config_array+7,&sensor_color_param_g,sizeof(unsigned short));

    if(CONFIG_SUCCESS == image_sensor_init(i2c_ports,sensor_config_array,CONFIG_IN_SLAVE)) {
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
                  if(CONFIG_SUCCESS == image_sensor_init(i2c_ports,sensor_config_array,CONFIG_IN_SLAVE)) {
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

            case operation_started => apm_us.get_new_line(line_buf_union_t * movable &line_buf_ptr, mgmt_ROI_param_t &metadata) -> {unsigned line_num}: {
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

            case operation_started => apm_us.release_line_buf(line_buf_union_t * movable &line_buf_ptr):
              sensor_if_ptr[sensor_ptr_release_idx++] = move(line_buf_ptr);
              sensor_ptr_release_idx %= 3;
              break;
        }
    }
}

