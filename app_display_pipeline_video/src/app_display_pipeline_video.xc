// Copyright (c) 2014, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <platform.h>
#include <print.h>
#include <timer.h>

#include "pipeline_interface.h"
#include "image_sensor_server.h"

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
                      mgr_sensor.apm_mgmt(SET_SCREEN_RESOLUTION);
                      next_cmd_to_issue = '2';
                      break;

                  case '2':
                      // send bayer mode to bayer_if
                      printstrln("mgmt_if:Sending bayer mode to bayer_if");
                      mgr_bayer.apm_mgmt(BAYER_MODE);
                      next_cmd_to_issue = '3';
                      break;

                  case '3':
                      // send start operation to sensor_if and bayer_if
                      printstrln("mgmt_if:Sending start operation to sensor_if");
                      mgr_sensor.apm_mgmt(START_OPERATION);
                      printstrln("mgmt_if:Sending start operation to bayer_if");
                      mgr_bayer.apm_mgmt(START_OPERATION);
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
/****************************************************************************************
 *
 ***************************************************************************************/
void bayer_if(interface mgmt_interface server bayerif,
        interface pipeline_interface client apm_ds) {

    char operation_started = 0;
    // added this to guard, get new line starts only after responding to management interface
    char operation_start_responded = 0;
    char nof_lines_for_bayer_process = 0;
    unsigned * movable bayer_line_buf[NOF_LINES_FOR_BAYER_PROCESS];

    while(1){

        select {
            case bayerif.apm_mgmt(mgmt_intrf_commands_t command):
                if(command == BAYER_MODE)
                    printstrln("bayer_if: Bayer mode received from mgmt_if");
                else if(command == START_OPERATION) {
                    printstrln("bayer_if: Start operation received from mgmt_if");
                    operation_started = 1;
                    operation_start_responded = 0;
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
                break;

            (operation_start_responded) => default : {
                if(nof_lines_for_bayer_process < NOF_LINES_FOR_BAYER_PROCESS) {
                   // get new line twice for bayer interpolation
                   // TODO: change the macro NOF_LINES_FOR_BAYER incase more/less lines required
                   apm_ds.get_new_line(bayer_line_buf[nof_lines_for_bayer_process]);
                   nof_lines_for_bayer_process++;
                }
                else {
                  //TODO: do interpolation process before releasing the buffers.
                  for(int loop = 0; loop < nof_lines_for_bayer_process; loop++)
                      apm_ds.release_line_buf(bayer_line_buf[loop]);

                  nof_lines_for_bayer_process = 0; // reset and start getting the next lines
                }
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
        on tile[1]: mgmt_intrf(sensor_mgmt_intrf,bayer_mgmt_intrf);
        on tile[1]: image_sensor_server(sensor_mgmt_intrf,sensor_bayer_intrf);
        on tile[1]: bayer_if(bayer_mgmt_intrf,sensor_bayer_intrf);
    }
    return 0;
}

