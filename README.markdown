# ansible-role-virtual

## Description

Ansible role to install virtual machines on a `kvm` hypervisor.

## Playbook

When including this role, disable facts gathering in the playbook:

```yaml
- hosts: my-host
  gather_facts: no
  roles:
    - virtual
    - other_roles
```

This role (`virtual`) will gather facts just after the virtual host becomes ready, so the facts are available for any following roles.

The playbook needs to be started with `host_key_checking=False` until there is a better solution in ansible:

```sh
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook ...
```

## Bootstrap methods

- `create-fs-boot`: creates a vm from a template lvm `root` (bootloader: extlinux) **preferred method for production**
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
virtual_vm_template_vg: vg0
virtual_vm_template_name: vm-tpl
virtual_cpus: 1
virtual_memory: 1024
virtual_disk_size: 2G
virtual_disk_vg: vg0
virtual_disk_fs: ext4
virtual_bridge: br0
```

Edit the playbooks variables `virtual_guest_name`, `virtual_mac` and any other variables you would like to change (in this example the additional `virtual_disks` are removed):

```yml
---
- hosts: my-host
  gather_facts: no
  vars:
    - virtual_hypervisor_host: my-kvm-hypervisor
    - virtual_hypervisor_type: kvm
    - virtual_bootstrap_method: create
    - virtual_boot_method: fs-boot
    - virtual_distribution: debian
    - virtual_codename: stretch
    - virtual_vm_template_vg: r10
    - virtual_vm_template_name: vm-tpl
    - virtual_guest_name: foo
    - virtual_cpus: 4
    - virtual_memory: 4096
    - virtual_disk_size: 10G
    - virtual_disk_vg: r10
    - virtual_bridge: br0
    - virtual_mac: 52:54:00:7a:3b:8f
  roles:
    - virtual
```

while:

- `virtual_vm_template_vg`: the vg where to find the vm template filesystem
- `virtual_vm_template_name`: the lv prefix for the template, the template used will be `/dev/<virtual_vm_template_vg>/<virtual_vm_template_name>-<virtual_codename>`
- `virtual_guest_name`: the `<hostname>`
- `virtual_disk_size`: is the size of the root lv (min `2G`, the default)
- `virtual_disk_vg`: is the volume group where `<hostname>-root` (and `<hostname>-boot` in role `vm-create-part-boot`) lvs will be created
- `virtual_disk_fs`: the default filesystem to be used for additional `virtual_disks` with mount points
- `virtual_disks`: is an optional parameter to create lvs for other mount points
- `virtual_guest_name`: the geuests name used in libvirt and virsh (example: `virsh start <virtual_guest_name>`), use the short hostname
- `virtual_cpus`: amount of virtual cpus
- `virtual_memory`: memory in MB
- `virtual_bridge`: the bridge interface to be used
- `virtual_mac`: the guests mac address

In this example the whole extra disks `virtual_disks` key was removed to not create any additional mount points or empty disks.

To create additional lvs to be used as mount points, use the `virtual_disks` dictionary:

```yml
---
- hosts: my-host
  gather_facts: no
  vars:
    - virtual_hypervisor_host: my-kvm-hypervisor
    - virtual_hypervisor_type: kvm
    - virtual_bootstrap_method: create
    - virtual_boot_method: fs-boot
    - virtual_distribution: debian
    - virtual_codename: jessie
    - virtual_vm_template_vg: vg0
    - virtual_vm_template_name: vm-tpl
    - virtual_guest_name:
    - virtual_cpus: 2
    - virtual_memory: 2048
    - virtual_disk_size: 4G
    - virtual_disk_vg: vg0
    - virtual_disk_fs: ext3
    - virtual_bridge: br0
    - virtual_mac: 52:54:00:7a:3b:8f
    - virtual_disks:
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
    - virtual
```

The above will create the following disks and mount points (if `disk.vg` or  `disk.fs` is omitted, the value from `virtual_disk_vg` or `virtual_disk_fs` for the root disk will be used):

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
