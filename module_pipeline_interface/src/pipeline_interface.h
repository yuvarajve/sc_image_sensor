// Copyright (c) 2014, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef PIPELINE_INTERFACE_H_
#define PIPELINE_INTERFACE_H_

#define NOF_LINES_FOR_BAYER_PROCESS    2

typedef enum {
    // Not used command
    NOT_USED_COMMAND,
    // Sensor Interface commands
    SET_SCREEN_RESOLUTION,
    SET_COLOR_MODE,
    SET_REGION_OF_INTEREST,
    // Bayer Interface commands
    BAYER_MODE,
    // Common commands
    START_OPERATION,
    STOP_OPERATION,
    FRAME_CAPTURE
}mgmt_intrf_commands_t;

typedef enum {
    APM_MGMT_FAILURE,
    APM_MGMT_SUCCESS
}mgmt_intrf_status_t;

typedef struct {
  unsigned short column_start;
  unsigned short row_start;
  unsigned short horiz_blank;
  unsigned short verti_blank;
  unsigned short tiled_dig_gain;
}mgmt_resolution_param_t;

typedef enum {
  NOT_USED_COLOR,
  GREYSCALE,
  RGB
}mgmt_color_param_t;

typedef struct {
  unsigned short height;
  unsigned short width;
}mgmt_ROI_param_t;

typedef enum {
  NOT_USED_MODE,
  PIXEL_DOUBLE,
  BILINEAR,
  GRADIENT
}mgmt_bayer_param_t;

typedef union {
    unsigned pixel_word;
    struct {
        unsigned short byte_1;
        unsigned short byte_2;
    }pixel_short;
}line_buf_union_t;

typedef union {
    unsigned short pixel_short;
    struct {
        unsigned char byte_1;
        unsigned char byte_2;
    }pixel_char;
}pixel_buf_union_t;

{unsigned char, unsigned char }get_pixel_char_data(pixel_buf_union_t *pixel_short_data);
/*
 * add other management interface parameters here...
 */

interface mgmt_interface {
  [[guarded]] void apm_mgmt(mgmt_intrf_commands_t command, void * unsafe param);
  [[guarded]] [[notification]] slave void request_response(void);
  [[guarded]] [[clears_notification]] mgmt_intrf_status_t get_response(void);
};

interface pipeline_interface {
  [[guarded]] unsigned get_new_line(unsigned * movable &line_buf_ptr, mgmt_ROI_param_t &metadata);
  [[guarded]] void release_line_buf(unsigned * movable &line_buf_ptr);
};

#endif /* PIPELINE_INTERFACE_H_ */
