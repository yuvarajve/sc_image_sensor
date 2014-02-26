#include <stdint.h>

#include "image_sensor.h"
#include "image_sensor_defines.h"

void image_sensor_setup_master_mode(image_sensor_interface client inf, unsigned height, unsigned width){
    inf.setup_sensor(MASTER, height, width);
}


void image_sensor_setup_snapshot_mode(image_sensor_interface client inf, unsigned height, unsigned width){
    inf.setup_sensor(SNAPSHOT, height, width);
}

void color_interpolation(chanend c_dc, unsigned frBuf, unsigned height, unsigned width){
    unsigned buf[3][width/2], rgb565[width/2];
    char r[width], g[width], b[width];

    // Read first two rows
    display_controller_image_read_line(c_dc, 0, frBuf, buf[0]);
    display_controller_wait_until_idle(c_dc, buf[0]);
    display_controller_image_read_line(c_dc, 1, frBuf, buf[1]);
    display_controller_wait_until_idle(c_dc, buf[1]);

    // Store first row with 0s
    for (unsigned j=0; j<width/2; j++)
        rgb565[j]=0;
    display_controller_image_write_line(c_dc, 0, frBuf, rgb565);
    display_controller_wait_until_idle(c_dc, rgb565);

    // Find missing color components
    for (unsigned i=2; i<height-1; i++){
        unsigned row = i-1;

        display_controller_image_read_line(c_dc, i, frBuf, buf[i%3]);
        display_controller_wait_until_idle(c_dc, buf[i%3]);

        if (row&1){
            for (unsigned j=2; j<width-1; j+=2){    // odd row, even col, green pix
                g[j] = ((buf[row%3],short[])[j])>>2 & 0xff;
                unsigned b_top = ((buf[(row-1)%3],short[])[j])>>2 & 0xff;
                unsigned b_bot = ((buf[(row+1)%3],short[])[j])>>2 & 0xff;
                b[j] = (b_top+b_bot)/2;
                unsigned r_left = ((buf[row%3],short[])[j-1])>>2 & 0xff;
                unsigned r_right = ((buf[row%3],short[])[j+1])>>2 & 0xff;
                r[j] = (r_left+r_right)/2;
            }
            for (unsigned j=1; j<width-1; j+=2){    // odd row, odd col, red pix
                r[j] = ((buf[row%3],short[])[j])>>2 & 0xff;
                unsigned b_diag1 = ((buf[(row-1)%3],short[])[j-1])>>2 & 0xff;
                unsigned b_diag2 = ((buf[(row-1)%3],short[])[j+1])>>2 & 0xff;
                unsigned b_diag3 = ((buf[(row+1)%3],short[])[j-1])>>2 & 0xff;
                unsigned b_diag4 = ((buf[(row+1)%3],short[])[j+1])>>2 & 0xff;
                b[j] = (b_diag1+b_diag2+b_diag3+b_diag4)/4;
                unsigned g_adj1 = ((buf[(row-1)%3],short[])[j])>>2 & 0xff;
                unsigned g_adj2 = ((buf[(row-1)%3],short[])[j])>>2 & 0xff;
                unsigned g_adj3 = ((buf[row%3],short[])[j-1])>>2 & 0xff;
                unsigned g_adj4 = ((buf[row%3],short[])[j+1])>>2 & 0xff;
                g[j] = (g_adj1+g_adj2+g_adj3+g_adj4)/4;
            }
        }
        else {
            for (unsigned j=2; j<width-1; j+=2){    // even row, even col, blue pix
                b[j] = ((buf[row%3],short[])[j])>>2 & 0xff;
                unsigned r_diag1 = ((buf[(row-1)%3],short[])[j-1])>>2 & 0xff;
                unsigned r_diag2 = ((buf[(row-1)%3],short[])[j+1])>>2 & 0xff;
                unsigned r_diag3 = ((buf[(row+1)%3],short[])[j-1])>>2 & 0xff;
                unsigned r_diag4 = ((buf[(row+1)%3],short[])[j+1])>>2 & 0xff;
                r[j] = (r_diag1+r_diag2+r_diag3+r_diag4)/4;
                unsigned g_adj1 = ((buf[(row-1)%3],short[])[j])>>2 & 0xff;
                unsigned g_adj2 = ((buf[(row-1)%3],short[])[j])>>2 & 0xff;
                unsigned g_adj3 = ((buf[row%3],short[])[j-1])>>2 & 0xff;
                unsigned g_adj4 = ((buf[row%3],short[])[j+1])>>2 & 0xff;
                g[j] = (g_adj1+g_adj2+g_adj3+g_adj4)/4;
            }
            for (unsigned j=1; j<width-1; j+=2){    // even row, odd col, green pix
                g[j] = ((buf[row%3],short[])[j])>>2 & 0xff;
                unsigned b_left = ((buf[(row-1)%3],short[])[j])>>2 & 0xff;
                unsigned b_right = ((buf[(row+1)%3],short[])[j])>>2 & 0xff;
                b[j] = (b_left+b_right)/2;
                unsigned r_top = ((buf[row%3],short[])[j-1])>>2 & 0xff;
                unsigned r_bot = ((buf[row%3],short[])[j+1])>>2 & 0xff;
                r[j] = (r_top+r_bot)/2;
            }
        }

        // RGB565 conversion and write row
        for (unsigned j=1; j<width-1; j++)
            (rgb565,unsigned short[])[j] = rgb888_to_rgb565(b[j], g[j], r[j]);

        (rgb565,unsigned short[])[0] = 0;
        (rgb565,unsigned short[])[width-1] = 0;

        display_controller_image_write_line(c_dc, row, frBuf, rgb565);
        display_controller_wait_until_idle(c_dc, rgb565);
    }

    // Store last row with 0s
    for (unsigned j=0; j<width/2; j++)
        rgb565[j]=0;
    display_controller_image_write_line(c_dc, height-1, frBuf, rgb565);
    display_controller_wait_until_idle(c_dc, rgb565);

}


#pragma unsafe arrays
void image_sensor_master_mode_rx_frame(image_sensor_interface client inf, streaming chanend c_imgSensor, unsigned height, unsigned width, chanend c_dispCont, unsigned frBuf){
    unsigned data1[LCD_ROW_WORDS], data2[LCD_ROW_WORDS];
    unsigned * unsafe tempPtr, * unsafe readBufPtr, * unsafe storeBufPtr;

    inf.get_frame(MASTER, height, width);

    // Get frame & store
    unsafe {
        readBufPtr = data1; storeBufPtr = data2;    // pointers to manage double buffer
        get_row (c_imgSensor,readBufPtr);

        for (unsigned r=1; r<height; r++){
            //swap data buffers for reading and storing
            tempPtr = readBufPtr;
            readBufPtr = storeBufPtr;
            storeBufPtr = tempPtr;

            par {
                get_row (c_imgSensor,readBufPtr);
                store_row(c_dispCont,r-1,frBuf,(intptr_t)storeBufPtr);
            }
        }

        store_row(c_dispCont,height-1,frBuf,(intptr_t)readBufPtr);
    }

    // Color interpolation
    color_interpolation(c_dispCont, frBuf, height, width);

}

#pragma unsafe arrays
void image_sensor_snapshot_mode_get_frame(image_sensor_interface client inf, streaming chanend c_imgSensor, unsigned height, unsigned width, chanend c_dispCont, unsigned frBuf){
    unsigned data1[LCD_ROW_WORDS], data2[LCD_ROW_WORDS];
    unsigned * unsafe tempPtr, * unsafe readBufPtr, * unsafe storeBufPtr;

    inf.get_frame(SNAPSHOT, height, width);

    // Get frame & store
    unsafe {
        readBufPtr = data1; storeBufPtr = data2;    // pointers to manage double buffer
        get_row (c_imgSensor,readBufPtr);

        for (unsigned r=1; r<height; r++){
            //swap data buffers for reading and storing
            tempPtr = readBufPtr;
            readBufPtr = storeBufPtr;
            storeBufPtr = tempPtr;

            par {
                get_row (c_imgSensor,readBufPtr);
                store_row(c_dispCont,r-1,frBuf,(intptr_t)storeBufPtr);
            }
        }

        store_row(c_dispCont,height-1,frBuf,(intptr_t)readBufPtr);
    }

    // Color interpolation
    color_interpolation(c_dispCont, frBuf, height, width);

}



