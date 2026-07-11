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

## Прошивка

1. Разблокированный загрузчик обязателен.
2. Прошить lk2nd (один раз):
   ```sh
   fastboot flash boot lk2nd-msm8952.img   # берётся из чрута pmbootstrap
   ```
   Затем перезагрузиться, удерживая **Vol-Down**, чтобы попасть в fastboot самого lk2nd.
3. Прошить систему:
   ```sh
   pmbootstrap flasher flash_rootfs
   pmbootstrap flasher flash_kernel
   ```
   или вручную через fastboot в lk2nd:
   ```sh
   fastboot flash userdata qcom-msm89x7.img
   fastboot flash boot qcom-msm89x7-boot.img
   ```

Подробнее: https://wiki.postmarketos.org/wiki/Xiaomi_Redmi_4A_(xiaomi-rolex)
