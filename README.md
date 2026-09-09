# Отчёт по домашнему заданию №4: Terraform State & Modules

## Статус
✅ Задание выполнено полностью.  
✅ Ресурсы удалены (`terraform destroy` выполнен).  
✅ Репозиторий чистый: стейты и токены не закоммичены, настроен `.gitignore`.  
✅ Ветка: `terraform-04`.

## Задание 1. Модули для ВМ (marketing, analytics)
**Что сделано:**
- Создан локальный модуль `./vm` для создания вычислительных экземпляров.
- Два вызова модуля: `marketing_vm` и `analytics_vm`.
- Переданы метки (`labels = { project = "marketing" }` и т.д.) для идентификации ресурсов.
- SSH-ключ передаётся через переменную `var.public_key` в шаблон `cloud-init.tftpl` (без хардкода).
- Включён режим `preemptible = true` для экономии ресурсов.
- В `cloud-init` настроен пользователь `ubuntu` с правами `sudo` и установкой пакета `nginx`.

**Подтверждение:**
- Скриншоты меток ВМ в консоли Yandex Cloud.
- Проверка работы nginx внутри ВМ.

---

## Задание 2. Модуль VPC (сеть и подсеть)
**Что сделано:**
- Создан локальный модуль `./vpc` с ресурсами `yandex_vpc_network` и `yandex_vpc_subnet`.
- Использованы переменные: `env_name`, `zone`, `cidr`.
- Настроен `output` для передачи `subnet_id` в модули ВМ.
- В корневом `main.tf` модуль VPC используется вместо прямого объявления ресурсов.

**Подтверждение:**
- Вывод `terraform console` с обращением к `module.vpc_dev.subnet_id`.
- Скриншоты сети и подсети в консоли Yandex Cloud.

---

## Задание 3. Операции с Terraform state
**Что сделано:**
1. `terraform state list` — получен список ресурсов.
2. `terraform state rm` — удалены из стейта: сеть, подсеть, две ВМ.
3. `terraform import` — ресурсы импортированы обратно по их ID:
   - Сеть: `enp6gijvj59uk62kmdni`
   - Подсеть: `e9beu2gobo49o70anbl0`
   - ВМ analytics: `fhmgo86novfsbd7659p5`
   - ВМ marketing: `fhmiqrquk7j6dqcg96ui`
4. `terraform plan` — результат: `No changes. Your infrastructure matches the configuration.`

**Доказательство:**
- Скриншот вывода `terraform plan` со строкой `No changes`.
- Логи команд `import` в истории терминала.

---

## Очистка и безопасность
- `.gitignore` настроен: игнорируются `*.tfstate`, `*.tfvars`, `personal.auto.tfvars`.
- Стейт-файлы и токены **не закоммичены** в Git.
- Выполнен `terraform destroy` — все ресурсы в Yandex Cloud удалены.
- Баланс не расходуется.

## Ссылки и артефакты
- Репозиторий: https://github.com/michaelkoch51/terraform04
- Ветка: `terraform-04`
- Скриншоты: папка `img/`
