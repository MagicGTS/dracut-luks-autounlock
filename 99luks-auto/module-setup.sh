#!/bin/bash

check () {
        if ! dracut_module_included "systemd"; then
                "luks-auto needs systemd in the initramfs"
                return 1
        fi
        return 255
}

depends () {
        echo "systemd"
        return 0
}

install () {
        inst "$systemdutildir/systemd-cryptsetup"
		inst_simple "$moddir/luks.key" "/etc/luks.key"
		inst_script "$moddir/luks-auto-generator.sh" "$systemdutildir/system-generators/luks-auto-generator.sh"
		inst_script "$moddir/luks-auto-key.sh" "/etc/systemd/system/luks-auto-key.sh"
		inst_script "$moddir/luks-auto.sh" "/etc/systemd/system/luks-auto.sh"
		inst "$moddir/luks-auto.target" "${systemdsystemunitdir}/luks-auto.target"
		inst "$moddir/luks-auto-key.service" "${systemdsystemunitdir}/luks-auto-key.service"
		inst "$moddir/luks-auto-clean.service" "${systemdsystemunitdir}/luks-auto-clean.service"
		ln_r "${systemdsystemunitdir}/luks-auto.target" "${systemdsystemunitdir}/initrd.target.wants/luks-auto.target"
		ln_r "${systemdsystemunitdir}/luks-auto-key.service" "${systemdsystemunitdir}/initrd.target.wants/luks-auto-key.service"
		ln_r "${systemdsystemunitdir}/luks-auto-clean.service" "${systemdsystemunitdir}/initrd.target.wants/luks-auto-clean.service"
}
