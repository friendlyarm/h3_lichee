/*
 *  Copyright (C) 2015 FriendlyARM (www.arm9.net)
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */

#ifndef __AP621X_H__
#define __AP621X_H__

#if defined(CONFIG_MACH_MINI2451)
#include <linux/gpio.h>

#include <plat/gpio-cfg.h>
#include <plat/sdhci.h>
#include <plat/devs.h>
#include <mach/regs-gpio.h>

#if LINUX_VERSION_CODE >= KERNEL_VERSION(4, 1, 0)
#include <mach/gpio-samsung.h>
#else
#include <mach/gpio.h>
#endif

#include <mach/board-wlan.h>

#define sdmmc_channel	s3c_device_hsmmc0
extern void mmc_force_presence_change_onoff(struct platform_device *pdev, int val);

static inline void ap621x_wifi_init(void)
{
	// wifi power
#ifdef GPIO_WLAN_EN
	if (gpio_request(GPIO_WLAN_EN, "GPIO_WLAN_EN")) {
		printk(KERN_ERR"failed to request GPIO_WLAN_EN\n");
	}
	gpio_direction_output(GPIO_WLAN_EN, 1);
#endif

	// wifi int
	if (gpio_request(brcm_gpio_host_wake(), "GPIO_WLAN_HOST_WAKE")) {
		printk(KERN_ERR"failed to request GPIO_WLAN_HOST_WAKE\n");
	}
}

#elif defined(CONFIG_ARCH_CPU_SLSI)
#include <linux/platform_device.h>

#define SRCBASE		"drivers/net/wireless/bcm4336"

extern int force_presence_change(struct platform_device *dev, int state);
extern int get_host_wake_irq(void);
extern int wifi_pm_gpio_ctrl(char *name, int level);

static inline void ap621x_wifi_init(void) {
	// nothing here yet
}

#elif defined(CONFIG_ARCH_SUN8IW7)
#include <linux/platform_device.h>

#define SRCBASE		"drivers/net/wireless/bcm4336"

extern int force_presence_change(struct platform_device *dev, int state);
extern int get_host_wake_irq(void);
extern int wifi_pm_gpio_ctrl(char *name, int level);

static inline void ap621x_wifi_init(void) {
	// nothing here yet
}

#else

/* Stubs */
#define mmc_force_presence_change_onoff(pdev, val)	\
	do { } while (0)

#endif /* CONFIG_MACH_MINI2451 */

#endif /* __AP621X_H__ */
