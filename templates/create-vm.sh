#!/bin/bash

if [ -e {{ virtual_disk_prefix }}{{ virtual_disk_vg }}/{{ virtual_guest_name }}-root ]; then
    echo "lv already exists!"
    exit 1
fi

lvcreate -L {{ disk }} -n {{ virtual_guest_name }}-root {{ virtual_disk_vg }}
dd if={{ virtual_disk_prefix }}{{ virtual_template_vg }}/vm-template of={{ virtual_disk_prefix }}{{ virtual_disk_vg }}/{{ virtual_guest_name }}-root bs=1M
e2fsck -f {{ virtual_disk_prefix }}{{ virtual_disk_vg }}/{{ virtual_guest_name }}-root
resize2fs {{ virtual_disk_prefix }}{{ virtual_disk_vg }}/{{ virtual_guest_name }}-root

if [ ! -f /etc/libvirt/qemu/{{ virtual_guest_name }}.xml ]; then

virt-install \
--virt-type=kvm \
--cpu={{ virtual_cpu }} \
--cputune={{ virtual_cputune }} \
--name={{ virtual_guest_name }} \
--vcpus=vcpus={{ virtual_cpus }}{{ ',cpuset=' if virtual_cpuset != '' else '' }}{{ virtual_cpuset }} \
--memory={{ virtual_memory }} \
--memorybacking=hugepages=yes \
--memballoon=virtio \
--controller=type=scsi,model=virtio-scsi \
--disk=path={{ virtual_disk_prefix }}{{ virtual_disk_vg }}/{{ virtual_guest_name }}-root,bus=scsi,cache=none \
--os-type=linux \
--os-variant={{ os_variant }} \
--console=pty,target_type=serial \
--boot=kernel=/vmlinuz,initrd=/initrd.img,kernel_args="root={{ virtual_disk_prefix }}sda elevator=noop net.ifnames=0 biosdevname=0 nousb console=tty0 console=ttyS0,115200 serial" \
{% if virtual_mac is defined %}
--network=bridge={{ virtual_bridge }},model=virtio,mac={{ virtual_mac }} \
{% else %}
--network=bridge={{ virtual_bridge }},model=virtio \
{% endif %}
--nographics \
--noautoconsole \
--autostart

#--hvm \ # full virtualized
#--paravirt \ # paravirtualized

else
    echo "vm already defined!"
    exit 1
fi
