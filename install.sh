#!/bin/bash

error_exit() {
    echo "Ошибка: $1"
    exit 1
}


PLATFORM=$(uname -s) || error_exit "Не удалось определить платформу."
echo "Платформа: $PLATFORM"


case $PLATFORM in
    Linux)
        echo "Платформа Linux обнаружена"
        
        # Проверка наличия apt
        if ! command -v apt &> /dev/null
        then
            error_exit "apt не найден. Установка в Linux должна быть выполнена с использованием apt."
        fi
        
        # Установка Python через apt
        sudo apt-get update || error_exit "Не удалось обновить списки пакетов."
        sudo apt-get install -y python3 python3-pip || error_exit "Не удалось установить Python через apt."
        ;;
    
    Darwin)
        echo "Платформа macOS обнаружена"
        
        # Проверка наличия Homebrew
        if ! command -v brew &> /dev/null
        then
            echo "Homebrew не найден. Устанавливаем Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || error_exit "Не удалось установить Homebrew."
        fi
        
        # Установка Python через Homebrew
        brew update || error_exit "Не удалось обновить Homebrew."
        brew install python || error_exit "Не удалось установить Python через Homebrew."
        ;;
    
    *)
        error_exit "Платформа $PLATFORM не поддерживается этим скриптом."
        ;;
esac



# Проверка установки Python и pip
if command -v python3 &> /dev/null && command -v pip3 &> /dev/null
then
    echo "Python и pip успешно установлены!"
    python3 --version
    pip3 --version
else
    error_exit "Ошибка: Python или pip не были установлены."
fi

#  Chech if Git installed. If not, install it
if ! command -v git &> /dev/null
then
    echo "Git не найден. Устанавливаем Git..."
    sudo apt-get install -y git || error_exit "Не удалось установить Git."
fi

# Clone repository from GitHub
git clone https://github.com/0ndrec/crocogaia.git || error_exit "Не удалось получить репозиторий Croco Gaia из GitHub."


cd crocogaia || error_exit "Не удалось перейти в каталог crocogaia."



# Установка библиотек из requirements.txt
if [ -f "requirements.txt" ]; then
    echo "Установка библиотек из requirements.txt..."
    pip3 install -r requirements.txt || error_exit "Не удалось установить библиотеки из requirements.txt."
else
    echo "Файл requirements.txt не найден, пропускаем установку зависимостей."
fi



SERVICE_FILE="/etc/systemd/system/crocogaia.service"

if [ -f "main.py" ]; then
    read -p "Хотите создать службу для запуска Croco Gaia? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo bash -c "cat > $SERVICE_FILE" <<EOL
[Unit]
Description=Gaia testing tool
After=network.target

[Service]
User=$(whoami)
WorkingDirectory=$(pwd)
ExecStart=$(which python3) $(pwd)/main.py
Restart=always

[Install]
WantedBy=multi-user.target
EOL

        # Перезагрузка systemd и активация службы
        sudo systemctl daemon-reload || error_exit "Не удалось перезагрузить systemd."
        sudo systemctl enable crocogaia.service || error_exit "Не удалось включить службу."
        # sudo systemctl start crocogaia.service || error_exit "Не удалось запустить службу."

        echo "Служба включена!"
        echo "Запуск службы: sudo systemctl start crocogaia.service"
        echo "Отключить службу: sudo systemctl stop crocogaia.service"
        echo "Состояние службы: sudo systemctl status crocogaia.service"
        echo "Мониторинг журнала службы: sudo journalctl -u crocogaia.service -f"
        sleep 2

        read -p "Хотите запустить скрипт ? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            python3 main.py
        else
            echo "Скрипт не запущен."
        fi
        python3 main.py

    else
        echo "Служба не создана."
    fi
else
    echo "Файл main.py не найден, пропускаем создание службы."
fi
