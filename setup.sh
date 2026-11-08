#!/usr/bin/env bash
# Noldo — первоначальная настройка после распаковки архива.
#
# Запуск:
#   bash setup.sh
#
# Что делает:
#   1. Проверяет, что установлен bun (или предлагает установить)
#   2. Копирует .env.example в .env
#   3. Генерирует VAPID-ключи для push-уведомлений и вписывает в .env
#   4. Устанавливает зависимости (основной проект + mini-service)
#   5. Создаёт SQLite базу данных
#   6. Выводит дальнейшие инструкции

set -e

echo "=========================================="
echo "  Noldo — первоначальная настройка"
echo "=========================================="
echo ""

# 1. Check bun
if ! command -v bun >/dev/null 2>&1; then
  echo "❌ Bun не установлен."
  echo "   Установите его одной командой:"
  echo "   curl -fsSL https://bun.sh/install | bash"
  echo "   Затем перезапустите терминал и запустите setup.sh снова."
  exit 1
fi
echo "✓ Bun установлен: $(bun --version)"

# 2. .env
if [ ! -f .env ]; then
  cp .env.example .env
  echo "✓ Создан .env из .env.example"
else
  echo "✓ .env уже существует — пропускаю"
fi

# 3. VAPID keys (only if .env still has placeholders)
if grep -q "YOUR_PUBLIC_KEY_HERE" .env; then
  echo ""
  echo "→ Генерирую VAPID-ключи для push-уведомлений…"
  KEYS=$(bunx web-push generate-vapid-keys --json 2>/dev/null) || true
  if [ -n "$KEYS" ]; then
    PUB=$(echo "$KEYS" | python3 -c "import sys,json;print(json.load(sys.stdin)['publicKey'])")
    PRIV=$(echo "$KEYS" | python3 -c "import sys,json;print(json.load(sys.stdin)['privateKey'])")
    # Replace in .env (works on both Linux and macOS sed)
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s|YOUR_PUBLIC_KEY_HERE|$PUB|" .env
      sed -i '' "s|YOUR_PRIVATE_KEY_HERE|$PRIV|" .env
    else
      sed -i "s|YOUR_PUBLIC_KEY_HERE|$PUB|" .env
      sed -i "s|YOUR_PRIVATE_KEY_HERE|$PRIV|" .env
    fi
    echo "✓ VAPID-ключи сгенерированы и вписаны в .env"
  else
    echo "⚠️  Не удалось сгенерировать ключи автоматически. Выполните вручную:"
    echo "   bunx web-push generate-vapid-keys"
    echo "   И скопируйте public/private key в .env"
  fi
fi

# 4. Install deps
echo ""
echo "→ Устанавливаю зависимости основного проекта…"
bun install

echo "→ Устанавливаю зависимости chat-service…"
cd mini-services/chat-service
bun install
cd ../..

# 5. Database
echo ""
echo "→ Создаю базу данных (SQLite)…"
bun run db:push

echo ""
echo "=========================================="
echo "  ✓ Готово!"
echo "=========================================="
echo ""
echo "Теперь запустите два процесса в разных терминалах:"
echo ""
echo "  Терминал 1 (фронтенд):"
echo "    bun run dev"
echo "    → откроется на http://localhost:3000"
echo ""
echo "  Терминал 2 (WebSocket для real-time):"
echo "    cd mini-services/chat-service"
echo "    bun run dev"
echo "    → запустится на :3003"
echo ""
echo "Затем откройте http://localhost:3000 в браузере."
echo ""
echo "Подробная инструкция (как выложить в интернет для друзей):"
echo "  см. download/КАК-ЗАПУСТИТЬ.pdf"
