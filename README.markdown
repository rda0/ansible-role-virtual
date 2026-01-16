ansible-role-virtual
====================

Ansible role to deploy virtual hosts on a hypervisor.

Hypervisors
-----------

The following hypervisors are currently supported:

- `kvm`: QEMU-KVM

Requirements
------------

The methods `clone` and `bootstrap` require a bootstrap command to create guest images. By default the bootstrap command is configured to use [bootstrap](https://github.com/rda0/bootstrap), which should work out of the box with the role defaults.

Run the followin commands on the hypervisor to install it:

```bash
git clone https://github.com/rda0/bootstrap.git /opt/bootstrap
ln -s /opt/bootstrap/bootstrap /usr/local/bin/bootstrap
```

Playbook
--------

When including this role, disable facts gathering in the playbook. This is required because the virtual host (`inventory_hostname`) first needs to be created and/or started:

```yaml
- hosts: my-host
  gather_facts: no
  roles:
    - virtual
    - other_roles
```

This role (`virtual`) will gather facts just after the virtual host becomes ready, so the facts are available for any following roles.

Bootstrap methods
-----------------

Set using `virtual_bootstrap_method`.

- `clone`: clone guest from template disk image, **preferred method for production**
- `bootstrap`: same as clone, but bootstraps guest lvs directly (slower)
- `install`: install guest using the installer

Boot method options
-------------------

Set using `virtual_boot_method`

### method clone and bootstrap

- `fs`: clone vm from a template disk image `root` (bootloader: extlinux), **preferred method for production**
- `host`: clone vm from a template disk image `root` and boots using host boot method (kernel extracted from vm fs)
- `part`: clone vm from 2 template disk images `boot` and `root` (bootloader: grub)

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
- `virtual_disk_type`: defaults to `lv`, use `zvol` for zfs volumes or `file` for file based disk images, extra-disks type must be the same
- `virtual_disk_vg`: defaults to `vg0`, use(s by default) the absolute file image pool path (default: `/var/virtual/images`) if `virtual_disk_type` is set to `file`
- `virtual_disk_bus`: defaults to `scsi` (virtio-scsi), use `virtio` for virtio-blk
- `virtual_disk_bus_id`: automatically set to `s` (scsi) or `v` (virtio). note: make sure bootloader is set correctly
- `virtual_disk_file_allocation`: `fallocate` (default) or `qemu-img`
- `virtual_disk_bs`: for zvol only, defaults to `8K`, use per disk key `bs` in `virtual_disks` for extra disks
- `virtual_file_extension`: defaults to `''`, example `.raw`, for file based images/templates only
- `virtual_disk_zfs_props`: defaults to `{}`, dict with zfs properties (except `volsize`, `volblocksize`, which are overridden), see `man zfsprops`

Required inventory variables (or override via `virtual_` variable):

- `virtual_ssh_host_keys_public`: defaults to `ssh_host_keys_public`
- `virtual_ssh_host_keys_private`: defaults to `vault_ssh_host_keys_private`
- `virtual_root_password_hash`: defaults to `vault_root_password_hash`

The ssh host keys must be pre-defined in the inventory (see above), otherwise set `host_key_checking=False`.

Examples
--------

Edit the playbooks variables `virtual_guest_name`, `virtual_mac` and any other variables you would like to change (in this example the additional `virtual_disks` are removed):

```yaml
- hosts: my-host
  gather_facts: no
  vars:
    - virtual_hypervisor_host: my-kvm-hypervisor
    - virtual_hypervisor_type: kvm
    - virtual_bootstrap_method: clone
    - virtual_boot_method: fs
    - virtual_distribution: debian
    - virtual_codename: stretch
    - virtual_template_vg: r10
    - virtual_template_name_prefix: tpl
    - virtual_guest_name: my-host
    - virtual_cpus: 4
    - virtual_memory: 4096
    - virtual_disk_size_root: 10G
    - virtual_disk_vg: r10
    - virtual_bridge: br0
    - virtual_mac: '52:54:00:7a:3b:8f'
  roles:
    - virtual
```

while:

- `virtual_template_type`: type of the template disk image, `lv` (default) or `file`
- `virtual_template_name_prefix`: the name prefix for the template filename (lv or file), `-<boot_method>-<codename>-<mount_point>` will be appended
- `virtual_template_vg`: the vg containing the template disk lv
- `virtual_template_path`: base-path containing file-based disk image template (default: `/var/virtual/images`)
- `virtual_guest_name`: the guests name (default: `inventory_hostname`)
- `virtual_disk_size_root`: the size of the root lv (min `2G`, the default)
- `virtual_disk_size_boot`: the size of the boot lv (min `512M`, the default)
- `virtual_disk_vg`: the volume group where `<hostname>-root` (and optional `<hostname>-boot`) LVs will be created
- `virtual_disk_fs`: the default filesystem to be used for additional `virtual_disks` with mount points
- `virtual_disks`: optional parameter to create disks for other mount points
- `virtual_guest_name`: the geuests name used in libvirt and virsh (example: `virsh start <virtual_guest_name>`), use the short hostname
- `virtual_cpus`: amount of virtual cpus
- `virtual_memory`: memory in MB
- `virtual_bridge`: the bridge interface to be used
- `virtual_mac`: the guests mac address

In this example the whole extra disks `virtual_disks` key was removed to not create any additional mount points or empty disks.

To create additional disks to be used as mount points, use the `virtual_disks` dictionary:

```yaml
- hosts: my-host
  gather_facts: no
  vars:
    - virtual_hypervisor_host: my-kvm-hypervisor
    - virtual_hypervisor_type: kvm
    - virtual_bootstrap_method: clone
    - virtual_boot_method: fs
    - virtual_distribution: debian
    - virtual_codename: bullseye
    - virtual_template_path: /var/virtual/images
    - virtual_template_type: file
    - virtual_template_name_prefix: tpl
    - virtual_guest_name: my-host
    - virtual_cpus: 2
    - virtual_memory: 2048
    - virtual_disk_size_root: 4G
    - virtual_disk_vg: vg0
    - virtual_disk_fs: ext4
    - virtual_bridge: br0
    - virtual_mac: '52:54:00:7a:3b:8f'
    - virtual_disks:
        - mount: /var
          size: 2G
        - mount: /var/log
          size: 2G
        - mount: /export
          size: 100G
          vg: vg1-data
          options: defaults
        - mount: /scratch
          size: 20G
          vg: vg1-data
          fs: xfs
        - size: 10G
        - mount: /var/data
          size: 4T
          vg: vg1-data
          import: True
  roles:
    - virtual
```

The above will create (or import) the following disks and mount points:

```
/dev/sda /         ext4   4G vg0
/dev/sdb /var      ext4   2G vg0
/dev/sdc /var/log  ext4   2G vg0
/dev/sdd /export   ext4 100G vg1-data
/dev/sde /scratch  xfs   20G vg1-data
/dev/sdf                 10G vg0
/dev/sdg /var/data ext3   4T vg1-data
```

- `disk.vg`: default is `virtual_disk_vg`
- `disk.fs`: default is `virtual_disk_fs`
- `disk.options`: default is `virtual_disk_mount_options`
- `disk.import`: when `True` import existing disk, disk contents will not be modified (only use leaf mount points)
- `disk.error_policy`: the default is left to the discretion of the hypervisor, usually the VM is stopped/paused on IO errors on the host system. Use `report` to report the error to the guest OS instead.

To import disks from other disk types, override `prefix`, `suffix` and `vg` accordingly, example:

```yaml
virtual_file_extension: '.raw'
virtual_disk_type: file
virtual_disk_vg: /var/virtual/images
virtual_disks:
  - mount: /var/lv
    size: 2G
    prefix: /dev/
    vg: vg0
    suffix: ''
    import: True
  - mount: /var/zvol
    size: 2G
    prefix: /dev/
    vg: zp0
    suffix: ''
    import: True
```

To create additional interfaces use `virtual_interfaces`:

```yaml
virtual_interfaces:
  - suffix: foo
  - suffix: bar
    mac: '52:54:00:a0:b0:c0'
  - name: full-interface-name
    mac: '52:54:00:a0:b0:c1'
    bridge: br-foobar
```

- `suffix`: will be appended (with `-`) to the name of the main interface
- `mac`: (optional) if omitted a mac will be generated
- `bridge`: (optional) defaults to `virtual_bridge`

Example to use zvols:

```yaml
virtual_disk_size_root: 10G
virtual_disk_type: zvol
virtual_disk_vg: zp0
virtual_disk_bs: 64K
virtual_disk_zfs_props:
  compression: 'lz4'
  reservation: 'none'
  refreservation: 'none'
virtual_disks:
  - mount: /var
    size: 2G
    zfs_props:
      compression: 'off'
  - mount: /var/log
    size: 2G
    bs: 32K
    zfs_props:
      compression: 'off'
```

- `bs`: volblocksize, defaults to `virtual_disk_bs`
- `zfs_props`: dict of zfs properties, merged with `virtual_disk_zfs_props`

### Experimental

virtiofs: Sharing a host directory with a guest

- https://libvirt.org/kbase/virtiofs.html
- https://www.kernel.org/doc/html/latest/filesystems/virtiofs.html

```yaml
virtual_filesystems:
  - target: mount_test
    source: /var/test
```

In the guest mount it with:

```bash
mount -t virtiofs mount_test /mnt
```
