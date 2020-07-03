#!/bin/bash

set -x

# This script will set up the infrastructure to deploy a single node OKD 4.X cluster
CPU="4"
MEMORY="16384"
DISK="200"

export SNC_DOMAIN=snc.test

#FCOS_VER=31.20200517.3.0
#FCOS_VER=32.20200615.3.0
#FCOS_VER=32.20200619.20
#FCOS_VER=31.20200521.20
FCOS_VER=32.20200629.2.0
#FCOS_STREAM=stable
FCOS_STREAM=testing


OKD_REGISTRY=quay.io/openshift/okd
#OKD_RELEASE="4.6.0-0.okd-2020-07-01-233221"
#OKD_RELEASE="4.4.0-0.okd-2020-05-23-055148-beta5"
#OKD_RELEASE="4.4.0-0.okd-2020-05-23-055148-beta5"
OKD_RELEASE="4.5.0-0.okd-2020-06-29-110348-beta6"



FCOS_ISO_DIR=fcos_iso

yum install -y centos-release-qemu-ev qemu-kvm-ev
/usr/libexec/qemu-kvm --version

NODE="bootstrap"
NODE_MAC_ADDR="52:54:00:f0:d4:3d"
VM_NODE_PATH=/VirtualMachines

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
          echo "usage: $0 --memory=16384 --cpu=2 --node=bootstrap --mac-addr=52:54:00:f0:d4:3d"
          exit 1
    ;;
esac
done


mkdir -p okd-release-tmp
cd okd-release-tmp
echo "${OKD_REGISTRY}:${OKD_RELEASE}"
oc adm release extract --command='openshift-install' ${OKD_REGISTRY}:${OKD_RELEASE}
oc adm release extract --command='oc' ${OKD_REGISTRY}:${OKD_RELEASE}
ls -lh openshift-install
ls -lh oc

mv -f openshift-install ~/bin
mv -f oc ~/bin
cd ..
rm -rf okd-release-tmp

# Create and deploy ignition files
rm -rf okd4-install-dir
mkdir -p okd4-install-dir
cp -av install-config-snc.yaml okd4-install-dir/install-config.yaml

echo "install config:"
echo "========================================================"
cat okd4-install-dir/install-config.yaml
echo "========================================================"


#https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/32.20200615.3.0/x86_64/fedora-coreos-32.20200615.3.0-qemu.x86_64.qcow2.xz

if [ ! -f fcos-${FCOS_VER}.qcow2.xz ] ; then
  echo "qemu qcow2"
  curl -o fcos-${FCOS_VER}.qcow2.xz https://builds.coreos.fedoraproject.org/prod/streams/${FCOS_STREAM}/builds/${FCOS_VER}/x86_64/fedora-coreos-${FCOS_VER}-qemu.x86_64.qcow2.xz
fi


echo FCOS_VER=$FCOS_VER

openshift-install --dir=okd4-install-dir create ignition-configs
rm ${VM_NODE_PATH}/$NODE.qcow2.xz
cp -av fcos-${FCOS_VER}.qcow2.xz ${VM_NODE_PATH}/fcos-$NODE.qcow2.xz
xz --decompress $VM_NODE_PATH/fcos-$NODE.qcow2.xz
#qemu-img create -f qcow2 -F qcow2 -b ${VM_NODE_PATH}/fcos-$NODE.qcow2 ${VM_NODE_PATH}/${NODE}.qcow2 

cp -av okd4-install-dir/bootstrap.ign ${VM_NODE_PATH}/${NODE}.ign
chown qemu:qemu ${VM_NODE_PATH}/${NODE}*


virt-install --name $NODE.snc.test \
    --memory ${MEMORY} --vcpus ${CPU} \
    --os-variant centos7.0 \
    --import \
    --network bridge=br0,mac="$NODE_MAC_ADDR" \
    --disk backing_store=${VM_NODE_PATH}/fcos-${NODE}.qcow2,size=$DISK,format=qcow2,bus=virtio \
    --graphics none \
    --noautoconsole \
    --qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=${VM_NODE_PATH}/${NODE}.ign"


virsh console $NODE.snc.test
