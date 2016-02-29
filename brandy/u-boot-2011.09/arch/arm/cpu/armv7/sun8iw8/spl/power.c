/*
 * (C) Copyright 2007-2013
 * Allwinner Technology Co., Ltd. <www.allwinnertech.com>
 * Ming <liaoyongming@allwinnertech.com>
 *
 * See file CREDITS for list of people who contributed to this
 * project.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 * MA 02111-1307 USA
 */

#include "common.h"
#include <power/axp20_reg.h>
#include <i2c.h>

#define AXP_TWI_ID			(0)

static int axp20_set_dcdc2(int set_vol, int onoff)
{
    u32 vol, tmp;
	volatile u32 i;
	u8  reg_addr, value;
	if(set_vol == -1)
	{
		set_vol = 1400;
	}

	//PMU is AXP209
	reg_addr = BOOT_POWER20_DC2OUT_VOL;
	if(i2c_read(AXP_TWI_ID, AXP20_ADDR, reg_addr, 1, &value, 1))
	{
		return -1;
	}
	tmp     = value & 0x3f;
	vol     = tmp * 25 + 700;
	//如果电压过高，则调低
	while(vol > set_vol)
	{
		tmp -= 1;
		value &= ~0x3f;
		value |= tmp;
		reg_addr = BOOT_POWER20_DC2OUT_VOL;
		if(i2c_write(AXP_TWI_ID, AXP20_ADDR, reg_addr, 1, &value, 1))
		{
			return -1;
		}
		for(i=0;i<2000;i++);
		reg_addr = BOOT_POWER20_DC2OUT_VOL;
		if(i2c_read(AXP_TWI_ID, AXP20_ADDR, reg_addr, 1, &value, 1))
		{
			return -1;
		}
		tmp     = value & 0x3f;
		vol     = tmp * 25 + 700;
    }
	//如果电压过低，则调高，根据先调低再调高的过程，保证电压会大于等于用户设定电压+
	while(vol < set_vol)
	{
		tmp += 1;
		value &= ~0x3f;
		value |= tmp;
		reg_addr = BOOT_POWER20_DC2OUT_VOL;
		if(i2c_write(AXP_TWI_ID, AXP20_ADDR, reg_addr, 1, &value, 1))
		{
			return -1;
		}
		for(i=0;i<2000;i++);
		reg_addr = BOOT_POWER20_DC2OUT_VOL;
		if(i2c_read(AXP_TWI_ID, AXP20_ADDR, reg_addr, 1, &value, 1))
		{
			return -1;
		}
		tmp     = value & 0x3f;
		vol     = tmp * 25 + 700;
	}
	printf("after set, dcdc2 =%dmv\n",vol);

	return 0;
}

int pmu_set_vol(int set_vol, int onoff)
{
	u8 pmu_type = 0;
	i2c_init(0, CONFIG_SYS_I2C_SPEED, CONFIG_SYS_I2C_SLAVE);
	if(i2c_read(AXP_TWI_ID, AXP20_ADDR, BOOT_POWER20_VERSION, 1, &pmu_type, 1))
	{
		printf("axp read fail, maybe no pmu \n");
		return -1;
	}
	pmu_type &= 0x0f;
	if(pmu_type & 0x01)
	{
		printf("PMU: axp version ok \n");
	}
	else
	{
		printf("try pmu axp fail, maybe no pmu \n");
		return -1;
	}
	//set sys vol +
	if(axp20_set_dcdc2(set_vol, onoff))
	{
			printf("axp20 set dcdc2 vol fail, maybe no pmu \n");
			return -1;
	}
	printf("axp20 set dcdc2 success \n");

    return 0;
}
