/*
**********************************************************************************************************************
*
*						           the Embedded Secure Bootloader System
*
*
*						       Copyright(C), 2006-2014, Allwinnertech Co., Ltd.
*                                           All Rights Reserved
*
* File    :
*
* By      :
*
* Version : V2.00
*
* Date	  :
*
* Descript:
**********************************************************************************************************************
*/
#include "common.h"
#include "asm/io.h"
#include <asm/arch/efuse.h>
#include <asm/arch/efuse_map.h>
#include <malloc.h>

//*****************************************************************************
//	u32 sid_read_key(u32 key_index)
//  Description:
//				Read key from Efuse by software
//	Arguments:	None
//
//
//	Return Value:	Key value
//*****************************************************************************
u32 sid_set_burned_flag(int bit_offset)
{
    u32 reg_val;

    reg_val  = sid_read_key(EFUSE_CHIP_CONFIG);
    reg_val |= (0x1<<bit_offset);		//使能securebit
    sid_program_key(EFUSE_CHIP_CONFIG, reg_val);
    reg_val = (sid_read_key(EFUSE_CHIP_CONFIG) >> bit_offset) & 1;

    return reg_val;
}



/*
************************************************************************************************************
*
*                                             function
*
*    name          :
*
*    parmeters     :
*
*    return        :
*
*    note          :
*
*
************************************************************************************************************
*/
int sunxi_efuse_write(void *key_buf)
{
	sunxi_efuse_key_info_t  *key_list = NULL;
	unsigned char *key_data;
	int i,j;
	unsigned int key_start_addr;			// 每一笔数据的开始地址
	unsigned int key_once_data = 0;
	unsigned char *p_key_once_data;				// 一笔数据以字为单位
	unsigned int key_data_remain_size; 				//剩下字节数

	char *verify_buf;
	unsigned int *p_verify_buf;

	int burned_status;

	efuse_key_map_t *key_map = key_imformatiom;

	if (key_buf == NULL)
	{
		printf("[efuse] error: buf is null\n");
		return -1;
	}
	key_list = (sunxi_efuse_key_info_t  *)key_buf;
	key_data = key_list->key_data;
	//map_ns_memory((pa_t)key_buf, (va_t *)(&key_list), sizeof(sunxi_efuse_key_info_t));
	//map_ns_memory((pa_t)key_list->key_data, (va_t *)(&key_data), key_list->len);
#ifdef EFUSE_DEBUG
		printf("^^^^^^^printf key_buf^^^^^^^^^^^^\n");
		printf("key name=%s\n", key_list->name);
		printf("key len=%d\n", key_list->len);
		printf("key data:\n");
		sunxi_dump(key_data, key_list->len);
		printf("###################\n");
#endif
	// 查字典，被允许的key才能烧写
	for (; key_map != NULL; key_map++)
	{
		if (!memcmp(key_list->name, key_map->name, strlen(key_map->name)))
		{
			printf(" burn key start\n");
			printf("burn key start\n");
			printf("key name = %s\n", key_map->name);
			printf("key index = 0x%x\n", key_map->key_index);

			//	判断是否足够空间来存放key
			if ((key_map->store_max_bit / 8) < key_list->len)
			{
				printf("[efuse] error: not enough space to store the key, efuse size(%d), data size(%d)\n", key_map->store_max_bit/8, key_list->len);

				return -1;
			}
			// 判断存放key的区域是否已经烧录
			printf("===== key_map->burned_bit_offset ====%d \n",key_map->burned_bit_offset);
			burned_status = (sid_read_key(EFUSE_CHIP_CONFIG) >> key_map->burned_bit_offset) & 1;
			if(burned_status)
			{
				printf("key %s has been burned already\n", key_map->name);

				return -1;
			}

			break;
		}
	}

	if (key_map == NULL)
	{
		printf("[efuse] error: can't burn the key (unknow)\n");

		return -1;
	}

	//烧写key
	key_start_addr = key_map->key_index;
	key_data_remain_size = key_list->len;
	//flush_cache((uint)pbuf, byte_cnt);
	for(i=0;key_data_remain_size >= 4; key_data_remain_size-=4, i+=4, key_start_addr += 4)
	{
		key_once_data = *(unsigned int *)(key_list->key_data + i);

		sid_program_key(key_start_addr, key_once_data);

		printf("[efuse] addr = 0x%x, data = 0x%x\n", key_start_addr, key_once_data);
	}
	key_once_data = 0;
	if(key_data_remain_size)
	{
		j=0;
		p_key_once_data = (unsigned char *)&key_once_data;
		while(key_data_remain_size--)
		{
			p_key_once_data[j++] = key_list->key_data[i++];
		}
		sid_program_key(key_start_addr, key_once_data);

		printf("[efuse] addr = 0x%x, data = 0x%x\n", key_start_addr, key_once_data);
	}
	//读出烧录的key信息
	key_start_addr = key_map->key_index;
	key_data_remain_size = key_list->len;

	verify_buf = malloc((key_data_remain_size + 3) & (~3));
	if(verify_buf == NULL)
	{
		printf("cant malloc memory to store burned key\n");

		return -1;
	}
	memset(verify_buf,0,(key_data_remain_size + 3) & (~3));
	p_verify_buf = (unsigned int *)verify_buf;

	if(key_data_remain_size & 3)
		key_data_remain_size = (key_data_remain_size + 3) & (~3);
	for(;key_data_remain_size >= 4; key_data_remain_size-=4)
	{
		*p_verify_buf++ = sid_read_key(key_start_addr);
		key_start_addr += 4;
	}
	//比较
	if(memcmp(verify_buf, key_list->key_data, key_list->len))
	{
		printf("compare burned key with memory data failed\n");
		printf("memory data:\n");
		sunxi_dump(key_list->key_data, key_list->len);
		printf("burned key:\n");
		sunxi_dump(verify_buf, key_list->len);

		return -1;
	}
	//锁定
	sid_set_burned_flag(key_map->burned_bit_offset);

	printf(" burn key end\n");

	return 0;
}


/*
************************************************************************************************************
*
*                                             function
*
*    name          :
*
*    parmeters     :
*
*    return        :
*
*    note          :
*
*
************************************************************************************************************
*/
int sunxi_efuse_read(void *key_name, void *read_buf)
{
	efuse_key_map_t *key_map = key_imformatiom;
	unsigned int key_start_addr;								// 每一笔数据的开始地址
	int show_status;
	char *check_buf;
	unsigned int *p_check_buf;
	unsigned int key_data_remain_size; 				//剩下字节数
	//char *p_key_name;
	u32 dst_buf = 0;
	
	//p_key_name = (char *)key_name;

	//map_ns_memory((pa_t)key_name, (va_t *)(&p_key_name), sizeof(p_key_name));

	// 查字典，被允许的key才能被查看
	for (; key_map != NULL; key_map++)
	{
		if (!memcmp(key_name, key_map->name, strlen(key_map->name)))
		{
			printf("read key start\n");
			printf("key name = %s\n", key_map->name);
			printf("key index = 0x%x\n", key_map->key_index);

			//判断key有没有烧录过
			show_status = (sid_read_key(EFUSE_CHIP_CONFIG) >> key_map->burned_bit_offset) & 1;
			if(!show_status)
			{
				printf("key %s have not been burned yet\n", key_map->name);

				return -1;
			}
			// 判断存放key的区域是否允许被查看
			//如果没有此标志位，表示一定可以查看
			if(key_map->show_bit_offset < 0)
			{
				break;
			}
			//如果存在标志位，并且不允许查看，则不读出，并且返回报错
			show_status = (sid_read_key(EFUSE_CHIP_CONFIG) >> key_map->show_bit_offset) & 1;
			if(show_status)
			{
				printf("key %s don't show \n", key_map->name);

				return -1;
			}
			break;
		}
	}

	if (key_map == NULL)
	{
		printf("[efuse] error: can't read the key (unknow)\n");

		return -1;
	}

	//烧写key
	key_start_addr = key_map->key_index;
	key_data_remain_size = key_map->store_max_bit / 8;

	//map_ns_memory((pa_t)read_buf, (va_t *)&dst_buf, key_data_remain_size);

	check_buf = (char *)malloc((key_data_remain_size + 3) & (~3));
	if(check_buf == NULL)
	{
		printf("cant malloc memory to store burned key\n");

		return -1;
	}
	p_check_buf = (unsigned int *)check_buf;

	if(key_data_remain_size & 3)
		key_data_remain_size = (key_data_remain_size + 3) & (~3);
	for(;key_data_remain_size >= 4; key_data_remain_size-=4)
	{
		*p_check_buf++ = sid_read_key(key_start_addr);
		key_start_addr += 4;
	}
	sunxi_dump(check_buf, key_map->store_max_bit / 8);
	memcpy((void *)dst_buf, check_buf, key_map->store_max_bit / 8);

	//unmap_ns_memory((va_t)dst_buf, key_map->store_max_bit/8);

	return 0;
}

