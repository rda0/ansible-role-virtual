ansible-role-virtual
====================

Description
-----------

Ansible role to deploy virtual machines on a `kvm` hypervisor.

Playbook
--------

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

Bootstrap methods
-----------------

Set using `virtual_bootstrap_method`.

- `create`: create vm from template disk image, **preferred method for production**
- `install`: install vm using the installer

Boot method options
-------------------

Set using `virtual_boot_method`

### method create

- `fs-boot`: create vm from a template disk image `root` (bootloader: extlinux), **preferred method for production**
- `host-boot`: create vm from a template disk image `root` and boots using host boot method (kernel extracted from vm fs)
- `part-boot`: create vm from 2 template disk images `boot` and `root` (bootloader: grub)

### method install

- `manual`: install vm using manual installation via console
- `preseed`: install vm using the installer and preseed file

Network
-------

First generate a mac address for the new vm starting with `52:54:00` (kvm), example:

```
52:54:00:7a:3b:8f
```

Make sure the mac address is properly configured (DNS, DHCP) in your network.

Role variables
--------------

See `defaults/main.yml` for all variable defaults.

Special variables:

- `virtual_interface_name`: the maximum interface name length is limited to 15 characters
- `virtual_cpus_max`: if set to a larger value than `virtual_cpus`, cpu hotplugging will be enabled
- `virtual_memory_max`: if set to a larger value than `virtual_memory`, memory hotplugging will be enabled
- `virtual_memory_hugepages`: defaults to `True`, make sure enough free hugepages are available on the hypervisor

Examples
--------

Edit the playbooks variables `virtual_guest_name`, `virtual_mac` and any other variables you would like to change (in this example the additional `virtual_disks` are removed):

```yaml
- hosts: my-host
  gather_facts: no
  vars:
    - virtual_hypervisor_host: my-kvm-hypervisor
    - virtual_hypervisor_type: kvm
    - virtual_bootstrap_method: create
    - virtual_boot_method: fs-boot
    - virtual_distribution: debian
    - virtual_codename: stretch
    - virtual_template_vg: r10
    - virtual_template_name: vm-tpl
    - virtual_guest_name: my-host
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

- `virtual_template_type`: type of the template disk image, `lv` (default) or `file`
- `virtual_template_name`: the name prefix for the template (lv or file), `-<codename>-<mount_point>` will be appended
- `virtual_template_vg`: the vg containing the template disk lv
- `virtual_template_path`: base-path containing file-based disk image template (default: `/var/opt/img`)
- `virtual_guest_name`: the `<hostname>`
- `virtual_disk_size`: the size of the root lv (min `2G`, the default)
- `virtual_disk_vg`: the volume group where `<hostname>-root` (and optional `<hostname>-boot`) LVs will be created
- `virtual_disk_fs`: the default filesystem to be used for additional `virtual_disks` with mount points
- `virtual_disks`: optional parameter to create lvs for other mount points
- `virtual_guest_name`: the geuests name used in libvirt and virsh (example: `virsh start <virtual_guest_name>`), use the short hostname
- `virtual_cpus`: amount of virtual cpus
- `virtual_memory`: memory in MB
- `virtual_bridge`: the bridge interface to be used
- `virtual_mac`: the guests mac address

In this example the whole extra disks `virtual_disks` key was removed to not create any additional mount points or empty disks.

To create additional lvs to be used as mount points, use the `virtual_disks` dictionary:

```yaml
- hosts: my-host
  gather_facts: no
  vars:
    - virtual_hypervisor_host: my-kvm-hypervisor
    - virtual_hypervisor_type: kvm
    - virtual_bootstrap_method: create
    - virtual_boot_method: fs-boot
    - virtual_distribution: debian
    - virtual_codename: jessie
    - virtual_template_path: /var/opt/img
    - virtual_template_type: file
    - virtual_template_name: vm-tpl
    - virtual_guest_name: my-host
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
