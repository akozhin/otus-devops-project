# Финальный проект по курсу Otus DevOps

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

- otus.4ippi.ru - LoadBalancer для k8s node поднятый terraform;

- gitlab.otus.4ippi.ru - GitLab;

- prometheus.otus.4ippi.ru - Prometheus

- grafana.otus.4ippi.ru - Grafana

  

## Подготовка ВМ с использованием ansible

### ansible inventory

Inventory выполнен в комбинации динамический + статический инвентори.

Динамический инвентори выполнен с использованием плагина gcp_compute. Статический инвентори нужен для создания родительских групп.

Структура inventory:

```
tree ansible/inventory/stage/
inventory/stage/
├── inventory.gcp.yml
└── inventory.static.yml
```

Для вызова одновременного вызова  динамический + статический инвентори, указываем на директорию, а не на файл инвентори.

Проверка динамического инвентори:

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

NFS будет использоваться .

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

###- kubectl

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

Устанавливаем prometheus:

Настройки хранятся в `k8s/helm/prometheus/values.yaml`

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

Настраиваем:

- ingress;
- datasource Prometheus по умолчанию;
- провайдера dashboards (**пока не заработало**);
- базовые dashboards (**пока не заработало**);

Устанавливаем grafana;

```sh
GRAFANA_ADMIN_PASSWD=$(pwgen -n -c 8 1)

#без явного указания grafana/values.yaml не видел ingress/host/nodeport, как будто они не настроены
helm upgrade --install grafana stable/grafana -f grafana/values.yaml --set "adminPassword=${GRAFANA_ADMIN_PASSWD}"

#получить пароль
kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

Grafana доступна по ссылке http://grafana.otus.4ippi.ru
