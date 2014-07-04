// Copyright (c) 2014, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <platform.h>
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

static inline void config_data_port(struct image_sensor_ports &imgports) {

    configure_clock_src(imgports.clk1, imgports.pix_clk);   // Port clock setup
    configure_in_port_strobed_slave(imgports.data_port, imgports.line_valid, imgports.clk1);
    start_clock(imgports.clk1);
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
void image_sensor_server(void) {

  config_data_port(imgports);
  if(CONFIG_SUCCESS == image_sensor_init(imgports.i2c_ports,CONFIG_IN_SLAVE)) {

    while(1) {

    } /**< Image sensor slave mode core functionality begins here... */
  } /**< Image sensor initialisation */
}
