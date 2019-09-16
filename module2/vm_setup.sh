#!/bin/sh

vbmg () { VBoxManage.exe "$@"; }

vbmg createvm --name VM_ACIT4640 -ostype RedHat_64 --register

vbmg natnetwork remove --netname "net_4640"
vbmg natnetwork add --netname "net_4640" --network "192.168.250.0/24" --enable --dhcp off --ipv6 off


vbmg natnetwork modify \
	--netname "net_4640" --port-forward-4 "ssh:tcp:[]:50022:[192.168.250.10]:22" \
	--port-forward-4 "http:tcp:[]:50080:[192.168.250.10]:80" \
	--port-forward-4 "https:tcp:[]:50443:[192.168.250.10]:443"





vbmg modifyvm VM_ACIT4640 \
	        --memory 1024 \
		--cpus 1 \
		--nic1 natnetwork \
		--nat-network1 "net_4640"


VM_NAME="VM_ACIT4640"
SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"
VBOX_FILE=$(vbmg showvminfo VM_ACIT4640 | sed -ne "$SED_PROGRAM")
VM_DIR=$(dirname "$VBOX_FILE")

vbmg storagectl VM_ACIT4640 --name SATA --add sata

vbmg createmedium disk --filename "$VM_DIR/VM_ACIT4640.vdi" --size 10240 --format VDI
vbmg storageattach VM_ACIT4640 --storagectl SATA --port 0 --device 0 --type hdd --medium "$VM_DIR/VM_ACIT4640.vdi"
