#!/bin/sh

action=$1

if [ "$action" = "on" ];then
	ubus send openclash.switch '{"action":"on"}'
fi

if [ "$action" = "off" ];then
	ubus send openclash.switch '{"action":"off"}'
fi

sleep 10
