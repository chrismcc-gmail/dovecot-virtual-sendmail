#!/bin/bash
dnf -y install epel-release
dnf -y install puppet 
dnf -y update
echo "run puppet with:"
echo "puppet apply --modulepath=`pwd` --verbose  manifests/init.pp"
