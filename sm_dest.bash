#!/bin/bash

# Объявление ассоциативного массива
declare -A user_host_map

# Массив с именами узлов
hosts=()
for i in $(seq -f "fx%02g" 1 38); do
    hosts+=($i)
done

# Имя пользователя и пароль для SSH
ssh_user="golovin"
ssh_password=""
source_folder="/home/golovin/Documents/build"

log_file="copy_log.txt"
users_file="users.txt"
> $log_file


# Цикл для подключения к каждому узлу
for host in "${hosts[@]}"; do
    echo "Подключение к $host..."

    # Выполнение команды 'who' через ssh
    output=$(sshpass -p $ssh_password ssh -o StrictHostKeyChecking=no $ssh_user@$host 'who')

    # Проверка на успешное подключение
    if [ $? -eq 0 ]; then
        # Извлечение имени пользователя из вывода команды 'who'
        username=$(echo $output | awk '{print $1}')

        # Добавление пары пользователь-хост в ассоциативный массив
        user_host_map[$username]=$host

        echo "Подключено к $host, имя пользователя: $username"
    else
        echo "Не удалось подключиться к $host"
    fi
done

# запишем список пользователей в файл;
users_file="users.txt"
> $users_file

# echo "Список пользователей и хостов:"
for user in "${!user_host_map[@]}"; do
    echo "$user - ${user_host_map[$user]}" >> $users_file
done
# echo $user_host_map >> $users_file
сat $users_file

# копируем файлы;
for user in "${!user_host_map[@]}"; do
    host=${user_host_map[$user]}
    if sshpass -p $ssh_password scp -rv $source_folder $user@$host:/home/$user/; then
        echo "$(date) - УСПЕХ: Копирование на $host для пользователя $user" >> $log_file
    else
        echo "$(date) - ОШИБКА: Копирование на $host для пользователя $user" >> $log_file
    fi
done

echo "Результаты копирования:"
cat $log_file
