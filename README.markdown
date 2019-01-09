# ansible-kvm

## Description

Install virtual machines using `kvm` and `ansible`

## Roles (installation methods)

- `vm-create`: creates a vm from 2 template lvms `boot` and `root` (preferred method for production)
- `vm-create-host-boot`: creates a vm from a template lvm `root` and boots the host kernel
- `vm-install`: install a vm using the installer and preseed file
- `vm-install-manual`: install a vm using manual installation via console

## Create vm template for roles `vm-create*`

This bootstraps a minimal system to lvms to be used as template disks for vms (required for roles `vm-create*`)

```
Usage: scripts/bootstrap vm vg dist release [options]

    Bootstraps a bootable kvm vm to lvm filesystem.

Options:

    vm
        Name of the vm (used for lvm naming)
    vg
        Volume group name
    dist
        Distribution name (debian, ubuntu)
    release
        Release name (stable, stretch, etc)
    vg
        Volume group name
    -b, --boot
        Size of boot disk lv (512M)
    -r, --root
        Size of root fs lv (2G)
    -h, --help
        Print this help message
```

Where `vm` is the base name of the lv to be created. The preferred naming sheme is: `vm-template-<dist_codename>`.

For example Debian 9 Stretch bootstrap:

```
scripts/bootstrap vm-template-stretch r10 debian stretch
```

This will create the 2 lvs:

- `/dev/r10/vm-template-stretch-boot`: disk containing grub in MBR and a boot partition
- `/dev/r10/vm-template-stretch-root`: disk containgin the root filesystem

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

To create a new vm named `foo`, start from the template playbook and copy it tho the kvm hosts playbook directory:

```sh
cp playbooks/new-vm-template.yml "playbooks/$(hostname -s)/foo.yml"
```

Edit the playbooks variables `guest_name`, `mac` and any other variables you would like to change (in this example the additional disks are removed):

```yml
---
- hosts: production
  vars:
    - dist: debian9
    - vm_template_vg: r10
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

Create the vm:

```sh
ansible-playbook playbooks/<hostname>/foo.yml
```
