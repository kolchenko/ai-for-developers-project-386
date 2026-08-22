### Hexlet tests and linter status:
[![Actions Status](https://github.com/kolchenko/ai-for-developers-project-386/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/kolchenko/ai-for-developers-project-386/actions)

## Деплой

Публичная ссылка на опубликованное приложение: <https://call-calendar-kid4.onrender.com>

Приложение упаковано в Docker-образ (см. `Dockerfile`) и запускается в контейнере на порту из переменной окружения `PORT`. Деплой на Render выполнен через GitHub-репозиторий: Render собирает образ из `Dockerfile` в `master` и запускает сервис на публичном URL выше.