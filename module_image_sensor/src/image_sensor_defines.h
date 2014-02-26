
#ifndef IMAGE_SENSOR_DEFINES_H_
#define IMAGE_SENSOR_DEFINES_H_

enum mode{MASTER, SNAPSHOT, SLAVE};


// Sensor registers
#define DEV_ADDR 0x48   // Seven most significant bits of 0x90 and 0x91
#define RESET_REG 0x0C
#define CHIP_CNTL_REG 0x07
#define WIN_HEIGHT_REG 0x03
#define WIN_WIDTH_REG 0x04
#define HOR_BLANK_REG 0x05


#endif /* IMAGE_SENSOR_DEFINES_H_ */
