#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
export DRACUT_SYSTEMD=1
. /lib/dracut-lib.sh

MNT_B="/tmp/luks-auto"
CRYPTSETUP='/usr/lib/systemd/systemd-cryptsetup'

for i in $(ls -p $MNT_B | grep -v /);do
	info "Trying $i on $1..."
	$CRYPTSETUP attach "luks-$1" "/dev/disk/by-uuid/$1" $MNT_B/$i 'tries=1'
	if [ "$?" -eq "0" ]; then
		info "Found $i for $1"
		exit 0
	fi
done
warn "No key found for $1.  Fallback to passphrase mode."
