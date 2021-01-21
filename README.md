# dracut-luks-autounlock
 dracut + systemd + LUKS + usbflash
 
That project solve issue when you want auto unlock LUKS volumes with USB key but you're initramfs using systemd.

## Instalation
1. Place 99luks-auto inside /usr/lib/dracut/modules.d
2. chmod +x /usr/lib/dracut/modules.d/99luks-auto/*.sh
3. echo 'add_dracutmodules+=" luks-auto "' > /etc/dracut.conf.d/luks-auto.conf
4. dracut -f
