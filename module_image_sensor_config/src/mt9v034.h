// Copyright (c) 2014, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef MT9V034_H_
#define MT9V034_H_

/**************************************************************************//**
 * @defgroup MT9V034_IMAGE_SENSOR_BitFields
 * @{
 *****************************************************************************/

/* COLUMN START CONTEXT A/B */
#define COLUMN_START(x)                           ((x & 0x03FF) << 0)
/* ROW START CONTEXT A/B */
#define ROW_START(x)                              ((x & 0x01FF) << 0)
/* WINDOW HEIGHT CONTEXT A/B */
#define WINDOW_HEIGHT(x)                          ((x & 0x01FF) << 0)
/* WINDOW WIDTH CONTEXT A/B */
#define WINDOW_WIDTH(x)                           ((x & 0x03FF) << 0)
/* HORIZONTAL BLANKING CONTEXT A/B */
#define HORIZONTAL_BLANK(x)                       ((x & 0x03FF) << 0)
/* VERTICAL BLANKING CONTEXT A/B */
#define VERTICAL_BLANK(x)                         ((x & 0x07FFF) << 0)
/* COARSE SHUTTER WIDTH 1 CONTEXT A/B */
#define COARSE_SHUTTER_WIDTH_1(x)                 ((x & 0x7FFF) << 0)
/* COARSE SHUTTER WIDTH 2 CONTEXT A/B */
#define COARSE_SHUTTER_WIDTH_2(x)                 ((x & 0x7FFF) << 0)
/* COARSE SHUTTER WIDTH TOTAL CONTEXT A/B */
#define COARSE_SHUTTER_WIDTH_TOTAL(x)             ((x & 0x7FFF) << 0)

/* CHIP CTRL */
#define _PROGRESSIVE_SCAN_MODE                    (0x0000)
#define _INTERLACE_SCAN_2_FIELD_MODE              (0x0002)
#define _INTERLACE_SCAN_4_FIELD_MODE              (0x0003)
#define PROGRESSIVE_SCAN_MODE                     (_PROGRESSIVE_SCAN_MODE << 0)
#define INTERLACE_SCAN_2_FIELD_MODE               (_INTERLACE_SCAN_2_FIELD_MODE << 0)
#define INTERLACE_SCAN_4_FIELD_MODE               (_INTERLACE_SCAN_4_FIELD_MODE << 0)
#define _SLAVE_MODE                               (0x0000)
#define _MASTER_MODE                              (0x0001)
#define _SNAPSHOT_MODE                            (0x0003)
#define SLAVE_MODE                                (_SLAVE_MODE << 3)
#define MASTER_MODE                               (_MASTER_MODE << 3)
#define SNAPSHOT_MODE                             (_SNAPSHOT_MODE << 3)
#define _STEREOSCOPY_MODE_DISABLE                 (0x0000)
#define _STEREOSCOPY_MODE_ENABLE                  (0x0001)
#define STEREOSCOPY_MODE_DISABLE                  (_STEREOSCOPY_MODE_DISABLE << 5)
#define STEREOSCOPY_MODE_ENABLE                   (_STEREOSCOPY_MODE_ENABLE << 5)
#define _STEREOSCOPIC_MASTER_MODE                 (0x0000)
#define _STEREOSCOPIC_SLAVE_MODE                  (0x0001)
#define STEREOSCOPIC_MASTER_MODE                  (_STEREOSCOPIC_MASTER_MODE << 6)
#define STEREOSCOPIC_SLAVE_MODE                   (_STEREOSCOPIC_SLAVE_MODE << 6)
#define _PARALLEL_OUT_DISABLE                     (0x0000)
#define _PARALLEL_OUT_ENABLE                      (0x0001)
#define PARALLEL_OUT_DISABLE                      (_PARALLEL_OUT_DISABLE << 7)
#define PARALLEL_OUT_ENABLE                       (_PARALLEL_OUT_ENABLE << 7)
#define _PIX_READ_SEQUENTIAL_MODE                 (0x0000)
#define _PIX_READ_SIMULTANEOUS_MODE               (0x0001)
#define PIX_READ_SEQUENTIAL_MODE                  (_PIX_READ_SEQUENTIAL_MODE << 8)
#define PIX_READ_SIMULTANEOUS_MODE                (_PIX_READ_SIMULTANEOUS_MODE << 8)
#define _DEFECTIVE_PIXEL_CORRECTION_DISABLE       (0x0000)
#define _DEFECTIVE_PIXEL_CORRECTION_ENABLE        (0x0001)
#define DEFECTIVE_PIXEL_CORRECTION_DISABLE        (_DEFECTIVE_PIXEL_CORRECTION_DISABLE << 9)
#define DEFECTIVE_PIXEL_CORRECTION_ENABLE         (_DEFECTIVE_PIXEL_CORRECTION_ENABLE << 9)
#define _CONTEXT_A_REG_SELECT                     (0x0000)
#define _CONTEXT_B_REG_SELECT                     (0x0001)
#define CONTEXT_A_REG_SELECT                      (_CONTEXT_A_REG_SELECT << 15)
#define CONTEXT_B_REG_SELECT                      (_CONTEXT_B_REG_SELECT << 15)

/* SHUTTER WIDTH CONTROL CONTEXT A/B */
#define SHUTTER_WIDTH_T2_RATIO(x)                 ((x & 0x000F) << 0)
#define SHUTTER_WIDTH_T3_RATIO(x)                 ((x & 0x000F) << 4)
#define _SHUTTER_WIDTH_EXP_KNEE_AUTOADJ_DISABLE   (0x0000)
#define _SHUTTER_WIDTH_EXP_KNEE_AUTOADJ_ENABLE    (0x0001)
#define SHUTTER_WIDTH_EXP_KNEE_AUTOADJ_DISABLE    (_SHUTTER_WIDTH_EXP_KNEE_AUTOADJ_DISABLE << 8)
#define SHUTTER_WIDTH_EXP_KNEE_AUTOADJ_ENABLE     (_SHUTTER_WIDTH_EXP_KNEE_AUTOADJ_ENABLE << 8)
#define _SHUTTER_WIDTH_SINGLE_KNEE_DISABLE        (0x0000)
#define _SHUTTER_WIDTH_SINGLE_KNEE_ENABLE         (0x0001)
#define SHUTTER_WIDTH_SINGLE_KNEE_DISABLE         (_SHUTTER_WIDTH_SINGLE_KNEE_DISABLE << 9)
#define SHUTTER_WIDTH_SINGLE_KNEE_ENABLE          (_SHUTTER_WIDTH_SINGLE_KNEE_ENABLE << 9)

/* RESET */
#define _SOFT_RESET_DISABLE                       (0x0000)
#define _SOFT_RESET_ENABLE                        (0x0001)
#define SOFT_RESET_DISABLE                        (_SOFT_RESET_DISABLE << 0)
#define SOFT_RESET_ENABLE                         (_SOFT_RESET_ENABLE << 0)
#define _AUTO_BLOCK_SOFT_RESET_DISABLE            (0x0000)
#define _AUTO_BLOCK_SOFT_RESET_ENABLE             (0x0001)
#define AUTO_BLOCK_SOFT_RESET_DISABLE             (_AUTO_BLOCK_SOFT_RESET_DISABLE << 1)
#define AUTO_BLOCK_SOFT_RESET_ENABLE              (_AUTO_BLOCK_SOFT_RESET_ENABLE << 1)

/* READ MODE CONTEXT A/B */
#define _READ_MOD_ROW_BIN_NORMAL                  (0x0000)
#define _READ_MOD_ROW_BIN_2                       (0x0001)
#define _READ_MOD_ROW_BIN_4                       (0x0002)
#define READ_MOD_ROW_BIN_NORMAL                   (_READ_MOD_ROW_BIN_NORMAL << 0)
#define READ_MOD_ROW_BIN_2                        (_READ_MOD_ROW_BIN_2 << 0)
#define READ_MOD_ROW_BIN_4                        (_READ_MOD_ROW_BIN_4 << 0)

/* READ MODE CONTEXT A */
#define _READ_MOD_COL_BIN_NORMAL                  (0x0000)
#define _READ_MOD_COL_BIN_2                       (0x0001)
#define _READ_MOD_COL_BIN_4                       (0x0002)
#define READ_MOD_COL_BIN_NORMAL                   (_READ_MOD_COL_BIN_NORMAL << 2)
#define READ_MOD_COL_BIN_2                        (_READ_MOD_COL_BIN_2 << 2)
#define READ_MOD_COL_BIN_4                        (_READ_MOD_COL_BIN_4 << 2)
#define _READ_MOD_ROW_FLIP_DISABLE                (0x0000)
#define _READ_MOD_ROW_FLIP_ENABLE                 (0x0001)
#define READ_MOD_ROW_FLIP_DISABLE                 (_READ_MOD_ROW_FLIP_DISABLE << 4)
#define READ_MOD_ROW_FLIP_ENABLE                  (_READ_MOD_ROW_FLIP_ENABLE < 4)
#define _READ_MOD_COL_FLIP_DISABLE                (0x0000)
#define _READ_MOD_COL_FLIP_ENABLE                 (0x0001)
#define READ_MOD_COL_FLIP_DISABLE                 (_READ_MOD_COL_FLIP_DISABLE << 5)
#define READ_MOD_COL_FLIP_ENABLE                  (_READ_MOD_COL_FLIP_ENABLE << 5)
#define _READ_MOD_DARK_ROW_DISABLE                (0x0000)
#define _READ_MOD_DARK_ROW_ENABLE                 (0x0001)
#define READ_MOD_DARK_ROW_DISABLE                 (_READ_MOD_DARK_ROW_DISABLE << 6)
#define READ_MOD_DARK_ROW_ENABLE                  (_READ_MOD_DARK_ROW_ENABLE << 6)
#define _READ_MOD_DARK_COL_DISABLE                (0x0000)
#define _READ_MOD_DARK_COL_ENABLE                 (0x0001)
#define READ_MOD_DARK_COL_DISABLE                 (_READ_MOD_DARK_COL_DISABLE << 7)
#define READ_MOD_DARK_COL_ENABLE                  (_READ_MOD_DARK_COL_ENABLE << 7)
#define _READ_MOD_RESERVED_BITS                   (0x0003)
#define READ_MOD_RESERVED_BITS                    (_READ_MOD_RESERVED_BITS << 8)

/* SENSOR TYPE CONTROL */
#define _HIGH_DYNAMIC_RANGE_DISABLE               (0x0000)
#define _HIGH_DYNAMIC_RANGE_ENABLE                (0x0001)
#define HIGH_DYNAMIC_RANGE_CONTEXT_A_DISABLE      (_HIGH_DYNAMIC_RANGE_DISABLE << 0)
#define HIGH_DYNAMIC_RANGE_CONTEXT_A_ENBALE       (_HIGH_DYNAMIC_RANGE_ENABLE << 0)
#define _MONOCHROME_SENSOR_CONTROL                (0x0000)
#define _COLOR_SENSOR_CONTROL                     (0x0001)
#define MONOCHROME_SENSOR_CONTROL                 (_MONOCHROME_SENSOR_CONTROL << 1)
#define COLOR_SENSOR_CONTROL                      (_COLOR_SENSOR_CONTROL << 1)
#define HIGH_DYNAMIC_RANGE_CONTEXT_B_DISABLE      (_HIGH_DYNAMIC_RANGE_DISABLE << 8)
#define HIGH_DYNAMIC_RANGE_CONTEXT_B_ENBALE       (_HIGH_DYNAMIC_RANGE_ENABLE << 8)

/* LED OUT CONTROL */
#define _LED_OUT_DISABLE                          (0x0000)
#define _LED_OUT_ENABLE                           (0x0001)
#define LED_OUT_DISABLE                           (_LED_OUT_DISABLE << 0)
#define LED_OUT_ENABLE                            (_LED_OUT_ENABLE << 0)
#define _LED_OUT_POLARITY_HIGH                    (0x0000)
#define _LED_OUT_POLARITY_LOW                     (0x0001)
#define LED_OUT_POLARITY_HIGH                     (_LED_OUT_POLARITY_HIGH << 0)
#define LED_OUT_POLARITY_LOW                      (_LED_OUT_POLARITY_LOW << 0)

/* ADC COMPANDING MODE */
#define _ADC_MOD_10BIT_LINEAR                     (0x0002)
#define _ADC_MOD_12_TO_10_COMPANDING              (0x0003)
#define ADC_MOD_CONTEXT_A_10BIT_LINEAR            (_ADC_MOD_10BIT_LINEAR << 0)
#define ADC_MOD_CONTEXT_A_12_TO_10_COMPANDING     (_ADC_MOD_12_TO_10_COMPANDING << 0)
#define ADC_MOD_CONTEXT_B_10BIT_LINEAR            (_ADC_MOD_10BIT_LINEAR << 8)
#define ADC_MOD_CONTEXT_B_12_TO_10_COMPANDING     (_ADC_MOD_12_TO_10_COMPANDING << 8)

/* VREF ADC CONTROL */
#define _VREF_ADC_VTG_1P0                         (0x0000)
#define _VREF_ADC_VTG_1P1                         (0x0001)
#define _VREF_ADC_VTG_1P2                         (0x0002)
#define _VREF_ADC_VTG_1P3                         (0x0003)
#define _VREF_ADC_VTG_1P4                         (0x0004)
#define _VREF_ADC_VTG_1P5                         (0x0005)
#define _VREF_ADC_VTG_1P6                         (0x0006)
#define _VREF_ADC_VTG_2P1                         (0x0007)
#define VREF_ADC_VTG_1P0                          (_VREF_ADC_VTG_1P0 << 0)
#define VREF_ADC_VTG_1P1                          (_VREF_ADC_VTG_1P1 << 0)
#define VREF_ADC_VTG_1P2                          (_VREF_ADC_VTG_1P2 << 0)
#define VREF_ADC_VTG_1P3                          (_VREF_ADC_VTG_1P3 << 0)
#define VREF_ADC_VTG_1P4                          (_VREF_ADC_VTG_1P4 << 0)
#define VREF_ADC_VTG_1P5                          (_VREF_ADC_VTG_1P5 << 0)
#define VREF_ADC_VTG_1P6                          (_VREF_ADC_VTG_1P6 << 0)
#define VREF_ADC_VTG_2P1                          (_VREF_ADC_VTG_2P1 << 0)

/* V1,V2,V3,V4 CONTROL CONTEXT A/B */
#define V_CTRL_VTG_LEVEL(x)                       ((x & 0x003F) << 0)

/* ANALOG GAIN CONTEXT A/B */
#define GLOBAL_ANALOG_GAIN(x)                     ((x & 0x007F) << 0)
#define _GLOBAL_ANALOG_GAIN_ATTENUATION_DISABLE   (0x0000)
#define _GLOBAL_ANALOG_GAIN_ATTENUATION_ENABLE    (0x0001)
#define GLOBAL_ANALOG_GAIN_ATTENUATION_DISABLE    (_GLOBAL_ANALOG_GAIN_ATTENUATION_DISABLE << 15)
#define GLOBAL_ANALOG_GAIN_ATTENUATION_ENABLE     (_GLOBAL_ANALOG_GAIN_ATTENUATION_ENABLE << 15)

/* DARK AVERAGE THRESHOLDS */
#define DARK_AVG_LOWER_THRESHOLD(x)               ((x & 0x00FF) << 0)
#define DARK_AVG_UPPER_THRESHOLD(x)               ((x & 0x00FF) << 8)

/* BLACK LEVEL CALIBRATION CONTROL */
#define _MANUAL_OVERRIDE_NORMAL                   (0x0000)
#define _MANUAL_OVERRIDE_AUTOMATIC                (0x0001)
#define MANUAL_OVERRIDE_NORMAL                    (_MANUAL_OVERRIDE_NORMAL << 0)
#define MANUAL_OVERRIDE_AUTOMATIC                 (_MANUAL_OVERRIDE_AUTOMATIC << 0)
#define FRAME_TO_AVERAGE(x)                       ((x & 0x0007) << 5)

/* BLACK LEVEL CALIBRATION VALUE */
#define BLACK_LEVEL_CALIB_VALUE(x)                ((x & 0x00FF) << 0)
/* BLACK LEVEL CALIBRAION VALUE STEP SIZE */
#define STEP_SIZE_OF_CALIB_VALUE(x)               ((x & 0x001F) << 0)

/* ROW NOISE CORRECTION CONTROL */
#define _NOISE_CORRECTION_DISABLE                 (0x0000)
#define _NOISE_CORRECTION_ENABLE                  (0x0001)
#define NOISE_CORRECTION_CONTEXT_A_DISABLE        (_NOISE_CORRECTION_DISABLE << 0)
#define NOISE_CORRECTION_CONTEXT_A_ENABLE         (_NOISE_CORRECTION_ENABLE << 0)
#define _BLACK_LEVEL_AVG_DISABLE                  (0x0000)
#define _BLACK_LEVEL_AVG_ENABLE                   (0x0001)
#define BLACK_LEVEL_AVG_CONTEXT_A_DISABLE         (_BLACK_LEVEL_AVG_DISABLE << 1)
#define BLACK_LEVEL_AVG_CONTEXT_A_ENABLE          (_BLACK_LEVEL_AVG_ENABLE << 1)
#define NOISE_CORRECTION_CONTEXT_B_DISABLE        (_NOISE_CORRECTION_DISABLE << 8)
#define NOISE_CORRECTION_CONTEXT_B_ENABLE         (_NOISE_CORRECTION_ENABLE << 8)
#define BLACK_LEVEL_AVG_CONTEXT_B_DISABLE         (_BLACK_LEVEL_AVG_DISABLE << 9)
#define BLACK_LEVEL_AVG_CONTEXT_B_ENABLE          (_BLACK_LEVEL_AVG_ENABLE << 9)

/* ROW NOISE CONSTANT */
#define ROW_NOISE_CONSTANT(x)                     ((x & 0x03FF) << 0)

/* PIXEL CLOCK, FRAME VALID and LINE VALID CONTROL */
#define _LINE_VALID_HIGH                          (0x0000)
#define _LINE_VALID_LOW                           (0x0001)
#define LINE_VALID_HIGH                           (_LINE_VALID_HIGH << 0)
#define LINE_VALID_LOW                            (_LINE_VALID_LOW << 0)
#define _FRAME_VALID_HIGH                         (0x0000)
#define _FRAME_VALID_LOW                          (0x0001)
#define FRAME_VALID_HIGH                          (_FRAME_VALID_HIGH << 1)
#define FRAME_VALID_LOW                           (_FRAME_VALID_LOW << 1)
#define _XOR_LINE_VALID_DISABLE                   (0x0000)
#define _XOR_LINE_VALID_ENABLE                    (0x0001)
#define XOR_LINE_VALID_DISABLE                    (_XOR_LINE_VALID_DISABLE << 2)
#define XOR_LINE_VALID_ENABLE                     (_XOR_LINE_VALID_ENABLE << 2)
#define _CONTINUOUS_LINE_VALID_DISABLE            (0x0000)
#define _CONTINUOUS_LINE_VALID_ENABLE             (0x0001)
#define CONTINUOUS_LINE_VALID_DISABLE             (_CONTINUOUS_LINE_VALID_DISABLE << 3)
#define CONTINUOUS_LINE_VALID_ENABLE              (_CONTINUOUS_LINE_VALID_ENABLE << 3)
#define _PIXEL_CLOCK_INVERT_DISABLE               (0x0000)
#define _PIXEL_CLOCK_INVERT_ENABLE                (0x0001)
#define PIXEL_CLOCK_INVERT_DISABLE                (_PIXEL_CLOCK_INVERT_DISABLE << 4)
#define PIXEL_CLOCK_INVERT_ENABLE                 (_PIXEL_CLOCK_INVERT_ENABLE << 4)

/* DIGITAL TEST PATTERN */
#define SERIAL_INTERFACE_TEST_DATA(x)             ((x & 0x03FF) << 0)
#define _USE_GRAY_SHADE_TESTE_PATTERN             (0x0000)
#define _USE_SERIAL_INTERFACE_TEST_DATA           (0x0001)
#define USE_GRAY_SHADE_TESTE_PATTERN              (_USE_GRAY_SHADE_TESTE_PATTERN << 10)
#define USE_SERIAL_INTERFACE_TEST_DATA            (_USE_SERIAL_INTERFACE_TEST_DATA << 10)
#define _GRAY_SHADE_TEST_PATTERN_NONE             (0x0000)
#define _GRAY_SHADE_TEST_PATTERN_VERTICAL         (0x0001)
#define _GRAY_SHADE_TEST_PATTERN_HORIZONTAL       (0x0002)
#define _GRAY_SHADE_TEST_PATTERN_DIAGONAL         (0x0003)
#define GRAY_SHADE_TEST_PATTERN_NONE              (_GRAY_SHADE_TEST_PATTERN_NONE << 11)
#define GRAY_SHADE_TEST_PATTERN_VERTICAL          (_GRAY_SHADE_TEST_PATTERN_VERTICAL << 11)
#define GRAY_SHADE_TEST_PATTERN_HORIZONTAL        (_GRAY_SHADE_TEST_PATTERN_HORIZONTAL << 11)
#define GRAY_SHADE_TEST_PATTERN_DIAGONAL          (_GRAY_SHADE_TEST_PATTERN_DIAGONAL << 11)
#define _DIG_TEST_PATT_TEST_DISABLE               (0x0000)
#define _DIG_TEST_PATT_TEST_ENABLE                (0x0001)
#define DIG_TEST_PATT_TEST_DISABLE                (_DIG_TEST_PATT_TEST_DISABLE << 13)
#define DIG_TEST_PATT_TEST_ENABLE                 (_DIG_TEST_PATT_TEST_ENABLE << 13)
#define _FLIP_SERIAL_INTERFACE_TEST_DATA_DISABLE  (0x0000)
#define _FLIP_SERIAL_INTERFACE_TEST_DATA_ENABLE   (0x0001)
#define FLIP_SERIAL_INTERFACE_TEST_DATA_DISABLE   (_FLIP_SERIAL_INTERFACE_TEST_DATA_DISABLE << 14)
#define FLIP_SERIAL_INTERFACE_TEST_DATA_ENABLE    (_FLIP_SERIAL_INTERFACE_TEST_DATA_ENABLE << 14)

/* TILED DIGITAL GAIN */
#define TILE_GAIN_CONTEXT_A(x)                    ((x & 0x000F) << 0)
#define GAIN_SAMPLE_WEIGHT(x)                     ((x & 0x000F) << 4)
#define TILE_GAIN_CONTEXT_B(x)                    ((x & 0x000F) << 8)

/* DIGITAL TILE COORDINATE - X - DIRECTION */
#define STARTING_X_COORDINATE(x)                  ((x & 0x03FF) << 0)
/* DIGITAL TILE COORDINATE - Y - DIRECTION */
#define STARTING_Y_COORDINATE(x)                  ((x & 0x01FF) << 0)

/* AEC/AGC DESIRED BIN */
#define AEC_AGC_DESIRED_BIN(x)                    ((x & 0x003F) << 0)
/* AEC UPDATE FREQUENCY */
#define AEC_EXPOSURE_SKIP_FRAME(x)                ((x & 0x000F) << 0)

/* AEC LOW PASS FILTER */
#define _AEC_EXP_LPF_ACTUAL_EQU2_CALC             (0x0000)
#define _AEC_EXP_LPF_ACTUAL_EQU2_CALC_BY_2        (0x0001)
#define _AEC_EXP_LPF_ACTUAL_EQU2_CALC_BY_4        (0x0002)
#define AEC_EXP_LPF_ACTUAL_EQU2_CALC              (_AEC_EXP_LPF_ACTUAL_EQU2_CALC << 0)
#define AEC_EXP_LPF_ACTUAL_EQU2_CALC_BY_2         (_AEC_EXP_LPF_ACTUAL_EQU2_CALC_BY_2 << 0)
#define AEC_EXP_LPF_ACTUAL_EQU2_CALC_BY_4         (_AEC_EXP_LPF_ACTUAL_EQU2_CALC_BY_4 << 0)

/* AGC OUTPUT UPDATE FREQUENCY */
#define AGC_GAIN_SKIP_FRAME(x)                    ((x & 0x000F) << 0)

/* AGC LOW PASS FILTER */
#define _AGC_GAIN_LPF_ACTUAL_EQU2_CALC            (0x0000)
#define _AGC_GAIN_LPF_ACTUAL_EQU2_CALC_BY_2       (0x0001)
#define _AGC_GAIN_LPF_ACTUAL_EQU2_CALC_BY_4       (0x0002)
#define AGC_GAIN_LPF_ACTUAL_EQU2_CALC             (_AGC_GAIN_LPF_ACTUAL_EQU2_CALC << 0)
#define AGC_GAIN_LPF_ACTUAL_EQU2_CALC_BY_2        (_AGC_GAIN_LPF_ACTUAL_EQU2_CALC_BY_2 << 0)
#define AGC_GAIN_LPF_ACTUAL_EQU2_CALC_BY_4        (_AGC_GAIN_LPF_ACTUAL_EQU2_CALC_BY_4 << 0)

/* MAXIMUM ANALOG GAIN */
#define MAX_ANALOG_GAIN(x)                        ((x & 0x007F) << 0)
/* MINUMUM COARSE SHUTTER WIDTH */
#define MIN_COARSE_SHUTTER_WIDTH_TOTAL(x)         ((x & 0xFFFF) << 0)
/* MAX COARSE SHUTTER WIDTH */
#define MAX_COARSE_SHUTTER_WIDTH_TOTAL(x)         ((x & 0xFFFF) << 0)
/* AGC/AEC BIN DIFFERENCE THRESHOLD */
#define AGC_AEC_BIN_DIFFERENCE_THRESHOLD(x)       ((x & 0x00FF) << 0)

/* AGC/AEC ENABLE */
#define _AEC_DISABLE                              (0x0000)
#define _AEC_ENABLE                               (0x0001)
#define AEC_CONTEXT_A_DISABLE                     (_AEC_DISABLE << 0)
#define AEC_CONTEXT_A_ENABLE                      (_AEC_ENABLE << 0)
#define _AGC_DISABLE                              (0x0000)
#define _AGC_ENABLE                               (0x0001)
#define AGC_CONTEXT_A_DISABLE                     (_AGC_DISABLE << 1)
#define AGC_CONTEXT_A_ENABLE                      (_AGC_ENABLE << 1)
#define AEC_CONTEXT_B_DISABLE                     (_AEC_DISABLE << 8)
#define AEC_CONTEXT_B_ENABLE                      (_AEC_ENABLE << 8)
#define AGC_CONTEXT_B_DISABLE                     (_AGC_DISABLE << 9)
#define AGC_CONTEXT_B_ENABLE                      (_AGC_ENABLE << 9)

/* AGC/AEC PIXEL COUNT */
#define AGC_AEC_PIXEL_COUNT(x)                    ((x & 0xFFFF) << 0)

/* STEREOSCOPY ERROR CONTROL */
#define _STEREO_ERR_DETECT_DISABLE                (0x0000)
#define _STEREO_ERR_DETECT_ENABLE                 (0x0001)
#define STEREO_ERR_DETECT_DISABLE                 (_STEREO_ERR_DETECT_DISABLE << 0)
#define STEREO_ERR_DETECT_ENABLE                  (_STEREO_ERR_DETECT_ENABLE << 0)
#define _STEREO_ERR_FLAG_DISABLE                  (0x0000)
#define _STEREO_ERR_FLAG_ENABLE                   (0x0001)
#define STEREO_ERR_FLAG_DISABLE                   (_STEREO_ERR_FLAG_DISABLE << 1)
#define STEREO_ERR_FLAG_ENABLE                    (_STEREO_ERR_FLAG_ENABLE << 1)
#define _STEREO_ERR_FLAG_CLEAR                    (0x0001)
#define STEREO_ERR_FLAG_CLEAR                     (_STEREO_ERR_FLAG_CLEAR << 2)

/* FIELD VERTICAL BLANK */
#define FIELD_VERTICAL_BLANK(x)                   ((x & 0x01FF) << 0)
/* MONITOR MODE CAPTURE CONTROL */
#define MONITOR_MOD_NOF_FRAME_TO_CAPTURE(x)       ((x & 0x00FF) << 0)

/* ANALOG CONTROLS */
#define _ANALOG_CTRL_RESERVED_BIT                 (0x0001)
#define ANALOG_CTRL_RESERVED_BIT                  (_ANALOG_CTRL_RESERVED_BIT << 6)
#define _ANTI_ECLIPSE_DISABLE                     (0x0000)
#define _ANTI_ECLIPSE_ENABLE                      (0x0001)
#define ANTI_ECLIPSE_DISABLE                      (_ANTI_ECLIPSE_DISABLE << 7)
#define ANTI_ECLIPSE_ENABLE                       (_ANTI_ECLIPSE_ENABLE << 7)
#define V_RST_LIM_VOLTAGE_LEVEL(x)                ((x & 0x0007) << 11)

/* NTSC FRAME VALID CONTROL */
#define _NTSC_EXTEND_FRAME_VALID_DISABLE          (0x0000)
#define _NTSC_EXTEND_FRAME_VALID_ENABLE           (0x0001)
#define NTSC_EXTEND_FRAME_VALID_DISABLE           (_NTSC_EXTEND_FRAME_VALID_DISABLE << 0)
#define NTSC_EXTEND_FRAME_VALID_ENABLE            (_NTSC_EXTEND_FRAME_VALID_ENABLE << 0)
#define _REPLACE_FVLV_BY_PEDSYNC_DISABLE          (0x0000)
#define _REPLACE_FVLV_BY_PEDSYNC_ENABLE           (0x0001)
#define REPLACE_FVLV_BY_PEDSYNC_DISABLE           (_REPLACE_FVLV_BY_PEDSYNC_DISABLE << 1)
#define REPLACE_FVLV_BY_PEDSYNC_ENABLE            (_REPLACE_FVLV_BY_PEDSYNC_ENABLE << 1)

/* NTSC HORIZONTAL BLANK CONTROL */
#define NTSC_FRONT_PORCH_WIDTH(x)                 ((x & 0x00FF) << 0)
#define NTSC_SYNC_WIDTH(x)                        ((x & 0x00FF) << 8)

/* NTSC VERTICAL BLANK CONTROL */
#define NTSC_EQUALIZING_PULSE_WIDTH(x)            ((x & 0x00FF) << 0)
#define NTSC_VERTI_SERRATION_WIDTH(x)             ((x & 0x00FF) << 8)

/* FINE SHUTTER WIDTH 1 CONTEXT A/B */
#define FINE_SHUTTER_WIDTH_1(x)                   ((x & 0x07FF) << 0)
/* FINE SHUTTER WIDTH 2 CONTEXT A/B */
#define FINE_SHUTTER_WIDTH_2(x)                   ((x & 0x07FF) << 0)
/* FINE SHUTTER WIDTH 2 CONTEXT A/B */
#define FINE_SHUTTER_WIDTH_TOTAL(x)               ((x & 0x07FF) << 0)

/* MONITOR MODE */
#define _MONITOR_MODE_DISABLE                     (0x0000)
#define _MONITOR_MODE_ENABLE                      (0x0001)
#define MONITOR_MODE_DISABLE                      (_MONITOR_MODE_DISABLE << 0)
#define MONITOR_MODE_ENABLE                       (_MONITOR_MODE_ENABLE << 0)

/* REGISTER LOCK */
#define _LOCK_REG_0D_0E                           (0xDEAF)
#define LOCK_REG_0D_0E                            (_LOCK_REG_0D_0E << 0)
#define _LOCK_ALL_REG                             (0xDEAD)
#define LOCK_ALL_REG                              (_LOCK_ALL_REG << 0)
#define _UNLOCK_ALL_REG                           (0xBEEF)
#define UNLOCK_ALL_REG                            (_UNLOCK_ALL_REG << 0)

/** @} End of group MT9V034_IMAGE_SENSOR_BitFields */

/**************************************************************************//**
 * @defgroup MT9V034_IMAGE_SENSOR_Defines
 * @{
 *****************************************************************************/
#define MT9V034_MAX_HEIGHT   480
#define MT9V034_MAX_WIDTH    752
#define MT9V034_REG_LOCK     0
#define MT9V034_REG_UNLOCK   1

/** @} End of group MT9V034_IMAGE_SENSOR_Defines */
#endif /* MT9V034_H_ */
