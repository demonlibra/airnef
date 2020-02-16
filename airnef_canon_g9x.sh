#!/bin/bash

# Скрипт создает Wi-Fi точку доступа, к которой подключается фотоаппарат, и скачивает фото/видео программой Airnef

# !!! Важное примечание !!! Необходимо исключить строку 1137 в файле airnefcmd.py
# http://testcams.com/blog/forums/topic/canon-eos-m5-connection-refused/

adapter="wlp2s0"											# Имя Wi-Fi адаптера (можно определить в терминале командой ifconfig)
ssid="demonlibra-hotspot"									# Имя сети для создаваемой точки доступа
password="12345678"											# Пароль создаваемой точки доступа, который придется вводить в фотоаппарате
canonmac="84:ba:3b:52:06:5a"								# MAC адрес фотоаппарата (можно найти в параметрах беспроводоной сети фотоаппарата)
conname="hotspotcanon"										# Имя соединения в списке NetworkManager
pathairnef="/home/demonlibra/App/airnef/airnefcmd.py"		# Путь к программе Airnef
pathout="/mnt/data/Airnef"									# Путь для копирования файлов из фотоаппарата
quality_jpg=85												# Процент сжатия фото

# Включаем wifi, если выключен
if [[ `nmcli radio wifi` = "disabled" ]]
	then
		echo "Включаем Wi-Fi"
		nmcli radio wifi on
		sleep 1
	fi

if [[ `nmcli radio wifi` = "enabled" ]]
	then
		# Создаем точку доступа
		nmcli device wifi hotspot ssid "$ssid" con-name "$conname" password "$password"
		timeout=60
		for ((i=$timeout; i>1; i--))
			do
				sleep 1
				if [[ `iw dev $adapter station dump | grep $canonmac` ]]
					then
						check=`arp | grep $canonmac`
						canonip=`echo ${check%%" "*}`

						# Запускаем airnef и копируем файлы из фотоаппарата в каталог pathout
						python $pathairnef --ipaddress $canonip --outputdir $pathout

						# Сжатие новых фотографий
						find "$pathout" -iname "*.JPG" | sort | while IFS= read -r file
							do
								if [[ `identify -format '%Q' "$file"` > 95 ]]
									then 
										# Сжимаем фото
										echo; echo --------------------------------; echo
										convert -quality "$quality_jpg" -verbose "$file" "$file"
										echo; echo --------------------------------; echo;
								fi
							done
							
						i=0									# Обнуляем обратный отсчет подключения
						nmcli connection down "$conname"	# Выключаем точку доступа
					else
						echo "# Включите фотоаппарат и выберите тип подключения Smartphone. Осталось секунд: $i"
				fi
			done
			echo; echo --------------------------------; echo; echo "Скачивание и сжатие завершено"; echo; read -p "Нажмите ENTER чтобы закрыть окно"
fi

#Выключаем wifi, если питание от аккумулятора
if [[ `acpi -a` != "Adapter 0: on-line" ]]
	then
		nmcli radio wifi off
fi

exit 0
