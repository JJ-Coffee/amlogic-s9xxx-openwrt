#!/bin/bash
#================================================================================================
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
# This file is a part of the make OpenWrt for Amlogic s9xxx tv box
# https://github.com/ophub/amlogic-s9xxx-openwrt
#
# Description: Build OpenWrt with Image Builder
# Copyright (C) 2021~ https://github.com/unifreq/openwrt_packit
# Copyright (C) 2021~ https://github.com/ophub/amlogic-s9xxx-openwrt
# Copyright (C) 2021~ https://downloads.openwrt.org/releases
# Copyright (C) 2023~ https://downloads.immortalwrt.org/releases
#
# Download from: https://downloads.openwrt.org/releases
#                https://downloads.immortalwrt.org/releases
#
# Documentation: https://openwrt.org/docs/guide-user/additional-software/imagebuilder
# Instructions:  Download OpenWrt firmware from the official OpenWrt,
#                Use Image Builder to add packages, lib, theme, app and i18n, etc.
#
# Command: ./config-openwrt/imagebuilder/imagebuilder.sh <source:branch>
#          ./config-openwrt/imagebuilder/imagebuilder.sh openwrt:21.02.3
#
#======================================== Functions list ========================================
#
# error_msg               : Output error message
# download_imagebuilder   : Downloading OpenWrt ImageBuilder
# adjust_settings         : Adjust related file settings
# custom_packages         : Add custom packages
# custom_config           : Add custom config
# custom_files            : Add custom files
# rebuild_firmware        : rebuild_firmware
#
#================================ Set make environment variables ================================
#
# Set default parameters
make_path="${PWD}"
openwrt_dir="openwrt"
imagebuilder_path="${make_path}/${openwrt_dir}"
custom_files_path="${make_path}/config-openwrt/imagebuilder/files"
custom_config_file="${make_path}/config-openwrt/imagebuilder/config"

# Set default parameters
STEPS="[\033[95m STEPS \033[0m]"
INFO="[\033[94m INFO \033[0m]"
SUCCESS="[\033[92m SUCCESS \033[0m]"
WARNING="[\033[93m WARNING \033[0m]"
ERROR="[\033[91m ERROR \033[0m]"
#
#================================================================================================

# Encountered a serious error, abort the script execution
error_msg() {
    echo -e "${ERROR} ${1}"
    exit 1
}

# Downloading OpenWrt ImageBuilder
download_imagebuilder() {
    cd ${make_path}
    echo -e "${STEPS} Start downloading OpenWrt files..."

    # Downloading imagebuilder files
    if [[ "${op_sourse}" == "openwrt" ]]; then
        download_file="https://downloads.openwrt.org/releases/${op_branch}/targets/armvirt/64/openwrt-imagebuilder-${op_branch}-armvirt-64.Linux-x86_64.tar.xz"
    else
        download_file="https://downloads.immortalwrt.org/releases/${op_branch}/targets/armvirt/64/immortalwrt-imagebuilder-${op_branch}-armvirt-64.Linux-x86_64.tar.xz"
    fi
    wget -q ${download_file}
    [[ "${?}" -eq "0" ]] || error_msg "Wget download failed: [ ${download_file} ]"

    # Unzip and change the directory name
    tar -xJf *-imagebuilder-* && sync && rm -f *-imagebuilder-*.tar.xz
    mv -f *-imagebuilder-* ${openwrt_dir}

    sync && sleep 3
    echo -e "${INFO} [ ${make_path} ] directory status: $(ls . -l 2>/dev/null)"
}

# Adjust related files in the ImageBuilder directory
adjust_settings() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start adjusting .config file settings..."

    # For .config file
    if [[ -s ".config" ]]; then
        # Root filesystem archives
        sed -i "s|CONFIG_TARGET_ROOTFS_CPIOGZ=.*|# CONFIG_TARGET_ROOTFS_CPIOGZ is not set|g" .config
        # Root filesystem images
        sed -i "s|CONFIG_TARGET_ROOTFS_EXT4FS=.*|# CONFIG_TARGET_ROOTFS_EXT4FS is not set|g" .config
        sed -i "s|CONFIG_TARGET_ROOTFS_SQUASHFS=.*|# CONFIG_TARGET_ROOTFS_SQUASHFS is not set|g" .config
        sed -i "s|CONFIG_TARGET_IMAGES_GZIP=.*|# CONFIG_TARGET_IMAGES_GZIP is not set|g" .config
    else
        error_msg "There is no .config file in the [ ${download_file} ]"
    fi

    # For other files
    # ......
    sed -i "s|CONFIG_DEFAULT_dnsmasq=.*|# CONFIG_DEFAULT_dnsmasq is not set|g" .config
    sed -i "s|CONFIG_DEFAULT_6in4=.*|# CONFIG_DEFAULT_6in4 is not set|g" .config
    sed -i "s|CONFIG_DEFAULT_default-settings=.*|# CONFIG_DEFAULT_default-settings is not set|g" .config
    sed -i "s|CONFIG_DEFAULT_default-settings-chn=.*|# CONFIG_DEFAULT_default-settings-chn is not set|g" .config
    

    sync && sleep 3
    echo -e "${INFO} [ openwrt ] directory status: $(ls -al 2>/dev/null)"
}

# Add custom packages
# If there is a custom package or ipk you would prefer to use create a [ packages ] directory,
# If one does not exist and place your custom ipk within this directory.
custom_packages() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start adding custom packages..."

    # Create a [ packages ] directory
    [[ -d "packages" ]] || mkdir packages

    # Download luci-app-amlogic
    amlogic_api="https://api.github.com/repos/ophub/luci-app-amlogic/releases"
    #
    amlogic_file="luci-app-amlogic"
    amlogic_file_down="$(curl -s ${amlogic_api} | grep "browser_download_url" | grep -oE "https.*${amlogic_name}.*.ipk" | head -n 1)"
    wget ${amlogic_file_down} -q -P packages
    [[ "${?}" -eq "0" ]] || error_msg "[ ${amlogic_file} ] download failed!"
    echo -e "${INFO} The [ ${amlogic_file} ] is downloaded successfully."
    #
    amlogic_i18n="luci-i18n-amlogic"
    amlogic_i18n_down="$(curl -s ${amlogic_api} | grep "browser_download_url" | grep -oE "https.*${amlogic_i18n}.*.ipk" | head -n 1)"
    wget ${amlogic_i18n_down} -q -P packages
    [[ "${?}" -eq "0" ]] || error_msg "[ ${amlogic_i18n} ] download failed!"
    echo -e "${INFO} The [ ${amlogic_i18n} ] is downloaded successfully."

    # Download other luci-app-xxx
    # ......
    
    # Download other luci-app-openclash
    #
    openclash_api="https://api.github.com/repos/vernesong/OpenClash/releases"
    #
    openclash_file="luci-app-openclash"
    openclash_file_down="$(curl -s ${openclash_api} | grep "browser_download_url" | grep -oE "https.*${openclash_name}.*.ipk" | head -n 1)"
    wget -q ${openclash_file_down} -O packages/${openclash_file_down##*/}
    [[ "${?}" -eq "0" ]] && echo -e "${INFO} The [ ${openclash_file} ] is downloaded successfully."

    sync && sleep 3
    echo -e "${INFO} [ packages ] directory status: $(ls packages -l 2>/dev/null)"
}

# Add custom packages, lib, theme, app and i18n, etc.
custom_config() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start adding custom config..."

    config_list=""
    if [[ -s "${custom_config_file}" ]]; then
        config_list="$(cat ${custom_config_file} 2>/dev/null | grep -E "^CONFIG_PACKAGE_.*=y" | sed -e 's/CONFIG_PACKAGE_//g' -e 's/=y//g' -e 's/[ ][ ]*//g' | tr '\n' ' ')"
        echo -e "${INFO} Custom config list: \n$(echo "${config_list}" | tr ' ' '\n')"
    else
        echo -e "${INFO} No custom config was added."
    fi
}

# Add custom files
# The FILES variable allows custom configuration files to be included in images built with Image Builder.
# The [ files ] directory should be placed in the Image Builder root directory where you issue the make command.
custom_files() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start adding custom files..."

    if [[ -d "${custom_files_path}" ]]; then
        # Copy custom files
        [[ -d "files" ]] || mkdir -p files
        cp -rf ${custom_files_path}/* files

        sync && sleep 3
        echo -e "${INFO} [ files ] directory status: $(ls files -l 2>/dev/null)"
    else
        echo -e "${INFO} No customized files were added."
    fi
}

# Rebuild OpenWrt firmware
rebuild_firmware() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start building OpenWrt with Image Builder..."

    # Selecting default packages, lib, theme, app and i18n, etc.
    # sorting by https://build.moz.one
    my_packages="\
        acpid attr base-files bash bc blkid block-mount blockd bsdtar \
        btrfs-progs busybox bzip2 cgi-io chattr comgt comgt-ncm containerd coremark \
        coreutils coreutils-base64 coreutils-nohup coreutils-stat coreutils-truncate curl \
        dosfstools dumpe2fs e2freefrag e2fsprogs exfat-mkfs \
        f2fs-tools f2fsck fdisk getopt gzip hostapd-common iconv iw-full iwinfo jq jshn \
        kmod-brcmfmac kmod-brcmutil kmod-cfg80211 kmod-mac80211 libjson-script \
        liblucihttp liblucihttp-lua losetup lsattr lsblk lscpu mkf2fs \
        mount-utils nano openssl-util parted perl-http-date perlbase-file perlbase-getopt \
        perlbase-time perlbase-unicode perlbase-utf8 pigz ppp ppp-mod-pppoe \
        pv resize2fs runc tar \
        tini ttyd tune2fs uclient-fetch uhttpd uhttpd-mod-ubus unzip uqmi usb-modeswitch \
        uuidgen wget-ssl wpad-basic wwan xfs-fsck xfs-mkfs xz \
        xz-utils ziptool zoneinfo-asia zoneinfo-core zstd \
        \
        luci luci-base luci-compat luci-lib-base  \
        luci-lib-ip luci-lib-ipkg luci-lib-jsonc luci-lib-nixio  \
        luci-mod-admin-full luci-mod-network luci-mod-status luci-mod-system  \
        luci-proto-ipip luci-proto-ipv6 \
        luci-proto-ppp \
        \
        luci-app-amlogic luci-app-openclash -dnsmasq \
        \
        php8 php8-cgi php8-mod-ctype php8-mod-fileinfo php8-mod-gettext php8-mod-gmp php8-mod-iconv php8-mod-mbstring php8-mod-pcntl php8-mod-session php8-mod-zip \
        php8-mod-filter \
        \
        kmod-inet-diag kmod-netlink-diag kmod-nft-tproxy \
        kmod-crypto-acompress kmod-crypto-crc32c kmod-crypto-hash \
        kmod-fs-btrfs \
        \
        kmod-usb-net-rndis kmod-usb-net-cdc-ncm kmod-usb-net-cdc-eem kmod-usb-net-cdc-ether kmod-usb-net-cdc-subset \
        kmod-nls-base kmod-usb-core kmod-usb-net kmod-usb2 kmod-usb-net-ipheth \
        kmod-usb-net-huawei-cdc-ncm kmod-usb-serial kmod-usb-serial-option kmod-usb-serial-wwan usbutils \
        kmod-usb-net-asix kmod-usb-net-asix-ax88179 kmod-usb-net-dm9601-ether kmod-usb-net-rtl8152 \
        \
        autocore \
        \
        ${config_list} \
        "

    # Rebuild firmware
    make image PROFILE="Default" PACKAGES="${my_packages}" FILES="files"

    sync && sleep 3
    echo -e "${INFO} [ openwrt/bin/targets/armvirt/64 ] directory status: $(ls bin/targets/*/* -l 2>/dev/null)"
    echo -e "${SUCCESS} The rebuild is successful, the current path: [ ${PWD} ]"
}

# Show welcome message
echo -e "${STEPS} Welcome to Rebuild OpenWrt Using the Image Builder."
[[ -x "${0}" ]] || error_msg "Please give the script permission to run: [ chmod +x ${0} ]"
[[ -z "${1}" ]] && error_msg "Please specify the OpenWrt Branch, such as [ ${0} openwrt:22.03.3 ]"
[[ "${1}" =~ ^[a-z]{3,}:[0-9]+ ]] || error_msg "Incoming parameter format <source:branch>: openwrt:22.03.3"
op_sourse="${1%:*}"
op_branch="${1#*:}"
echo -e "${INFO} Rebuild path: [ ${PWD} ]"
echo -e "${INFO} Rebuild Source: [ ${op_sourse} ], Branch: [ ${op_branch} ]"
echo -e "${INFO} Server space usage before starting to compile: \n$(df -hT ${make_path}) \n"
#
# Perform related operations
download_imagebuilder
adjust_settings
custom_packages
custom_config
custom_files
rebuild_firmware
#
# Show server end information
echo -e "Server space usage after compilation: \n$(df -hT ${make_path}) \n"
# All process completed
wait
