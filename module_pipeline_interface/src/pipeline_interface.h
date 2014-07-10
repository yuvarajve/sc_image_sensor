// Copyright (c) 2014, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef PIPELINE_INTERFACE_H_
#define PIPELINE_INTERFACE_H_

typedef enum {
    SET_RESOLUTION,
    BAYER_MODE,
    START_OPERATION
}mgmt_intrf_commands_t;

typedef enum {
    APM_MGMT_SUCCESS,
    APM_MGMT_FAILURE
}mgmt_intrf_status_t;

interface mgmt_interface {
  [[guarded]] void apm_mgmt(mgmt_intrf_commands_t command);
  [[guarded]] [[notification]] slave void request_response(void);
  [[guarded]] [[clears_notification]] mgmt_intrf_status_t get_response(void);
};

interface pipeline_interface {
  void get_new_line(unsigned * movable &line_buf_ptr);
  void release_line_buf(unsigned * movable &line_buf_ptr);
};

#endif /* PIPELINE_INTERFACE_H_ */
