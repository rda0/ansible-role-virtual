#!/bin/bash

if [ ! -f /etc/libvirt/qemu/{{ virtual_guest_name }}.xml ]; then

virt-install \
--virt-type=kvm \
--cpu=host \
--name={{ virtual_guest_name }} \
--vcpus={{ virtual_cpus }} \
--memory={{ virtual_memory }} \
--memorybacking=hugepages=yes \
--memballoon=virtio \
--controller=type=scsi,model=virtio-scsi \
--disk=path=/dev/{{ virtual_disk_vg }}/{{ virtual_guest_name }}-root,bus=scsi,cache=none \
--location={{ location }} \
--os-type=linux \
--os-variant={{ os_variant }} \
--console=pty,target_type=serial \
--initrd-inject={{ vm_path }}/{{ virtual_guest_name }}/preseed.cfg \
--extra-args='auto=true priority=critical elevator=noop net.ifnames=0 biosdevname=0 nousb console=tty0 console=ttyS0,115200' \
--boot=kernel_args="elevator=noop net.ifnames=0 biosdevname=0 nousb console=tty0 console=ttyS0,115200" \
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
