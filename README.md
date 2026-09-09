## Статус инфраструктуры (Yandex Cloud + Terraform)

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
