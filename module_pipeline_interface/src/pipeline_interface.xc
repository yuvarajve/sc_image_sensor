// Copyright (c) 2014, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <stdio.h>
#include <xs1.h>
#include <platform.h>
#include "pipeline_interface.h"
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
{unsigned char, unsigned char } get_pixel_char_data(pixel_buf_union_t *pixel_short_data){
  if(pixel_short_data == NULL)
     return {0,0};

  return{pixel_short_data->pixel_char.byte_1,pixel_short_data->pixel_char.byte_2};
}
