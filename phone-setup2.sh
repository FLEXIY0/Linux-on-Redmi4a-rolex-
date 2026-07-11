#!/bin/sh
# Доводка Redmi 4A с postmarketOS:
#  - чиним VNC-рабочий стол (IceWM реально запускается, панель, меню, буфер обмена)
#  - разрешение под монитор (по умолчанию 1920x1080, можно задать: RES=1600x900 sudo sh ...)
#  - Bluetooth (bluez + blueman)
#  - файловый менеджер и терминал в меню
# Запуск: sudo sh phone-setup2.sh   (пароль sudo: 191321)

[ "$(id -u)" = 0 ] || { echo "Запусти через sudo: sudo sh $0"; exit 1; }
RES="${RES:-1920x1080}"

echo "== Ставлю пакеты (bluetooth, панель, менеджер файлов) =="
apk add bluez blueman icewm xterm pcmanfm tigervnc \
    xf86-video-fbdev ttf-dejavu 2>&1 | tail -3

echo "== Включаю Bluetooth =="
# нужны модули и демон
modprobe hci_uart 2>/dev/null; modprobe btqca 2>/dev/null; modprobe bluetooth 2>/dev/null
systemctl enable --now bluetooth 2>/dev/null || rc-update add bluetooth default 2>/dev/null
# питание bt-контроллера
(sleep 3; bluetoothctl power on) >/dev/null 2>&1 &

echo "== Чиню VNC-рабочий стол =="
# Нормальный xstartup: гарантированно поднимаем IceWM + буфер обмена + фон
mkdir -p /home/user/.vnc
cat > /home/user/.vnc/xstartup <<'EOF'
#!/bin/sh
unset SESSION_MANAGER DBUS_SESSION_BUS_ADDRESS
export XDG_RUNTIME_DIR=/tmp/xdg-user
mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"
vncconfig -nowin &          # синхронизация буфера обмена ПК<->телефон
xsetroot -solid "#2e3440"   # ровный фон вместо мусора
icewmbg &                   # фон/обои IceWM
icewm-session               # сам оконный менеджер (держит сессию живой)
EOF
chmod +x /home/user/.vnc/xstartup
chown -R user:user /home/user/.vnc

# Меню IceWM: добавим приложения, если их там нет
mkdir -p /home/user/.icewm
cat > /home/user/.icewm/menu <<'EOF'
prog "Terminal" xterm xterm
prog "Files" pcmanfm pcmanfm
prog "Bluetooth" blueman blueman-manager
prog "Web (если есть)" firefox firefox
EOF
chown -R user:user /home/user/.icewm

echo "== Перезапускаю виртуальный стол в разрешении $RES =="
cat > /usr/local/bin/vnc-desktop <<EOF
#!/bin/sh
/usr/bin/Xvnc :1 -geometry $RES -depth 24 -rfbauth /home/user/.vnc/passwd \\
    -AlwaysShared -SecurityTypes VncAuth -desktop rolex-remote > /tmp/xvnc.log 2>&1 &
XP=\$!
sleep 2
HOME=/home/user DISPLAY=:1 /home/user/.vnc/xstartup > /tmp/xstartup.log 2>&1 &
wait \$XP
EOF
chmod +x /usr/local/bin/vnc-desktop
systemctl restart vnc-desktop.service 2>/dev/null || systemctl start vnc-desktop.service

echo ""
echo "================= ГОТОВО ================="
echo "VNC:  TightVNC Viewer -> 192.168.0.108::5901   пароль: 191321"
echo "Разрешение: $RES  (сменить: RES=1600x900 sudo sh $0)"
echo "В окне VNC жми Full screen (кнопка с 4 стрелками) — будет как рабочий стол."
echo "Меню IceWM — клик по панели внизу или ПКМ по фону."
echo "Bluetooth: меню -> Bluetooth (blueman)."
echo "Если Bluetooth не появился — напиши, проверим модули ядра."
