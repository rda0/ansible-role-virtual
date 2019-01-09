#!/bin/sh

TARGET='/target'
chroot $TARGET

export DEBIAN_PRIORITY=critical
export DEBIAN_FRONTEND=noninteractive
apt-get install -y lsb-release

if [ $(lsb_release -s -i) = 'Ubuntu' ]; then
    if ! which wget; then
        apt-get install -y wget
    fi
fi

/bin/sed 's/\PermitRootLogin\ yes/PermitRootLogin\ without-password/' -i /etc/ssh/sshd_config
/bin/mkdir /root/.ssh/
/bin/chmod 700 /root/.ssh/ ; \
/bin/echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDonNLHO7lFg6Zbv+0MRj/uSziIHeC3D7igNmiSqOiw03eaXE9gFzET1rQ+7Uh4syb0ZXaVzmFeqRk8SKmtMwFII0m+pJfkHlzBBwIYUCFtwaAmWep+gsJDo6Bzf1ubxoM3iYM4NYc87NyuB0V7jrbkFktiDBHI+yqAzNSzURofHY4R1tzqiUFwJ7Vo8U2Cy22NvkHUFtNShBy1DwoksZYblYssI8b6uMWY7i97kQsHlOPVnTYpmCYBiylYHwiG4Z2Qo+nMG6Q1pSbTHm9Ig6daoP6Jq2k9KGQ5LiVDsdb8YQVWpXgAzOci1v779QB43diBvPaOZDJ9KhDDd1hPxkEUJGD5C2fZrNSuiapzhFaYZv70UqDQgIvDuL5mT0SjXhxBw4VN+AIVwSs7MX1E1vJ1AcRt7pL7LJV3AYMK+BENRfxrHwR/xv1jgN8UlrsxZo/oVDf6whQuJaVHK7HDFJ/jkhM0AjLKP6NngazepXxsFbtvWaHfBHnKjdy9QrhWUwS4ZdfK95idpHdN7Wx7AVwV4yAi+sPuiU0MyIfuAfka28TPeQDPLZ6Wb1rjcBBiu4jp4haRCjempOizhJPRNtCS31YZBAZ9LMJ90MiXfxIqpNs8ZTexB5sK9LthDWEofR+YJUEBc28v3Xvn0A5fU15vPfJd8qXeKqRz8L/tLPH+Sw== maedersv@snidget" >> /root/.ssh/authorized_keys ; \
/bin/chmod 600 /root/.ssh/authorized_keys ; \

sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT=""/g' /etc/default/grub
sed -i 's/#GRUB_TERMINAL=console/GRUB_TERMINAL="serial console"/g' /etc/default/grub
update-grub

cat > /usr/local/bin/ansible-notify.sh << 'EOF'
#!/bin/bash

HOSTNAME="$(hostname -s)"
IP="$(host ${HOSTNAME} | grep -iEo '[.0-9]+$')"
GET "http://{{ ansible_fqdn }}/webapp/index?hostname=${HOSTNAME}&ip=${IP}"
EOF

chmod +x /usr/local/bin/ansible-notify.sh

cat > /etc/systemd/system/ansible-notify.service << 'EOF'
[Unit]
After=sshd.service network.target network-online.target

[Service]
ExecStart=/usr/local/bin/ansible-notify.sh

[Install]
WantedBy=default.target
EOF

ln -s /etc/systemd/system/ansible-notify.service /etc/systemd/system/multi-user.target.wants/ansible-notify.service

exit
