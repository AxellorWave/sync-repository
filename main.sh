#!/bin/bash

if [[ $# -eq 0 ]]; then
    PARAM="--help"
else
    PARAM="$1"
fi

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

merge_branches()
{
  skipped_branches=()
  complete_branches=()
  for branch in $(git branch --format='%(refname:short)'); do
    if [ "$branch" != "master" ]; then
      git switch $branch
      if git merge master; then
        git push
        complete_branches+=("$branch")
      else
        if [$PARAM == 's']; then
          git merge --abort
          skipped_branches+=("$branch")
        else 
          echo "Конфликт. Ветка: $branch"
          echo "Обновленные ветки:"
          for branch in "${complete_branches[@]}"; do
            echo "* $branch"
          done
          return 0
        fi  
      fi
    fi
  done
  echo "Синхронизация окончена"
  echo "Обновленные ветки:"
  for branch in "${complete_branches[@]}"; do
    echo "* $branch"
  done
  echo "Пропущенные ветки:"
  for branch in "${skipped_branches[@]}"; do
    echo "* $branch"
  done
  return 0
}

main()
{
  case "$PARAM" in
    --help|-h)
        echo "Help text"
        exit 0
        ;;
    --skip-conflict|-s)
        $PARAM = "s"
        ;;
    --stop-conflict|-c)
        $PARAM = "c"
        ;;
    *)
        echo "Неизвестный параметр: $PARAM" >&2
        exit 1
        ;;
esac
  if check_upstream; then
    git switch master
    git fetch upstream
    git merge upstream/master
    git push
    merge_branches
  else 
    exit 1
  fi
}

main