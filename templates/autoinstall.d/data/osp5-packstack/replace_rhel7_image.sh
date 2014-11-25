#!/bin/bash

source ./subr.sh

srchost=ori@10.0.1.253
src=rhel-guest-image-7.0-20140909.0.x86_64.img
name=rhel7

source ~/keystonerc_admin
glance image-delete ${name}
scp ${ssh_options} ${srchost}:${src} ./images/
glance image-create --name ${name} --is-public true --disk-format qcow2 --container-format bare --file ./images/${src}
