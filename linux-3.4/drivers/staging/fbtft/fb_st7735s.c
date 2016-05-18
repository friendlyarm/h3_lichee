/*
 * FB driver for the st7789s LCD display controller
 *
 * This display uses 9-bit SPI: Data/Command bit + 8 data bits
 * For platforms that doesn't support 9-bit, the driver is capable
 * of emulating this using 8-bit transfer.
 * This is done by transferring eight 9-bit words in 9 bytes.
 *
 * Copyright (C) 2013 Christian Vogelgsang
 * Based on adafruit22fb.c by Noralf Tronnes
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/delay.h>

#include "fbtft.h"

#define DRVNAME		"fb_st7735s"
#define WIDTH		80
#define HEIGHT		160
//#define TXBUFLEN	(4 * PAGE_SIZE)
#define DEFAULT_GAMMA	"04 22 07 0A 2E 30 25 2A 28 26 2E 3A 00 01 03 13\n" \
			"04 16 06 0D 2D 26 23 27 27 25 2D 3B 00 01 04 13"
#define BPP			16
#define FPS			60		

static int init_display(struct fbtft_par *par)
{	
	// printk("%s()\n", __func__);

	par->fbtftops.reset(par);

	/* startup sequence for MI0283QT-9A */
	write_reg(par, 0X01); /* software reset */
	mdelay(120);

	write_reg(par, 0X2a, 0x00, 0x18, 0x00, 0x67);  
	write_reg(par, 0x2b, 0x00, 0x00, 0x00, 0x9f);
	
	write_reg(par, 0XB1, 0X05, 0X3C, 0X3C);	 // frame rate
	write_reg(par, 0xB2, 0X05, 0X3C, 0X3C);
	write_reg(par, 0xB3, 0X05, 0X3C, 0X3C, 0X05, 0X3C, 0X3C);

	write_reg(par, 0xB4, 0X03);				// not inversion
	
	write_reg(par, 0xC0, 0X28, 0X08, 0X04);
	write_reg(par, 0xC1, 0XC0);
	write_reg(par, 0xC2, 0X0D, 0X00);
	write_reg(par, 0xC3, 0X8D, 0X2A);
	write_reg(par, 0xC4, 0X8D, 0XEE);

	write_reg(par, 0xC5, 0X13, 0X36, 0X20);	// VCOM: MX, MY, RGB mode

	write_reg(par, 0x3a, 0X05);				//65k mode

	write_reg(par, 0X011); 					/* sleep out */
	mdelay(100);
	write_reg(par, 0x29);					// display on
	mdelay(20);
	
	return 0;
}

static void set_addr_win(struct fbtft_par *par, int xs, int ys, int xe, int ye)
{
	// printk("%s(xs=%d, ys=%d, xe=%d, ye=%d)\n", __func__, xs, ys, xe, ye);

	switch (par->info->var.rotate) {
	case 0:
		xs += 24;
		xe += 24;
		break;
	case 90:
		ys += 24;
		ye += 24;
		break;
	case 180:
		xs += 24;
		xe += 24;		
		break;
	case 270:	
		ys += 24;
		ye += 24;
		break;
	}
	
	/* Column address set */
	write_reg(par, 0x2A,
		(xs >> 8) & 0xFF, xs & 0xFF, (xe >> 8) & 0xFF, xe & 0xFF);

	/* Row address set */
	write_reg(par, 0x2B,
		(ys >> 8) & 0xFF, ys & 0xFF, (ye >> 8) & 0xFF, ye & 0xFF);

//	write_reg(par, 0X2a, 0x00, 0x18, 0x00, 0x67);  
//	write_reg(par, 0x2b, 0x00, 0x00, 0x00, 0x9f);

	/* Memory write */
	write_reg(par, 0x2C);
}

#define MY (1 << 7)
#define MX (1 << 6)
#define MV (1 << 5)
static int set_var(struct fbtft_par *par)
{
	// printk("%s() rotate=%d\n", __func__, par->info->var.rotate);

	/* MADCTL - Memory data access control
	     RGB/BGR:
	     1. Mode selection pin SRGB
	        RGB H/W pin for color filter setting: 0=RGB, 1=BGR
	     2. MADCTL RGB bit
	        RGB-BGR ORDER color filter panel: 0=RGB, 1=BGR */
	switch (par->info->var.rotate) {
	case 0:
		write_reg(par, 0x36, par->bgr << 3);
		break;
	case 90:
		write_reg(par, 0x36, MX | MV | (par->bgr << 3));
		break;
	case 180:
		write_reg(par, 0x36, MX | MY | (par->bgr << 3));
		break;
	case 270:
		write_reg(par, 0x36, MY | MV | (par->bgr << 3));
		break;
	}
	return 0;
}

/*
  Gamma string format:
    VRF0P VOS0P PK0P PK1P PK2P PK3P PK4P PK5P PK6P PK7P PK8P PK9P SELV0P SELV1P SELV62P SELV63P
    VRF0N VOS0N PK0N PK1N PK2N PK3N PK4N PK5N PK6N PK7N PK8N PK9N SELV0N SELV1N SELV62N SELV63N
*/
#define CURVE(num, idx)  curves[num*par->gamma.num_values + idx]
static int set_gamma(struct fbtft_par *par, unsigned long *curves)
{
	int i, j;

	// printk("%s()\n", __func__);

	/* apply mask */
	for (i = 0; i < par->gamma.num_curves; i++)
		for (j = 0; j < par->gamma.num_values; j++)
			CURVE(i, j) &= 0x3f;

	for (i = 0; i < par->gamma.num_curves; i++)
		write_reg(par, 0xE0 + i,
			CURVE(i, 0), CURVE(i, 1), CURVE(i, 2), CURVE(i, 3),
			CURVE(i, 4), CURVE(i, 5), CURVE(i, 6), CURVE(i, 7),
			CURVE(i, 8), CURVE(i, 9), CURVE(i, 10), CURVE(i, 11),
			CURVE(i, 12), CURVE(i, 13), CURVE(i, 14), CURVE(i, 15));

	return 0;
}
#undef CURVE

static struct fbtft_display display = {
	.regwidth = 8,
	.width = WIDTH,
	.height = HEIGHT,
	.gamma_num = 2,
	.gamma_len = 16,
	.gamma = DEFAULT_GAMMA,
	.bpp = BPP,
	.fps = FPS,
	.fbtftops = {
		.init_display = init_display,
		.set_addr_win = set_addr_win,
		.set_var = set_var,
		.set_gamma = set_gamma,
	},
};
FBTFT_REGISTER_DRIVER(DRVNAME, "fa,st7735s", &display);

MODULE_ALIAS("spi:" DRVNAME);
MODULE_ALIAS("platform:" DRVNAME);
MODULE_ALIAS("spi:st7735s");
MODULE_ALIAS("platform:st7735s");

MODULE_DESCRIPTION("FB driver for the st7789s LCD display controller");
MODULE_AUTHOR("friendlyarm");
MODULE_LICENSE("GPL");
