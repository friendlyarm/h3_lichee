#include <linux/module.h>
#include <linux/gpio.h>
#include <linux/delay.h>
#include <linux/kernel.h>
#include <linux/moduleparam.h>
#include <linux/init.h>
#include <linux/hrtimer.h>
#include <linux/ktime.h>
#include <linux/device.h>
#include <linux/kdev_t.h>
#include <linux/interrupt.h> 
#include <linux/sched.h>
#include <linux/platform_device.h>
#include <media/gpio-ir-recv.h>

#include <asm/mach/irq.h>
#include <mach/platform.h>

static int gpio = -1;
void gpio_ir_receiver_dev_release(struct device *dev)
{
}

static struct gpio_ir_recv_platform_data gpio_ir_rc_data = {
       .gpio_nr        = -1,
       .active_low     = 1,
};

static struct platform_device gpio_ir_receiver_dev = {
       .name   = "gpio-rc-recv",
       .id             = -1,
       .dev    = {
               .platform_data = &gpio_ir_rc_data,
               .release 	  = gpio_ir_receiver_dev_release,
       },
};

static int gpio_ir_receiver_init(void)
{		
	int ret = 0;
    // printk(KERN_INFO "matrix-ir_receiver init.\n");
	
	gpio_ir_rc_data.gpio_nr = gpio;
	printk("plat: add device matrix-ir_receiver, pin=%d\n", gpio_ir_rc_data.gpio_nr);
	if ((ret = platform_device_register(&gpio_ir_receiver_dev))) {
		return ret;
	}

	return ret;
}

static void gpio_ir_receiver_exit(void)
{
    // printk(KERN_INFO "matrix-ir_receiver exit.\n");
    platform_device_unregister(&gpio_ir_receiver_dev);
}

module_init(gpio_ir_receiver_init);
module_exit(gpio_ir_receiver_exit);

MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("FriendlyARM");
MODULE_DESCRIPTION("Driver for Matrix IR Receiver");
module_param(gpio, int, 0644);
