#!/bin/bash

if [[ $# -eq 0 ]]; then
    PARAM="--help"
else
    PARAM="$1"
fi

check_upstream() 
{
  if ! git remote get-url upstream &>/dev/null; then
    echo "Upstream не настроен"
    echo "Для настройки введите команду:"
    echo "git remote get-url upstream <repository_link>" 
    return 1
  fi
  if [ "$(git remote get-url upstream)" = "$(git remote get-url origin)" ]; then
    echo "origin и upstream совпадают"
    echo "Изменити ссылку на upstream с помощью команд:"
    echo "git remote remove upstream"
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
          echo "Обновленные ветки:"
          for branch in "${complete_branches[@]}"; do
            echo "* $branch"
          done
          if [ ${#my_array[@]} -eq 0 ]; then
            echo "Нет обновленных веток"
          fi
          return 0
        fi  
      fi
    fi
  done
  echo "Обновленные ветки:"
  for branch in "${complete_branches[@]}"; do
    echo "* $branch"
  done
  if [ ${#my_array[@]} -eq 0 ]; then
    echo "Нет обновленных веток"
  fi
  echo "Пропущенные ветки:"
  for branch in "${skipped_branches[@]}"; do
    echo "* $branch"
  done
  if [ ${#my_array[@]} -eq 0 ]; then
    echo "Нет пропущенных веток"
  fi
  return 0
}

main()
{
  case "$PARAM" in
    --help|-h)
      echo "ОПИСАНИЕ"
      echo "  Скрипт для синхронизации всех веток проекта с мастер-веткой"
      echo "  через upstream-репозиторий. Автоматически обновляет master"
      echo "  из upstream и мержит изменения во все остальные ветки."
      echo ""
      echo "ИСПОЛЬЗОВАНИЕ"
      echo "  ./update_repository.sh [ПАРАМЕТР]"
      echo ""
      echo "ПАРАМЕТРЫ"
      echo "  -h, --help           Показать эту справку"
      echo "  -s, --skip-conflict  Пропускать ветки с конфликтами"
      echo "  -c, --stop-conflict  Остановиться при первом конфликте (по умолчанию)"
      echo ""
      echo "ПРЕДВАРИТЕЛЬНЫЕ ТРЕБОВАНИЯ"
      echo "  • Настроен upstream-репозиторий:"
      echo "    git remote add upstream <repository_url>"
      echo "  • Доступ на push в origin-репозиторий"
      echo ""
      echo "ПРОЦЕСС РАБОТЫ"
      echo "  1. Переключение на master ветку"
      echo "  2. Получение изменений из upstream"
      echo "  3. Слияние upstream/master в локальный master"
      echo "  4. Push обновленного master в origin"
      echo "  5. Последовательное обновление всех веток проекта"
      echo ""
      echo "ПРИМЕРЫ"
      echo "  ./update_repository.sh -c               # Остановка при конфликтах"
      echo "  ./update_repository.sh -s               # Пропуск конфликтующих веток"
      echo "  ./update_repository.sh -h               # Вывод справки"
      echo ""
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