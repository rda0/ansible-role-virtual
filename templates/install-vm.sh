#!/bin/bash

if [ ! -f /etc/libvirt/qemu/{{ guest_name }}.xml ]; then

virt-install \
--virt-type=kvm \
--name={{ guest_name }} \
--vcpus={{ vcpus }} \
--memory={{ memory }} \
--controller type=scsi,model=virtio-scsi \
--disk=/var/lib/libvirt/images/{{ guest_name }}.qcow2,format=qcow2,size={{ disk_size }},bus=scsi,cache=none \
--location={{ location }} \
--os-type=linux \
--os-variant={{ os_variant }} \
--console=pty,target_type=serial \
--initrd-inject={{ vm_path }}/{{ guest_name }}/preseed.cfg \
--extra-args='auto console=ttyS0,115200n8 serial' \
{% if mac is defined %}
--network=bridge={{ bridge }},model=virtio,mac={{ mac }} \
{% else %}
--network=bridge={{ bridge }},model=virtio \
{% endif %}
--nographics \
--noautoconsole

#--hvm \ # full virtualized
#--paravirt \ # paravirtualized

else
    echo "vm already defined!"
    exit 1
fi
