# ansible-kvm

## Description

Install virtual machines using `kvm` and `ansible`

## Roles (installation methods)

- `vm-create`: creates a vm from a template lvm `root` (bootloader: extlinux) **preferred method for production**
- `vm-create-host-boot`: creates a vm from a template lvm `root` and boots using host boot method (kernel extracted from vm fs)
- `vm-create-part-boot`: creates a vm from 2 template lvms `boot` and `root` (bootloader: grub)
- `vm-install`: install a vm using the installer and preseed file
- `vm-install-manual`: install a vm using manual installation via console

## Create vm template for roles `vm-create*`

This bootstraps a minimal system to lvms to be used as template disks for vms (required for roles `vm-create*`)

```
Usage: scripts/bootstrap/bootstrap vm vg dist release [options]

    Bootstraps a bootable kvm vm to lvm filesystem.
    Default bootloader: extlinux

Options:

    vm
        Name of the vm (used for lvm naming)
    vg
        Volume group name
    dist
        Distribution name (example: `debian`, `ubuntu`)
    release
        Release name (example `stable`, `stretch`, etc)
    -r, --root <size>
        Size of root fs lv (default: `2G`)
    -b, --boot <size>
        Enable boot disk (and grub), size of boot disk lv (example: `512M`)
    -t, --fs-type <type>
        Type for root file system (default: `ext4`)
    -i, --package-install <package_list>
        List of extra packages to install (default: bootstrap-packages/<dist>/<release>/install)
    -u, --package-purge <package_list>
        List of packages to purge (default: bootstrap-packages/<dist>/<release>/purge)
    -n, --network-interface <interface_name>
        Network interface name (default: `eth0`)
    -h, --help
        Print this help message
```

Where `vm` is the base name of the lv to be created. The preferred naming scheme is: `vm-tpl-<dist_codename>`.

### Bootstrap a template for role `vm-create`

For example Debian 9 Stretch bootstrap:

```
scripts/bootstrap/bootstrap vm-tpl-stretch r10 debian stretch
```

This will create the lv:

- `/dev/r10/vm-tpl-stretch-root`: disk containing the root filesystem (bootloader: extlinux)

### Bootstrap a template for role `vm-create-part-boot`

```
scripts/bootstrap/bootstrap vm-tpl-part-boot-stretch r10 debian stretch -b 512M
```

This will create the 2 lvs:

- `/dev/r10/vm-tpl-part-boot-stretch-boot`: disk containing a boot partition with an MBR (bootloader: grub)
- `/dev/r10/vm-tpl-part-boot-stretch-root`: disk containing the root filesystem

## On new kvm hosts

Create a playbooks directory for the host incl. the required `vars` symlink:

```sh
mkdir "playbooks/$(hostname -s)"
ln -s ../../vars "playbooks/$(hostname -s)/vars"
```

## Create a vm

First generate a mac address for the new vm:

```sh
scripts/macgen
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

## bootstrap script

### create package lists

To bootstrap a system using standard packages, you can create 3 files corresponding to the apt package priorities. Run the following `aptitude` commands on a running system with the target release to generate the list of packages:

```
aptitude search --display-format "%p" '~prequired' > required
aptitude search --display-format "%p" '~pimportant' > important
aptitude search --display-format "%p" '~pstandard' > standard
```

Place the files in the following location:

```
scripts/bootstrap/packages/<dist>/<release>/
```

To install some extra packages, write a list of packages in:

```
scripts/bootstrap/packages/<dist>/<release>/install
```

To purge some unwanted packages, write a list of packages in:

```
scripts/bootstrap/packages/<dist>/<release>/purge
```
