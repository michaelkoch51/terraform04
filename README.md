# Домашнее задание «Использование Terraform в команде»

**Студент:** Michael Kochnev
**Репозиторий:** https://github.com/michaelkoch51/terraform04
**Ветка:** `terraform-05`
**Дата:** Сентябрь 2026

---

## Содержание

- [Задание 0 — Статья про neprivet.com](#задание-0)
- [Задание 1 — Анализ кода tflint и checkov](#задание-1)
- [Задание 2 — Remote state и блокировки](#задание-2)
- [Задание 3 — Hotfix и Pull Request](#задание-3)
- [Задание 4 — Валидация переменных](#задание-4)
- [Задание 5* — Сложная валидация](#задание-5)
- [Задание 7* — Bootstrap-модуль для remote state](#задание-7)

---

## Задание 0 — Статья про neprivet.com

Прочитал статью [neprivet.com](https://neprivet.com/) — про культуру приветствий и важность уважительного общения в команде. Идея простая: «привет» — это базовое уважение, которое занимает секунду, но задаёт тон всему общению.

**Вывод:** в командной работе важно быть вежливым и уважительным. Это влияет на атмосферу и продуктивность. Распространяю идею в своём коллективе.

---

## Задание 1 — Анализ кода tflint и checkov

### Установка инструментов

```bash
brew install terraform-linters/tap/tflint
brew install checkov
```

Проверка версий:
```bash
$ tflint --version
TFLint version 0.64.0
+ ruleset.terraform (0.15.0-bundled)

$ checkov --version
3.3.10
```

### tflint — результаты

Запуск:
```bash
$ tflint --init
$ tflint --recursive
7 issue(s) found:
```

**Обнаруженные типы ошибок (без дублей):**

1. **`terraform_required_providers`** — отсутствует ограничение версии провайдера в блоке `required_providers`
   - Вхождения: `providers.tf` (yandex, random), `vm/versions.tf` (yandex), `vpc/main.tf` (yandex)

2. **`terraform_unused_declarations`** — объявленная переменная не используется
   - Вхождения: `variables.tf` — переменная `token`

3. **`terraform_required_version`** — отсутствует атрибут `required_version` в блоке `terraform`
   - Вхождения: `vm/versions.tf`, `vpc/main.tf`

**Итого:** 7 предупреждений, 3 уникальных типа.

### checkov — результаты

Запуск:
```bash
$ checkov -d . --framework terraform
Passed checks: 2, Failed checks: 4, Skipped checks: 0
```

**Обнаруженные типы ошибок (без дублей):**

1. **`CKV_YC_2`** — «Ensure compute instance does not have public IP»
   - VM имеет публичный IP (`nat = true`)
   - Вхождения: `module.analytics_vm`, `module.marketing_vm`

2. **`CKV_YC_11`** — «Ensure security group is assigned to network interface»
   - Security group не назначена на сетевой интерфейс
   - Вхождения: `module.analytics_vm`, `module.marketing_vm`

**Итого:** 4 провалившихся проверки, 2 уникальных типа. Пройдено: 2 (CKV_YC_4 — serial console отключён).

**Примечание:** checkov выдал warning о невозможности подключиться к `api0.prismacloud.io` для загрузки guidelines. Это не влияет на результаты — все проверки выполнены локально.

---

## Задание 2 — Remote state и блокировки

### Создание S3-бакета для state

```bash
$ yc storage bucket create --name michael-terraform-state-2026
$ yc storage bucket update --name michael-terraform-state-2026 --versioning versioning-enabled
```

![Бакет с версионированием](https://github.com/user-attachments/assets/82dbf9bc-d2a4-40fa-8688-10d86af4fb8d)

### Создание service account с правами на bucket

```bash
$ yc iam service-account create --name terraform04-state-sa
id: aje30pe1jkqhi7dnk1rg

$ yc resource-manager folder add-access-binding b1g12jnkavef24dh5fcn \
    --role storage.editor \
    --service-account-id aje30pe1jkqhi7dnk1rg
done (2s)

$ yc iam access-key create --service-account-id aje30pe1jkqhi7dnk1rg
```

Ключи сохранены в `~/.secrets/terraform04-state-key.txt` (вне репозитория, права `600`).

### Настройка backend в providers.tf

```hcl
terraform {
  required_version = ">= 1.12.0, < 2.0.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.120"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote state с встроенными блокировками (Terraform >= 1.6)
  backend "s3" {
    bucket = "michael-terraform-state-2026"
    key    = "terraform04/terraform.tfstate"
    region = "ru-central1"

    # Встроенный механизм блокировок — не требует YDB/DynamoDB
    use_lockfile = true

    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}
```

### Миграция state в S3

```bash
$ terraform init -migrate-state -backend-config=$HOME/.secrets/terraform04-backend.hcl
Initializing the backend...
Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
...
Terraform has been successfully initialized!
```

![Миграция state](https://github.com/user-attachments/assets/02af6f61-0024-49b9-ae5e-fab525b9f2bf)

Проверка, что state в S3:
```bash
$ yc storage s3api list-objects --bucket michael-terraform-state-2026
```

![State в S3](https://github.com/user-attachments/assets/8378d3d0-eb72-410a-a70f-d4ae4bf5742d)

### Тест блокировки

**Терминал 1** — открыт `terraform console` (держит lock).

**Терминал 2** — попытка `terraform apply`:
```bash
$ terraform apply
╷
│ Error: Error acquiring the state lock
│
│ Lock Info:
│   ID:        ea8f3708-80c0-b281-964f-12bf1a041a09
│   Path:      michael-terraform-state-2026/terraform04/terraform.tfstate
│   Operation: OperationTypeInvalid
│   Who:       michaelkochnev@MacBook-Pro-Mihail.local
│   Version:   1.14.8
│   Created:   2026-09-11 11:05:18.137751 +0000 UTC
```

**Блокировка сработала автоматически!** ✅

![Ошибка блокировки](https://github.com/user-attachments/assets/fbe3295a-b250-4087-9b59-f043b91d0618)

### Принудительная разблокировка

```bash
$ terraform force-unlock ea8f3708-80c0-b281-964f-12bf1a041a09
Do you really want to force-unlock?
  Enter a value: yes

Terraform state has been successfully unlocked!

The state has been unlocked, and Terraform commands should now be able to
obtain a new lock on the remote state.
```

![Force unlock](https://github.com/user-attachments/assets/eff60453-55da-4048-90f8-53b9d96e00df)

**Как работает `use_lockfile = true`:** при `terraform apply` Terraform создаёт lock-файл `<key>.lock.info` рядом со state в том же S3-бакете. Другой процесс видит lock и падает с ошибкой. Это упрощает настройку — не нужно создавать YDB в режиме DynamoDB.

---

## Задание 3 — Hotfix и Pull Request

### Создание ветки

```bash
$ git checkout -b terraform-hotfix
$ git push -u origin terraform-hotfix
```

### Исправления

| Правило | Файл | Исправление |
|---|---|---|
| `terraform_required_version` | `vm/versions.tf`, `vpc/main.tf` | Добавлен `required_version = ">= 1.12.0, < 2.0.0"` |
| `terraform_required_providers` | `vm/versions.tf`, `vpc/main.tf` | Добавлена версия `~> 0.120` для yandex |
| `terraform_unused_declarations` | `variables.tf` | Удалена неиспользуемая переменная `yc_token` |
| `CKV_YC_11` | `main.tf` | Создана security group `yandex_vpc_security_group.vm_sg` и передана в модули |
| `CKV_YC_2` | `vm/main.tf` | Добавлен `#checkov:skip=CKV_YC_2:Public IP required for SSH access and HTTP traffic` |

### Проверки после исправлений

**tflint:**
```bash
$ tflint --recursive
# 0 issues (было 7)
```

![tflint после](https://github.com/user-attachments/assets/4c6ff4a4-381b-456e-a5d0-8bf0c4d66b3f)

**checkov:**
```bash
$ checkov -d . --framework terraform
Passed checks: 5, Failed checks: 0, Skipped checks: 2
```

![checkov после](https://github.com/user-attachments/assets/4cf7ce85-5dd8-4374-a5b8-69c7c904afea)

**terraform plan:**
```bash
$ terraform plan
Plan: 6 to add, 0 to change, 0 to destroy.
```

### Pull Request

**Ссылка:** https://github.com/michaelkoch51/terraform04/pull/1

PR создан из ветки `terraform-hotfix` в ветку `terraform-05`. **Не влит** — по заданию.

В комментарии PR указаны:
- результаты tflint (0 issues)
- результаты checkov (5 passed, 0 failed, 2 skipped)
- план изменений инфраструктуры из `terraform plan`

![Pull Request](https://github.com/user-attachments/assets/1811b230-f74c-4b36-a69d-fbb0ffffc4cb)

---

## Задание 4 — Валидация переменных

### Файл `variables_validation.tf`

```hcl
# ============================================================
# Задание 4: Переменные с валидацией
# ============================================================

# Одиночный IP-адрес
variable "ip_address" {
  type        = string
  description = "ip-адрес"
  default     = "192.168.0.1"

  validation {
    condition     = can(cidrhost("${var.ip_address}/32", 0))
    error_message = "Значение должно быть корректным IP-адресом (например, 192.168.0.1)."
  }
}

# Список IP-адресов
variable "ip_list" {
  type        = list(string)
  description = "список ip-адресов"
  default     = ["192.168.0.1", "1.1.1.1", "127.0.0.1"]

  validation {
    condition = alltrue([
      for ip in var.ip_list : can(cidrhost("${ip}/32", 0))
    ])
    error_message = "Все элементы списка должны быть корректными IP-адресами."
  }
}
```

**Как работает:**
- `can(cidrhost("IP/32", 0))` — проверяет, может ли функция `cidrhost` обработать CIDR. Если IP невалидный — вернёт `false`.
- `alltrue([...])` — возвращает `true`, только если **все** элементы списка `true`.

### Тесты в terraform console

**Тест 1 — валидный IP:**
```
$ terraform console
> var.ip_address
"192.168.0.1"
```

![Валидный IP](https://github.com/user-attachments/assets/2797326e-1ec0-463b-8ff3-bc132c9cc886)

**Тест 2 — невалидный IP:**
```
> var.ip_address = "1920.1680.0.1"
╷
│ Error: Invalid value for variable
│
│   on variables_validation.tf line 6:
│    6: variable "ip_address" {
│     │ var.ip_address is "1920.1680.0.1"
│
│ Значение должно быть корректным IP-адресом (например, 192.168.0.1).
```

![Невалидный IP](https://github.com/user-attachments/assets/768a582f-38ab-4832-be58-1f98a99e0f9d)

**Тест 3 — валидный список:**
```
> var.ip_list
tolist([
  "192.168.0.1",
  "1.1.1.1",
  "127.0.0.1",
])
```

**Тест 4 — список с невалидным IP:**
```
> var.ip_list = ["192.168.0.1", "1.1.1.1", "1270.0.0.1"]
╷
│ Error: Invalid value for variable
│
│   on variables_validation.tf line 18:
│   18: variable "ip_list" {
│     │ var.ip_list is list of string with 3 elements
│
│ Все элементы списка должны быть корректными IP-адресами.
```

![Невалидный список](https://github.com/user-attachments/assets/7929984d-fa4c-4d4e-9010-ae4859aa7e63)

---

## Задание 5* — Сложная валидация

### Файл `variables_validation_5.tf`

```hcl
# ============================================================
# Задание 5*: Переменные со сложной валидацией
# ============================================================

# Строка без заглавных букв
variable "lowercase_string" {
  type        = string
  description = "любая строка"
  default     = "hello world"

  validation {
    condition     = var.lowercase_string == lower(var.lowercase_string)
    error_message = "Строка не должна содержать заглавных букв."
  }
}

# Object: только один MacLeod
variable "in_the_end_there_can_be_only_one" {
  description = "Who is better Connor or Duncan?"
  type = object({
    Dunkan = optional(bool)
    Connor = optional(bool)
  })

  default = {
    Dunkan = true
    Connor = false
  }

  validation {
    condition = (
      var.in_the_end_there_can_be_only_one.Dunkan !=
      var.in_the_end_there_can_be_only_one.Connor
    )
    error_message = "There can be only one MacLeod"
  }
}
```

**Как работает:**

**1. Проверка строки без заглавных:**
- `lower("Hello")` → `"hello"`
- Если строка без заглавных: `"hello" == "hello"` → `true` ✅
- Если есть заглавные: `"Hello" == "hello"` → `false` ❌

**2. Проверка «только один» через `!=`:**
- `true != false` → `true` ✅ (один true, один false)
- `false != true` → `true` ✅ (один true, один false)
- `true != true` → `false` ❌ (оба true — ошибка)
- `false != false` → `false` ❌ (оба false — ошибка)

### Тесты

**Тест 1 — валидные значения:**
```
> var.lowercase_string
"hello world"

> var.in_the_end_there_can_be_only_one
{
  "Connor" = false
  "Dunkan" = true
}
```

![Валидная строка](https://github.com/user-attachments/assets/372aba21-7f66-45fa-a156-8d19ed3b250e)

**Тест 2 — строка с заглавными:**
```
> (после изменения default = "Hello World")
╷
│ Error: Invalid value for variable
│
│   on variables_validation_5.tf line 6:
│    6: variable "lowercase_string" {
│     │ var.lowercase_string is "Hello World"
│
│ Строка не должна содержать заглавных букв.
```

![Заглавные буквы](https://github.com/user-attachments/assets/7d780145-7915-4599-a9ac-1cf29e70f986)

**Тест 3 — object с двумя true:**
```
> (после изменения default: Dunkan = true, Connor = true)
╷
│ Error: Invalid value for variable
│
│   on variables_validation_5.tf line 18:
│   18: variable "in_the_end_there_can_be_only_one" {
│     │ var.in_the_end_there_can_be_only_one.Connor is true
│     │ var.in_the_end_there_can_be_only_one.Dunkan is true
│
│ There can be only one MacLeod
```

![Object с двумя true](https://github.com/user-attachments/assets/de0a809b-56a6-44c2-92d4-c962b32474af)

---

## Задание 7* — Bootstrap-модуль для remote state

### Структура

```
bootstrap/
├── main.tf          # ресурсы: bucket, SA, права, ключ
├── variables.tf     # переменные
├── outputs.tf       # outputs (bucket_name, access_key, secret_key, backend_config_example)
└── versions.tf      # версии Terraform и провайдера
```

### `bootstrap/main.tf`

```hcl
provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
}

# S3 bucket для Terraform state с версионированием
resource "yandex_storage_bucket" "tfstate" {
  bucket    = var.bucket_name
  folder_id = var.folder_id

  versioning {
    enabled = true
  }

  max_size = 1073741824  # 1 GB
}

# Сервисный аккаунт для работы с state
resource "yandex_iam_service_account" "tfstate_sa" {
  name        = var.sa_name
  description = "Service account for Terraform remote state"
}

# Права storage.editor на folder
resource "yandex_resourcemanager_folder_iam_member" "tfstate_sa_storage_editor" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.tfstate_sa.id}"
}

# Static access key для SA
resource "yandex_iam_service_account_static_access_key" "tfstate_sa_key" {
  service_account_id = yandex_iam_service_account.tfstate_sa.id
  description        = "Static access key for Terraform state"
}
```

### `bootstrap/outputs.tf`

```hcl
output "bucket_name" {
  value       = yandex_storage_bucket.tfstate.bucket
  description = "S3 bucket name for Terraform state"
}

output "access_key" {
  value       = yandex_iam_service_account_static_access_key.tfstate_sa_key.access_key
  description = "Static access key ID"
  sensitive   = true
}

output "secret_key" {
  value       = yandex_iam_service_account_static_access_key.tfstate_sa_key.secret_key
  description = "Static secret key"
  sensitive   = true
}

output "backend_config_example" {
  value = <<-EOT
    terraform {
      backend "s3" {
        bucket = "${yandex_storage_bucket.tfstate.bucket}"
        key    = "terraform.tfstate"
        region = "ru-central1"

        use_lockfile = true

        endpoints = {
          s3 = "https://storage.yandexcloud.net"
        }

        skip_region_validation      = true
        skip_credentials_validation = true
        skip_requesting_account_id  = true
        skip_s3_checksum            = true
      }
    }
  EOT
  description = "Example backend configuration"
}
```

### Применение

```bash
$ cd bootstrap
$ terraform init
$ terraform apply \
    -var="token=$(yc iam create-token)" \
    -var="cloud_id=b1gca93klbl4pf1m344h" \
    -var="folder_id=b1g12jnkavef24dh5fcn"

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

bucket_name = "terraform04-bootstrap-demo"
backend_config_example = <<EOT
terraform {
  backend "s3" {
    bucket = "terraform04-bootstrap-demo"
    key    = "terraform.tfstate"
    region = "ru-central1"
    use_lockfile = true
    ...
  }
}
EOT
access_key = <sensitive>
secret_key = <sensitive>
```


### Использование outputs для настройки backend

После `apply` можно взять outputs и настроить backend в основном проекте:

```bash
$ terraform output bucket_name
"terraform04-bootstrap-demo"

$ terraform output backend_config_example
# готовый блок для providers.tf
```

![Bootstrap apply/outputs](https://github.com/user-attachments/assets/bbf32e95-0bec-4b9c-98b5-8ea76a146c34)

### Удаление ресурсов

```bash
$ terraform destroy \
    -var="token=$(yc iam create-token)" \
    -var="cloud_id=b1gca93klbl4pf1m344h" \
    -var="folder_id=b1g12jnkavef24dh5fcn"

Destroy complete! Resources: 4 destroyed.
```

![Bootstrap destroy](https://github.com/user-attachments/assets/7c726685-59e1-44c7-bcef-60cbb0607cb2)

**Все созданные ресурсы удалены** — по требованию задания.

---

## Итоги

### Что было сделано

| Задание | Что сделано |
|---|---|
| **1** | Проанализирован код tflint (7 проблем, 3 типа) и checkov (4 failed, 2 типа) |
| **2** | Настроен remote state в S3 с `use_lockfile = true`. Протестирована блокировка и разблокировка |
| **3** | Ветка `terraform-hotfix` с исправлениями. PR #1 создан (не влит) |
| **4** | Переменные `ip_address` и `ip_list` с валидацией. Все 4 теста прошли |
| **5*** | Переменные `lowercase_string` и `in_the_end_there_can_be_only_one` с валидацией |
| **7*** | Bootstrap-модуль для remote state с outputs. Ресурсы удалены |

### Использованные инструменты

- **Terraform** 1.14.8
- **Yandex Cloud CLI** 1.18.0
- **tflint** 0.64.0
- **checkov** 3.3.10
- **Git** 2.50.1

### Репозиторий

https://github.com/michaelkoch51/terraform04

**Ветки:**
- `main` — основная
- `terraform-04` — ДЗ-4
- `terraform-05` — **текущая (сдача)**
- `terraform-hotfix` — исправления tflint/checkov

**Pull Request:** https://github.com/michaelkoch51/terraform04/pull/1
