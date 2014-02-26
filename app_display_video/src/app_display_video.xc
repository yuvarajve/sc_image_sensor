
#include <platform.h>

#include "i2c.h"
#include "lcd.h"
#include "sdram.h"
#include "display_controller.h"
#include "image_sensor.h"


// Port declaration
on tile[1]: image_sensor_ports imgports = { //circle slot
   XS1_PORT_1J, XS1_PORT_1K, XS1_PORT_1L, XS1_PORT_16B,
   XS1_PORT_1E, {XS1_PORT_1H, XS1_PORT_1I, 1000}, XS1_CLKBLK_1
};
on tile[0] : lcd_ports lcdports = { //triangle slot
  XS1_PORT_1I, XS1_PORT_1L, XS1_PORT_16B, XS1_PORT_1J, XS1_PORT_1K, XS1_CLKBLK_1 };
on tile[0] : sdram_ports sdramports = { //star slot
  XS1_PORT_16A, XS1_PORT_1B, XS1_PORT_1G, XS1_PORT_1C, XS1_PORT_1F, XS1_CLKBLK_2 };

