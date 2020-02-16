#!/bin/bash

# Скрипт подключается к фотоаппарату через Wi-Fi и скачивает фото из видео из фотоаппарата программой Airnef

adapter="wlp2s0"										# Имя Wi-Fi адаптера
SSID="NikonP34040005585"								# SSID точки доступа фотоаппарата
pathairnef="/home/demonlibra/App/airnef/airnefcmd.py"		# Путь к программе AIRNEF
pathout="/mnt/data/Airnef"								# Путь для копирования файлов из фотоаппарата
quality_jpg=85												# Процент сжатия фото

# Включаем wifi, если выключен
if [[ `nmcli radio wifi` = "disabled" ]]
	then
		echo "Включаем Wi-Fi"
		nmcli radio wifi on
		sleep 5
	fi
	
nmcli -p radio wifi
echo --------------------------------

timeout=60

# Сканируем сеть и подключаемся к фотоаппарату
if [[ `nmcli radio wifi` = "enabled" ]] && [[ `iwgetid $adapter -r` != $SSID ]]; then
	for ((i=$timeout; i>1; i--))
		do
			nmcli device wifi rescan ifname $adapter					# Пересканировать беспроводоную сеть
			sleep 3
			if [[ `iwgetid $adapter -r` != $SSID ]]
				then
					check=`nmcli con show $SSID`					
					if [ $? = 0 ]
						then nmcli --wait 1 con up $SSID				# Проверяем существование ранее созданного соединения и соединяемся
						else nmcli --wait 1 dev wifi connect $SSID		# Или подключаемся с созданием нового соединения
					fi
			fi
			echo "# Включите фотоаппарат и активируйте wifi. Осталось секунд: $i"
			if [[ `iwgetid $adapter -r` = $SSID ]]; then i=0; fi
	done
fi

# Запускаем airnef и копируем файлы из фотоаппарата в каталог pathout
if [[ `nmcli radio wifi` = "enabled" ]] && [[ `iwgetid $adapter -r` = $SSID ]]
	then
		sleep 3
		python $pathairnef --outputdir $pathout

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
		echo; echo --------------------------------; echo; echo "Скачивание и сжатие завершено"; echo; read -p "Нажмите ENTER чтобы закрыть окно"
fi

#Выключаем wifi, если питание от аккумулятора
if [[ `acpi -a` != "Adapter 0: on-line" ]]
	then
		nmcli radio wifi off
fi

exit 0