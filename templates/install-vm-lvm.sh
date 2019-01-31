#!/bin/bash

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
--location={{ location }} \
--os-type=linux \
--os-variant={{ os_variant }} \
--console=pty,target_type=serial \
--initrd-inject={{ vm_path }}/{{ guest_name }}/preseed.cfg \
--extra-args='auto=true priority=critical elevator=noop net.ifnames=0 biosdevname=0 nousb console=tty0 console=ttyS0,115200' \
--boot=kernel_args="elevator=noop net.ifnames=0 biosdevname=0 nousb console=tty0 console=ttyS0,115200" \
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
