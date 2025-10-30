#!/bin/bash

if [[ ! -f "config.conf" ]]; then
  echo "Ошибка: Отсутствует файл config.conf"
  exit 1
fi

source config.conf

if [[ -z "${DIR_PATH+x}" ]]; then
  echo "Ошибка: Переменная DIR_PATH отсутствует в файле config.conf"
  exit 1
fi

cd "$DIR_PATH" &>/dev/null || {
  echo "Ошибка: Не удалось перейти в директорию '$DIR_PATH'"
  exit 1
}

check_upstream() {
    
  if git remote get-url upstream &>/dev/null; then
    echo "Upstream уже настроен: $(git remote get-url upstream)"
    return 0
  else
    echo "Upstream не настроен" 
    pwd
    return 1
  fi
}

check_upstream