
#ifndef IMAGE_SENSOR_DEFINES_H_
#define IMAGE_SENSOR_DEFINES_H_

enum mode{MASTER, SNAPSHOT, SLAVE};


// Sensor registers
#define DEV_ADDR 0x48   // Seven most significant bits of 0x90 and 0x91
#define CHIP_CNTL_REG 0x07
#define WIN_HEIGHT_REG 0x03
#define WIN_WIDTH_REG 0x04
#define HOR_BLANK_REG 0x05
#define ROW_START_REG 0x02
#define COL_START_REG 0x01

// Sensor resolution
#define MAX_HEIGHT 480
#define MAX_WIDTH 752



#endif /* IMAGE_SENSOR_DEFINES_H_ */
