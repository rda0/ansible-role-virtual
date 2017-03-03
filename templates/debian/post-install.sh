#!/bin/sh

TARGET='/target'
chroot $TARGET

/bin/sed 's/\PermitRootLogin\ yes/PermitRootLogin\ without-password/' -i /etc/ssh/sshd_config
/bin/mkdir /root/.ssh/
/bin/chmod 700 /root/.ssh/ ; \
/bin/echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCiwnyZxVCZElbgeOnf8jjfgJlg42Hy43vZ755womYewhT7zPePkXSMWjfjBXXiZXqzy8SDXR+M+qhv+Fsf+FpraAc8k1dEVA0EFWrEE3xryyZklJxuIprDjy2AaXjTP7D/cIliKQOMDA2tNh76Hb0PaZD8Ytn+OX1K9UgCEo8LiPjswH3IY+ZBwXzIVVpn/S8rQhZ9fvHoawyu+wv2NTk2LPE6/sR9BlrXgjL2GwkF3hZUCoMGxnGAfHHy4j4Ak4DuCET9vOe9mJ8kbHVNw7bKraSY837UDulnzHA7MWiXichnUXpV7sV32V6SsCAoZXscakQbnaWrB7fxUwYYhICYIrlV1kibdeoLvwiHjWJbCtRTlLQ+s1SZ79gkL/U4U8pNfADtsT/QlU+3wueFz5c43/PkVwTbJYhLrx+Zl6qeowTJ2mT9QxZoCSRn0s6EgHg7m7Fd/9q6pEZ8WbjBVGT55gbsykAz7n/kSAu9/R/Nq1qBbtqEcC+tGahmTUQSHDaGevdI0BgJb4UUKh96BxkPF4sOE9WLeG6W8091DMadLbLl+Yy6zxfGyXJrGiam6Q7X3WVYjghjBgfhRo0iVztqVKtatRylkF7Vjw9tD6nBhyCyjZA2ul1VK6Hh/2FEOTHvt0Ta3Q6MnCV+YN4LaMNW0nJN1gExQNA67D8ne7NKBw== root@baal" > /root/.ssh/authorized_keys ; \
/bin/chmod 600 /root/.ssh/authorized_keys ; \

exit
