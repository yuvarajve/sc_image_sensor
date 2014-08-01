// Copyright (c) 2014, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>
#include <stdio.h>
#include <xs1.h>
#include <platform.h>
#include <print.h>
#include <string.h>

#include "xassert.h"
#include "sdram.h"
#include "sdram_slicekit_support.h"
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
on tile[SDRAM_L16_CIRCLE_TILE] : r_i2c i2c_ports = { XS1_PORT_1H, XS1_PORT_1I, 1000};

on tile[SDRAM_L16_CIRCLE_TILE] : image_sensor_ports imgports = { //circle slot
   XS1_PORT_1J, XS1_PORT_1K, XS1_PORT_1L, XS1_PORT_8C,
   XS1_CLKBLK_1
};

on tile [SDRAM_L16_SQUARE_TILE] : sdram_ports sdramports = SDRAM_L16_SQUARE_PORTS(XS1_CLKBLK_2);

interface local_pipe {
  [[guarded]] void inform_state(mgmt_intrf_commands_t command,void * unsafe param);
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
/****************************************************************************************
 *
 ***************************************************************************************/
static inline void get_frame(streaming chanend c_imgSensor,unsigned width,unsigned height) {

  unsigned nof_data_in_frame = (width * height)/4;
  //TODO: Add code here to validate vertical blanking period using line_valid pin
  //TODO: remove this frame_valid pin check after implementing the above code
  imgports.frame_valid when pinseq(0) :> void;
  imgports.frame_valid when pinseq(1) :> void; // wait for a valid frame

  clearbuf(imgports.data_port);
  for(unsigned idx = 0; idx < nof_data_in_frame; idx++) {
      c_imgSensor <: do_input(imgports.data_port);
  }

}
/************************************************************************************//**
 * @brief
 *   Image Sensor Master Mode Server.
 *
 * @param[in] None
 *
 * @return
 *  None.
 *
 ***************************************************************************************/
void image_sensor_server_master(streaming chanend c_imgSensor, interface mgmt_interface server sensorif,
                                                               interface local_pipe client lp_us) {

  char operation_started = 0;
  // added this to guard, get frame starts only after responding to management interface
  char operation_start_responded = 0;
  mgmt_intrf_status_t sensor_if_status_l = APM_MGMT_FAILURE;
  /**< Sensor configuraion array */
  unsigned short sensor_config_array[E_SIZE_OF_CONFIG_ARRAY] = {0};
  /**< management interface parameters */
  static mgmt_resolution_param_t mgmt_resolution_l = {136, 106, 94, 4, 10};
  static mgmt_color_param_t      mgmt_color_mode_l = {RGB};
  static mgmt_ROI_param_t        mgmt_roi_l = {CONFIG_WINDOW_HEIGHT, CONFIG_WINDOW_WIDTH};
  /* Initialise image senor ports, i2c interface */
  config_image_sensor_ports();
  /* configure sensor with the default paramaters */
  memcpy(sensor_config_array+0,&mgmt_resolution_l,sizeof(mgmt_resolution_param_t));
  memcpy(sensor_config_array+5,&mgmt_roi_l,sizeof(mgmt_ROI_param_t));
  memcpy(sensor_config_array+7,&mgmt_color_mode_l,sizeof(unsigned short));

  if(CONFIG_SUCCESS == image_sensor_init(i2c_ports,sensor_config_array,CONFIG_IN_MASTER)) {
    sensor_if_status_l = APM_MGMT_SUCCESS;
    }

    while(1){

        select {
            case sensorif.apm_mgmt(mgmt_intrf_commands_t command, void * unsafe param):
              if( (command == SET_SCREEN_RESOLUTION) && (param != NULL) ){
                  printstrln("sensor_if: Resoultion received from mgmt_if");
                  mgmt_resolution_l = *(mgmt_resolution_param_t *)param;
                  /* copy to sensor config array */
                  memcpy(sensor_config_array+0,&mgmt_resolution_l,sizeof(mgmt_resolution_param_t));
              }
              else if( (command == SET_COLOR_MODE) && (param != NULL) ){
                  printstrln("sensor_if: Color Mode received from mgmt_if");
                  mgmt_color_mode_l = *(mgmt_color_param_t *)param;
                  /* copy to sensor config array */
                  memcpy(sensor_config_array+7,&mgmt_color_mode_l,sizeof(unsigned short));
              }
              else if( (command == SET_REGION_OF_INTEREST) && (param != NULL) ){
                  printstrln("sensor_if: Region of Interest received from mgmt_if");
                  mgmt_roi_l = *(mgmt_ROI_param_t *)param;
                  /* copy to sensor config array */
                  memcpy(sensor_config_array+5,&mgmt_roi_l,sizeof(mgmt_ROI_param_t));
              }
              else if( (command == START_OPERATION) && (param == NULL) ) {
                  printstrln("sensor_if: Start operation received from mgmt_if");
                  printstrln("sensor_if: Reconfiguring sensor....!!!");
                  sensor_if_status_l = APM_MGMT_FAILURE;
                  if(CONFIG_SUCCESS == image_sensor_init(i2c_ports,sensor_config_array,CONFIG_IN_MASTER)) {
                      sensor_if_status_l = APM_MGMT_SUCCESS;
                      operation_started = 1;
                      operation_start_responded = 0;
                  }
              }
              else if(command == STOP_OPERATION) {
                  operation_started = 0;
                  operation_start_responded = 0;
                  lp_us.inform_state(STOP_OPERATION,NULL);
              }

              sensorif.request_response();
              break;

            case sensorif.get_response(void) -> mgmt_intrf_status_t sensor_if_status:
              sensor_if_status = sensor_if_status_l;
              if(operation_started == 1){
                  operation_start_responded = 1;
                  lp_us.inform_state(START_OPERATION,NULL);
              }
              break;

            case operation_start_responded => c_imgSensor :> mgmt_intrf_commands_t cmd:{
              assert(cmd == FRAME_CAPTURE);
              unsafe { lp_us.inform_state(FRAME_CAPTURE,&mgmt_roi_l); }
              //start getting the frames
              get_frame(c_imgSensor,mgmt_roi_l.width,mgmt_roi_l.height);
            }
            break;
        }
    }
}
#pragma select handler
static inline void capture_incoming_line(streaming chanend c_img_sen,
                                         unsigned words_per_line,
                                         unsigned lines_per_frame,
                                         unsigned &put_line_num,
                                         unsigned dataPtr[])
{
  static unsigned no_of_lines = 0;

  for (unsigned i=0; i<words_per_line; i++) {
      c_img_sen :> dataPtr[i];
      }

  no_of_lines++;
  put_line_num = no_of_lines;
  no_of_lines %= lines_per_frame;
}
void image_sensor_sdram_client(streaming chanend c_img_sen,
                               streaming chanend c_sdram_server,
                               interface pipeline_interface server apm_us,
                               interface local_pipe server lp_ds) {

  char operation_started = 0;
  char sensor_data_send_ptr_idx = 0;
  char sensor_ptr_release_idx = 0;
  char frame_capture_send = 0;

  unsigned get_line_num = 0;
  unsigned wr_bank = 0, wr_row = 0, wr_col = 0;
  unsigned rd_bank = 0, rd_row = 0, rd_col = 0;
  unsigned nof_lines_produced = 0;
  unsigned nof_lines_consumed = 0;

  unsigned sensor_line_buf_1[MT9V034_MAX_WIDTH/4];
  unsigned sensor_line_buf_2[MT9V034_MAX_WIDTH/4];
  unsigned sensor_line_buf_3[MT9V034_MAX_WIDTH/4];
  unsigned * movable sensor_data_rx_ptr = &sensor_line_buf_1[0];
  unsigned * movable sensor_data_tx_ptr[2] = {&sensor_line_buf_2[0],&sensor_line_buf_3[0]};

  mgmt_ROI_param_t        mgmt_roi_l;
  set_thread_fast_mode_on();
  s_sdram_state sdram_state;
  sdram_init_state(c_sdram_server, sdram_state);

  while(1) {
    select {

//#pragma ordered
      case operation_started => capture_incoming_line(c_img_sen,(mgmt_roi_l.width/4),mgmt_roi_l.height,get_line_num,sensor_data_rx_ptr): {
          // donot store incoming frames into SDRAM unless and until one frame is processed after storing two full frames
          // TODO: how to identify the first line of the frame???
          if(nof_lines_produced < (2 * mgmt_roi_l.height)) {
            sdram_write(c_sdram_server, sdram_state, wr_bank, wr_row++, wr_col, (mgmt_roi_l.width/4), move(sensor_data_rx_ptr));
            sdram_complete(c_sdram_server, sdram_state, sensor_data_rx_ptr);
            // update no of line produced from sensor
            nof_lines_produced++;
            printstr("producing....");printuintln(nof_lines_produced);
            if((wr_row % mgmt_roi_l.height) == 0) {
              //printstr("frame capture completed..."); printuintln(nof_lines_produced);
              // clear this flag, so that the signal is send to receive next frame
              frame_capture_send = 0;
            }
          }
          else {
              wr_bank = wr_row = wr_col = 0;
              //printstrln("ERROR: Filled lines are not consumed from downstream component...");printuintln(lost++);
              frame_capture_send = 1;
          }
        }
        break;

      case operation_started => apm_us.get_new_line(unsigned * movable &line_buf_ptr, mgmt_ROI_param_t &metadata) -> {unsigned line_num}: {
          if(get_line_num == 1) {
            line_num = get_line_num;
            metadata = mgmt_roi_l;
          }
          else
            line_num = 0;

          /* atleast a line should be produced,
           * nof_lines_produced should be greater than nof_lines consumed,
           */
          if( nof_lines_produced > nof_lines_consumed) {
            sdram_read(c_sdram_server, sdram_state, rd_bank, rd_row++, rd_col, (mgmt_roi_l.width/4), move(sensor_data_tx_ptr[sensor_data_send_ptr_idx]));
            sdram_complete(c_sdram_server, sdram_state, sensor_data_tx_ptr[sensor_data_send_ptr_idx]);
            // update no of line consumed from sensor
            nof_lines_consumed++;
            nof_lines_produced--;
            printstr("consuming....");printuintln(nof_lines_consumed);
          }
          else {
            printstrln("no..... lines..... produced....");
          }

          line_buf_ptr = move(sensor_data_tx_ptr[sensor_data_send_ptr_idx++]);
          sensor_data_send_ptr_idx %= 2;
        }
        break;

      case operation_started => apm_us.release_line_buf(unsigned * movable &line_buf_ptr):
        sensor_data_tx_ptr[sensor_ptr_release_idx++] = move(line_buf_ptr);
        sensor_ptr_release_idx %= 2;
        break;

      case lp_ds.inform_state(mgmt_intrf_commands_t command, void * unsafe param):
        if(command == START_OPERATION)
          operation_started = 1;
        else if(command == STOP_OPERATION)
          operation_started = 0;
        else if(command == FRAME_CAPTURE) {
          mgmt_roi_l = *(mgmt_ROI_param_t *)param;
          printstrln("frames capture started...");
        }
        break;

        (operation_started && (frame_capture_send == 0)) => default:{
            c_img_sen <: FRAME_CAPTURE;
            // set this flag, so that there is no signal send untill a full frame is received
            frame_capture_send = 1;
        }
        break;
    }
  }
}
/************************************************************************************//**
 * @brief
 *   Image Sensor Mode Server.
 *
 * @param[in] None
 *
 * @return
 *  None.
 *
 ***************************************************************************************/
void image_sensor_server(interface mgmt_interface server sensorif, interface pipeline_interface server apm_us) {

    streaming chan sdram_c[1];
    streaming chan c_imgSensor;
    interface local_pipe lp;

    par {
        image_sensor_server_master(c_imgSensor,sensorif,lp);
        image_sensor_sdram_client(c_imgSensor,sdram_c[0],apm_us,lp);
        sdram_server(sdram_c,1,sdramports);
    }



}
