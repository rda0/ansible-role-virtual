#!/bin/bash

if [ ! -f /etc/libvirt/qemu/{{ virtual_guest_name }}.xml ]; then

virt-install \
--name={{ virtual_guest_name }} \
--virt-type=kvm \
{% if virtual_memory_hotpluggable %}
--cpu=model={{ virtual_cpu }},cell0.id=0,cell0.cpus={{ virtual_numa_cell_cpus }},cell0.memory={{ virtual_numa_cell_memory }} \
--memory=memory={{ virtual_memory }},hotplugmemorymax={{ virtual_memory_max }},hotplugmemoryslots={{ virtual_memory_slots }} \
{% else %}
--cpu={{ virtual_cpu }} \
--memory={{ virtual_memory }} \
{% endif %}
{% if virtual_cpus_hotpluggable %}
--vcpus=vcpus={{ virtual_cpus }},maxvcpus={{ virtual_cpus_max }} \
{% else %}
--vcpus={{ virtual_cpus }} \
{% endif %}
{% if virtual_memory_hugepages %}
--memorybacking=hugepages=yes,size={{ virtual_memory_hugepages_size }},unit={{ virtual_memory_hugepages_unit }} \
{% endif %}
{% if virtual_memory_balloon %}
--memballoon=virtio \
{% else %}
--memballoon=none \
{% endif %}
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
--network=bridge={{ virtual_bridge }},model=virtio,target={{ virtual_interface_name }},mac={{ virtual_mac }} \
{% else %}
--network=bridge={{ virtual_bridge }},model=virtio,target={{ virtual_interface_name }} \
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
