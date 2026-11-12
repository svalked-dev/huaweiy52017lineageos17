# Evolution X 4.5 (LineageOS 17.1) — Huawei MYA-U29

Порт **Evolution X 4.5** на **Huawei MYA-U29** (MT6580, ARMv7, 1 ГБ RAM,
480×854). Порт сделан «с нуля»: готовых сборок Evolution X 4.5 / LineageOS 17.1
под этот аппарат не существовало.

> **Назначение проекта изначально — порт Evolution X 4.5.**
> Evolution X 4.5 — это сборка поверх LineageOS 17.1 (Android 10), поэтому база
> здесь именно `lineage-17.1`, а продукт называется `evolution_mya_u29` и уже
> несёт брендинг EvoX (`ro.modversion=EvolutionX-4.5-…`, `ro.evolution.version=4.5`,
> `PRODUCT_BRAND=Evolution`). Этап EvoX-слоя (тема, оверлеи, EvoX-Settings /
> EvoX-SystemUI / EvoX-Launcher) подключается вторым шагом поверх уже рабочей
> LineageOS 17.1 — так всегда остаётся рабочий откат. Подробности — в
> разделе «Что внутри» и в истории коммитов.

Работает **без GSI**: собирается обычный `system.img` + `vendor.img` + `boot.img`,
которые прошиваются через TWRP или напрямую через `adb` с root.

---

## 1. Устройство и раскладка разделов

| Раздел | Блок | Размер | Что в нём |
|---|---|---|---|
| `system` | `mmcblk0p23` | 3 ГБ | LineageOS 17.1 (system image) |
| `cust`   | `mmcblk0p24` | 400 МБ | **vendor image** (`/vendor`) |
| `cache`  | `mmcblk0p25` | 200 МБ | кэш |
| `userdata`| `mmcblk0p26` | ~10.6 ГБ | данные пользователя (не трогаем) |
| `boot`   | `mmcblk0p8` | 16 МБ | ядро + ramdisk |
| `recovery`| `mmcblk0p9` | 64 МБ | TWRP (не трогаем) |

Важно: на MYA-U29 **нет раздела `vendor`** — вендорная часть лежит в
MTK-разделе `cust` и монтируется как `/vendor`. Это отражено в
`device/huawei/mya_u29/rootdir/fstab.mt6580` и в `recovery.fstab`.

`data`, `nvram`, `oeminfo` порт не трогает.

---

## 2. Что внутри

```
device/huawei/mya_u29/     дерево устройства MYA-U29
  BoardConfig.mk           архитектура, разделы, ядро, fstab recovery
  device.mk                product-конфигурация (PRODUCT_PACKAGES, копии)
  evolution_mya_u29.mk     продукт + брендинг Evolution X 4.5
  rootdir/fstab.mt6580     fstab: system -> /system, cust -> /vendor
  rootdir/init.mt6580.rc   device-специфичный init (mount_all, MTK-фиксы)
  sepolicy/                .te-файлы политики устройства
  tools/patch-vendor-fstab.py  замена G81-fstab внутри vendor-образа
tools/flash.sh             прошивка через adb (root) без TWRP
tools/inspect-images.py    проверка собранных образов
patches/                   патчи AOSP-дерева, без которых сборка не идёт
manifest/local_manifests.xml  пример подключения проектов к repo
```

Ядро — prebuilt `zImage` из `vendor/alps/g81/device-prebuilts/kernel`
(G81, тот же MT6580). Исходники ядра для сборки не нужны.

Вендорная часть — готовое проверенное изображение
`vendor/alps/g81/proprietary/vendor.img` (400 МБ, Git LFS), внутри которого
лежат MTK HAL-ы, `/etc/init/hw/*`, `nonplat_sepolicy.cil`, `precompiled_sepolicy`
и VINTF-манифест. Fstab внутри него заменяется на MYA-U29-овский
(см. `tools/patch-vendor-fstab.py`).

### Состояние EvoX-слоя

Сейчас в сборке — **база LineageOS 17.1** (Launcher3QuickStep, Settings,
SystemUI, Trebuchet) + **брендинг Evolution X 4.5**. Собственно наработки EvoX
(тема, оверлеи, EvoX-версии Settings/SystemUI/Launcher) в дерево пока **не
включены**: в манифесте нет ни одного EvoX-проекта, а `src/evolutionx` и
`src/evox_src` пусты.

Порядок работ (сознательно такой):

1. довести до рабочей загрузки чистую LineageOS 17.1 на MYA-U29 — этого на
   аппарате не было никогда, и это основной результат;
2. поверх — подключить EvoX-проекты отдельными записями в манифесте с
   `remove-project` для стоковых `packages/apps/Settings` и оверлеев, чтобы
   конфликт по именам не ломал сборку.

Общесистемной тёмной темы и Substratum в порту нет — только то, что приносит
сам EvoX-слой.

---

## 3. Сборка

Требования: 12+ ГБ RAM, ~200 ГБ на диске, JDK 11, `repo`, `git-lfs`,
`python3`, `bc`, `libncurses` (для prebuilt clang нужен ncurses 5 —
см. раздел «Особенности»).

```bash
repo init -u https://github.com/LineageOS/android.git -b lineage-17.1
repo sync -c -j$(nproc)
# дерево устройства и вендор копируются из этого репозитория:
./setup.sh /path/to/los17.1
cd /path/to/los17.1
export TOP=$PWD
source build/envsetup.sh
lunch evolution_mya_u29-userdebug
m -j$(nproc) bacon
```

Готовые образы: `out/target/product/mya_u29/{system.img,vendor.img,boot.img}`.

Проверить, что всё собралось правильно:

```bash
python3 tools/inspect-images.py out/target/product/mya_u29
```

---

## 4. Прошивка

Вариант A — напрямую через adb (телефон должен быть подключён, adbd с root):

```bash
./tools/flash.sh out/target/product/mya_u29
```

Скрипт сам размонтирует `/system` и `/vendor`, затем пишет потоком через
`adb shell dd` (местом на телефоне для 3 ГБ разматывать не нужно).

Вариант B — через TWRP: `Advanced → Install → img files`, или вручную
`dd` в разделы `p23` (system), `p24` (cust), `p8` (boot).

После прошивки — обычная перезагрузка. Раздел `recovery` не трогаем,
TWRP остаётся доступен.

---

## 5. Особенности загрузки (важно)

* Загрузчик MTK стартует ядро с `root=/dev/ram`, поэтому в `boot.img` остаётся
  ramdisk с first-stage `init`; `androidboot.hardware=mt6580` в cmdline ядра
  нужен, чтобы `fs_mgr` нашёл `/fstab.mt6580` до монтирования разделов.
* AOSP 10 требует system-as-root, но этот телефон грузится через ramdisk,
  поэтому port использует схему: first-stage init монтирует `/system`
  и `/vendor` (`first_stage_mount`), делает pivot в `/system`, а второй stage
  вызывает `mount_all /fstab.mt6580` из `root/init.mt6580.rc` (в generic
  `init.rc` AOSP 10 `mount_all` нет).
* `ro.hardware=mt6580` задаётся в `PRODUCT_SYSTEM_DEFAULT_PROPERTIES`, т.к.
  в Lineage 17.1 bucket `PRODUCT_DEFAULT_PROPERTY_OVERRIDES` не попадает в
  `default.prop`.
* Политика SELinux: системная часть из AOSP, вендорная — из
  `/vendor/etc/selinux/nonplat_sepolicy.cil` внутри vendor-образа; init
  собирает split-policy сам (`secilc` из system).

---

## 6. Особенности сборки (для контрибьюторов)

* `patches/0001-test-framework-disable-vts-tests.patch` — отключает VTS/VTF:
  CTS в манифесте нет, тесты в сборку не входят.
* `patches/0002-prebuilts-sdk-tools-libllvm-variant.patch` — указывает
  prebuilt `libLLVM_android`/`libclang_android` на linux-библиотеки.
* Prebuilt clang из AOSP собран против ncurses 5. На дистрибутивах с ncurses 6
  нужен симлинк: `ln -s /usr/lib/libncursesw.so.6 libncurses.so.5` (и
  `libtinfo.so.5`) в каталоге, который добавляется в `LD_LIBRARY_PATH`.
* Если сборка падает на `Options.inc not found` — не выключайте `llvm_tblgen`
  в `external/clang/Android.bp`: после синка `external/llvm` tblgen
  собирается штатно.

---

## 7. Благодарности

* **LineageOS** — база 17.1 и все патчи платформы.
* **[17-Pro-Max-Mini](https://github.com/17-Pro-Max-Mini)** — публичное дерево
  G81 (`device/alps/g81`, `vendor/alps/g81`), из которого взяты vendor-образ,
  prebuilt-ядро и device-специфичные наработки.
* **Huawei** — стоковые kernel/разделы устройства.

## 8. Лицензия

Код — под лицензиями соответствующих проектов AOSP/LineageOS (Apache 2.0,
GPLv2 и т.д.). vendor-образ содержит проприетарные компоненты Huawei/MTK и
распространяется только для владельцев устройства.
