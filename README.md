# Финальный проект по курсу Otus DevOps

**Участники:**

- Александр Кожин
- Максим Солдатов

**Требования к проекту:**

- [x] 1) Автоматизированные процессы создания и управления платформой

  - [x] Ресурсы GCP
  - [x] Инфраструктура для CI/CD
  - [x] Инфраструктура для сбора обратной связи

- [x] 2) Использование практики IaC (Infrastructure as Code) для управления конфигурацией и инфраструктурой 

- [x] 3) Настроен процесс CI/CD 

- [x] 4) Все, что имеет отношение к проекту хранится в GitТребования

- [x] 5) Настроен процесс сбора обратной связи 

  - [x] Мониторинг (сбор метрик, алертинг, визуализация) 
  - [ ]  Логирование (опционально) 
  - [ ] Трейсинг (опционально) 
  - [ ]  ChatOps (опционально) 

- [x] 6) Документация 

  - [x] README по работе с репозиторием 
  - [x] Описание приложения и его архитектуры  (в ссылках к готовым приложениям, которые использованы в проекте)
  - [x] How to start (по ходу README)
  - [x] CHANGELOG с описанием выполненной работы 
  - [x] Если работа в группе, то пункт включает автора изменений

**За основу взяты готовые приложения: **

- [Search engine crawler](https://github.com/express42/search_engine_crawler)
- [Search engine UI](https://github.com/express42/search_engine_ui)

**Ссылки на сервисы проекта:**

| Сервис                                | Адрес                            |
| ------------------------------------- | -------------------------------- |
| Приложение поиска (prod окружение)    | http://otus.4ippi.ru/            |
| Gitlab                                | http://gitlab.otus.4ippi.ru/     |
| Grafana                               | http://grafana.otus.4ippi.ru/    |
| Prometheus                            | http://prometheus.otus.4ippi.ru/ |
| Приложение поиска (staging окружение) | http://staging.otus.4ippi.ru/    |
| Приложение поиска (review окружение)  | Wildcard DNS запись              |

## Подготовка инфраструктуры с использованием trerraform

Хранение состояния terraform реализовано на стороне GCP, для этого подними сегмент в GCP.

```sh
cd infra/terraform/backend_tfstate/
terraform init
terraform apply
```

 Типы серверов реализованы модулями, и включают:

- ВМ для k8s master;
- ВМ для k8s node и LoadBalancer для k8s node;
- ВМ для gitlab

Необходимые правила файервола для типа сервера содержаться в соответствующем  модуле.

Любой из типов серверов может масштабироваться указанием переменной `instance_pool_count_*`

Созданные модули типов серверов параметризированы.

Поднимаем инфраструктуру проекта:

```sh
cd infra/terraform/stage/
terraform init
terraform apply
```



## DNS

В качестве DNS сервера использован один из бесплатных сервисов, в который по ходу развертывания проекта вносились `A` записи:

- otus.4ippi.ru - LoadBalancer для k8s node поднятый terraform, использовано в качестве prod окружения приложения в ci/cd;
- staging.otus.4ippi.ru - использовано в качестве staging окружения приложения в ci/cd;
- gitlab.otus.4ippi.ru - GitLab;
- prometheus.otus.4ippi.ru - Prometheus
- grafana.otus.4ippi.ru - Grafana
- для review окружения приложения в ci/cd, которое генерирует под домен использована Wildcard DNS запись типа `*.example.com`



## Подготовка ВМ с использованием ansible

### ansible inventory

Inventory выполнен в комбинации динамический + статический inventory.

Динамический inventoryвыполнен с использованием плагина gcp_compute. Статический inventoryнужен для создания родительских групп.

Структура inventory:

```
tree ansible/inventory/stage/
inventory/stage/
├── inventory.gcp.yml
└── inventory.static.yml
```

Для вызова одновременного вызова  динамический + статический inventory, указываем на директорию, а не на файл inventory.

Проверка динамического inventory:

```rst
cd ansible
ansible-inventory -i inventory/stage/ --graph

@all:
  |--@etcd:
  |  |--104.155.1.48
  |--@k8s-cluster:
  |  |--@kube-master:
  |  |  |--104.155.1.48
  |  |--@kube-node:
  |  |  |--35.189.235.128
  |  |  |--35.241.223.209
  |--@nfs-server:
  |  |--35.241.246.199
  |--@repo:
  |  |--35.241.246.199
  |--@ungrouped:
  |  |--88fef22dD9adf7f3a6624CcdfB5F8Cf4B9DF3F2E973BB9cEc18250D5F5DBDBFC
  |  |--ktaeLCpR9JmdkUa
```

> Некоторые ссылки используемые в работе:
>
> - http://matthieure.me/2018/12/31/ansible_inventory_plugin.html



### Базовые роли ansible

Для подготовки серверов созданы базовые роли, которые используются в ansible playbook

- роль `common-pkg` - базовая роль, которая устанавливает небольшой набор инструментов
- роль `selinux` - отключает selinux на серверах

Остальные роли созданы по ходу развертывания проекта и будут описаны по мере необходимости.



## Развертывание k8s master

В рамках проекта было принято решение не использовать kubernets от google, а развернуть свой.

Развертывание k8s выполняется с использованием kuberspray v2.10.4, которая работает с kubernetes v1.14.3. 

Т.к. в бесплатном аккаунте есть ограничения по ресурсам, всего использовано 3 ВМ для кластера kubernetes:

kube_master - 1 ВМ, так же будет использоваться для хранения состояния кластера k8s в etcd ;

kube-node - 2 ВМ.

Получаем роль kubespray в локальную директорию

```sh
cd ansible
git clone https://github.com/kubernetes-sigs/kubespray.git

cd kubespray
git tags
git checkout v2.10.4
rm -Rf kubespray/.git
pip install -r requirements.txt #sudo?
```

Проверка доступности серверов:

```
cd ansible
ansible-inventory -i inventory/stage/ --graph
ansible -i inventory/stage/ kube-master -m ping
ansible -i inventory/stage/ kube-node -m ping
ansible -i inventory/stage/ etcd -m ping
ansible -i inventory/stage/ k8s-cluster -m ping
```

Подготовка сервера к развертыванию:

```sh
cd ansible

#selinux/packages
ansible-playbook -i inventory/stage/ -v -l k8s-cluster playbooks/prepare_server.yaml
ansible -i inventory/stage/ k8s-cluster -b -v -m command -a "reboot"
```

Создание кластера k8s:

Настройки хранятся в `ansible/inventory/stage/group_vars/k8s-cluster`

```sh
cd ansible
ansible-playbook --become -i inventory/stage/ kubespray/cluster.yml -v
```

Dashboard доступен по ссылке https://104.155.1.48:6443/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login

> Некоторые сложности возникшие при развертывании кластера kubernetes.
>
> Dashboard не заработал при использовании `kube_network_plugin: calico`, заработал `kube_network_plugin: flannel`
>
> https://github.com/kubernetes-sigs/kubespray/blob/master/docs/getting-started.md#accessing-kubernetes-dashboard
>



## Развертывание NFS-сервера

В связи с тем, что используем свой kubernetes, хоть и на серверах GCP, многие возможности не доступны.

Для Persistent Volume в kubernetes, кластерную ФС в рамках проекта поднимать не будем, будем использовать NFS.

Для создания NFS взята роль `geerlingguy.nfs` c ansible-galaxy. Получаем роль на локальный диск:

```sh
cd ansible
ansible-galaxy install geerlingguy.nfs --roles-path=roles
```

Разворачиваем NFS:

Настройки хранятся в `ansible/inventory/stage/group_vars/nfs-server.yml`

```sh
cd ansible
ansible-playbook -i inventory/stage/ -v -l repo playbooks/nfs.yaml
```



## Удаленное управление kubernetes

Для удаленного управления kubernetes понадобится kubectl и helm, настроим их.

### - kubectl

Установка kubectl

```sh
cd /tmp
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.14.3/bin/linux/amd64/kubectl

chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

При развертывании kubernetes была создана учетная запись администратора и возможностью авторизации по логину/паролю, используем ее для настройки kubectl

```sh
#подключаемся к удаленной ВМ
ssh appuser@104.155.1.48 -i ~/.ssh/appuser
sudo -s
#смотрим логин/пароль созданого администратора, отличного от kube
cat /etc/kubernetes/users/known_users.csv

#на локальном хосте выполняем настройку kubectl
kubectl config set-cluster otus-cluster --server=https://104.155.1.48:6443 --insecure-skip-tls-verify
kubectl config set-credentials admin-otus-cluster --username='<admin_user>' --password='<admin_password>'
kubectl config set-context admin@otus-cluster --cluster=otus-cluster --user=<admin_user>
kubectl config view
kubectl config use-context admin@otus-cluster

```

Проверка

```sh
kubectl version
Client Version: version.Info{Major:"1", Minor:"14", GitVersion:"v1.14.3", GitCommit:"5e53fd6bc17c0dec8434817e69b04a25d8ae0ff0", GitTreeState:"clean", BuildDate:"2019-06-06T01:44:30Z", GoVersion:"go1.12.5", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"14", GitVersion:"v1.14.3", GitCommit:"5e53fd6bc17c0dec8434817e69b04a25d8ae0ff0", GitTreeState:"clean", BuildDate:"2019-06-06T01:36:19Z", GoVersion:"go1.12.5", Compiler:"gc", Platform:"linux/amd64"}

kubectl get nodes
NAME             STATUS   ROLES    AGE    VERSION
104.155.1.48     Ready    master   2d4h   v1.14.3
35.189.235.128   Ready    <none>   33h    v1.14.3
35.241.223.209   Ready    <none>   2d4h   v1.14.3
```

> Некоторые ссылки используемые в работе:
>
> https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

### - helm

Установка helm

```sh
cd /tmp
wget https://get.helm.sh/helm-v2.13.1-linux-amd64.tar.gz
tar -xvzf helm-v2.13.1-linux-amd64.tar.gz
sudo mv linux-amd64/helm linux-amd64/tiller /usr/local/bin/
rm -R linux-amd64
```

Проверка

```sh
helm version
Client: &version.Version{SemVer:"v2.13.1", GitCommit:"618447cbf203d147601b4b9bd7f8c37a5d39fbb4", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.13.1", GitCommit:"618447cbf203d147601b4b9bd7f8c37a5d39fbb4", GitTreeState:"clean"}
```



## Развертывание GitLab

В рамках проекта развернут GitLab - Omnibus CE v12.0.3 на отдельном сервере с использованием ansible в docker 18.06 через docker-compose.

Для развертывания GitLab ansible:

- Для установки docker взята роль `geerlingguy.docker` с ansible-galaxy
- Для управления docker/docker-compose создана небольшая вспомогательная роль `docker.under.ansible`
- Для развертывания контейнера GitLab создана роль `gitlab`  в которой указана версия устанавливаемого GitLab

Подготовка сервера

```sh
cd ansible

#selinux/packages
ansible-playbook -i inventory/stage/ -v -l repo playbooks/prepare_server.yaml
ansible -i inventory/stage/ repo -b -v -m command -a "reboot"
```

Установка Gitlab

Настройки хранятся в `ansible/inventory/stage/group_vars/repo.yml`

```sh
cd ansible
ansible-playbook -i inventory/stage/ -v -l repo playbooks/gitlab.yaml
```

GitLab доступен по ссылке http://gitlab.otus.4ippi.ru/



## Развертывание Prometheus

За основу взят `stable/prometheus` https://hub.helm.sh/charts/stable/prometheus

Получаем prometheus на локальную диск

```sh
cd k8s/helm
helm repo update
helm fetch --untar stable/prometheus --version 8.14.1
```

Для хранения данных в volumes, созданы манифесты для PersistentVolumes и PersistentVolumeClaims

Применяем манифесты:

```sh
kubectl apply -f k8s/deployment/pv-prometheus-server.yml -n default
kubectl apply -f k8s/deployment/pv-prometheus-alertmanager.yml -n default
```

Настройки хранятся в `k8s/helm/prometheus/values.yaml`

Включены модули:

- alertmanager;
- kubeStateMetrics;
- nodeExporter;

Для prometheus сервера настроено:

- ingress;
- persistentVolume, который связан с заранее созданным запросом на том по имени `existingClaim` и классу `storageClassName`;
- включены jobs
  - job_name: prometheus
  - job_name: 'kubernetes-apiservers'
  - job_name: 'kubernetes-nodes'
  - job_name: 'kubernetes-nodes-cadvisor'
  - job_name: 'kubernetes-service-endpoints'
  - job_name: 'prometheus-pushgateway'
  - job_name: 'kubernetes-services'
  - job_name: 'kubernetes-pods'

Для alertmanager настроено:

- интеграция со slack каналом;
- persistentVolume, который связан с заранее созданным запросом на том по имени `existingClaim` и классу `storageClassName`;
- алерты
  - alert: InstanceDown
  - alert: InstanceAPIServerDown

Устанавливаем prometheus:

```sh
helm upgrade prometheus k8s/helm/prometheus --install
```

Prometheus доступен по ссылке http://prometheus.otus.4ippi.ru/



## Развертывание Grafana

За основу взят `stable/grafana` https://hub.helm.sh/charts/stable/grafana

Получаем grafana на локальный диск

```sh
cd k8s/helm
helm repo update
helm fetch --untar stable/grafana --version 3.5.8
```

Настройки хранятся в `k8s/helm/grafana/values.yaml`

Настраиваем:

- ingress;
- datasource Prometheus по умолчанию;
- провайдера dashboards (автоматически пока не подхватывается);
- базовые dashboards (автоматически пока не подхватывается);

Импортирован dashboard [Kubernetes cluster monitoring (via Prometheus)](https://grafana.com/dashboards/315)

Устанавливаем grafana:

```sh
GRAFANA_ADMIN_PASSWD=$(pwgen -n -c 8 1)

#без явного указания grafana/values.yaml не видел ingress/host/nodeport, как будто они не настроены
helm upgrade --install grafana stable/grafana -f grafana/values.yaml --set "adminPassword=${GRAFANA_ADMIN_PASSWD}"

#получить пароль
kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

Grafana доступна по ссылке http://grafana.otus.4ippi.ru



## Подготовка приложения

### Создание образов

Для сборки образов приложений добавлены Dockerfile-ы на основе `python:3.6-alpine`

**Локальная разработка**

Для локального запуска и тестирования добавлен compose-file, котоый включает mongodb и rabbitmq (версия с плагинами для управления).

```sh
docker-compose up -d
```

Интерфейс для управления rabbitmq доступен на порту 15672. 

При первом запуске необходимо создать очередь, с которой будет работать crawler.


### Сборка docker образов

Для сборки образов создан Makefile `services/Makefile`

```sh
cd services

# собрать и запушить образ
make docker-build-(ui|crawler)
make docker-push-(ui|crawler)

# собрать и запушить все образы
make all
```

### Создание Helm Charts

Созданы Helm Charts для каждого из компонентов приложения и главный Helm Chart приложения:

- компонент приложения mongodb
- компонент приложения rabbitmq
- компонент приложения search-ui
- компонент приложения crawler
- приложение search-engine

#### Компонент приложения mongodb

За основу взят `stable/mongodb` https://hub.helm.sh/charts/stable/mongodb/0.4.18

Получаем rabbitmq на локальный диск

```sh
cd services/helm
helm repo update
helm fetch --untar stable/mongodb --version 0.4.18
```

Настройки хранятся в `services/helm/mongodb/values.yaml`

Настраиваем:

- persistentVolume, который связан с заранее созданным запросом на том по классу `storageClassName` 
- ! параметр  `existingClaim`  не указан в файле настроек, имя PersistentVolumeClaims формируется в шаблоне `services/helm/mongodb/templates/pvc.yaml` из наименования HelmChart+суффикс;

#### Компонент приложения rabbitmq

За основу взят `stable/rabbitmq` https://hub.helm.sh/charts/stable/rabbitmq

Получаем rabbitmq на локальный диск

```sh
cd services/helm
helm repo update
helm fetch --untar stable/rabbitmq --version 6.1.5
```

Настройки хранятся в `services/helm/rabbitmq/values.yaml`

Настраиваем:

- persistentVolume, который связан с заранее созданным запросом на том по классу `storageClassName`;
- включаем metrics;
- отключен securityContext (контейнер не стартует, Permission denied при создании файла);
- указано название кластера `k8s_domain` `cluster_formation.k8s.host`
- при необходимости указываем учетную запись.

#### Компонент приложения search-ui

Helm chart для компонента приложения search-ui создан в директории `services/helm/search-ui`

#### Компонент приложения crawler

Helm chart для компонента приложения crawler создан в директории `services/helm/crawler`

#### Приложение search-engine

Главный helm chart приложения, который включает все компоненты приложения со всеми зависимостями.

Загрузка зависимостей в helm chart приложения:

```sh
cd services/helm
helm dep update search-engine
```



## Развертывание приложения в kubernetes

#### Подготовительные мероприятия в кластере kubernetes

Компонентам mongodb и crawler необходим PersistentVolume в кластере.

PersistentVolume для этих компонентов подготовлены в директории `k8s/deployment`/

Создадим PersistentVolume в кластере

```sh
kubectl apply -f k8s/deployment/pv-mongodb.yml -n default
kubectl apply -f k8s/deployment/pv-rabbitmq.yml -n default
```

### Развертывание приложенияsearch-engine

Развернуть приложения можно в кластере kubernetes можно с использованием подготовленных helm charts:

- по отдельности каждый компонент;
- все приложение через главный helm chart приложения.

Пример развертывания отдельного компонента приложения:

```sh
cd services/helm
helm upgrade --install mongodb mongodb/
helm upgrade --install rabbitmq rabbitmq/
helm upgrade --install crawler crawler/
helm upgrade --install search-ui search-ui
```

Развертывание приложения со всеми зависимостями:

```sh
cd services/helm

#обновляем изменения в зависимостях
helm dep update search-engine

#устанавливаем приложение
helm upgrade --install search-engine search-engine/
```

Приложение доступно по ссылке http://otus.4ippi.ru



## Мониторинг приложения

###Сбор метрик

Настройка мониторинга endpoints приложения указана в файле `k8s/helm/prometheus/values.yaml`:

- Метрики компонента приложения search-ui `job_name: 'search-ui-endpoints`

  Список метрик:

  `web_page_gen_time_bucket`

  `web_page_gen_time_count`

  `web_page_gen_time_sum`

  `web_pages_served`

- Метрики компонента приложения crawler `job_name: 'crawler-endpoints'`

  Список метрик:

  `crawler_page_parse_time_bucket`

  `crawler_page_parse_time_count`

  `crawler_page_parse_time_sum`

  `crawler_pages_parsed`

  `crawler_site_connection_time_bucket`

  `crawler_site_connection_time_count`

  `crawler_site_connection_time_sum`

### Оповещения (alerts)

Ранее была настроена отправка оповещений в slack канал.

Настройки оповещений указаны в файле `k8s/helm/prometheus/values.yaml`:

- настроено оповещении о сбое компонента search-ui `alert: Application-Search-UI-Down`
- Настроено оповещении о сбое компонента crawler `alert: Application-Crawler-Down`

### Визуализация метрик

Создан dashboard для приложения Search-UI `k8s/helm/grafana/dashboards/app_search_ui.json` с параметризацией по `namespace` .

Dashboard включает 3 графика:

- 95% quantile of web page gen time

- Rate of web pages served

- Rate of web page gen time sum                           



## GitLab CI/CD

### Подготовительные мероприятия

#### Подготовка томов

В связи с тем, что используем свой kubernetes, хоть и на серверах GCP, многие возможности не доступны, подготовим Persisten Volumes для CI/CD.

Подготавливаем NFS для mongo/rabbitmq в review/stage/prod `ansible/inventory/stage/group_vars/nfs-server.yml` и применяем настройки

```sh
cd ansible
ansible-playbook -i inventory/stage/ -v -l repo playbooks/nfs.yaml
```

Создаем Persisten Volumes в kubernetes:

```sh
kubectl apply -f k8s/deployment/pv-mongodb-staging.yml
kubectl apply -f k8s/deployment/pv-mongodb-prod.yml
kubectl apply -f k8s/deployment/pv-rabbitmq-staging.yml
kubectl apply -f k8s/deployment/pv-rabbitmq-prod.yml
```

>    Тома для `review` заранее не создаем, том будет автоматически создаваться и освобождаться в pipelines CI/CD.

#### Удаление приложения search-engine в namespace default

Ранее приложение было установлено в `namespace=default`, удалим его, т.к. в рамках CI/CD будут использованы namespace для review/staging/prod и приложения в default больше не будет.

```sh
helm delete $(helm ls -a|grep search-engine|grep default|awk '{print $1}') --purge
kubectl delete pvc $(kubectl get pvc -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' -n default|grep rabbitmq|head -n1) -n default
kubectl delete -f k8s/deployment/pv-mongodb.yml
kubectl delete -f k8s/deployment/pv-rabbitmq.yml
```

### Настройка интеграции GitLab с Kubernetes

В Admin Area > Kubernetes добавляем существующий кластер.

В GitLab входит справка, по нажатию More information под полем, для получения нужной информации для интеграции. Выполнено в соответствии с руководством.

- Получаем API URL:

```sh
kubectl cluster-info | grep 'Kubernetes master' | awk '/http/ {print $NF}'
https://104.155.1.48:6443
```

- Получаем CA certificate:

```sh
kubectl get secrets|grep -iE "name|default-token"
NAME                                        TYPE                                  DATA   AGE
default-token-7cwxq                         kubernetes.io/service-account-token   3      2d13h

kubectl get secret default-token-7cwxq -o jsonpath="{['data']['ca\.crt']}" | base64 --decode
-----BEGIN CERTIFICATE-----
MIICyDCCAbCgAwIBAgIBADANBgkqhkiG9w0BAQsFADAVMRMwEQYDVQQDEwprdWJl
cm5ldGVzMB4XDTE5MDcwNzE3Mjc1NFoXDTI5MDcwNDE3Mjc1NFowFTETMBEGA1UE
...
llugMIZyGf6TlZfgwkK+u8AiZJs4/dw0MrVViHjF75S7oxv2u6xK8n3uUV/jC24g
iS0F29ALtIJzPh0LbXAKHa0l7nkSa5MD/tdnyRgih+CATJz1d+vozcKxNI8=
-----END CERTIFICATE-----
```

- Получаем Service Token

  - Применяем манифест с пользователем `gitlab-admin`

    ```yaml
    cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: gitlab-admin
      namespace: kube-system
    ---
    apiVersion: rbac.authorization.k8s.io/v1beta1
    kind: ClusterRoleBinding
    metadata:
      name: gitlab-admin
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: cluster-admin
    subjects:
    - kind: ServiceAccount
      name: gitlab-admin
      namespace: kube-system
    EOF
    ```

  - Получаем token  пользователя `gitlab-admin`

    ```sh
    kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep gitlab-admin | awk '{print $1}')
    ```

    Пример вывода

    ```rst
    Name:         gitlab-admin-token-4v4lf
    Namespace:    kube-system
    Labels:       <none>
    Annotations:  kubernetes.io/service-account.name: gitlab-admin
                  kubernetes.io/service-account.uid: 736b3451-a2e3-11e9-8caa-42010a84000e
    
    Type:  kubernetes.io/service-account-token
    
    Data
    ====
    ca.crt:     1025 bytes
    namespace:  11 bytes
    token: <authentication_token>
    ```

- Указываем полученную информацию, завершаем интеграцию.

  > Снять галку с `GitLab-managed cluster`, иначе GitLab вместо использования учетной записи `gitlab-admin` будет создавать дополнительные сервисные аккаунты и пытаться развернуть приложения с использованием этих сервисных аккаунтов.

- В Application устанавливаем 

  - Helm Tiller (ставить первым, до установки др. приложений из списка в интеграции с кластером)

  - GitLab Runner

    > При необходимости можно еще установить доступные приложения из списка в интеграции:
    >
    > - Ingress
    >   Ingress gives you a way to route requests to services based on the request host or path, centralizing a number of services into a single entrypoint. 
    > - Cert-Manager
    >   Cert-Manager is a native Kubernetes certificate management controller that helps with issuing certificates. Installing Cert-Manager on your cluster will issue a certificate by Let's Encrypt and ensure that certificates are valid and up-to-date.
    > - Prometheus
    >   Prometheus is an open-source monitoring system with GitLab Integration to monitor deployed applications.

- Проверка

  ```sh
  kubectl get pods -n gitlab-managed-apps
  NAME                                   READY   STATUS    RESTARTS   AGE
  runner-gitlab-runner-7c8fb8457-pnxts   1/1     Running   0          38m
  tiller-deploy-7fb68896db-9bflz         1/1     Running   0          41m
  ```

### CI/CD

В CI/CD реализованы следующие этапы (stages):

- build - сборка приложения;

- test - тестирование приложения (в данном этапе функционирует заглушка);

- review - обзор и проверка приложения, приложение развертывается в динамическом доменном имени с использованием wilcard DNS записи;

- release - отправка образов на Docker Hub;

- cleanup - очистка окружения review, выполняется в ручную по кнопке в pipeline;

- staging - развертывание приложения в окружении staging, приложение доступно по ссылке http://staging.otus.4ippi.ru/;

- prod- развертывание приложения в окружении prod, приложение доступно по ссылке http://otus.4ippi.ru/.

Общий принцип работы CI/CD:

- коммит в branch 

  - автоматически выполняются этапы build/test/review;
  - в ручную в pipeline выполняется cleanup (stop_review).

- коммит в master

  - автоматически выполняются этапы build/test/release/staging;
  - в ручную в pipeline выполняется развертывание в prod окружение.



**PS:**

Дополнительные материалы представлены в директории `assets`.

