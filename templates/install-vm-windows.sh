#!/bin/bash

if [ ! -f /etc/libvirt/qemu/{{ guest_name }}.xml ]; then

#qemu-img create -f qcow2 -o preallocation=metadata /var/lib/libvirt/images/{{ guest_name }}.qcow2 {{ disk_size }}

virt-install \
--virt-type=kvm \
--name={{ guest_name }} \
--vcpus={{ vcpus }} \
--memory={{ memory }} \
--disk=/var/lib/libvirt/images/{{ guest_name }}.qcow2,format=qcow2,size={{ disk_size }},bus=virtio,cache=none \
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

#--controller type=scsi,model=virtio-scsi \
#--disk path={{ driver }},device=cdrom \
#--boot cdrom,fd,hd,network,menu=on \

# virsh domblklist phd-ads1
# virsh change-media phd-ads1 hda --eject
# virsh change-media phd-ads1 hda /opt/iso/windows/virtio-win.iso --insert

else
    echo "vm already defined!"
    exit 1
fi
