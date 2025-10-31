#!/bin/bash

if [[ $# -eq 0 ]]; then
  PARAM="--help"
else
  PARAM="$1"
fi

is_script_ignored() {
  local script_name
  script_name=$(basename "$0")
  local global_excludes
  global_excludes=$(git config --global core.excludesFile)

  if [[ -n "$global_excludes" ]] && [[ -f "$global_excludes" ]] && grep -q "^${script_name}$" "$global_excludes"; then
    return 0
  else
    return 1
  fi
}

check_upstream() {
  if ! git remote get-url upstream &>/dev/null; then
    echo "Upstream не настроен"
    echo "Для настройки введите команду:"
    echo "git remote add upstream <repository_link>"
    return 1
  fi

  if [[ "$(git remote get-url upstream)" == "$(git remote get-url origin)" ]]; then
    echo "origin и upstream совпадают"
    echo "Измените ссылку на upstream с помощью команд:"
    echo "git remote remove upstream"
    echo "git remote add upstream <repository_link>"
    return 1
  fi

  return 0
}

merge_branches() {
  local skipped_branches=()
  local complete_branches=()
  local branch

  for branch in $(git branch --format='%(refname:short)'); do
    if [[ "$branch" != "master" ]]; then
      git switch "$branch"

      if git ls-remote --heads origin "$branch" | grep -q . && git merge master; then
        git push
        complete_branches+=("$branch")
      else
        if [[ "$PARAM" == "s" ]]; then
          git merge --abort
          skipped_branches+=("$branch")
        else
          if ! git ls-remote --heads origin "$branch" | grep -q .; then
            git merge master
          else 
            git push
          fi
          for complete_branch in "${complete_branches[@]}"; do
            echo "* $complete_branch"
          done
          return 0
        fi
      fi
    fi
  done

  for skipped_branch in "${skipped_branches[@]}"; do
    echo "* $skipped_branch"
  done

  git switch master &>/dev/null
  return 0
}

main() {
  case "$PARAM" in
    --help|-h)
      echo "ОПИСАНИЕ"
      echo "  Скрипт для синхронизации всех веток проекта с мастер-веткой"
      echo "  через upstream-репозиторий. Автоматически обновляет master"
      echo "  из upstream и мержит изменения во все остальные ветки."
      echo ""
      echo "ИСПОЛЬЗОВАНИЕ"
      echo "  ./$(basename "$0") [ПАРАМЕТР]"
      echo ""
      echo "ПАРАМЕТРЫ"
      echo "  -h, --help           Показать эту справку"
      echo "  -s, --skip-conflict  Пропускать ветки с конфликтами и выводить их"
      echo "  -c, --stop-conflict  Остановиться при первом конфликте и вывести обработанные"
      echo ""
      echo "ПРЕДВАРИТЕЛЬНЫЕ ТРЕБОВАНИЯ"
      echo "  • Настроен upstream-репозиторий:"
      echo "    git remote add upstream <repository_url>"
      echo "  • Доступ на push в origin-репозиторий"
      echo "  • Настройка игнорирования скрипта:"
      echo "    Если файла с игнором не было раньше"
      echo "    (проверить через git config --global core.excludesFile)"
      echo "       mkdir -p ~/.config/git/ && echo \"$(basename "$0")\" >> ~/.config/git/ignore"
      echo "       git config --global core.excludesFile ~/.config/git/ignore"
      echo "    Если файл был"
      echo "       echo \"$(basename "$0")\" >> \"\$(git config --global core.excludesFile)\""
      echo ""
      echo "ПРОЦЕСС РАБОТЫ"
      echo "  1. Переключение на master ветку"
      echo "  2. Получение изменений из upstream"
      echo "  3. Слияние upstream/master в локальный master"
      echo "  4. Push обновленного master в origin"
      echo "  5. Последовательное обновление всех веток проекта"
      echo ""
      echo "ПРИМЕРЫ"
      echo "  ./$(basename "$0") -c               # Остановка при конфликтах"
      echo "  ./$(basename "$0") -s               # Пропуск конфликтующих веток"
      echo "  ./$(basename "$0") -h               # Вывод справки"
      echo ""
      exit 0
      ;;
    --skip-conflict|-s)
      PARAM="s"
      ;;
    --stop-conflict|-c)
      PARAM="c"
      ;;
    *)
      echo "Неизвестный параметр: $PARAM" >&2
      exit 1
      ;;
  esac

  if ! is_script_ignored; then
    echo "WARNING! Скрипт не добавлен в ignore"
    echo "Используйте следующие команды:"
    if ! git config --global core.excludesFile &>/dev/null; then
      echo "mkdir -p ~/.config/git/ && echo \"$(basename "$0")\" >> ~/.config/git/ignore"
      echo "git config --global core.excludesFile ~/.config/git/ignore"
    else
      echo "echo \"$(basename "$0")\" >> \"\$(git config --global core.excludesFile)\""
    fi
    echo ""
  fi

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