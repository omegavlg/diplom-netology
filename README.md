# Дипломный практикум в Yandex.Cloud - `Дедюрин Денис`

---

## Создание облачной инфраструктуры

Выполняем создание облачной инфраструктуры с помощью **terraform**.

```
cd ~/diplom-netology/terraform/00-bucket
terraform apply

~/diplom-netology/terraform/01-core-infra
terraform apply
```

Создались:

1. **Object Storage** - для хранения состояния **terraform**;

<img src = "img/01.png" width = 100%>

2. **Virtual Private Cloud** с подсетями **subnet-a (10.10.0.0/24)**, **subnet-b (10.20.0.0/24)**;

<img src = "img/02.png" width = 100%>

3. 4 Виртуальные машины (**Jenkins**, **k8s-master**, **k8s-worker-1**, **k8s-worker-2**);

<img src = "img/03.png" width = 100%>

4. **Network Load Balancer**.

<img src = "img/04.png" width = 100%>

Т.к. пока еще не поднята система мониторинга, то статус у целевой группы пока что **Unhealthy**

## Создание Kubernetes кластера

Выполняем создание Kubernetes кластера.

```
cd ~/diplom-netology/ansible
source venv/bin/activate

ansible-playbook -i inventory.ini setup.yml
ansible-playbook -i inventory.ini create-cluster.yml
```

Playbook **setup.yml** выполнил начальную подготовку ВМ, присовил ниманование хостам и обновил все билиотеки и приложения до актуальных, после чего выполнил перезагрузку.

<img src = "img/05.png" width = 100%>

Playbook **screate-cluster.yml** выполнил установку кластера Kubernetes, произвел его инициализацию, подключил две worker-ноды, создал файл конфигурации **~/.kube/config** на машине, с которого был выполнен запуск playbook.

<img src = "img/06.png" width = 100%>

Проверяем, что все поднялось:

```
kubectl get pods --all-namespaces
```

<img src = "img/07.png" width = 100%>

## Подготовка cистемы мониторинга и деплой приложения

Деплоим в кластер систему мониторинга.

```
cd ~/diplom-netology/monitoring

kubectl apply --server-side -f manifests/setup
kubectl wait --for condition=Established --all CustomResourceDefinition --namespace=monitoring
kubectl apply -f manifests/
```
<img src = "img/08.png" width = 100%>
<img src = "img/09.png" width = 100%>
<img src = "img/10.png" width = 100%>

Снова проверим статус у целевой группы. Видим что статус изменился на **Healthy**

<img src = "img/20.png" width = 100%>

Проверяем, что все поднялось:

```
kubectl get pods -n monitoring
```
<img src = "img/11.png" width = 100%>

Заходим в интерфес **Grafana** и проверяем в дашбордах состояние **Kubernetes** кластера

<img src = "img/12.png" width = 100%>
<img src = "img/13.png" width = 100%>

## Создание тестового приложения

Подготавливаем Dockerfile.

Репоизиторий для тестового приложения:

https://github.com/omegavlg/diplom-test-app

```
# Dockerfile
FROM nginx:1.26.3

COPY nginx.conf /etc/nginx/nginx.conf
COPY index.html /usr/share/nginx/html/index.html

EXPOSE 8080
```
Собираем образ и публикуем его **DockerHub**, а так же деплоим его в **Kubernetes** кластер.

```
docker build -t omegavlg/diplom-test-app:latest .
docker push omegavlg/diplom-test-app:latest

kubectl apply -f deployment.yml
```

<img src = "img/14.png" width = 100%>
<img src = "img/15.png" width = 100%>
<img src = "img/16.png" width = 100%>
<img src = "img/17.png" width = 100%>

## Установка и настройка CI/CD

Собираем образ.

```
cd ~/diplom-netology/ansible

docker build -t omegavlg/jenkins-blueocean:v1 .
docker push omegavlg/jenkins-blueocean:v1
```

<img src = "img/18.png" width = 100%>
<img src = "img/19.png" width = 100%>

Выполняем установку **Jenkins**.

```
cd ~/diplom-netology/ansible

ansible-playbook -i inventory.ini jenkins-setup.yml
```
Playbook **jenkins-setup.yml** выполнил установку и настройку контейнеров. Скопиррует на ВМ **~/.kube/config**, чтобы **Jenkins** был доступ к **Kubernetes** кластеру.

<img src = "img/21.png" width = 100%>
<img src = "img/22.png" width = 100%>

Создаем новый Item с типом **Multibranch Pipeline** и заполняем все необходимые поля.

<img src = "img/23.png" width = 100%>
<img src = "img/24.png" width = 100%>
<img src = "img/25.png" width = 100%>
<img src = "img/26.png" width = 100%>

**Jenkinsfile** размещаем в корне проекта тестового приложения.

```
pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds')
        IMAGE_NAME = "omegavlg/diplom-test-app"
    }

    stages {
        stage('Debug Info') {
            steps {
                script {
                    echo "BRANCH_NAME: ${env.BRANCH_NAME}"
                    echo "GIT_COMMIT: ${env.GIT_COMMIT}"
                    echo "Is tag: ${env.BRANCH_NAME.startsWith("v")}"
                }
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                script {
                    def imageTag = env.BRANCH_NAME.startsWith("v") ? env.BRANCH_NAME : "latest"

                    echo "Building Docker image with tag: ${imageTag}"

                    sh "docker build -t ${IMAGE_NAME}:${imageTag} ."
                    sh "echo ${DOCKERHUB_CREDENTIALS_PSW} | docker login -u ${DOCKERHUB_CREDENTIALS_USR} --password-stdin"
                    sh "docker push ${IMAGE_NAME}:${imageTag}"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            when {
                expression { env.BRANCH_NAME.startsWith("v") }
            }
            steps {
                script {
                    echo "Deploying image ${IMAGE_NAME}:${env.BRANCH_NAME} to Kubernetes"

                    sh """
                        sed -i 's|image: .*|image: ${IMAGE_NAME}:${env.BRANCH_NAME}|' k8s/deployment.yml
                        cat k8s/deployment.yml
                        kubectl apply -f k8s/deployment.yml
                        kubectl rollout status deployment diplom-test-app || true
                        kubectl get deployment diplom-test-app -o jsonpath='{.spec.template.spec.containers[*].image}'
                    """
                }
            }
        }
    }

    post {
        success {
            echo 'Сборка и деплой выполнены успешно.'
        }
        failure {
            echo 'Ошибка при сборке или деплое.'
        }
    }
}
```

В итоге, при выполнении любого коммита в ветку, автоматически запускается сборка этой ветки по сценарию из **Jenkinsfile**. Аналогично, при появлении новых тегов в репозитории **Jenkins** обнаруживает их и запускает так же сборку, пушит ее в **DockerHub**, а также в **Kubernetes** кластер.

Попробуем воспроизвести:
Внесу изменения в главную страницу проекта и выполю коммит.

<img src = "img/27.png" width = 100%>
<img src = "img/28.png" width = 100%>

Запустилась сборка с этим коммитом и запушилась в **DockerHub**.

Теперь добавим tag

```
git tag v1.0.0

git push origin v1.0.0
```

<img src = "img/29.png" width = 100%>

Автоматически запустился сценарий, который выполнил сборку, запушил ее в **DockerHub**, а также задеплоил в **Kubernetes** кластер

<img src = "img/30.png" width = 100%>

<img src = "img/31.png" width = 100%>

<img src = "img/32.png" width = 100%>

