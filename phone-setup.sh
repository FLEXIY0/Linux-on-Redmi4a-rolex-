#!/bin/sh
# Настройка Redmi 4A с postmarketOS одним скриптом:
#  - виртуальный рабочий стол VNC 1920x1080 с буфером обмена (порт 5901, автозапуск)
#  - кнопка питания: коротко — экран вкл/выкл, долго — выключение
#  - файрвол выключается (телефон за домашним роутером)
#  - пароль пользователя user меняется на 191321
# Запуск: sudo sh phone-setup.sh

[ "$(id -u)" = 0 ] || { echo "Запусти через sudo: sudo sh $0"; exit 1; }

echo "== Ставлю пакеты =="
apk add tigervnc || { echo "Не удалось поставить tigervnc"; exit 1; }
apk add triggerhappy 2>/dev/null || apk add evtest 2>/dev/null || \
    echo "ВНИМАНИЕ: не нашлось ни triggerhappy, ни evtest — кнопка работать не будет"

echo "== Кнопка питания: больше не выключает телефон коротким нажатием =="
mkdir -p /etc/systemd/logind.conf.d
printf '[Login]\nHandlePowerKey=ignore\nHandlePowerKeyLongPress=poweroff\n' \
    > /etc/systemd/logind.conf.d/10-powerkey.conf
systemctl restart systemd-logind || true

echo "== Переключатель подсветки =="
cat > /usr/local/bin/screen-toggle <<'EOF'
#!/bin/sh
B=$(ls /sys/class/backlight/*/brightness 2>/dev/null | head -1)
[ -n "$B" ] || exit 1
if [ "$(cat "$B")" -eq 0 ]; then
    cat "$(dirname "$B")/max_brightness" > "$B"
else
    echo 0 > "$B"
fi
EOF
chmod +x /usr/local/bin/screen-toggle

echo "== Вешаю переключатель на кнопку питания =="
if command -v thd >/dev/null 2>&1; then
    mkdir -p /etc/triggerhappy/triggers.d
    echo 'KEY_POWER 1 /usr/local/bin/screen-toggle' > /etc/triggerhappy/triggers.d/power.conf
    cat > /etc/systemd/system/powerkey.service <<'EOF'
[Unit]
Description=Power button toggles screen backlight (triggerhappy)

[Service]
ExecStart=/bin/sh -c 'exec /usr/sbin/thd --triggers /etc/triggerhappy/triggers.d/ --user root /dev/input/event*'
Restart=always

[Install]
WantedBy=multi-user.target
EOF
elif command -v evtest >/dev/null 2>&1; then
    cat > /usr/local/bin/powerkey-watch <<'EOF'
#!/bin/sh
DEV=$(awk '/pwrkey/{f=1} f && /Handlers/{for(i=1;i<=NF;i++) if($i ~ /^event/){print "/dev/input/"$i; exit}}' /proc/bus/input/devices)
[ -n "$DEV" ] || exit 1
evtest "$DEV" 2>/dev/null | while read -r line; do
    case "$line" in
        *"(KEY_POWER), value 1"*) /usr/local/bin/screen-toggle ;;
    esac
done
EOF
    chmod +x /usr/local/bin/powerkey-watch
    cat > /etc/systemd/system/powerkey.service <<'EOF'
[Unit]
Description=Power button toggles screen backlight (evtest)

[Service]
ExecStart=/usr/local/bin/powerkey-watch
Restart=always

[Install]
WantedBy=multi-user.target
EOF
fi
systemctl daemon-reload
systemctl enable --now powerkey.service 2>/dev/null || true

echo "== Виртуальный рабочий стол VNC 1920x1080 (порт 5901) =="
mkdir -p /home/user/.vnc
echo 191321 | vncpasswd -f > /home/user/.vnc/passwd
chmod 600 /home/user/.vnc/passwd
chown -R user /home/user/.vnc

cat > /usr/local/bin/vnc-desktop <<'EOF'
#!/bin/sh
/usr/bin/Xvnc :1 -geometry 1920x1080 -depth 24 -rfbauth /home/user/.vnc/passwd \
    -AlwaysShared -desktop rolex-remote &
XP=$!
sleep 2
export DISPLAY=:1
vncconfig -nowin &
icewm-session &
wait $XP
EOF
chmod +x /usr/local/bin/vnc-desktop

cat > /etc/systemd/system/vnc-desktop.service <<'EOF'
[Unit]
Description=Virtual VNC desktop (IceWM, 1920x1080, port 5901)
After=network.target

[Service]
User=user
ExecStart=/usr/local/bin/vnc-desktop
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now vnc-desktop.service

pkill x11vnc 2>/dev/null || true

echo "== Выключаю файрвол (телефон за домашним роутером) =="
systemctl disable --now nftables 2>/dev/null || true

echo "== Меняю пароль пользователя user (SSH и sudo) на 191321 =="
echo 'user:191321' | chpasswd

echo ""
echo "================= ГОТОВО ================="
echo "VNC с ПК:  TightVNC Viewer -> 192.168.0.108::5901   пароль: 191321"
echo "Буфер обмена между ПК и телефоном работает (текст)."
echo "Кнопка питания: коротко = экран вкл/выкл, ~10 сек = выключить телефон."
echo "Новый пароль SSH/sudo: 191321"
