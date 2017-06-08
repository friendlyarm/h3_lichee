#ifdef CUSTOMER_HW
#include <osl.h>
#include <dngl_stats.h>
#include <dhd.h>

#include "ap621x.h"

struct wifi_platform_data dhd_wlan_control = {0};

#ifdef CUSTOMER_OOB
uint bcm_wlan_get_oob_irq(void)
{
	uint host_oob_irq = 0;

#ifdef GPIO_WLAN_HOST_WAKE
	printf("GPIO(GPIO_WLAN_HOST_WAKE) = %d\n", brcm_gpio_host_wake());
	host_oob_irq = gpio_to_irq(brcm_gpio_host_wake());
	gpio_direction_input(brcm_gpio_host_wake());
#elif defined(CONFIG_ARCH_CPU_SLSI) || defined(CONFIG_ARCH_SUN8IW7)
	host_oob_irq = get_host_wake_irq();
#endif

	printf("host_oob_irq: %d\n", host_oob_irq);
	return host_oob_irq;
}

uint bcm_wlan_get_oob_irq_flags(void)
{
	uint host_oob_irq_flags = 0;

#if defined(GPIO_WLAN_HOST_WAKE) || defined(CONFIG_ARCH_CPU_SLSI) || defined(CONFIG_ARCH_SUN8IW7)
#ifdef HW_OOB
	host_oob_irq_flags = IORESOURCE_IRQ | IORESOURCE_IRQ_HIGHLEVEL | IORESOURCE_IRQ_SHAREABLE;
#else
	host_oob_irq_flags = IORESOURCE_IRQ | IORESOURCE_IRQ_HIGHEDGE  | IORESOURCE_IRQ_SHAREABLE;
#endif
#endif
	printf("host_oob_irq_flags = %x\n", host_oob_irq_flags);

	return host_oob_irq_flags;
}
#endif

int bcm_wlan_set_power(bool on)
{
	int err = 0;

	if (on) {
		printf("======== PULL WL_REG_ON HIGH! ========\n");
#ifdef GPIO_WLAN_EN
		gpio_set_value(GPIO_WLAN_EN, 1);
#elif defined(CONFIG_ARCH_CPU_SLSI)
		wifi_pm_gpio_ctrl("bcmdhd", 1);
#elif defined(CONFIG_ARCH_SUN8IW7)
		wifi_pm_gpio_ctrl("wl_reg_on", 1);
#endif
		/* Lets customer power to get stable */
		msleep(50);
	} else {
		printf("======== PULL WL_REG_ON LOW! ========\n");
#ifdef GPIO_WLAN_EN
		gpio_set_value(GPIO_WLAN_EN, 0);
#elif defined(CONFIG_ARCH_CPU_SLSI)
		wifi_pm_gpio_ctrl("bcmdhd", 0);
#elif defined(CONFIG_ARCH_SUN8IW7)
		wifi_pm_gpio_ctrl("wl_reg_on", 0);
#endif
		msleep(50);
	}

	return err;
}

int bcm_wlan_set_carddetect(bool present)
{
	int err = 0;

#if 0
	if (present) {
		printf("======== Card detection to detect SDIO card! ========\n");
		err = sdhci_s3c_force_presence_change(&sdmmc_channel, 1);
	} else {
		printf("======== Card detection to remove SDIO card! ========\n");
		err = sdhci_s3c_force_presence_change(&sdmmc_channel, 0);
	}
#endif

#if defined(CONFIG_ARCH_CPU_SLSI) || defined(CONFIG_ARCH_SUN8IW7)
	force_presence_change(NULL, present);
#else
	mmc_force_presence_change_onoff(&sdmmc_channel, present);
#endif

	return err;
}

int bcm_wlan_get_mac_address(unsigned char *buf)
{
	int err = 0;

	printf("======== %s ========\n", __FUNCTION__);
#ifdef EXAMPLE_GET_MAC
	/* EXAMPLE code */
	{
		struct ether_addr ea_example = {{0x00, 0x11, 0x22, 0x33, 0x44, 0xFF}};
		bcopy((char *)&ea_example, buf, sizeof(struct ether_addr));
	}
#endif /* EXAMPLE_GET_MAC */

	return err;
}

#ifdef CONFIG_DHD_USE_STATIC_BUF
extern void *bcmdhd_mem_prealloc(int section, unsigned long size);
void* bcm_wlan_prealloc(int section, unsigned long size)
{
	void *alloc_ptr = NULL;
	alloc_ptr = bcmdhd_mem_prealloc(section, size);
	if (alloc_ptr) {
		printf("success alloc section %d, size %ld\n", section, size);
		if (size != 0L)
			bzero(alloc_ptr, size);
		return alloc_ptr;
	}
	printf("can't alloc section %d\n", section);
	return NULL;
}
#endif

int bcm_wlan_set_plat_data(void) {
	printf("======== %s ========\n", __FUNCTION__);
	dhd_wlan_control.set_power = bcm_wlan_set_power;
	dhd_wlan_control.set_carddetect = bcm_wlan_set_carddetect;
	dhd_wlan_control.get_mac_addr = bcm_wlan_get_mac_address;
#ifdef CONFIG_DHD_USE_STATIC_BUF
	dhd_wlan_control.mem_prealloc = bcm_wlan_prealloc;
#endif
	return 0;
}

#endif /* CUSTOMER_HW */
