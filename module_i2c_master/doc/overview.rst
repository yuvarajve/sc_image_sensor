Overview
========

I2C is the Philips 2 wire interface, used to configure many digital chips, typically offered with the following options

   * Whether the unit is a *master* or a *slave*. 
   * The speed supported. Normal speeds are 100 kbps and 400 kbps. 
   * Whether there is a single master or multiple masters.
   * Whether clock stretching is supported.


Features
--------

This module supports:

   * multi-master
   * 100 or 400 kbps with 
   * clock stretching 
   * multiple I2C buses. 

The interface comprises four functions, init, rx, reg_read, and reg_write that are called when required. This is a function library for integration with application code, no separate logical core is required.

