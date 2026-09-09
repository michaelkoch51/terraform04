## Статус инфраструктуры (Yandex Cloud + Terraform)
# Домашнее задание №4. Продвинутые методы работы с Terraform

## Задание 1. Создание ВМ через remote-модули

**Требование:** с помощью двух вызовов модуля создать две ВМ (marketing и analytics), использовать labels, передать ssh-ключ через переменную в cloud-init, установить nginx.

**Что сделано:**

В корневом `main.tf` описаны два вызова модуля `./vm` — для marketing и analytics. Каждой ВМ переданы labels с указанием проекта:

```hcl
module "marketing_vm" {
  source         = "./vm"
  env_name       = "marketing"
  instance_name  = "marketing"
  instance_count = 1
  image_id       = data.yandex_compute_image.ubuntu_2204.id
  subnet_id      = module.vpc_dev.subnet_id
  public_ip      = true
  labels = { project = "marketing" }
  metadata = {
    user-data          = templatefile("
```


Инфраструктура успешно развернута в зоне `ru-central1-a`. ВМ были пересозданы (`terraform taint` + `apply`) для применения актуального SSH‑ключа пользователя.

**Статус виртуальных машин:**

| ВМ | Имя ресурса | Внешний IP (NAT) | Статус | Nginx |
|----|--------------|------------------|--------|-------|
| Marketing | marketing-marketing-1 | `51.250.65.78` | running | ✅ active (v1.18.0) |
| Analytics | analytics-analytics-1 | *см. `terraform state show`* | running | — |

**Ключевые факты:**
- ОС: Ubuntu 22.04 LTS.
- Пользователь `ubuntu` имеет sudo-доступ без пароля (`NOPASSWD`).
- Доступ по SSH осуществляется по ключу `id_ed25519`.
- В рамках `cloud-init` установлен и автоматически запущен `nginx`.
- Ресурсы: 2 vCPU, 2 GB RAM, 8 GB HDD, преэмптивная ВМ.

**Подтверждение работоспособности (вывод команд):**

```bash
ssh -i ~/.ssh/id_ed25519 ubuntu@51.250.65.78
```


Welcome to Ubuntu 22.04.5 LTS ...
ubuntu@fhmiqrquk7j6dqcg96ui:~\$ nginx -v
nginx version: nginx/1.18.0 (Ubuntu)

ubuntu@fhmiqrquk7j6dqcg96ui:~\$ systemctl status nginx --no-pager | head -n 5
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
     Active: active (running) since Wed 2026-09-09 16:13:53 UTC; 1min 26s ago
       Docs: man:nginx(8)
    Process: 1391 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)

## Проверка работы Docker и тестового контейнера

Docker установлен и настроен на ВМ `marketing-marketing-1` (Ubuntu 22.04, Yandex Cloud). Пользователь `ubuntu` добавлен в группу `docker`, команды выполняются без `sudo`.

### Запуск тестового контейнера Nginx

Для проверки работоспособности Docker был запущен контейнер с веб‑сервером Nginx:

```bash
docker run --name nginx-test -d -p 8080:80 nginx
```

docker ps

CONTAINER ID   IMAGE     COMMAND                  CREATED         STATUS        PORTS                                     NAMES
8c21680e4716   nginx     "/docker-entrypoint.…"   6 seconds ago   Up 1 second   0.0.0.0:8080->80/tcp, [::]:8080->80/tcp   nginx-test

## Демонстрация работы стека FastAPI + MySQL (Docker Compose)

Стек развёрнут на ВМ `marketing-marketing-1` (Ubuntu 22.04, Yandex Cloud) с использованием утилиты `docker-compose` (v1.29.2).

**Команда запуска:**
```bash
docker-compose up -d --build
```

CONTAINER ID   IMAGE                COMMAND                  CREATED         STATUS                             PORTS                                         NAMES
39a1093e5df3   devops-project_api   "uvicorn main:app --…"   ...             Up ...                              0.0.0.0:8000->8000/tcp, [::]:8000->8000/tcp   devops-project_api_1
1686da6c1b61   mysql:8.0            "docker-entrypoint.s…"   ...             Up ... (health: starting)           3306/tcp, 33060/tcp                           devops-project_db_1
8c21680e4716   nginx                "/docker-entrypoint.…"   ...             Up ...                              0.0.0.0:8080->80/tcp, [::]:8080->80/tcp       nginx-test

# DevOps-проект: Terraform + Docker + FastAPI + MySQL

## Статус проекта

✅ Инфраструктура поднята в Yandex Cloud (Terraform).  
✅ Docker Compose v2 управляет мультисервисным приложением.  
✅ FastAPI успешно подключается к MySQL через внутреннюю сеть Docker.  
✅ Эндпоинт `/health` возвращает `{"health": "healthy", "db": "connected"}` — доказательство реального взаимодействия сервисов.

### 3. Эндпоинт `/users`: чтение данных из БД

Команда: `curl http://localhost:8000/users`

```json
{
  "users": [
    {
      "id": 1,
      "name": "Alice",
      "email": "alice@example.com"
    }
  ]
}

Получение списка пользователей из таблицы users в MySQL через FastAPI.

Пояснение: Приложение выполняет реальный SELECT к таблице users, преобразует строки в JSON и возвращает их клиенту. Это демонстрирует полноценную работу с данными в контейнеризованном стеке.

---

## Демонстрация работы

### 1. Статус контейнеров

Команда: `docker ps`

```text
CONTAINER ID   IMAGE                COMMAND                  ...   PORTS                        NAMES
268f7126d209   devops-project-api   "uvicorn main:app --…"   ...   0.0.0.0:8000->8000/tcp       devops-project-api-1
657ca26b2e5b   mysql:8.0            "docker-entrypoint.s…"   ...   3306/tcp, 33060/tcp           devops-project-db-1
```

