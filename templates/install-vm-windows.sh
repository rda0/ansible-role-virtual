#!/bin/bash

if [ ! -f /etc/libvirt/qemu/{{ virtual_guest_name }}.xml ]; then

virt-install \
--virt-type=kvm \
--name={{ virtual_guest_name }} \
--vcpus=vcpus={{ virtual_cpus }} \
--memory={{ virtual_memory }} \
--controller type=scsi,model=virtio-scsi \
--disk=/var/lib/libvirt/images/{{ virtual_guest_name }}.qcow2,format=qcow2,size={{ virtual_disk_size_root }},bus=scsi,cache=none \
--cdrom={{ location }} \
--os-type=windows \
--os-variant={{ os_variant }} \
{% if virtual_mac is defined %}
--network=bridge={{ virtual_bridge }},model=e1000,mac={{ virtual_mac }} \
{% else %}
--network=bridge={{ virtual_bridge }},model=e1000 \
{% endif %}
--vnc \
--accelerate \
--noapic \
--keymap=en-us \
--noautoconsole

# virsh domblklist {{ virtual_guest_name }}
# virsh change-media {{ virtual_guest_name }} <target> --eject
# virsh change-media {{ virtual_guest_name }} <target> /opt/iso/windows/virtio-win.iso --insert
# load virioscsi driver (2k16/amd64)
# virsh change-media {{ virtual_guest_name }} <target> --eject
# virsh change-media {{ virtual_guest_name }} <target> /opt/iso/windows/win_srv_16.iso --insert

else
    echo "vm already defined!"
    exit 1
fi
