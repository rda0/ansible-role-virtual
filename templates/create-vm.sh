#!/bin/bash

if [ -e {{ virtual_disk_prefix }}{{ virtual_disk_vg }}/{{ virtual_guest_name }}-root{{ virtual_disk_suffix }} ]; then
    echo "lv already exists!"
    exit 1
fi

lvcreate -L {{ disk }} -n {{ virtual_guest_name }}-root {{ virtual_disk_vg }}
dd if={{ virtual_disk_prefix }}{{ virtual_template_vg }}/vm-template of={{ virtual_disk_prefix }}{{ virtual_disk_vg }}/{{ virtual_guest_name }}-root{{ virtual_disk_suffix }} bs=1M
e2fsck -f {{ virtual_disk_prefix }}{{ virtual_disk_vg }}/{{ virtual_guest_name }}-root{{ virtual_disk_suffix }}
resize2fs {{ virtual_disk_prefix }}{{ virtual_disk_vg }}/{{ virtual_guest_name }}-root{{ virtual_disk_suffix }}

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
{% if virtual_disk_bus == 'scsi' %}
--controller=type=scsi,model=virtio-scsi \
{% endif %}
--disk=path={{ virtual_disk_prefix }}{{ virtual_disk_vg }}/{{ virtual_guest_name }}-root{{ virtual_disk_suffix }},bus={{ virtual_disk_bus }},cache=none \
--os-type=linux \
--os-variant={{ os_variant }} \
--console=pty,target_type=serial \
--boot=kernel=/vmlinuz,initrd=/initrd.img,kernel_args="root=/dev/sda elevator=noop net.ifnames=0 biosdevname=0 nousb console=tty0 console=ttyS0,115200 serial" \
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
