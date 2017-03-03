#!/bin/bash

virt-install \
--virt-type=kvm \
--name={{ guest_name }} \
--vcpus={{ vcpus }} \
--memory={{ memory }} \
--controller type=scsi,model=virtio-scsi \
--disk=/var/lib/libvirt/images/{{ guest_name }}.qcow2,format=qcow2,size={{ disk_size }},bus=scsi,cache=none \
--location={{ location }} \
--os-type=linux \
--os-variant={{ os_variant }} \
--graphics=none \
--console=pty,target_type=serial \
--initrd-inject={{ vm_path }}/{{ guest_name }}/preseed.cfg \
--extra-args='auto console=ttyS0,115200n8 serial' \
--network=bridge={{ bridge }},model=virtio
