#!/bin/bash

if [ ! -f /etc/libvirt/qemu/{{ virtual_guest_name }}.xml ]; then

virt-install \
--virt-type=kvm \
--name={{ virtual_guest_name }} \
--vcpus=vcpus={{ virtual_cpus }}{{ ',cpuset=' if virtual_cpuset != '' else '' }}{{ virtual_cpuset }} \
--memory={{ virtual_memory }} \
{% if virtual_disk_bus == 'scsi' %}
--controller type=scsi,model=virtio-scsi \
{% endif %}
--disk=/var/lib/libvirt/images/{{ virtual_guest_name }}.qcow2,format=qcow2,size={{ virtual_disk_size_root }},bus={{ virtual_disk_bus }},cache=none \
--location={{ location }} \
--osinfo={{ virtual_osinfo }} \
--console=pty,target_type=serial \
--initrd-inject={{ vm_path }}/{{ virtual_guest_name }}/preseed.cfg \
--extra-args='auto=true priority=critical console=ttyS0,115200n8 serial' \
{% if virtual_mac is defined %}
--network=bridge={{ virtual_bridge }},model=virtio,mac={{ virtual_mac }} \
{% else %}
--network=bridge={{ virtual_bridge }},model=virtio \
{% endif %}
--nographics \
{% if virtual_noreboot %}
--noreboot \
{% endif %}
--noautoconsole

#--hvm \ # full virtualized
#--paravirt \ # paravirtualized

else
    echo "vm already defined!"
    exit 1
fi
