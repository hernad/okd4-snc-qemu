#!/bin/bash

set -x

# This script will set up the infrastructure to deploy a single node OKD 4.X cluster
CPU="8"
MEMORY="32384"
DISK="300"

#FCOS_VER=31.20200517.3.0
#FCOS_VER=32.20200615.3.0
FCOS_VER=32.20200629.2.0
#FCOS_STREAM=stable
FCOS_STREAM=testing



NODE="master-1"
NODE_MAC_ADDR="52:54:00:f0:d1:3d"

#NODE="master-2"
#NODE_MAC_ADDR="52:54:00:f0:d2:3d"


#NODE="master-3"
#NODE_MAC_ADDR="52:54:00:f0:d3:3d"

for i in "$@"
do
case $i in
    -c=*|--cpu=*)
    CPU="${i#*=}"
    shift
    ;;
    -m=*|--memory=*)
    MEMORY="${i#*=}"
    shift
    ;;
    -n=*|--node=*)
    NODE="${i#*=}"
    ;;
    -x=*|--mac-addr=*)
    NODE_MAC_ADDR="${i#*=}"
    ;;
 
    *)
    UNKNOWN="${i#*=}"
    shift
          echo "unknown option: $UNKNOWN"
          echo "usage: $0 --memory=16384 --cpu=4 --node=master-3 --mac-addr=52:54:00:f0:d3:3d"
          exit 1
    ;;
esac
done



VM_NODE_PATH=/VirtualMachines
mkdir -p $VM_NODE_PATH

rm ${VM_NODE_PATH}/$NODE.qcow2.xz
cp -av fcos-${FCOS_VER}.qcow2.xz ${VM_NODE_PATH}/fcos-${NODE}.qcow2.xz
xz --decompress $VM_NODE_PATH/fcos-${NODE}.qcow2.xz

cp -av okd4-install-dir/master.ign ${VM_NODE_PATH}/$NODE.ign
chown qemu:qemu ${VM_NODE_PATH}/${NODE}*


virt-install --name ${NODE}.snc.test \
    --memory $MEMORY --vcpus $CPU \
    --os-variant centos7.0 \
    --import \
    --network bridge=br0,mac="$NODE_MAC_ADDR" \
    --disk backing_store=${VM_NODE_PATH}/fcos-${NODE}.qcow2,size=$DISK,format=qcow2,bus=virtio \
    --graphics none \
    --noautoconsole \
    --qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=${VM_NODE_PATH}/${NODE}.ign"


virsh console ${NODE}.snc.test
