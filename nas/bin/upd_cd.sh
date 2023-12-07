#!/bin/sh
echo 'update privilege'
sed -i 's/package/root/g' /var/packages/CloudDrive2/conf/privilege
echo $0
