// Copyright (c) 2014, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef MT9V034_REGS_H_
#define MT9V034_REGS_H_

#define MT9V034_I2C_ADDR        (0x90 >> 1)   // 7-bit addressing
#define MT9V034_CHIP_VERSION    (0x1324)
/**************************************************************************//**
 * @defgroup MT9V034_IMAGE_SENSOR_Registers
 * @{
 * @brief MT9V034_IMAGE_SENSOR Register Declaration
 *****************************************************************************/
typedef enum {

  REG_CHIP_VERSION = 0x00,                  // default value: 0x1324

  REG_COLUMN_START_CONTEXT_A,               // default value: 0x0001
  REG_ROW_START_CONTEXT_A,                  // default value: 0x0004
  REG_WINDOW_HEIGHT_CONTEXT_A,              // default value: 0x01E0
  REG_WINDOW_WIDTH_CONTEXT_A,               // default value: 0x02F0
  REG_HORIZONTAL_BLANK_CONTEXT_A,           // default value: 0x005E
  REG_VERTICAL_BLANK_CONTEXT_A,             // default value: 0x002D
  REG_CHIP_CONTROL,                         // default value: 0x0388
  REG_COARSE_SHUTTER_WIDTH_1_CONTEXT_A,     // default value: 0x01BB
  REG_COARSE_SHUTTER_WIDTH_2_CONTEXT_A,     // default value: 0x01D9
  REG_SHUTTER_WIDTH_CTRL_CONTEXT_A,         // default value: 0x0164
  REG_COARSE_TOTAL_SHUTTER_WIDTH_CONTEXT_A, // default value: 0x01E0

  REG_RESET,                                // default value: 0x0000
  REG_READ_MODE_CONTEXT_A,                  // default value: 0x0300
  REG_READ_MODE_CONTEXT_B,                  // default value: 0x0000
  REG_SENSOR_TYPE_CONTROL,                  // default value: 0x0100

  REG_LED_OUT_CTRL = 0x1B,                  // default value: 0x0000
  REG_ADC_COMPANDING_MODE,                  // default value: 0x0302
  REG_VREF_ADC_CONTROL = 0x2C,              // default value: 0x0004

  REG_V1_CONTEXT_A = 0x31,                  // default value: 0x0027
  REG_V2_CONTEXT_A,                         // default value: 0x001A
  REG_V3_CONTEXT_A,                         // default value: 0x0005
  REG_V4_CONTEXT_A,                         // default value: 0x0003
  REG_ANALOG_GAIN_CONTEXT_A,                // default value: 0x0010
  REG_ANALOG_GAIN_CONTEXT_B,                // default value: 0x8010

  REG_V1_CONTEXT_B = 0x39,                  // default value: 0x0027
  REG_V2_CONTEXT_B,                         // default value: 0x0026
  REG_V3_CONTEXT_B,                         // default value: 0x0005
  REG_V4_CONTEXT_B,                         // default value: 0x0003

  REG_FRAME_DARK_AVG = 0x42,                //
  REG_DARK_AVG_THRESHOLD = 0x46,            // default value: 0x231D
  REG_BLACK_LEVEL_CALIB_CONTROL,            // default value: 0x0080
  REG_BLACK_LEVEL_CALIB_VALUE,              // default value: 0x0000 // unpreditable depends on calibration
  REG_BLACK_LEVEL_CALIB_STEP_SIZE = 0x4C,   // default value: 0x0002

  REG_ROW_NOISE_CORR_CONTROL = 0x70,        // default value: 0x0000
  REG_ROW_NOISE_CONSTANT,                   // default value: 0x002A
  REG_PIXCLK_FV_LV_CTRL,                    // default value: 0x0000
  REG_DIGITAL_TEST_PATTERN = 0x7F,          // default value: 0x0000

  REG_TILE_DIGITAL_GAIN_X0_Y0,              // default value: 0x04F4
  REG_TILE_DIGITAL_GAIN_X1_Y0,              // default value: 0x04F4
  REG_TILE_DIGITAL_GAIN_X2_Y0,              // default value: 0x04F4
  REG_TILE_DIGITAL_GAIN_X3_Y0,              // default value: 0x04F4
  REG_TILE_DIGITAL_GAIN_X4_Y0,              // default value: 0x04F4

  REG_TILE_DIGITAL_GAIN_X0_Y1,              // default value: 0x04F4
  REG_TILE_DIGITAL_GAIN_X1_Y1,              // default value: 0x04F4
  REG_TILE_DIGITAL_GAIN_X2_Y1,              // default value: 0x04F4
  REG_TILE_DIGITAL_GAIN_X3_Y1,              // default value: 0x04F4
  REG_TILE_DIGITAL_GAIN_X4_Y1,              // default value: 0x04F4

  REG_TILE_DIGITAL_GAIN_X0_Y2,              // default value: 0x04F4
  REG_TILE_DIGITAL_GAIN_X1_Y2,              // default value: 0x04F4
  REG_TILE_DIGITAL_GAIN_X2_Y2,              // default value: 0x04F4
  REG_TILE_DIGITAL_GAIN_X3_Y2,              // default value: 0x04F4
  REG_TILE_DIGITAL_GAIN_X4_Y2,              // default value: 0x04F4

  REG_TILE_DIGITAL_GAIN_X0_Y3,              // default value: 0x04F4
  REG_TILE_DIGITAL_GAIN_X1_Y3,              // default value: 0x04F4
  REG_TILE_DIGITAL_GAIN_X2_Y3,              // default value: 0x04F4
  REG_TILE_DIGITAL_GAIN_X3_Y3,              // default value: 0x04F4
  REG_TILE_DIGITAL_GAIN_X4_Y3,              // default value: 0x04F4

  REG_TILE_DIGITAL_GAIN_X0_Y4,              // default value: 0x04F4
  REG_TILE_DIGITAL_GAIN_X1_Y4,              // default value: 0x04F4
  REG_TILE_DIGITAL_GAIN_X2_Y4,              // default value: 0x04F4
  REG_TILE_DIGITAL_GAIN_X3_Y4,              // default value: 0x04F4
  REG_TILE_DIGITAL_GAIN_X4_Y4,              // default value: 0x04F4

  REG_DIGITAL_TILE_COORD_1_X_0_5,           // default value: 0x0000
  REG_DIGITAL_TILE_COORD_2_X_1_5,           // default value: 0x0096
  REG_DIGITAL_TILE_COORD_3_X_2_5,           // default value: 0x012C
  REG_DIGITAL_TILE_COORD_4_X_3_5,           // default value: 0x01C2
  REG_DIGITAL_TILE_COORD_5_X_4_5,           // default value: 0x0258
  REG_DIGITAL_TILE_COORD_6_X_5_5,           // default value: 0x02F0

  REG_DIGITAL_TILE_COORD_1_Y_0_5,           // default value: 0x0000
  REG_DIGITAL_TILE_COORD_2_Y_1_5,           // default value: 0x0060
  REG_DIGITAL_TILE_COORD_3_Y_2_5,           // default value: 0x00C0
  REG_DIGITAL_TILE_COORD_4_Y_3_5,           // default value: 0x0120
  REG_DIGITAL_TILE_COORD_5_Y_4_5,           // default value: 0x0180
  REG_DIGITAL_TILE_COORD_6_Y_5_5,           // default value: 0x01E0

  REG_AEC_AGC_DESIRED_BIN,                  // default value: 0x003A
  REG_AEC_UPDATE_FREQ,                      // default value: 0x0002
  REG_AEC_LPF = 0xA8,                       // default value: 0x0000
  REG_AGC_UPDATE_FREQ,                      // default value: 0x0002
  REG_AGC_LPF,                              // default value: 0x0002
  REG_MAX_ANALOG_GAIN,                      // default value: 0x0040
  REG_AEC_MIN_EXPOSURE,                     // default value: 0x0001
  REG_AEC_MAX_EXPOSURE,                     // default value: 0x01E0
  REG_AGC_AEC_BIN_DIFF_THRESHOLD,           // default value: 0x0014
  REG_AGC_AEC_ENABLE_A_B,                   // default value: 0x0003
  REG_AGC_AEC_PIX_COUNT,                    // default value: 0xABE0

  REG_LVDS_MASTER_CTRL,                     // default value: 0x0002
  REG_LVDS_SHIFT_CLK_CTRL,                  // default value: 0x0010
  REG_LVDS_DATA_CTRL,                       // default value: 0x0010
  REG_DATA_STREAM_LATENCY,                  // default value: 0x0000
  REG_LVDS_INTERNAL_SYNC,                   // default value: 0x0000
  REG_LVDS_PAYLOAD_CONTROL,                 // default value: 0x0000
  REG_STEREOSCOP_ERR_CTRL,                  // default value: 0x0000
  REG_STEREOSCOP_ERR_FLAG,                  // Read-Only
  REG_LVDS_DATA_OUTPUT,                     // Read-Only
  REG_AGC_GAIN_OUTPUT,                      // Read-Only
  REG_AEC_GAIN_OUTPUT,                      // Read-Only
  REG_AGC_AEC_CURRENT_BIN,                  // Read-Only

  REG_FIELD_VERTICAL_BLANK = 0xBF,          // default value: 0x0016
  REG_MONITOR_MODE_CAPTURE_CTRL,            // default value: 0x000A
  REG_ANTI_ECLIPSE_CTRLS = 0xC2,            // default value: 0x0840
  REG_NTSV_FV_LV_CTRL = 0xC6,               // default value: 0x0000
  REG_NTSC_HORIZ_BLANK_CTRL,                // default value: 0x4416
  REG_NTSC_VERT_BLANK_CTRL,                 // default value: 0x4421

  REG_COLUMN_START_CONTEXT_B,               // default value: 0x0001
  REG_ROW_START_CONTEXT_B,                  // default value: 0x0004
  REG_WINDOW_HEIGHT_CONTEXT_B,              // default value: 0x01E0
  REG_WINDOW_WIDTH_CONTEXT_B,               // default value: 0x02F0
  REG_HORIZONTAL_BLANK_CONTEXT_B,           // default value: 0x005E
  REG_VERTICAL_BLANK_CONTEXT_B,             // default value: 0x002D
  REG_COARSE_SHUTTER_WIDTH_1_CONTEXT_B,     // default value: 0x01DE
  REG_COARSE_SHUTTER_WIDTH_2_CONTEXT_B,     // default value: 0x01DF
  REG_SHUTTER_WIDTH_CTRL_CONTEXT_B,         // default value: 0x0064
  REG_COARSE_TOTAL_SHUTTER_WIDTH_CONTEXT_B, // default value: 0x01E0

  REG_FINE_SHUTTER_WIDTH_1_CONTEXT_A,       // default value: 0x0000
  REG_FINE_SHUTTER_WIDTH_2_CONTEXT_A,       // default value: 0x0000
  REG_FINE_SHUTTER_WIDTH_TOTAL_CONTEXT_A,   // default value: 0x0000
  REG_FINE_SHUTTER_WIDTH_1_CONTEXT_B,       // default value: 0x0000
  REG_FINE_SHUTTER_WIDTH_2_CONTEXT_B,       // default value: 0x0000
  REG_FINE_SHUTTER_WIDTH_TOTAL_CONTEXT_B,   // default value: 0x0000

  REG_MONITOR_MODE,                         // default value: 0x0000
  REG_BYTEWISE_ADDR = 0xF0,                 // default value: 0x0000
  REG_REGISTER_LOCK = 0xFE                  // default value: 0xBEEF

}mt9v034_i2c_reg_addr_t;

#define NOF_SHADOWED_REGS    56

mt9v034_i2c_reg_addr_t mt9v034_shadowed_regs[NOF_SHADOWED_REGS] = {
  REG_COLUMN_START_CONTEXT_A,
  REG_WINDOW_HEIGHT_CONTEXT_A,
  REG_HORIZONTAL_BLANK_CONTEXT_A,
  REG_CHIP_CONTROL,
  REG_RESET,
  REG_READ_MODE_CONTEXT_A,
  REG_READ_MODE_CONTEXT_B,
  REG_SENSOR_TYPE_CONTROL,

  REG_LED_OUT_CTRL,
  REG_ROW_NOISE_CONSTANT,
  REG_PIXCLK_FV_LV_CTRL,
  REG_DIGITAL_TEST_PATTERN,
  REG_TILE_DIGITAL_GAIN_X0_Y0,
  REG_TILE_DIGITAL_GAIN_X1_Y0,
  REG_TILE_DIGITAL_GAIN_X2_Y0,
  REG_TILE_DIGITAL_GAIN_X3_Y0,

  REG_TILE_DIGITAL_GAIN_X4_Y0,
  REG_TILE_DIGITAL_GAIN_X0_Y1,
  REG_TILE_DIGITAL_GAIN_X1_Y1,
  REG_TILE_DIGITAL_GAIN_X2_Y1,
  REG_TILE_DIGITAL_GAIN_X3_Y1,
  REG_TILE_DIGITAL_GAIN_X4_Y1,
  REG_TILE_DIGITAL_GAIN_X0_Y2,
  REG_TILE_DIGITAL_GAIN_X1_Y2,

  REG_TILE_DIGITAL_GAIN_X2_Y2,
  REG_TILE_DIGITAL_GAIN_X3_Y2,
  REG_TILE_DIGITAL_GAIN_X4_Y2,
  REG_TILE_DIGITAL_GAIN_X0_Y3,
  REG_TILE_DIGITAL_GAIN_X1_Y3,
  REG_TILE_DIGITAL_GAIN_X2_Y3,
  REG_TILE_DIGITAL_GAIN_X3_Y3,
  REG_TILE_DIGITAL_GAIN_X4_Y3,

  REG_TILE_DIGITAL_GAIN_X0_Y4,
  REG_TILE_DIGITAL_GAIN_X1_Y4,
  REG_TILE_DIGITAL_GAIN_X2_Y4,
  REG_TILE_DIGITAL_GAIN_X3_Y4,
  REG_TILE_DIGITAL_GAIN_X4_Y4,
  REG_AEC_AGC_DESIRED_BIN,
  REG_AEC_UPDATE_FREQ,
  REG_AEC_LPF,

  REG_AGC_UPDATE_FREQ,
  REG_AGC_LPF,
  REG_AGC_AEC_BIN_DIFF_THRESHOLD,
  REG_AGC_AEC_ENABLE_A_B,
  REG_AGC_AEC_PIX_COUNT,
  REG_LVDS_MASTER_CTRL,
  REG_LVDS_SHIFT_CLK_CTRL,
  REG_LVDS_DATA_CTRL,

  REG_DATA_STREAM_LATENCY,
  REG_LVDS_INTERNAL_SYNC,
  REG_LVDS_PAYLOAD_CONTROL,
  REG_STEREOSCOP_ERR_CTRL,
  REG_FIELD_VERTICAL_BLANK,
  REG_MONITOR_MODE_CAPTURE_CTRL,
  REG_NTSV_FV_LV_CTRL,
  REG_MONITOR_MODE
};


/** @} End of group MT9V034_IMAGE_SENSOR_Registers */

#endif /* MT9V034_REGS_H_ */






