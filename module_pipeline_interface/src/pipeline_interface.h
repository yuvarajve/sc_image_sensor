// Copyright (c) 2014, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef PIPELINE_INTERFACE_H_
#define PIPELINE_INTERFACE_H_

#define NOF_LINES_FOR_BAYER_PROCESS    2

typedef enum {
    // Sensor Interface commands
    SET_SCREEN_RESOLUTION,
    SET_ROW_START,
    SET_COLUMN_START,
    SET_HORIZONTAL_BLANK,
    SET_VERTICAL_BLANK,
    SET_TEST_PATTERN,
    // Bayer Interface commands
    BAYER_MODE,
    START_OPERATION,
    STOP_OPERATION
}mgmt_intrf_commands_t;

typedef enum {
    APM_MGMT_FAILURE,
    APM_MGMT_SUCCESS
}mgmt_intrf_status_t;

interface mgmt_interface {
  [[guarded]] void apm_mgmt(mgmt_intrf_commands_t command);
  [[guarded]] [[notification]] slave void request_response(void);
  [[guarded]] [[clears_notification]] mgmt_intrf_status_t get_response(void);
};

interface pipeline_interface {
  [[guarded]] void get_new_line(unsigned * movable &line_buf_ptr);
  [[guarded]] void release_line_buf(unsigned * movable &line_buf_ptr);
};

#endif /* PIPELINE_INTERFACE_H_ */
