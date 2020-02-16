#!/bin/bash

# Сценарий создает Wi-Fi точку доступа, к которой подключается фотоаппарат, и скачивает фото/видео программой Airnef

# !!! Важное примечание !!! Необходимо исключить строку 1137 в файле airnefcmd.py
# http://testcams.com/blog/forums/topic/canon-eos-m5-connection-refused/

#----------------------------------- Параметры -----------------------------------------------------------------------------------------------

adapter="wlp2s0"											# Имя Wi-Fi адаптера (можно определить в терминале командой ifconfig)
ssid="demonlibra-hotspot"									# Имя сети для создаваемой точки доступа (задать на свое усмотрение)
password="12345678"											# Пароль создаваемой точки доступа, который придется вводить в фотоаппарате
canon_mac="84:ba:3b:52:06:5a"								# MAC адрес фотоаппарата (можно найти в параметрах беспроводоной сети фотоаппарата)
hotspot_name="hotspotcanon"									# Имя соединения в списке NetworkManager (задать на свое усмотрение)
timeout=60													# Время ожидания подключения

pathairnef="$HOME/App/airnef/airnefcmd.py"					# Путь к файлу airnefcmd.py
pathout="/mnt/data/Airnef"									# Путь сохранения фото/видео

quality_jpg=85												# Процент сжатия фото после копирования

power_from_battery="Adapter 0: on-line"						# Только для ноутбуков. Выполните в терминале "apci -a" при работе от батареи

#---------------------------------------------------------------------------------------------------------------------------------------------

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
		nmcli device wifi hotspot ssid "$ssid" con-name "$hotspot_name" password "$password"

		for ((i=$timeout; i>1; i--))	# Цикл проверки подключения камеры к точке доступа
			do
				sleep 1
				if [[ `iw dev $adapter station dump | grep "$canon_mac"` ]]
					then
						check=`arp | grep $canon_mac`
						canon_ip=`echo ${check%%" "*}`
						
						if [[ "$canon_ip" ]]
							then
								echo; echo "IP адрес камеры: "$canon_ip
								
								# Запускаем airnef и копируем файлы из фотоаппарата в каталог pathout
								python "$pathairnef" --ipaddress "$canon_ip" --outputdir "$pathout"

								# Сжатие новых фотографий
								find "$pathout" -iname "*.JPG" | sort | while IFS= read -r file
									do
										if [[ `identify -format '%Q' "$file"` -gt "$quality_jpg" ]] # Выполнять сжатие для файлов без сжатия
											then 
												# Сжимаем фото
												echo; echo --------------------------------; echo
												convert -quality "$quality_jpg" -verbose "$file" "$file"
												echo; echo --------------------------------; echo;
										fi
									done
												
								i=0										# Обнуляем обратный отсчет подключения для завершения цикла
								echo
								nmcli connection down "$hotspot_name"	# Выключаем точку доступа
						fi
					else
						clear
						echo "# Включите фотоаппарат и выберите тип подключения Smartphone. Осталось секунд: $i"
				fi
			done
			
			#Выключаем wifi, если питание от аккумулятора
			if [[ `acpi -a` != "$power_from_battery" ]]
				then
					nmcli radio wifi off
			fi

			echo; echo --------------------------------; echo; echo "Скачивание и сжатие завершено"; echo; read -p "Нажмите ENTER чтобы закрыть окно"
fi

exit 0
