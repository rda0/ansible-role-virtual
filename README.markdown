# ansible-role-virtual

## Description

Ansible role to install virtual machines on a `kvm` hypervisor.

## Bootstrap methods

- `create`: creates a vm from a template lvm `root` (bootloader: extlinux) **preferred method for production**
- `create-host-boot`: creates a vm from a template lvm `root` and boots using host boot method (kernel extracted from vm fs)
- `create-part-boot`: creates a vm from 2 template lvms `boot` and `root` (bootloader: grub)
- `install`: install a vm using the installer and preseed file
- `install-manual`: install a vm using manual installation via console


## Create a vm

First generate a mac address for the new vm starting with `52:54:00` (kvm), example:

```
52:54:00:7a:3b:8f
```

Make sure the mac address is properly configured in your network.

To create a new vm named `foo`, start from the template playbook and copy it to the kvm hosts playbook directory:

```sh
cp playbooks/templates/vm-create.yml "playbooks/$(hostname -s)/foo.yml"
```

The following variables are the defaults used in the roles:

```yml
---
vm_template_vg: vg0
vm_template_name: vm-tpl
vg: vg0
vcpus: 1
memory: 1024
disk_size: 2G
fs: ext4
bridge: br0
```

Edit the playbooks variables `guest_name`, `mac` and any other variables you would like to change (in this example the additional disks are removed):

```yml
---
- hosts: production
  vars:
    - distribution: debian
    - codename: stretch
    - vm_template_vg: r10
    - vm_template_name: vm-tpl
    - vg: r10
    - guest_name: foo
    - vcpus: 4
    - memory: 4096
    - disk_size: 10G
    - bridge: br0
    - mac: 52:54:00:7a:3b:8f
  roles:
    - { role: vm-create, tags: vm-create }
```

while:

- `vm_template_vg`: the vg where to find the vm template filesystem
- `vm_template_name`: the lv prefix for the template, the template used will be `/dev/<vm_template_vg>/<vm_template_name>-<codename>`
- `vg`: is the volume group where `<hostname>-root` (and `<hostname>-boot` in role `vm-create-part-boot`) lvs will be created
- `guest_name`: the `<hostname>`
- `disk_size`: is the size of the root lv (min `2G`, the default)
- `disks`: is an optional parameter to create lvs for other mount points
- `fs`: the default filesystem to be used for additional disks with mount points
- `guest_name`: the geuests name used in libvirt and virsh (example: `virsh start <guest_name>`), use the short hostname
- `vcpus`: amount of virtual cpus
- `memory`: memory in MB
- `bridge`: the bridge interface to be used
- `mac`: the guests mac address

In this example the whole extra disks `disks` key was removed to not create any additional mount points or empty disks.

To create additional lvs to be used as mount points, use the `disks` dictionary:

```yml
---
- hosts: production
  vars:
    - distribution: debian
    - codename: jessie
    - vm_template_vg: vg0
    - vm_template_name: vm-tpl
    - vg: vg0
    - guest_name:
    - vcpus: 2
    - memory: 2048
    - disk_size: 4G
    - fs: ext3
    - bridge: br0
    - mac: 52:54:00:7a:3b:8f
    - disks:
        - mount: /var
          size: 2G
        - mount: /var/log
          size: 2G
        - mount: /export
          size: 100G
          vg: vg1-data
        - mount: /scratch
          size: 20G
          vg: vg1-data
          fs: xfs
        - size: 10G
  roles:
    - { role: vm-create, tags: vm-create }
```

The above will create the following disks and mount points (if `disk.vg` or  `disk.fs` is omitted, the value from `vg` or `fs` for the root disk will be used):

```
/dev/sda /        ext3   4G vg0
/dev/sdb /var     ext3   2G vg0
/dev/sdc /var/log ext3   2G vg0
/dev/sdd /export  ext3 100G vg1-data
/dev/sde /scratch xfs   20G vg1-data
/dev/sdf                10G vg0
```

Finally create the vm:

```sh
ansible-playbook playbooks/<hostname>/foo.yml
```
