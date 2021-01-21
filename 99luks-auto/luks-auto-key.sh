#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
export DRACUT_SYSTEMD=1

. /lib/dracut-lib.sh
MNT_B="/tmp/luks-auto"
ARG=$(getargs rd.luks.key)
IFS=$':' _t=(${ARG})
KEY=${_t[0]}
F_FIELD=''
F_VALUE=''
if [ ! -z $KEY ] && [ ! -z ${_t[1]} ];then
	IFS=$'=' _t=(${_t[1]})
	F_FIELD=${_t[0]}
	F_VALUE=${_t[1]}
	F_VALUE="${F_VALUE%\"}"
	F_VALUE="${F_VALUE#\"}"
fi
mkdir -p $MNT_B

finding_luks_keys(){
	local _DEVNAME=''
	local _UUID=''
	local _TYPE=''
	local _LABEL=''
	local _MNT=''
	local _KEY="$1"
	local _F_FIELD="$2"
	local _F_VALUE="$3"
	local _RET=0	
	blkid -s TYPE -s UUID -s LABEL -u filesystem | grep -v -E -e "TYPE=\".*_member\"" -e "TYPE=\"crypto_.*\"" -e "TYPE=\"swap\"" | while IFS=$'' read -r _line; do
		IFS=$':' _t=($_line);
		_DEVNAME=${_t[0]}
		_UUID=''
		_TYPE=''
		_LABEL=''
		_MNT=''
		IFS=$' ' _t=(${_t[1]});
		for _a in "${_t[@]}"; do
			IFS=$'=' _v=(${_a});
			temp="${_v[1]%\"}"
			temp="${temp#\"}"
			case ${_v[0]} in
				'UUID')
					_UUID=$temp
				;;
				'TYPE')
					_TYPE=$temp
				;;
				'LABEL')
					_LABEL=$temp
				;;
			esac
		done
		if [ ! -z "$_F_FIELD" ];then
			case $_F_FIELD in
				'UUID')
					[ ! -z "$_F_VALUE" ] && [ "$_UUID" != "$_F_VALUE" ] && continue
				;;
				'LABEL')
					[ ! -z "$_F_VALUE" ] && [ "$_LABEL" != "$_F_VALUE" ] && continue
				;;
				*)
					[ "$_DEVNAME" != "$_F_FIELD" ] && continue
				;;
			esac
		fi
		_MNT=$(findmnt -n -o TARGET $_DEVNAME)
		if [ -z "$_MNT" ]; then
			_MNT=${MNT_B}/KEY-${_UUID}
			mkdir -p "$_MNT" && mount -o ro "$_DEVNAME" "$_MNT"
			_RET=$?
		else
			_RET=0
		fi
		if [ "${_RET}" -eq 0 ] && [ -f "${_MNT}/${_KEY}" ]; then
			cp "${_MNT}/${_KEY}" "$MNT_B/${_UUID}.key"
			info "Found ${_MNT}/${_KEY} on ${_UUID}"
		fi
		if [[ "${_MNT}" =~ "${MNT_B}" ]]; then
			umount "$_MNT" && rm -rfd --one-file-system "$_MNT"						
		fi
	done
	return 0
}
finding_luks_keys $KEY $F_FIELD $F_VALUE
