#!/bin/bash

HOSTNAME="$(hostname -s)"
IP="$(host ${HOSTNAME} | grep -iEo '[.0-9]+$')"
GET "http://phd-kvm1.ethz.ch/webapp/index?hostname=${HOSTNAME}&ip=${IP}"
