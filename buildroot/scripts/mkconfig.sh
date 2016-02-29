# scripts/mkcmd.sh
#
# (c) Copyright 2013
# Allwinner Technology Co., Ltd. <www.allwinnertech.com>
# James Deng <csjamesdeng@allwinnertech.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# Notice:
#   1. This script muse source at the top directory of lichee.
LICHEE_TOP_DIR=`pwd`
LICHEE_ROOT=${LICHEE_TOP_DIR}
LICHEE_BOOT_DIR=${LICHEE_TOP_DIR}/boot
LICHEE_BR_DIR=${LICHEE_TOP_DIR}/buildroot
BR_SCRIPTS_DIR=${LICHEE_BR_DIR}/scripts
PACK_ROOT=${LICHEE_TOP_DIR}/tools/pack
build_config=${BR_SCRIPTS_DIR}/.buildconfig
pack_config=${BR_SCRIPTS_DIR}/.packconfig

declare -a config_array
config_index=0

function mk_error()
{
    echo -e "\033[47;31mERROR: $*\033[0m"
}

function mk_warn()
{
    echo -e "\033[47;34mWARN: $*\033[0m"
}

function mk_info()
{
    echo -e "\033[47;30mINFO: $*\033[0m"
}
function define_config()
{
	config_array[config_index]=$1
 	config_index=`expr $config_index + 1`	
	config_array[config_index]=$2
 	config_index=`expr $config_index + 1`	
	config_array[config_index]=$3
 	config_index=`expr $config_index + 1`	
	config_array[config_index]=$4
 	config_index=`expr $config_index + 1`	 	 		
	config_array[config_index]=$5
 	config_index=`expr $config_index + 1`	 	
	config_array[config_index]=$6
 	config_index=`expr $config_index + 1`	 	 	
}
function parse_config()
{
	if [ -f $1 ];then
		mk_info	Found config file $1
		. $1
		return 1
	else
		mk_warn	Not Found config file $1
		return 0
	fi

}
function select_option()
{
#	arg1: name arg2:type arg3:dir arg4:env  arg5:var	arg6:match
   local count=0
   local cmd_cnt=0
   if [ x$5 = xY ];then
			EVALCMD=eval
   else
			EVALCMD=
   fi
   
   if [ x$2 = xsubdir ] ; then
			    for optiondir in $($EVALCMD cd $3; find -mindepth 1 -maxdepth 1 -type d |grep -v default|sort); do
							if [ ! x$6 = xN ];then
			    			if echo `basename $3/$optiondir`|grep $6 >/dev/null ;then
			    				option[$count]=`basename $3/$optiondir`
			        		printf "$count. ${option[$count]}\n"
			        		let count=$count+1	
			    			fi
			    		else
			        option[$count]=`basename $3/$optiondir`
			        printf "$count. ${option[$count]}\n"
			        let count=$count+1			    		
			    		fi
			    done
			
			    while true; do
			        read -p "Please select a $1:"
			        RES=`expr match $REPLY "[0-9][0-9]*$"`
			        if [ "$RES" -le 0 ]; then
			            echo "please use index number"
			            continue
			        fi
			        if [ "$REPLY" -ge $count ]; then
			            echo "too big"
			            continue
			        fi
			        if [ "$REPLY" -lt "0" ]; then
			            echo "too small"
			            continue
			        fi
			        break
			    done
			    export $4=${option[$REPLY]}
					echo "export $4=${option[$REPLY]}">>$exportfile
	fi
	
#	arg1: name arg2:type arg3:list argr4 evn  arg5:cmd list  arg6: cmd env
if [ x$2 = xlist ] ; then
			    for cmd in `eval echo $5`; do
			        cmdoption[$cmd_cnt]=$cmd
			        let cmd_cnt=$cmd_cnt+1			    		
			    done
			    
			    for target in `eval echo $3`; do
			        option[$count]=$target
			        printf "$count. ${option[$count]}\n"
			        let count=$count+1			    		
			    done
			    			
			    while true; do
			        read -p "Please select a $1:"
			        RES=`expr match $REPLY "[0-9][0-9]*$"`
			        if [ "$RES" -le 0 ]; then
			            echo "please use index number"
			            continue
			        fi
			        if [ "$REPLY" -ge $count ]; then
			            echo "too big"
			            continue
			        fi
			        if [ "$REPLY" -lt "0" ]; then
			            echo "too small"
			            continue
			        fi
			        break
			    done
			    export $4=${option[$REPLY]}
			    export $6=${cmdoption[$REPLY]}			    
					echo "export $4=${option[$REPLY]}">>$exportfile
					echo "export $6=${cmdoption[$REPLY]}">>$exportfile
	fi	
}
function select_config()
{
    local arg1
    local arg2
    local arg3
    local arg4   
    local arg5        
    local arg6    
    exportfile=$1
		if [ -f $exportfile ];then
			rm -f $exportfile 
		fi         
		for (( i=0; i<$config_index;)) ; do
		arg1=${config_array[$i]}
 		i=`expr $i + 1`	
		arg2=${config_array[$i]}
 		i=`expr $i + 1`	
		arg3=${config_array[$i]}
 		i=`expr $i + 1`	
		arg4=${config_array[$i]}
 		i=`expr $i + 1`	
		arg5=${config_array[$i]}
 		i=`expr $i + 1`	
		arg6=${config_array[$i]}	
		if [ x$arg2 = xlist ] ; then
			select_option $arg1 $arg2 '$arg3' $arg4 '$arg5' $arg6			
		else				
			select_option $arg1 $arg2 $arg3 $arg4 $arg5 $arg6
		fi
 		i=`expr $i + 1`	 		 		 	
		done
}


function setup_config()
{
	#	 config val define 
	#	option_name	option_type   option_dir  option_env	option_variable	option_match_str
	define_config 'chip' 	    'subdir' $PACK_ROOT/chips 	chip  'N' 'N'
	define_config 'platform' 	'subdir' 			  '$PACK_ROOT/chips/$chip/configs'							platform					'Y'										'N'	
	define_config 'board' 		'subdir' 				'$PACK_ROOT/chips/$chip/configs/$platform'		board							'Y'										'N'	
	define_config	'kernel'		'subdir'				$LICHEE_ROOT																	LICHEE_KERN_NAME   'N'										linux-3.	
	#							option_name	option_type		target_list																												target_env			cmd_list																													cmd_env
	define_config	'module'		'list'				'all boot buildroot kernel uboot clean mrproer distclean'					module			'mklichee mkboot mkbr mkkernel mkuboot mkmrproer mkdistclean'			buildcmd

	#	 config 
	has_config=0
	if [ "$1" = "config" ] ; then
			select_config		$build_config
	    has_config=1
	else
			if [ "x$1" = "x" ] ; then
			parse_config	$build_config
			retval=$?
			if [ x$retval = x0 ] ; then
			    select_config	$build_config
			fi
			has_config=1
		fi
	fi
	show_config
	export has_config=$has_config

}
function show_config()
{
if [ -f $build_config ];then
	while read LINE
	do
	        echo ${LINE#*export}
	done < $build_config
else
		mk_error	Not Found config file $build_config
fi
}
function get_configvalue()
{
if [ -f $1 ];then
	while read LINE
	do
        config_str=${LINE#*export}
        config=${config_str%%=*}
        value=${config_str##*=}
	    if [ "x$(echo $config)" = "x$(echo $2)" ];then
            echo $value
        fi
	done < $1
else
		mk_error	Not Found config file $1
fi
}
function setup_packconfig()
{
	#	 config val define 
	#							option_name	option_type			option_dir																option_env						option_variable			  option_match_str
	define_config 'chip' 			'subdir' 				$PACK_ROOT/chips 															chip            	'N' 									'N'
	define_config 'platform' 	'subdir' 			  '$PACK_ROOT/chips/$chip/configs'							platform					'Y'										'N'	
	define_config 'board' 		'subdir' 				'$PACK_ROOT/chips/$chip/configs/$platform'		board							'Y'										'N'	
	define_config	'kernel'		'subdir'				$LICHEE_ROOT																	LICHEE_KERN_NAME  'N'										linux-3.	

	#	 config 
	has_packconfig=0
	if [ "$1" = "config" ] ; then
			select_config		$pack_config
	    has_packconfig=1
	else
			if [ "x$1" = "x" ] ; then
			parse_config	$pack_config
			retval=$?
			if [ x$retval = x0 ] ; then
			    select_config	$pack_config
			fi
            build_chip=$(get_configvalue $build_config chip)
            pack_chip=$(get_configvalue $pack_config chip)
            build_platform=$(get_configvalue $build_config platform)
            pack_platform=$(get_configvalue $pack_config platform)
            if [ ! x$build_chip = x$pack_chip ];then
                mk_warn "build chip is $build_chip, but pack chip is $pack_chip, so i want you to re-select"
                select_config		$pack_config
                has_packconfig=1
            elif [ ! x$build_platform = x$pack_platform ];then
                mk_warn "build platform is $build_platform, but pack platform is $pack_platform, so i want you to re-select"
                select_config		$pack_config
                has_packconfig=1
            else
			has_packconfig=1
            fi
		fi
	fi
	show_packconfig
	export has_packconfig=$has_packconfig
}
function show_packconfig()
{
if [ -f $pack_config ];then
	while read LINE
	do
	        echo ${LINE#*export}
	done < $pack_config
else
		mk_error	Not Found packconfig file $pack_config
fi
}
