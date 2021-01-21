#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

. /lib/dracut-lib.sh

SYSTEMD_RUN='/run/systemd/system'
CRYPTSETUP='/usr/lib/systemd/systemd-cryptsetup'
TOUT=$(getargs rd.luks.key.tout)
if [ ! -z "$TOUT" ]; then
	mkdir -p "${SYSTEMD_RUN}/luks-auto-key.service.d"
	cat > "${SYSTEMD_RUN}/luks-auto-key.service.d/drop-in.conf"  <<EOF
[Service]
Type=oneshot
ExecStartPre=/usr/bin/sleep $TOUT

EOF
fi
mkdir -p "$SYSTEMD_RUN/luks-auto.target.wants"
for argv in $(getargs rd.luks.uuid -d rd_LUKS_UUID); do
	_UUID=${argv#luks-}
	_UUID_ESC=$(systemd-escape -p $_UUID)
	mkdir -p "${SYSTEMD_RUN}/systemd-cryptsetup@luks\x2d${_UUID_ESC}.service.d"
	cat > "${SYSTEMD_RUN}/systemd-cryptsetup@luks\x2d${_UUID_ESC}.service.d/drop-in.conf"  <<EOF
[Unit]
After=luks-auto.target
ConditionPathExists=!/dev/mapper/luks-${_UUID}

EOF
	cat > "${SYSTEMD_RUN}/luks-auto@${_UUID_ESC}.service"  <<EOF
[Unit]
Description=luks-auto Cryptography Setup for %I
DefaultDependencies=no
Conflicts=umount.target
IgnoreOnIsolate=true
Before=luks-auto.target
BindsTo=dev-disk-by\x2duuid-${_UUID_ESC}.device
After=dev-disk-by\x2duuid-${_UUID_ESC}.device luks-auto-key.service
Before=umount.target

[Service]
Type=oneshot
RemainAfterExit=yes
TimeoutSec=0
ExecStart=/etc/systemd/system/luks-auto.sh ${_UUID}
ExecStop=$CRYPTSETUP detach 'luks-${_UUID}'
Environment=DRACUT_SYSTEMD=1
StandardInput=null
StandardOutput=syslog
StandardError=syslog+console

EOF
ln -fs ${SYSTEMD_RUN}/luks-auto@${_UUID_ESC}.service $SYSTEMD_RUN/luks-auto.target.wants/luks-auto@${_UUID_ESC}.service
done
