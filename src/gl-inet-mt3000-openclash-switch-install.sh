#!/bin/sh

# 定义颜色输出函数
red() { echo -e "\033[31m\033[01m$1\033[0m"; }
green() { echo -e "\033[32m\033[01m$1\033[0m"; }
yellow() { echo -e "\033[33m\033[01m$1\033[0m"; }
blue() { echo -e "\033[34m\033[01m$1\033[0m"; }
light_magenta() { echo -e "\033[95m\033[01m$1\033[0m"; }
light_yellow() { echo -e "\033[93m\033[01m$1\033[0m"; }
cyan() { echo -e "\033[38;2;0;255;255m$1\033[0m"; }

##获取软路由型号信息
get_router_name() {
	model_info=$(cat /tmp/sysinfo/model)
	echo "$model_info"
}

get_router_hostname() {
	hostname=$(uci get system.@system[0].hostname)
	echo "$hostname 路由器"
}

#检查是否已经安装openclash
check_openclash_installed() {
	if [ -e /etc/init.d/openclash -a -e /etc/config/openclash ]; then
		return 0
	else
		return 1
	fi
}

# 检查是否安装了 whiptail
check_whiptail_installed() {
	if [ -e /usr/bin/whiptail ]; then
		return 0
	else
		return 1
	fi
}

#定义一个通用的Dialog
show_whiptail_dialog() {
	#判断是否具备whiptail dialog组件
	if check_whiptail_installed; then
		echo "whiptail has installed"
	else
		echo "# add your custom package feeds here" >/etc/opkg/customfeeds.conf
		opkg update
		opkg install whiptail
	fi
	local title="$1"
	local message="$2"
	local function_definition="$3"
	whiptail --title "$title" --yesno "$message" 15 60 --yes-button "是" --no-button "否"
	if [ $? -eq 0 ]; then
		eval "$function_definition"
	else
		echo "退出"
		exit 0
	fi
}

# 执行重启操作
do_reboot() {
	reboot
}

#提示用户要重启
show_reboot_tips() {
	reboot_code='do_reboot'
	show_whiptail_dialog "重启提醒" "           $(get_router_hostname)\n           $1openclash快捷开关完成.\n           开关生效需要重启路由器,\n           您是否要重启路由器?" "$reboot_code"
}

install_switch() {
	gl_name=$(get_router_name)
	case "$gl_name" in
		*3000*)
			;;
		*)
			echo "*      当前的路由器型号: "$gl_name | sed 's/ like iStoreOS//'
			red "并非MT3000 安装后无效！"
			exit 1
			;;
	esac
	if ! check_openclash_installed; then
		red "请先安装openclash！"
		exit 1
	fi
	
	mkdir -p /tmp/mt3000_openclash_switch
	cd /tmp/mt3000_openclash_switch
	wget -O openclash-mt3000-switch.tar.gz "https://github.com/parentalclash/gl-inet-mt3000-openclash-switch/releases/download/1.0/openclash-mt3000-switch.tar.gz"
	tar zxf openclash-mt3000-switch.tar.gz
	cp openclash.sh /etc/gl-switch.d
	chmod +x /etc/gl-switch.d/openclash.sh
	mkdir -p /etc/openclash/switch
	cp openclash-listener.sh /etc/openclash/switch
	chmod +x /etc/openclash/switch/openclash-listener.sh
	if [ -e /etc/rc.local ]; then
		sed -i '/exit 0/i /etc/openclash/switch/openclash-listener.sh &' "/etc/rc.local"
	else
		echo -e "/etc/openclash/switch/openclash-listener.sh &\nexit 0\n" > /etc/rc.local
	fi
	uci set switch-button.@main[0].func='openclash'
	uci commit
	show_reboot_tips '安装'
}

uninstall_switch() {
	uci set switch-button.@main[0].func='none'
	uci commit
	if [ -e /etc/rc.local ]; then
		file="/etc/rc.local"
		sed -i '/\/etc\/openclash\/switch\/openclash-listener.sh &/d' "$file"
	fi
	rm /etc/openclash/switch/openclash-listener.sh
	rm /etc/gl-switch.d/openclash.sh
	show_reboot_tips '卸载'
}



while true; do
	clear
	gl_name=$(get_router_name)
	echo "***********************************************************************"
	echo "*      一键安装openclash快捷开关 v1.0 by @parentalclash        "
	echo "**********************************************************************"
	echo "*      当前的路由器型号: "$gl_name | sed 's/ like iStoreOS//'
	echo
	echo "*******支持的机型列表***************************************************"
	green "*******GL-iNet MT-3000 "
	echo "**********************************************************************"
	echo
	echo " 1. 安装快捷开关"
	echo " 2. 卸载快捷开关"
	echo " Q. 退出本程序"
	echo
	read -p "请选择一个选项: " choice

	case $choice in
	1)
		install_switch
		;;
	2)
		uninstall_switch
		;;
	q | Q)
		echo "退出"
		exit 0
		;;
	*)
		echo "无效选项，请重新选择。"
		;;
	esac

	read -p "按 Enter 键继续..."
done