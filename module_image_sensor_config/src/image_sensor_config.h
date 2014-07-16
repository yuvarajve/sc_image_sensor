// Copyright (c) 2014, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef IMAGE_SENSOR_CONFIG_H_
#define IMAGE_SENSOR_CONFIG_H_

#include "i2c.h"
#include "mt9v034.h"

#define CONFIG_SUCCESS                  1
#define CONFIG_FAILURE                  0
#define CONFIG_ERR_INVALID_PARAMATER   -1
#define CONFIG_ERR_NULL_POINTER        -2
#define CONFIG_ERR_NO_DEVICE           -3
#define CONFIG_ERR_DEVICE_LOCKED       -4

#define CONFIG_IN_MASTER                1
#define CONFIG_IN_SLAVE                 0
#define CONFIG_IN_SNAPSHOT              2

#if 0  //TODO: enable this for VGA Resolution
#define CONFIG_WINDOW_HEIGHT       480
#define CONFIG_WINDOW_WIDTH        640
#else // LCD Resolution
#define CONFIG_WINDOW_HEIGHT       272
#define CONFIG_WINDOW_WIDTH        480
#endif

typedef enum {
    E_COLUMN_START,
    E_ROW_START,
    E_HORIZ_BLANK,
    E_VERTI_BLANK,
    E_TILED_DIG_GAIN,
    E_WIN_HEIGHT,
    E_WIN_WIDTH,
    E_COLOR_MODE,
    E_SIZE_OF_CONFIG_ARRAY   //this should be always last
}image_sensor_basic_config_idx_t;

int image_sensor_init(REFERENCE_PARAM(struct r_i2c,i2c_master),unsigned short config_param[E_SIZE_OF_CONFIG_ARRAY], unsigned opt_mode);

#endif /* IMAGE_SENSOR_CONFIG_H_ */
