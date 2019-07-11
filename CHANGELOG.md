# CHANGELOG

**2019-07-10** Alexandr Kozhin

- настроены стандартные helm чарты для mongodb и rabbitmq
- добавлены helm чарты для приложений
- добавлен helm чарт с зависимостями
- добавлено описание проекта


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
