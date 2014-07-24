// Copyright (c) 2014, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <stdio.h>
#include <timer.h>
#include "mt9v034_regs.h"
#include "mt9v034.h"
#include "image_sensor_config.h"

#define TOTAL_FRAME_TIME_USEC    17767

struct r_i2c *i2c_interface_g;
unsigned char reg_lock_status_g = MT9V034_REG_UNLOCK;
/****************************************************************************************
 *
 ***************************************************************************************/
static inline unsigned char check_for_shadowed_reg(mt9v034_i2c_reg_addr_t reg_addr){
    for(unsigned idx = 0; idx < NOF_SHADOWED_REGS; idx++) {
        if(reg_addr == mt9v034_shadowed_regs[idx])
            return 1;
    }
    return 0;
}
/****************************************************************************************
 *
 ***************************************************************************************/
static inline int image_sensor_i2c_read(mt9v034_i2c_reg_addr_t reg_addr,unsigned short *rd_data)
{
    unsigned char data[2] = {0,0};
    rd_data[0] = 0; // Initialise before every read

    if( CONFIG_SUCCESS == i2c_master_read_reg(MT9V034_I2C_ADDR,reg_addr,data,sizeof(unsigned short),i2c_interface_g) )
    {
        rd_data[0] = (data[0] << 8 | data[1]);
        return CONFIG_SUCCESS;
    }

    return CONFIG_FAILURE;
}
/****************************************************************************************
 *
 ***************************************************************************************/
static inline int image_sensor_i2c_write(mt9v034_i2c_reg_addr_t reg_addr,unsigned short wr_data)
{
    unsigned char data[2] = {0,0};
    data[0] = (unsigned char )((wr_data & 0xFF00) >> 8);
    data[1] = (unsigned char )(wr_data & 0x00FF);

    if( CONFIG_SUCCESS == i2c_master_write_reg(MT9V034_I2C_ADDR,reg_addr,data,sizeof(unsigned short),i2c_interface_g) ) {
      /* Once write is success, check whether the updated register is shadowed,
       * if so include total frame time delay to update the register
       * The certain register contains shadowed bit(s), write gets effective from next frame.
       * Total Frame Time @ 25MHz = 444,154 pixel clocks/25MHz = 17766.16uSec
       */
      if(check_for_shadowed_reg(reg_addr))
          delay_microseconds(TOTAL_FRAME_TIME_USEC);

      return CONFIG_SUCCESS;
    }

    return CONFIG_FAILURE;
}
/****************************************************************************************
 *
 ***************************************************************************************/
static inline int image_sensor_read_chip_version(void)
{
    unsigned short rd_data = 0;

    if(CONFIG_SUCCESS == image_sensor_i2c_read(REG_CHIP_VERSION,&rd_data)) {

        if(MT9V034_CHIP_VERSION == rd_data) {
          return CONFIG_SUCCESS;
        }
        else {
            printf("ERROR: Image Sensor Chip Version: 0x%x\n",rd_data);
            return CONFIG_ERR_NO_DEVICE;
        }

    }
    else
        printf("ERROR: Image Sensor I2C Read Failed\n");

    return CONFIG_FAILURE;
}
/****************************************************************************************
 *
 ***************************************************************************************/
int image_sensor_reg_lock(void) {
    if(CONFIG_SUCCESS == image_sensor_i2c_write(REG_REGISTER_LOCK,LOCK_ALL_REG)) {
        reg_lock_status_g = MT9V034_REG_LOCK;
        return CONFIG_SUCCESS;
    }
    return CONFIG_FAILURE;
}
/****************************************************************************************
 *
 ***************************************************************************************/
int image_sensor_reg_unlock(void) {
    if(CONFIG_SUCCESS == image_sensor_i2c_write(REG_REGISTER_LOCK,UNLOCK_ALL_REG)) {
        reg_lock_status_g = MT9V034_REG_UNLOCK;
        return CONFIG_SUCCESS;
    }
    return CONFIG_FAILURE;
}
/****************************************************************************************
 *
 ***************************************************************************************/
unsigned char image_sensor_get_reg_lock_status(void) {
    return (reg_lock_status_g);
}
/****************************************************************************************
 *
 ***************************************************************************************/
int image_sensor_init(struct r_i2c *i2c_l,unsigned short config_param[E_SIZE_OF_CONFIG_ARRAY],unsigned opt_mode) {

    unsigned short img_snsr_init_val = 0;
    i2c_interface_g = i2c_l;
    i2c_master_init(i2c_interface_g);

    if(CONFIG_SUCCESS != image_sensor_read_chip_version()) {
      return CONFIG_ERR_NO_DEVICE;
    }

    if( (opt_mode < CONFIG_IN_SLAVE) && (opt_mode > CONFIG_IN_SNAPSHOT) ) {
       return CONFIG_ERR_INVALID_PARAMATER;
    }

    // reset all register value to its default state
    img_snsr_init_val = SOFT_RESET_ENABLE | AUTO_BLOCK_SOFT_RESET_ENABLE;

    if(CONFIG_SUCCESS == image_sensor_i2c_write(REG_RESET,img_snsr_init_val)) {

        // enable auto gain control and disable auto exposure control
        image_sensor_i2c_write(REG_AGC_AEC_ENABLE_A_B,(AEC_CONTEXT_A_DISABLE | AGC_CONTEXT_A_ENABLE));

        // configure tiled digital gain
        for(mt9v034_i2c_reg_addr_t reg_idx = REG_TILE_DIGITAL_GAIN_X0_Y0; reg_idx <= REG_TILE_DIGITAL_GAIN_X4_Y4; reg_idx++){
            image_sensor_i2c_write(reg_idx,(TILE_GAIN_CONTEXT_A(config_param[E_TILED_DIG_GAIN]) | GAIN_SAMPLE_WEIGHT(15)));

        }

        // configure vertical blank value as 4, in case of slave mode
        if(opt_mode == CONFIG_IN_SLAVE) {
            img_snsr_init_val = 4;
        }else {
            img_snsr_init_val = config_param[E_VERTI_BLANK];
        }

        // configure vertical blank
        image_sensor_i2c_write(REG_VERTICAL_BLANK_CONTEXT_A,VERTICAL_BLANK(img_snsr_init_val));
        // configure window height
        image_sensor_i2c_write(REG_WINDOW_HEIGHT_CONTEXT_A,WINDOW_HEIGHT(config_param[E_WIN_HEIGHT]));

        // configure window width
        image_sensor_i2c_write(REG_WINDOW_WIDTH_CONTEXT_A,WINDOW_WIDTH(config_param[E_WIN_WIDTH]));
        // configure horzontal blank
        image_sensor_i2c_write(REG_HORIZONTAL_BLANK_CONTEXT_A,HORIZONTAL_BLANK(config_param[E_HORIZ_BLANK]));

        // configure column start
        image_sensor_i2c_write(REG_COLUMN_START_CONTEXT_A,COLUMN_START(config_param[E_COLUMN_START]));

        // configure row start
        image_sensor_i2c_write(REG_ROW_START_CONTEXT_A,ROW_START(config_param[E_ROW_START]));

        /* Configure the default chip control values */
        img_snsr_init_val = PROGRESSIVE_SCAN_MODE | STEREOSCOPY_MODE_DISABLE | STEREOSCOPIC_MASTER_MODE | \
                            PARALLEL_OUT_ENABLE | PIX_READ_SIMULTANEOUS_MODE | DEFECTIVE_PIXEL_CORRECTION_ENABLE;

        if(opt_mode == CONFIG_IN_MASTER)
            img_snsr_init_val |= MASTER_MODE;
        else if(opt_mode == CONFIG_IN_SNAPSHOT)
            img_snsr_init_val |= SNAPSHOT_MODE;
        else
            img_snsr_init_val |= SLAVE_MODE;

        return(image_sensor_i2c_write(REG_CHIP_CONTROL,img_snsr_init_val));
    }

    return CONFIG_FAILURE;
}
/****************************************************************************************
 *
 ***************************************************************************************/
int image_sensor_config(void) {

    return CONFIG_FAILURE;
}
