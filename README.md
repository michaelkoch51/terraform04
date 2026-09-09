# Отчёт по домашнему заданию №4: Продвинутые методы работы с Terraform

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
![](https://github.com/user-attachments/assets/ca20ee5d-58cf-4f20-9d1c-febed7e547f9)
![](https://github.com/user-attachments/assets/b8049419-d3d8-47d9-8e25-022fd6469a06)
---

## Задание 2. Модуль VPC (сеть и подсеть)
**Что сделано:**
- Создан локальный модуль `./vpc` с ресурсами `yandex_vpc_network` и `yandex_vpc_subnet`.
- Использованы переменные: `env_name`, `zone`, `cidr`.
- Настроен `output` для передачи `subnet_id` в модули ВМ.
- В корневом `main.tf` модуль VPC используется вместо прямого объявления ресурсов.

**Подтверждение:**
- Вывод `terraform console` с обращением к `module.vpc_dev.subnet_id`.
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
![](https://github.com/user-attachments/assets/56d69384-8532-4246-8e2e-5db535004b81)
---

## Очистка и безопасность
- `.gitignore` настроен: игнорируются `*.tfstate`, `*.tfvars`, `personal.auto.tfvars`.
- Стейт-файлы и токены **не закоммичены** в Git.
- Выполнен `terraform destroy` — все ресурсы в Yandex Cloud удалены.
- Баланс не расходуется.

![](https://github.com/user-attachments/assets/fd3ea96e-4823-42e9-a6fc-c96d77d60109)
![](https://github.com/user-attachments/assets/52073a5d-ba17-4da8-b7df-4cbad65b13cf)
![](https://github.com/user-attachments/assets/11e93a42-72c4-4e19-958b-f15ef664b5b5)
