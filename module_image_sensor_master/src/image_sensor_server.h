/*
 * image_sensor_server.h
 *
 *  Created on: 02-Jul-2014
 *      Author: yuvaraj
 */

#ifndef IMAGE_SENSOR_SERVER_H_
#define IMAGE_SENSOR_SERVER_H_

#include "pipeline_interface.h"
#include "image_sensor_config.h"

/***************************************************************************//**
 * @brief
 *   Image Sensor Slave Mode Server.
 *
 * @param[in] imgports
 *   Pointer having image sensor hardware port mapping details.
 *
 * @return
 *  None.
 *
 ******************************************************************************/
void image_sensor_server(interface mgmt_interface server sensorif, interface pipeline_interface server apm_us);

#endif /* IMAGE_SENSOR_SERVER_H_ */
