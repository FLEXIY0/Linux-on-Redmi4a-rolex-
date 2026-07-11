#!/bin/sh -e
# Сборка образа postmarketOS для Xiaomi Redmi 4A (rolex, порт qcom-msm89x7) с IceWM.
# Требования: Linux, git, python3, kpartx, losetup, binfmt_misc, ~10 ГБ диска.

PMB_DIR="${PMB_DIR:-$HOME/pmbootstrap}"
PASSWORD="${PASSWORD:-postmarketos}"

if [ ! -d "$PMB_DIR" ]; then
    git clone --depth 1 https://gitlab.postmarketos.org/postmarketOS/pmbootstrap.git "$PMB_DIR"
fi
PMB="$PMB_DIR/pmbootstrap.py"
[ "$(id -u)" = 0 ] && PMB="$PMB --as-root"

# Первичная инициализация с ответами по умолчанию (если конфига ещё нет)
if [ ! -e "$HOME/.config/pmbootstrap_v3.cfg" ]; then
    yes '' | $PMB init
fi

$PMB config device qcom-msm89x7
$PMB config ui console
$PMB config extra_packages "icewm,xorg-server,xf86-input-libinput,xterm,xinit,font-terminus"
$PMB config hostname rolex
$PMB config user user
# Не пересобирать устаревшие пакеты из исходников — брать готовые бинарники
$PMB config build_pkgs_on_install False

$PMB install --password "$PASSWORD"

echo "Готово. Образы:"
ls -lh "$($PMB config work | tail -1)/chroot_native/home/pmos/rootfs/" 2>/dev/null || \
    ls -lh "$HOME/.local/var/pmbootstrap/chroot_native/home/pmos/rootfs/"
