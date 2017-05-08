#!/bin/bash

if [ ! -f /etc/libvirt/qemu/{{ guest_name }}.xml ]; then

virt-install \
--virt-type=kvm \
--name={{ guest_name }} \
--vcpus={{ vcpus }} \
--memory={{ memory }} \
--controller type=scsi,model=virtio-scsi \
--disk=/var/lib/libvirt/images/{{ guest_name }}.qcow2,format=qcow2,size={{ disk_size }},bus=scsi,cache=none \
--cdrom={{ location }} \
--os-type=windows \
--os-variant={{ os_variant }} \
{% if mac is defined %}
--network=bridge={{ bridge }},model=e1000,mac={{ mac }} \
{% else %}
--network=bridge={{ bridge }},model=e1000 \
{% endif %}
--vnc \
--accelerate \
--noapic \
--keymap=en-us \
--noautoconsole

# virsh domblklist {{ guest_name }}
# virsh change-media {{ guest_name }} <target> --eject
# virsh change-media {{ guest_name }} <target> /opt/iso/windows/virtio-win.iso --insert
# load virioscsi driver (2k16/amd64)
# virsh change-media {{ guest_name }} <target> --eject
# virsh change-media {{ guest_name }} <target> /opt/iso/windows/win_srv_16.iso --insert

else
    echo "vm already defined!"
    exit 1
fi
