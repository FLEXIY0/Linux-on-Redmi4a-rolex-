# Готовые образы

postmarketOS edge (aarch64, порт `qcom-msm89x7`) для Xiaomi Redmi 4A (rolex),
консольный UI + IceWM. Пользователь `user`, пароль `postmarketos`.

Образ разбит на части из-за лимита GitHub в 100 МБ на файл. Собрать обратно:

```sh
cat postmarketos-redmi4a-rolex-icewm.img.xz.part* > postmarketos-redmi4a-rolex-icewm.img.xz
sha256sum -c SHA256SUMS   # проверка (части + итоговый файл)
xz -d postmarketos-redmi4a-rolex-icewm.img.xz
```

Дальше прошивка — см. корневой `README.md` (lk2nd в boot, образ в userdata).
