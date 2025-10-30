#!/bin/bash

if [ ! -f "config.conf" ]; then
  echo "Ошибка: Отсутствует файл config.conf"
  exit 1
fi

source config.conf

if [ -z "${DIR_PATH+x}" ]; then
  echo "Ошибка: Переменная DIR_PATH отсутствует в файле config.conf"
  exit 1
fi

cd "$DIR_PATH" &>/dev/null || {
  echo "Ошибка: Не удалось перейти в директорию '$DIR_PATH'"
  exit 1
}

check_upstream() 
{
  if ! git remote get-url upstream &>/dev/null; then
    echo "Upstream не настроен"
    echo "Для настройки введите команды:"
    echo "cd $DIR_PATH"
    echo "git remote get-url upstream <repository_link>" 
    return 1
  fi
  return 0
}

main()
{
  if check_upstream; then
    echo "ok"
  else 
    exit 1
  fi
}

main