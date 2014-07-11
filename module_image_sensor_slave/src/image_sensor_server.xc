// Copyright (c) 2014, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <platform.h>
#include <print.h>
#include <timer.h>

#include "pipeline_interface.h"
#include "image_sensor_config.h"
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
    timer slv_tmr;
    unsigned tick = 0;

    imgports_slave.exposure  <: 1;
    slv_tmr :> tick;

    slv_tmr when timerafter(tick+812160) :> tick;        //812160
    imgports_slave.exposure  <: 0;

    slv_tmr when timerafter(tick+609120) :> tick;        //609120
    imgports_slave.stfrm_out <: 1;

    slv_tmr when timerafter(tick+404576) :> tick;        //404670
    imgports_slave.stln_out  <: 1; // vertical blanking period

    slv_tmr when timerafter(tick+1504) :> tick;           //1504
    imgports_slave.stfrm_out <: 0;

    slv_tmr when timerafter(tick+1504) :> tick;           //1410 //960
    imgports_slave.stln_out  <: 0;

    slv_tmr when timerafter(tick+880) :> tick;           //352 //880
    for(int i = 0; i < 5; i++) {
      imgports_slave.stln_out  <: 1;
      slv_tmr when timerafter(tick+3008) :> tick;          //2820 //1920

      imgports_slave.stln_out  <: 0;
      slv_tmr when timerafter(tick+880) :> tick;           //352 //880
    }
}
/****************************************************************************************
 *
 ***************************************************************************************/
static inline void get_line(unsigned buffer[],unsigned lines_per_frame,unsigned words_per_line) {

   static unsigned no_of_lines = 0;

   // trigger exposure and stfrm_out for the very first of line of each frame.
   if(!no_of_lines){
       imgports_slave.stln_out <: 0;
       trigger_exposure_stfrm_out();
   }

   // trigger stln_out high
   imgports_slave.stln_out <: 1;
   delay_microseconds(16);

   for(unsigned loop = 0; loop < words_per_line/4; loop++){
       buffer[loop] = do_input(imgports.data_port);
   }

   // trigger stln_out low
   imgports_slave.stln_out <: 0;
   delay_microseconds(1);

   no_of_lines++;
   no_of_lines %= lines_per_frame;

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
    if(CONFIG_SUCCESS == image_sensor_init(imgports.i2c_ports,CONFIG_IN_SLAVE)) {
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
                  get_line(sensor_if_ptr[sensor_data_send_ptr_idx],CONFIG_WINDOW_HEIGHT,CONFIG_WINDOW_WIDTH);
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
              get_line(sensor_if_ptr[sensor_data_send_ptr_idx],CONFIG_WINDOW_HEIGHT,CONFIG_WINDOW_WIDTH);
              }
              break;

            case operation_started => apm_us.release_line_buf(unsigned * movable &line_buf_ptr):
              sensor_if_ptr[sensor_ptr_release_idx++] = move(line_buf_ptr);
              sensor_ptr_release_idx %= 3;
              break;
        }
    }
}

