// Copyright (c) 2014, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <stdio.h>
#include "mt9v034_regs.h"
#include "mt9v034.h"
#include "image_sensor_config.h"

struct r_i2c *i2c_interface_g;

static inline int image_sensor_i2c_write(mt9v034_i2c_reg_addr_t reg_addr,unsigned short *wr_data)
{
    unsigned char data[2] = {0,0};
    data[0] = (unsigned char )((wr_data[0] & 0xFF00) >> 8);
    data[1] = (unsigned char )(wr_data[0] & 0x00FF);

    if( CONFIG_SUCCESS == i2c_master_write_reg(MT9V034_I2C_ADDR,reg_addr,data,sizeof(unsigned short),i2c_interface_g) )
      return CONFIG_SUCCESS;

    return CONFIG_FAILURE;
}

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

static inline int image_sensor_read_chip_version(void)
{
    unsigned short rd_data[1] = {0};
    if(CONFIG_SUCCESS == image_sensor_i2c_read(REG_CHIP_VERSION,rd_data)) {

        if(MT9V034_CHIP_VERSION == rd_data[0]) {
          printf("INFO: Image Sensor Chip Version: 0x%x\n",rd_data[0]);
          return CONFIG_SUCCESS;
        }
        else {
            printf("ERROR: Image Sensor Chip Version: 0x%x\n",rd_data[0]);
            return CONFIG_ERR_NO_DEVICE;
        }

    }
    else
        printf("ERROR: Image Sensor I2C Read Failed\n");

    return CONFIG_FAILURE;
}

int image_sensor_init(struct r_i2c *i2c_l,unsigned opt_mode) {

    unsigned short img_snsr_chip_ctrl = 0;
    i2c_interface_g = i2c_l;
    i2c_master_init(i2c_interface_g);
    if(MT9V034_CHIP_VERSION != image_sensor_read_chip_version()) {
      return CONFIG_ERR_NO_DEVICE;
    }

    if( (opt_mode < CONFIG_IN_SLAVE) && (opt_mode > CONFIG_IN_SNAPSHOT) ) {
       return CONFIG_ERR_INVALID_PARAMATER;
    }

    /* Configure the default chip control values */
    img_snsr_chip_ctrl = PROGRESSIVE_SCAN_MODE | STEREOSCOPY_MODE_DISABLE | STEREOSCOPIC_MASTER_MODE | \
                         PARALLEL_OUT_ENABLE | PIX_READ_SIMULTANEOUS_MODE | DEFECTIVE_PIXEL_CORRECTION_ENABLE;

    if(opt_mode == CONFIG_IN_MASTER)
        img_snsr_chip_ctrl |= MASTER_MODE;
    else if(opt_mode == SNAPSHOT_MODE)
        img_snsr_chip_ctrl |= SNAPSHOT_MODE;
    else
        img_snsr_chip_ctrl |= SLAVE_MODE;

    return CONFIG_SUCCESS;
}
