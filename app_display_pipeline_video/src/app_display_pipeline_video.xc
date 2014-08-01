// Copyright (c) 2014, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <platform.h>
#include <print.h>
#include <timer.h>
#include <stdio.h>

#include "mt9v034.h"
#include "pipeline_interface.h"
#include "image_sensor_server.h"

#define DISPLAY_TILE  0
#define SENSOR_TILE   1

/****************************************************************************************
 *
 ***************************************************************************************/
void mgmt_intrf(interface mgmt_interface client mgr_sensor,
             interface mgmt_interface client mgr_bayer) {

    timer mgmt_timer;
    unsigned mgmt_timer_tick;
    char issue_cmd_flag = 0;
    char cmd_to_issue = '1';
    char next_cmd_to_issue = '1';
    /**< management interface parameters */
    mgmt_resolution_param_t mgmt_resolution_l;
    mgmt_color_param_t      mgmt_color_mode_l;
    mgmt_ROI_param_t        mgmt_roi_l;
    mgmt_bayer_param_t      mgmt_bayer_mode_l;
    ///////////////////////////////////////////

    mgmt_timer :> mgmt_timer_tick;

    while(1) {
      select {
          case (!issue_cmd_flag) => mgmt_timer when timerafter(mgmt_timer_tick+25000) :> mgmt_timer_tick:
              issue_cmd_flag = 1;
              break;

          case mgr_sensor.request_response(void):
              mgmt_intrf_status_t response = mgr_sensor.get_response();
              if(response == APM_MGMT_SUCCESS) {
                  printstrln("mgmt_if: received APM_MGMT_SUCCESS from sensor_if");
                  //issue next command, if success received from the server interface
                  cmd_to_issue = next_cmd_to_issue;
              }
              break;

          case mgr_bayer.request_response(void):
              mgmt_intrf_status_t response = mgr_bayer.get_response();
              if(response == APM_MGMT_SUCCESS) {
                  printstrln("mgmt_if: received APM_MGMT_SUCCESS from bayer_if");
                  //issue next command, if success received from the server interface
                  cmd_to_issue = next_cmd_to_issue;
              }
              break;

          (issue_cmd_flag) => default: {
              issue_cmd_flag = 0;

              switch(cmd_to_issue) {
                  case '1':
                      //send resolution to sensor_if
                      printstrln("mgmt_if:Sending Resolution to sensor_if");
                      //TODO: Remove these hardcoded values
                      mgmt_resolution_l.column_start = 136;
                      mgmt_resolution_l.row_start = 106;
                      mgmt_resolution_l.horiz_blank = 94;
                      mgmt_resolution_l.verti_blank = 4;
                      mgmt_resolution_l.tiled_dig_gain = 10;

                      unsafe{ mgr_sensor.apm_mgmt(SET_SCREEN_RESOLUTION,&mgmt_resolution_l); }

                      next_cmd_to_issue = '2';
                      break;

                  case '2':
                      //send color to sensor_if
                      printstrln("mgmt_if:Sending Color Mode to sensor_if");
                      mgmt_color_mode_l = RGB;

                      unsafe{ mgr_sensor.apm_mgmt(SET_COLOR_MODE,&mgmt_color_mode_l); }

                      next_cmd_to_issue = '3';
                      break;

                  case '3':
                      //send region of interest to sensor_if
                      printstrln("mgmt_if:Sending Region of Interest to sensor_if");
                      //TODO: Remove these hardcoded values
                      mgmt_roi_l.height = 272;
                      mgmt_roi_l.width = 480;

                      unsafe{ mgr_sensor.apm_mgmt(SET_REGION_OF_INTEREST,&mgmt_roi_l); }

                      next_cmd_to_issue = '4';
                      break;

                  case '4':
                      // send bayer mode to bayer_if
                      printstrln("mgmt_if:Sending bayer mode to bayer_if");
                      mgmt_bayer_mode_l = PIXEL_DOUBLE;
                      unsafe {mgr_bayer.apm_mgmt(BAYER_MODE,&mgmt_bayer_mode_l);}
                      next_cmd_to_issue = '5';
                      break;

                  case '5':
                      // send start operation to sensor_if and bayer_if
                      printstrln("mgmt_if:Sending start operation to sensor_if");
                      unsafe{ mgr_sensor.apm_mgmt(START_OPERATION,NULL); }
                      printstrln("mgmt_if:Sending start operation to bayer_if");
                      unsafe{ mgr_bayer.apm_mgmt(START_OPERATION,NULL); }
                      next_cmd_to_issue = '0';
                      break;

                  default:
                      issue_cmd_flag = 1; //be in this default once start operation is given
                      break;
              }
          }
          break;
      }
    }
}
static inline unsigned short rgb888_to_rgb565(char b, char g, char r) {
  return (unsigned short)((r >> 3) & 0x1F) | ((unsigned short)((g >> 2) & 0x3F) << 5) | ((unsigned short)((b >> 3) & 0x1F) << 11);
}

#define LINE_0                  0
#define LINE_1                  1
#define NOF_LINE_TB_PROCESSED   2
/****************************************************************************************
 *
 ***************************************************************************************/
void bayer_if(interface mgmt_interface server bayerif,
              interface pipeline_interface client apm_ds) {

    char operation_started = 0;
    // added this to guard, get new line starts only after responding to management interface
    char operation_start_responded = 0;
    //char nof_lines_for_bayer_process = 0;
    unsigned rgb565buf_0[NOF_LINE_TB_PROCESSED][MT9V034_MAX_WIDTH/2],rgb565buf_1[NOF_LINE_TB_PROCESSED][MT9V034_MAX_WIDTH/2];
    unsigned * movable rgb565buf_ptr[NOF_LINE_TB_PROCESSED][NOF_LINE_TB_PROCESSED] = { {&rgb565buf_0[0][0], &rgb565buf_0[1][0]},
                                                                                       {&rgb565buf_1[0][0], &rgb565buf_1[1][0]} };
    unsigned * movable bayer_buf_ptr[NOF_LINE_TB_PROCESSED];
    char rgb_buf_ptr_index1 = 0;
    char ROI_rcvd = 0;
    unsigned short ht = 0, wd = 0;
    // bayer mode parameter from management interface
    mgmt_bayer_param_t bayer_mode_l = NOT_USED_MODE;
    // metadata required for bayer
    mgmt_ROI_param_t metadata;

    while(1){

        select {
            case bayerif.apm_mgmt(mgmt_intrf_commands_t command,void * unsafe param):
                if( (command == BAYER_MODE) && (param != NULL) ) {
                    printstrln("bayer_if: Bayer mode received from mgmt_if");
                    bayer_mode_l = *(mgmt_bayer_param_t *)param;
                }
                else if( (command == START_OPERATION) && (param == NULL) ){
                    printstrln("bayer_if: Start operation received from mgmt_if");
                    if(bayer_mode_l == PIXEL_DOUBLE){
                      printstrln("bayer_if: PIXEL_DOUBLE mode received....!!!");
                      operation_started = 1;
                      operation_start_responded = 0;
                    }
                }
                else if(command == STOP_OPERATION) {
                    operation_started = 0;
                    operation_start_responded = 0;
                }


                bayerif.request_response();
                break;

            case bayerif.get_response(void) -> mgmt_intrf_status_t bayer_if_status:
                bayer_if_status = APM_MGMT_SUCCESS;
                operation_started ? (operation_start_responded = 1) : (operation_start_responded = 0);
                if(operation_start_responded)
                    delay_milliseconds(1000);//delay_milliseconds(500);//delay_milliseconds(103); //TODO: remove this minimum delay
                break;

            (operation_start_responded) => default : {

                ROI_rcvd = apm_ds.get_new_line(bayer_buf_ptr[LINE_0], metadata);
                if (ROI_rcvd) {
                    ht = metadata.height;
                    wd = metadata.width;
               }
                apm_ds.get_new_line(bayer_buf_ptr[LINE_1], metadata);

                for (unsigned c=0; c<wd; c+=2){

                    char r = ((char *)bayer_buf_ptr[LINE_0])[c+1];
                    char b = ((char *)bayer_buf_ptr[LINE_1])[c];
                    char g0 = ((char *)bayer_buf_ptr[LINE_0])[c];
                    char g1 = ((char *)bayer_buf_ptr[LINE_1])[c+1];

                    unsigned short rgb565_0 = rgb888_to_rgb565(r,g0,b);
                    unsigned short rgb565_1 = rgb888_to_rgb565(r,g1,b);
                    unsigned rgb565_0_double = rgb565_0 | (rgb565_0<<16);
                    unsigned rgb565_1_double = rgb565_1 | (rgb565_1<<16);

                    rgb565buf_ptr[rgb_buf_ptr_index1][LINE_0][c/2] = rgb565_0_double;
                    rgb565buf_ptr[rgb_buf_ptr_index1][LINE_1][c/2] = rgb565_1_double;

                }

                apm_ds.release_line_buf(bayer_buf_ptr[LINE_0]);
                apm_ds.release_line_buf(bayer_buf_ptr[LINE_1]);
            }
            break;
        }
    }
}
int main(void) {
    interface mgmt_interface sensor_mgmt_intrf;
    interface mgmt_interface bayer_mgmt_intrf;
    interface pipeline_interface sensor_bayer_intrf;

    par {
        on tile[SENSOR_TILE]: mgmt_intrf(sensor_mgmt_intrf,bayer_mgmt_intrf);
        on tile[SENSOR_TILE]: image_sensor_server(sensor_mgmt_intrf,sensor_bayer_intrf);
        on tile[SENSOR_TILE]: bayer_if(bayer_mgmt_intrf,sensor_bayer_intrf);
    }
    return 0;
}


