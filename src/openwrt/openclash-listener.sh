#!/bin/sh

ubus listen openclash.switch | \
while read line ; do
	iface=$(echo "$line" | awk -F'"' '{print $6}')
        #logger -t openclash-listener "action is $iface"
	if [ "$iface" = "on" ];then
        	#logger -t "openclash-listener" "begin action on"
        	uci set openclash.config.enable='1'
        	uci commit openclash
		/etc/init.d/openclash restart >/dev/null 2>&1 &
        	#logger -t "openclash-listener" "end action on"
	fi

	if [ "$iface" = "off" ];then
        	#logger -t "openclash-listener" "begin action off"
        	uci set openclash.config.enable='0'
        	uci commit openclash
        	/etc/init.d/openclash stop >/dev/null 2>&1 &
        	#logger -t "openclash-listener" "end action off"
	fi
done
