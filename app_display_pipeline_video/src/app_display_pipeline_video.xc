// Copyright (c) 2014, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <platform.h>
#include <print.h>
#include <timer.h>
#include <stdio.h>

#include "pipeline_interface.h"
#include "image_sensor_server.h"
#include "lcd.h"
#include "sdram.h"
#include "display_controller.h"

#define DISPLAY_TILE  1
#define SENSOR_TILE   0

on tile[DISPLAY_TILE] : lcd_ports lcdports = { //triangle slot
  XS1_PORT_1I, XS1_PORT_1L, XS1_PORT_16B, XS1_PORT_1J, XS1_PORT_1K, XS1_CLKBLK_1 };
on tile[DISPLAY_TILE] : sdram_ports sdramports = { //star slot
  XS1_PORT_16A, XS1_PORT_1B, XS1_PORT_1G, XS1_PORT_1C, XS1_PORT_1F, XS1_CLKBLK_2 };

// Registers for performance (video quality) tuning
#define GREEN_REDUCTION_FACTOR_NUM 8     // Numerator of the factor for white balancing
#define GREEN_REDUCTION_FACTOR_DEN 10     // Denominator of the factor for white balancing

// Sensor resolution
#define MAX_HEIGHT 480
#define MAX_WIDTH 752

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

#pragma unsafe arrays
static inline unsafe void get_row(streaming chanend c, unsigned * unsafe dataPtr, unsigned width){
    unsigned n_data = width/4;
    for (unsigned i=0; i<n_data; i++){
        c :> dataPtr[i];
    }
}


#pragma unsafe arrays
static inline void store_row (chanend c_dc, unsigned row, unsigned frBuf, intptr_t buf){
    display_controller_image_write_line_p(c_dc, row, frBuf, buf);
    display_controller_wait_until_idle_p(c_dc, buf);
}

static inline unsigned short rgb888_to_rgb565(char b, char g, char r) {
  return (unsigned short)((r >> 3) & 0x1F) | ((unsigned short)((g >> 2) & 0x3F) << 5) | ((unsigned short)((b >> 3) & 0x1F) << 11);
}

#pragma unsafe arrays
void color_interpolation(chanend c_dc, unsigned frBuf, unsigned height, unsigned width){
    unsigned buf[3][MAX_WIDTH/2], rgb565[MAX_WIDTH/2];
    char r[MAX_WIDTH], g[MAX_WIDTH], b[MAX_WIDTH];

    // Read first two rows
    display_controller_image_read_line(c_dc, 0, frBuf, buf[0]);
    display_controller_wait_until_idle(c_dc, buf[0]);
    display_controller_image_read_line(c_dc, 1, frBuf, buf[1]);
    display_controller_wait_until_idle(c_dc, buf[1]);

    // Store first and last rows with 0s
    for (unsigned j=0; j<width/4; j++)
        rgb565[j]=0;
    display_controller_image_write_line(c_dc, 0, frBuf, rgb565);
    display_controller_wait_until_idle(c_dc, rgb565);
    display_controller_image_write_line(c_dc, height-1, frBuf, rgb565);
    display_controller_wait_until_idle(c_dc, rgb565);


    // Find missing color components
    for (unsigned i=2; i<height; i++){
        unsigned row = i-1;

        display_controller_image_read_line(c_dc, i, frBuf, buf[i%3]);
        display_controller_wait_until_idle(c_dc, buf[i%3]);

        if (row&1){
            for (unsigned j=1; j<width-1; j+=2){    // odd row, odd col, green pix
                g[j] = (buf[row%3],char[])[j];
                unsigned b_top = (buf[(row-1)%3],char[])[j];
                unsigned b_bot = (buf[(row+1)%3],char[])[j];
                b[j] = (b_top+b_bot)/2; // Take average
                unsigned r_left = (buf[row%3],char[])[j-1];
                unsigned r_right = (buf[row%3],char[])[j+1];
                r[j] = (r_left+r_right)/2;
            }
            for (unsigned j=2; j<width-1; j+=2){    // odd row, even col, red pix
                r[j] = (buf[row%3],char[])[j];
                unsigned b_diag1 = (buf[(row-1)%3],char[])[j-1];
                unsigned b_diag2 = (buf[(row-1)%3],char[])[j+1];
                unsigned b_diag3 = (buf[(row+1)%3],char[])[j-1];
                unsigned b_diag4 = (buf[(row+1)%3],char[])[j+1];
                b[j] = (b_diag1+b_diag2+b_diag3+b_diag4)/4;
                unsigned g_adj1 = (buf[(row-1)%3],char[])[j];
                unsigned g_adj2 = (buf[(row+1)%3],char[])[j];
                unsigned g_adj3 = (buf[row%3],char[])[j-1];
                unsigned g_adj4 = (buf[row%3],char[])[j+1];
                g[j] = (g_adj1+g_adj2+g_adj3+g_adj4)/4;
            }
        }
        else {
            for (unsigned j=1; j<width-1; j+=2){    // even row, odd col, blue pix
                b[j] = (buf[row%3],char[])[j];
                unsigned r_diag1 = (buf[(row-1)%3],char[])[j-1];
                unsigned r_diag2 = (buf[(row-1)%3],char[])[j+1];
                unsigned r_diag3 = (buf[(row+1)%3],char[])[j-1];
                unsigned r_diag4 = (buf[(row+1)%3],char[])[j+1];
                r[j] = (r_diag1+r_diag2+r_diag3+r_diag4)/4;
                unsigned g_adj1 = (buf[(row-1)%3],char[])[j];
                unsigned g_adj2 = (buf[(row+1)%3],char[])[j];
                unsigned g_adj3 = (buf[row%3],char[])[j-1];
                unsigned g_adj4 = (buf[row%3],char[])[j+1];
                g[j] = (g_adj1+g_adj2+g_adj3+g_adj4)/4;
            }
            for (unsigned j=2; j<width-1; j+=2){    // even row, even col, green pix
                g[j] = (buf[row%3],char[])[j];
                unsigned b_left = (buf[row%3],char[])[j-1];
                unsigned b_right = (buf[row%3],char[])[j+1];
                b[j] = (b_left+b_right)/2;
                unsigned r_top = (buf[(row-1)%3],char[])[j];
                unsigned r_bot = (buf[(row+1)%3],char[])[j];
                r[j] = (r_top+r_bot)/2;
            }
        }

        // RGB565 conversion and write row
        for (unsigned j=1; j<width-1; j++)
            (rgb565,unsigned short[])[j] = rgb888_to_rgb565(b[j], g[j]*GREEN_REDUCTION_FACTOR_NUM/GREEN_REDUCTION_FACTOR_DEN, r[j]);     // 8/10 is for white balancing since the output looks greenish

        (rgb565,unsigned short[])[0] = 0;
        (rgb565,unsigned short[])[width-1] = 0;

        display_controller_image_write_line(c_dc, row, frBuf, rgb565);
        display_controller_wait_until_idle(c_dc, rgb565);
    }

}
#pragma unsafe arrays
void image_sensor_get_frame(streaming chanend c_imgSensor, chanend c_dispCont, unsigned frBuf,
        unsigned height, unsigned width){
    unsigned data1[MAX_WIDTH/4];//, data2[MAX_WIDTH/4];
    unsigned * /*unsafe tempPtr, * */unsafe readBufPtr;//, * unsafe storeBufPtr;

    // Get frame & store
    unsafe {
        readBufPtr = data1;
        get_row (c_imgSensor,readBufPtr,width);

        for (unsigned r=1; r<height; r++){
              get_row (c_imgSensor,readBufPtr,width);
              store_row(c_dispCont,r-1,frBuf,(intptr_t)readBufPtr);
        }

        store_row(c_dispCont,height-1,frBuf,(intptr_t)readBufPtr);
    }

    // Color interpolation
    color_interpolation(c_dispCont, frBuf, height, width);

}
void app(streaming chanend c_img, chanend c_dc){

    unsigned frBuf[2], frBufIndex=0;

    // Create frame buffer
    frBuf[0] = display_controller_register_image(c_dc, LCD_ROW_WORDS, LCD_HEIGHT);
    frBuf[1] = display_controller_register_image(c_dc, LCD_ROW_WORDS, LCD_HEIGHT);
    display_controller_frame_buffer_init(c_dc, frBuf[0]);

    // Get frames and display them
    while (1){

        frBufIndex = 1-frBufIndex;
        image_sensor_get_frame(c_img, c_dc, frBuf[frBufIndex], LCD_HEIGHT, LCD_WIDTH);

        display_controller_frame_buffer_commit(c_dc, frBuf[frBufIndex]);
        delay_milliseconds(10);   // To remove flicker

    }
}
/****************************************************************************************
 *
 ***************************************************************************************/
void bayer_if(interface mgmt_interface server bayerif,
        interface pipeline_interface client apm_ds, streaming chanend img_sen) {

    char operation_started = 0;
    // added this to guard, get new line starts only after responding to management interface
    char operation_start_responded = 0;
    //char nof_lines_for_bayer_process = 0;
    line_buf_union_t * movable bayer_line_buf[2];
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
                break;

            (operation_start_responded) => default : {

              if(apm_ds.get_new_line(bayer_line_buf[0],metadata)) {
                 //do bayer operation based on metadata here...
                 /*
                  //How to use the bayer_line_buf
                  unsigned char color_cmp_1 = 0,color_cmp_2 = 0,color_cmp_3 = 0,color_cmp_4 = 0;
                  for(unsigned i = 0; i < LCD_WIDTH; i+= 2) {
                    // To Access the short variable
                    unsigned short var_1 = (bayer_line_buf[0]+i)->pixel_short.byte_1;
                    unsigned short var_2 = (bayer_line_buf[0]+i)->pixel_short.byte_2;
                    // To Access the individual 8-bit pixel data from short
                    {color_cmp_1,color_cmp_2} = get_pixel_char_data((pixel_buf_union_t *)&(bayer_line_buf[0]+i)->pixel_short.byte_1);
                    {color_cmp_3,color_cmp_4} = get_pixel_char_data((pixel_buf_union_t *)&(bayer_line_buf[0]+i)->pixel_short.byte_2);
                  }
                  */
              }

              for(unsigned l = 0; l < LCD_WIDTH/4; l++){
                  img_sen <: bayer_line_buf[0][l];
              }
              apm_ds.release_line_buf(bayer_line_buf[0]);
            }
            break;
        }
    }
}
int main(void) {
    chan c_dc, c_lcd, c_sdram;
    streaming chan c_img_sen;
    interface mgmt_interface sensor_mgmt_intrf;
    interface mgmt_interface bayer_mgmt_intrf;
    interface pipeline_interface sensor_bayer_intrf;

    par {
        on tile[SENSOR_TILE]: mgmt_intrf(sensor_mgmt_intrf,bayer_mgmt_intrf);
        on tile[SENSOR_TILE]: image_sensor_server(sensor_mgmt_intrf,sensor_bayer_intrf);
        on tile[SENSOR_TILE]: bayer_if(bayer_mgmt_intrf,sensor_bayer_intrf,c_img_sen);

        on tile[DISPLAY_TILE]: app(c_img_sen,c_dc);
        on tile[DISPLAY_TILE]: display_controller(c_dc,c_lcd,c_sdram);
        on tile[DISPLAY_TILE]: lcd_server(c_lcd,lcdports);
        on tile[DISPLAY_TILE]: sdram_server(c_sdram,sdramports);
    }
    return 0;
}

