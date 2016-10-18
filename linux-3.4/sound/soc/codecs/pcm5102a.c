/*
 * Driver for the PCM5102A codec
 *
 * Author:  Florian Meier <florian.meier@koalo.de>
 *      Copyright 2013
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 */

#include <linux/init.h>
#include <linux/module.h>
#include <linux/platform_device.h>

#include <sound/soc.h>

static struct snd_soc_dai_driver pcm5102a_dai = {
    .name = "pcm5102a-hifi",
    .playback = {
        .channels_min = 2,
        .channels_max = 2,
        .rates = SNDRV_PCM_RATE_8000_192000,
        .formats = SNDRV_PCM_FMTBIT_S16_LE |
               SNDRV_PCM_FMTBIT_S24_LE |
               SNDRV_PCM_FMTBIT_S32_LE
    },
};

static struct snd_soc_codec_driver soc_codec_dev_pcm5102a;

static int pcm5102a_probe(struct platform_device *pdev)
{
    printk("%s\n", __func__);
    return snd_soc_register_codec(&pdev->dev, &soc_codec_dev_pcm5102a,
            &pcm5102a_dai, 1);
}

static int pcm5102a_remove(struct platform_device *pdev)
{
    snd_soc_unregister_codec(&pdev->dev);
    return 0;
}

static const struct of_device_id pcm5102a_of_match[] = {
    { .compatible = "sunxi,pcm5102a", },
    { }
};
MODULE_DEVICE_TABLE(of, pcm5102a_of_match);

static struct platform_driver pcm5102a_codec_driver = {
    .probe      = pcm5102a_probe,
    .remove     = pcm5102a_remove,
    .driver     = {
        .name   = "pcm5102a-codec",
        .of_match_table = pcm5102a_of_match,
    },
};

static struct platform_device pcm5102a_codec_device = {
	.name 	= "pcm5102a-codec",
	.id 	= PLATFORM_DEVID_NONE,
};

static int __init pcm5102a_init(void)
{
	int err = 0;

		if((err = platform_device_register(&pcm5102a_codec_device)) < 0)
			return err;

		if ((err = platform_driver_register(&pcm5102a_codec_driver)) < 0)
			return err;

	return 0;
}
module_init(pcm5102a_init);

static void __exit pcm5102a_exit(void)
{
	platform_driver_unregister(&pcm5102a_codec_driver);
	platform_device_unregister(&pcm5102a_codec_device);
}
module_exit(pcm5102a_exit);

MODULE_DESCRIPTION("ASoC PCM5102A codec driver");
MODULE_AUTHOR("Florian Meier <florian.meier@koalo.de>");
MODULE_LICENSE("GPL v2");
