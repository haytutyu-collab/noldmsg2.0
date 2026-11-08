# Noldo — мессенджер для родных

Простой семейный мессенджер: чаты, голосовые сообщения, фото, групповые чаты, аудио/видеозвонки, push-уведомления, тёмная/светлая тема. Работает как PWA (устанавливается на главный экран iPhone и Android).

Полная инструкция по запуску и распространению среди друзей — в файле `download/КАК-ЗАПУСТИТЬ.pdf`.

## Технологии

- **Next.js 16** (App Router) + **TypeScript 5**
- **Tailwind CSS 4** + **shadcn/ui** (New York)
- **Prisma** ORM + SQLite (для разработки) / PostgreSQL (для продакшена)
- **Socket.io** для real-time (сообщения, presence, набор текста, сигналинг звонков)
- **WebRTC** для аудио/видеозвонков
- **web-push** для серверных push-уведомлений
- **bcryptjs** для хеширования паролей
- **sharp** для сжатия аватарок и фото-вложений
- **next-themes** для тёмной/светлой темы
- PWA: **manifest.json** + **service worker** (`/public/sw.js`)

## Возможности

- 🔐 Регистрация и вход с паролем (cookie-сессия, httpOnly)
- 👤 Профиль: имя, био, аватар (загрузка + авто-сжатие до 256×256)
- 💬 Личные чаты с real-time доставкой через WebSocket
- 👥 Групповые чаты (создание, участники, групповые сообщения)
- 🖼️ Фото-вложения в чате (сжимаются до max 1280px)
- 🎤 Голосовые сообщения (запись через MediaRecorder, аудио-плеер в чате)
- 📞 Аудио- и видеозвонки (WebRTC + сигналинг через socket.io)
- 🔔 Серверные push-уведомления (VAPID + web-push, работают на iOS 16.4+ и Android)
- 🟢 Presence (онлайн/офлайн), индикатор «печатает…», счётчик непрочитанных
- 🌙 Светлая/тёмная/системная тема
- 📱 Устанавливается как PWA на iPhone (через Safari) и Android (через Chrome)

## Запуск локально

Нужен установленный [Bun](https://bun.sh) (или Node.js 20+).

```bash
# 1. Установить зависимости
bun install
cd mini-services/chat-service && bun install && cd ../..

# 2. Скопировать .env.example в .env и заполнить
cp .env.example .env
# Сгенерировать VAPID-ключи:
bunx web-push generate-vapid-keys
# Вставить их в .env

# 3. Создать базу данных
bun run db:push

# 4. Запустить dev-сервер (фронтенд на :3000)
bun run dev

# 5. В отдельном терминале запустить WebSocket-сервис
cd mini-services/chat-service
bun run dev
# (он слушает :3003)

# 6. Открыть http://localhost:3000 в браузере
```

Для тестирования real-time звонков и presence откройте приложение в двух разных браузерах (или обычное + инкогнито окно), залогиньтесь под разными именами.

## Запуск в продакшене (бесплатно)

Подробная пошаговая инструкция — в `download/КАК-ЗАПУСТИТЬ.pdf`. Кратко:

1. **GitHub** — запушить код в репозиторий
2. **Vercel** — задеплоить фронтенд (Next.js), прописать env vars
3. **Render** или **Railway** — задеплоить `mini-services/chat-service` как Web Service
4. **Neon** или **Supabase** — бесплатная PostgreSQL (поменять `provider` в `prisma/schema.prisma` с `sqlite` на `postgresql`)
5. В `src/app/page.tsx` заменить URL сокета на адрес Render-сервиса

## Структура проекта

```
.
├── prisma/
│   └── schema.prisma          # User, Message, Group, GroupMember, PushSubscription
├── public/
│   ├── manifest.json          # PWA манифест
│   ├── sw.js                  # Service worker (offline cache + push)
│   ├── icon-192.png           # Иконки Noldo
│   ├── icon-512.png
│   └── apple-touch-icon.png
├── mini-services/
│   └── chat-service/
│       ├── index.ts           # socket.io сервер (port 3003)
│       └── package.json
├── src/
│   ├── app/
│   │   ├── layout.tsx         # ThemeProvider, PWA registration, metadata
│   │   ├── page.tsx           # Весь UI мессенджера
│   │   └── api/
│   │       ├── auth/{register,login,logout,me}/
│   │       ├── profile/
│   │       ├── users/
│   │       ├── messages/
│   │       ├── groups/[id]/
│   │       ├── upload/        # avatar | attachment | audio
│   │       └── push/{key,subscribe,unsubscribe}/
│   ├── components/
│   │   ├── ui/                # shadcn/ui компоненты
│   │   └── messenger/
│   │       ├── theme-provider.tsx
│   │       ├── theme-toggle.tsx
│   │       ├── pwa-register.tsx
│   │       ├── voice-recorder.tsx
│   │       └── call-screen.tsx   # WebRTC звонки + IncomingCallDialog
│   └── lib/
│       ├── db.ts              # Prisma client
│       ├── utils.ts
│       └── messenger/
│           ├── types.ts       # общие типы
│           └── push.ts        # helper отправки web-push
├── scripts/
│   ├── make-icons.py          # генерация иконок Noldo
│   ├── start-chat-service.py  # запуск mini-service как daemon
│   └── start-dev-server.py    # запуск Next.js как daemon
├── .env.example               # шаблон env vars (без секретов)
├── package.json
├── bun.lock
└── README.md                  # этот файл
```

## Известные ограничения

- **Push на iPhone** работает только с **iOS 16.4+** (ограничение Apple для PWA)
- **Установка как PWA на iPhone** — только через **Safari** (Chrome на iPhone не умеет)
- **Звонки в группах** пока не поддерживаются (только личные)
- **Звонки через строгий NAT** (мобильный интернет у обоих) потребуют добавления TURN-сервера в `src/components/messenger/call-screen.tsx` (см. инструкцию в `download/КАК-ЗАПУСТИТЬ.pdf`)
- **Голосовые в группах** работают, но без индикатора «печатает…» для них

## Что можно улучшить дальше

- Удаление и редактирование сообщений
- Поиск по истории переписки
- Звонки в группах (mesh topology или SFU)
- Реакции на сообщения (эмодзи)
- «Прочитано» для групповых сообщений (per-user read receipts)
- Импорт контактов из адресной книги
- Пересылка сообщений
- Архив чатов
- Бэкап переписки в файл
- Шифрование (E2EE) для полной приватности

## Лицензия

Личное использование. Код открыт для модификаций.

---

Сделано с ❤️ для семьи.
