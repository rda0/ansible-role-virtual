#!/bin/bash

if [ -e /dev/{{ vg }}/{{ guest_name }}-root ]; then
    echo "lv already exists!"
    exit 1
fi

lvcreate -L {{ disk }} -n {{ guest_name }}-root {{ vg }}
dd if=/dev/{{ vm_template_vg }}/vm-template of=/dev/{{ vg }}/{{ guest_name }}-root bs=1M
e2fsck -f /dev/{{ vg }}/{{ guest_name }}-root
resize2fs /dev/{{ vg }}/{{ guest_name }}-root

if [ ! -f /etc/libvirt/qemu/{{ guest_name }}.xml ]; then

virt-install \
--virt-type=kvm \
--cpu=host \
--name={{ guest_name }} \
--vcpus={{ vcpus }} \
--memory={{ memory }} \
--memorybacking=hugepages=yes \
--memballoon=virtio \
--controller=type=scsi,model=virtio-scsi \
--disk=path=/dev/{{ vg }}/{{ guest_name }}-root,bus=scsi,cache=none \
--os-type=linux \
--os-variant={{ os_variant }} \
--console=pty,target_type=serial \
--boot=kernel=/vmlinuz,initrd=/initrd.img,kernel_args="root=/dev/sda elevator=noop nousb console=ttyS0,115200n8 serial" \
{% if mac is defined %}
--network=bridge={{ bridge }},model=virtio,mac={{ mac }} \
{% else %}
--network=bridge={{ bridge }},model=virtio \
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
