#!/bin/sh


echo "#################### Deleting the Old ########################"


PXE_NAME="PXE_4640"
VM_NAME="VM_ACIT4640"
NAT_NAME="net_4640"

vbmg () { /mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }

vbmg unregistervm --delete $VM_NAME
vbmg natnetwork remove --netname $NAT_NAME

vbmg natnetwork add --netname "net_4640" --network "192.168.250.0/24" --enable --dhcp off --ipv6 off


vbmg natnetwork modify \
	--netname "net_4640" --port-forward-4 "ssh:tcp:[]:50022:[192.168.250.10]:22" \
	--port-forward-4 "http:tcp:[]:50080:[192.168.250.10]:80" \
	--port-forward-4 "https:tcp:[]:50443:[192.168.250.10]:443" \
	--port-forward-4 "ssh2:tcp:[]:50222:[192.168.250.200]:22"
	
vbmg modifyvm VM_ACIT4640 \
		--nic1 natnetwork \
		--nat-network1 "net_4640"
		
function start_pxe(){
    vbmg startvm "$PXE_NAME"
    while /bin/true; do
        ssh -i acit_admin_id_rsa -p 50222 \
            -o ConnectTimeout=2 -o StrictHostKeyChecking=no \
            -q admin@localhost exit
        if [ $? -ne 0 ]; then
                echo "PXE server is not up, sleeping..."
                sleep 2
        else
                break
        fi
    done
    echo "I am ready to copy files"
}

echo "################################# Starting PXE ##################################"	
start_pxe


chmod 600 acit_admin_id_rsa
#copy rsa file to PXE server then change mode
#chmod 600 acit_admin_id_rsa


copy_files_to_pxe(){
    echo "COPYING file"
    	ssh -i acit_admin_id_rsa -p 50222 admin@localhost sudo chmod a+rx /var/www/lighttpd
        scp -i acit_admin_id_rsa -P 50222 admin@localhost app_setup.sh admin@localhost:/var/www/lighttpd
	scp -i acit_admin_id_rsa -P 50222 admin@localhost vm_setup.sh admin@localhost:/var/www/lighttpd
	scp -i acit_admin_id_rsa -P 50222 admin@localhost ks.cfg admin@localhost:/var/www/lighttpd
}

echo "################################# Copying file to PXE ##################################"
copy_files_to_pxe

#scp -i acit_admin_id_rsa -P 50222 admin@localhost ks.cfg admin@localhost:/var/www/lighttpd
#ssh -i acit_admin_id_rsa -P 50222 admin@localhost sudo chown admin /var/www/lighttpd
#ssh -i acit_admin_id_rsa -P 50222 admin@localhost sudo chmod a+r /var/www/lighttpd
#ssh -i acit_admin_id_rsa -P 50222 admin@localhost sudo chmod a+rx /var/www/lighttpd

create_VM(){
vbmg createvm --name VM_ACIT4640 -ostype RedHat_64 --register

vbmg modifyvm VM_ACIT4640 \
	        --memory 2048 \
		--cpus 1 \
		--nic1 natnetwork \
		--nat-network1 "net_4640" \
		--boot1 disk \
		--boot2 net


VM_NAME="VM_ACIT4640"
SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"
VBOX_FILE=$(vbmg showvminfo VM_ACIT4640 | sed -ne "$SED_PROGRAM")
VM_DIR=$(dirname "$VBOX_FILE")

vbmg storagectl VM_ACIT4640 --name SATA --add sata

vbmg createmedium disk --filename "$VM_DIR/VM_ACIT4640.vdi" --size 20480 --format VDI
vbmg storageattach VM_ACIT4640 --storagectl SATA --port 0 --device 0 --type hdd --medium "$VM_DIR/VM_ACIT4640.vdi"
}

echo "########################### Creating VM ############################"
create_VM


#copy files(app_setup.sh nginx.conf,database.js ....) to kickstart folder /var/lib/tftpboot/pxelinux/pxelinux.cfg/ ks.cfg file
#ls -l root/anaconka.cfg kickstart file need to copy 
#scp kickstart file to own
#scp -P 50222 root@localhost:/root/amaconda-lks.cfg
#mv amaconda-lks.cfg ks.cfg    change name 
#ssh -i acit_admin_id_rsa -P 50222 admin@localhost sudo chown admin /var/www/lighttpd     change own
#then you can copy kickstart file
#permission x to everyone in ks.cfg
#permission 
#change cdrom to url in kickstart file
#url --url=http://192.168.250.200/centos/
#

start_vm(){
    vbmg startvm "$VM_NAME"
}

echo "############################### Starting VM ################################"
start_vm
#call functions
