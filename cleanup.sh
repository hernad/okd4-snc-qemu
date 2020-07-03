#!/bin/bash

for node in bootstrap.snc.test master.snc.test master-1.snc.test master-2.snc.test master-3.snc.test 
do
   echo destroying $node ..
   virsh destroy $node
   virsh undefine $node
done

rm -rf /VirtualMachines/*.xz
rm -rf /VirtualMachines/*.qcow2

#rm -rf /usr/share/nginx/html/install

virsh list --all
