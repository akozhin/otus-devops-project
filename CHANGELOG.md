# CHANGELOG

**2019-07-16** Maksim Soldatov

- настроен CI/CD с использованием GitLab
- добавлены Persistent Volumes для CI/CD
- доработан helm cart приложений для CI/CD
- внесены небольшие корректировки в разные части проекта для CI/CD, в том числе для устранения неточностей

**2019-07-14** Maksim Soldatov

- создан dashboard для приложения Search-UI

**2019-07-13** Maksim Soldatov

- настроен мониторинг компонентов приложения
- настроено оповещение (alerts)

**2019-07-11** Alexandr Kozhin

- настроены стандартные helm чарты для mongodb и rabbitmq
- добавлены helm чарты для приложений
- добавлен helm чарт с зависимостями
- добавлено описание проекта

**2019-07-11** Maksim Soldatov

- добавлен  volumes для mongodb и rabbitmq

**2019-07-10** Alexandr Kozhin

- добавлены стандартные helm чарты для mongodb и rabbitmq

**2019-07-10** Maksim Soldatov

- настроена интеграция GitLab с Kubernetes, в интеграции с кластером установлены приложения GitLab: Helm Tiller, GitLab Runner

**2019-07-09** Maksim Soldatov

- добавлена роль nfs
- добавлены манифесты для volumes prometheus 
- добавлен prometheus chart
- добавлен grafana chart
- добавлен балансировщик на kube_nodes
- исправлены некоторые ошибки

**2019-07-08** Maksim Soldatov

- добавлены роли ansible для подготовки серверов
- добавлены роли ansible для установки/управления docker
- в конфигурацию terraform добавлен сервер gitlab
- исправлены некоторые ошибки

**2019-07-07** Alexandr Kozhin

- добавлены Dockerfile-ы для приложений
- добавлен docker-compose
- проверена работа локальная работа приложения в docker контейнерах

**2019-07-07** Maksim Soldatov

- добавлена конфигурация terraform для серверов kuibernetes
- настроен динамический inventory для ansible
- добавлена ansible конфигурация для kubernbetes
- запущен kubernetes с использованием kubersparay
