# postmarketOS для Xiaomi Redmi 4A (rolex)

Сборка образа postmarketOS (edge) для Redmi 4A с оконным менеджером **IceWM**.

Устройство поддерживается через обобщённый mainline-порт **`qcom-msm89x7`**
(Qualcomm MSM8917) с загрузчиком второго уровня **lk2nd**. Отдельный пакет
`device-xiaomi-rolex` в pmaports больше не существует — Redmi 4A входит в
msm89x7 (панели `panel_xiaomi_rolex_*` включены в initramfs).

## Состав образа

- Канал: `edge` (pmaports `main`), арх. `aarch64`
- Ядро: `linux-postmarketos-qcom-msm89x7` (mainline)
- UI: `console` + дополнительные пакеты:
  `icewm, xorg-server, xf86-input-libinput, xterm, xinit, font-terminus`
- Пользователь: `user`, пароль: `postmarketos`, hostname: `rolex`

После первого входа запуск IceWM:

```sh
echo "exec icewm-session" > ~/.xinitrc
startx
```

## Как собрать самому

```sh
./build.sh
```

Скрипт ставит pmbootstrap из GitLab, настраивает устройство `qcom-msm89x7`
и собирает образы. Результат: `qcom-msm89x7.img` (rootfs) и
`qcom-msm89x7-boot.img` в `~/.local/var/pmbootstrap/chroot_native/home/pmos/rootfs/`.

## Установка

**Скачать готовый образ одним файлом:**
[Releases](https://github.com/FLEXIY0/Linux-on-Redmi4a-rolex-/releases) —
там лежат `postmarketos-redmi4a-rolex-icewm.img.xz` (целиком, клеить ничего
не нужно) и `lk2nd.img`. Части в `images/` — запасной вариант
(см. `images/README.md`).

Понадобятся: кабель USB, `fastboot` (android-tools) и `xz` на компьютере.

1. Разблокированный загрузчик обязателен.
2. Прошить lk2nd (один раз) из обычного fastboot (Vol-Down + Power):
   ```sh
   fastboot flash boot lk2nd.img
   fastboot reboot
   ```
   При загрузке удерживать **Vol-Down**, чтобы попасть в fastboot самого lk2nd.
3. Распаковать и прошить систему в fastboot lk2nd:
   ```sh
   xz -d postmarketos-redmi4a-rolex-icewm.img.xz
   fastboot flash userdata postmarketos-redmi4a-rolex-icewm.img
   fastboot reboot
   ```
   Отдельный boot.img не нужен: образ содержит разделы pmOS_boot и pmOS_root,
   lk2nd грузит ядро через extlinux. При сборке через `./build.sh` то же самое
   делается командами `pmbootstrap flasher flash_lk2nd` и
   `pmbootstrap flasher flash_rootfs`.

Подробнее: https://wiki.postmarketos.org/wiki/Xiaomi_Redmi_4A_(xiaomi-rolex)
