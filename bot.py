import os
import re
import time
import logging
import asyncio
from collections import defaultdict, deque
from datetime import datetime, timedelta, timezone

from telegram import Update, ChatPermissions
from telegram.ext import (
    Application, CommandHandler, MessageHandler, ContextTypes, filters
)

# ---------------- Logging ----------------
logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)
logging.getLogger("httpx").setLevel(logging.WARNING)

# ---------------- Config ----------------
BOT_TOKEN = ("8751726089:AAE991LNO6G15hICWl7jSX5JzVMzRwPIiTY
", "").strip()
OWNER_USERNAME = os.getenv("OWNER_USERNAME", "ShinnThieuu").strip().lstrip("@")
APP_NAME = "ShinnCheat"

if not BOT_TOKEN:
    raise RuntimeError("Missing BOT_TOKEN secret. Add it in GitHub repository Secrets.")

# --- Anti-spam / Anti-link config ---
SPAM_WINDOW = 10                      # giây
SPAM_THRESHOLD = 5                    # số lệnh tối đa trong SPAM_WINDOW
MUTE_DURATION = timedelta(days=1)     # mute 1 ngày
URL_PATTERN = r"(https?://|www\.|t\.me/|telegram\.me/)"
URL_FILTER = filters.TEXT & filters.Regex(URL_PATTERN, re.IGNORECASE)

# Lưu thời điểm dùng lệnh: user_id -> deque[timestamp]
user_cmd_times: dict[int, deque] = defaultdict(deque)

# ---------------- Text ----------------
TEXTS = {
    "start": (
        "👋 Chào mừng bạn đến với ShinnCheat!\n"
        "Dùng /help để xem các lệnh của bot.\n\n"
        "👋 Welcome to ShinnCheat!\n"
        "Use /help to see the bot commands."
    ),
    "help": (
        "📋 SHINNCHEAT — DANH SÁCH LỆNH\n\n"
        "/shinn — Thông tin ứng dụng\n"
        "/key — Thông tin key\n"
        "/buy — Liên hệ mua key\n"
        "/owner — Liên hệ Owner\n"
        "/update — Thông tin cập nhật\n"
        "/repo — Thông tin repository\n"
        "/support — Nhận hỗ trợ\n"
        "/rules — Nội quy nhóm\n"
        "/about — Giới thiệu bot\n"
        "/ad — Thông báo Owner đang bận/ngủ\n"
        "/id — Xem ID Telegram\n\n"
        "📋 ENGLISH\n"
        "/shinn — App information\n"
        "/key — Key information\n"
        "/buy — Buy a key\n"
        "/owner — Contact the owner\n"
        "/update — App updates\n"
        "/repo — Repository information\n"
        "/support — Get support\n"
        "/rules — Group rules\n"
        "/about — About the bot\n"
        "/ad — Owner status notice\n"
        "/id — Show Telegram ID"
    ),
    "shinn": (
        "📱 SHINNCHEAT\n\n"
        "🇻🇳 ShinnCheat là ứng dụng Patch với giao diện được thiết kế lại "
        "và các cải thiện về trải nghiệm sử dụng.\n"
        "🔑 Key: ShinnCheat / ShinnCheatTest\n"
        "🛒 Mua key: @{owner}\n\n"
        "🇬🇧 ShinnCheat is a patch app with a redesigned interface and "
        "usability improvements.\n"
        "🔑 Keys: ShinnCheat / ShinnCheatTest\n"
        "🛒 Buy a key: @{owner}"
    ),
    "key": (
        "🔑 SHINNCHEAT KEYS\n\n"
        "Available keys:\n"
        "• ShinnCheat\n"
        "• ShinnCheatTest\n\n"
        "🇻🇳 Cần mua key? Nhắn Owner: @{owner}\n"
        "🇬🇧 To purchase a key, contact the Owner: @{owner}\n"
        "📱 Theo thông tin hiện tại, key không giới hạn thiết bị.\n"
        "📱 Keys support unlimited devices."
    ),
    "buy": (
        "🛒 MUA KEY / BUY A KEY\n\n"
        "🇻🇳 Để mua key ShinnCheat, hãy nhắn trực tiếp Owner.\n"
        "🇬🇧 To purchase a ShinnCheat key, message the Owner directly.\n\n"
        "👤 Owner: @{owner}"
    ),
    "owner": (
        "👑 SHINNCHEAT OWNER\n\n"
        "🇻🇳 Liên hệ Owner để mua key hoặc cần hỗ trợ.\n"
        "🇬🇧 Contact the Owner for keys or support.\n\n"
        "📩 @{owner}"
    ),
    "update": (
        "🚀 SHINNCHEAT — UPDATE\n\n"
        "✨ Giao diện được thiết kế lại\n"
        "🎨 Cải thiện màu sắc và hiển thị\n"
        "🖼️ Hỗ trợ cập nhật ảnh đại diện\n"
        "🔧 Cải thiện Apply / Restore Patch\n"
        "⚡ Tối ưu hiệu suất và sửa lỗi\n"
        "🔄 Cải thiện đồng bộ Repository\n\n"
        "🇬🇧 Redesigned interface, improved visuals, avatar updates, "
        "Apply/Restore improvements, performance fixes and better repository sync."
    ),
    "repo": (
        "📦 REPOSITORY\n\n"
        "🇻🇳 Theo dõi thông báo trong nhóm để nhận liên kết repository mới nhất.\n"
        "🇬🇧 Check group announcements for the latest repository links.\n"
        "⚠️ Chỉ tải file từ nguồn mà bạn tin tưởng. / Only download from trusted sources."
    ),
    "support": (
        "🛠️ HỖ TRỢ / SUPPORT\n\n"
        "🇻🇳 Mô tả lỗi, phiên bản iOS và các bước gây ra lỗi; không gửi mật khẩu hoặc token.\n"
        "🇬🇧 Describe the issue, iOS version, and steps to reproduce it. Never send passwords or tokens.\n\n"
        "👤 Owner: @{owner}"
    ),
    "rules": (
        "📜 NỘI QUY NHÓM / GROUP RULES\n\n"
        "1. Tôn trọng mọi thành viên / Respect all members.\n"
        "2. Không spam hoặc quảng cáo trái phép / No spam or unauthorized ads.\n"
        "3. Không giả mạo Owner / Do not impersonate the Owner.\n"
        "4. Không chia sẻ thông tin cá nhân của người khác / Do not share others' private information.\n"
        "5. Liên hệ admin khi cần hỗ trợ / Contact an admin for help."
    ),
    "about": (
        "🤖 SHINNCHEAT BOT\n\n"
        "Bot hỗ trợ cộng đồng ShinnCheat: thông tin ứng dụng, key, cập nhật và hỗ trợ.\n"
        "A community bot for ShinnCheat app, key, update, and support information."
    ),
    "ad": (
        "🌙 THÔNG BÁO TỪ OWNER\n\n"
        "Shinn ngủ rồi. Nếu bạn có việc gấp, hãy liên hệ trực tiếp nhé!\n"
        "📩 Owner: @{owner}\n\n"
        "🌙 OWNER NOTICE\n"
        "Shinn is asleep. If your matter is urgent, you can contact the Owner directly.\n"
        "📩 Owner: @{owner}"
    ),
}

def render(key: str) -> str:
    return TEXTS[key].format(owner=OWNER_USERNAME)

# ---------------- Helpers ----------------
async def _is_privileged(chat, user) -> bool:
    """True nếu user là owner / admin / creator (bỏ qua kiểm tra)."""
    if user is None:
        return False
    if user.username and user.username.lower() == OWNER_USERNAME.lower():
        return True
    if chat is None:
        return False
    try:
        member = await chat.get_member(user.id)
        return member.status in ("administrator", "creator")
    except Exception:
        return False

async def _delayed_delete(message, delay: float):
    await asyncio.sleep(delay)
    try:
        await message.delete()
    except Exception:
        pass

async def _spam_guard(update: Update, context: ContextTypes.DEFAULT_TYPE) -> bool:
    """True nếu OK, False nếu đã mute vì spam."""
    user = update.effective_user
    chat = update.effective_chat
    msg = update.effective_message
    if user is None or chat is None or msg is None:
        return True
    if chat.type not in ("group", "supergroup"):
        return True
    if await _is_privileged(chat, user):
        return True

    now = time.time()
    dq = user_cmd_times[user.id]
    while dq and now - dq[0] > SPAM_WINDOW:
        dq.popleft()
    dq.append(now)

    if len(dq) < SPAM_THRESHOLD:
        return True

    dq.clear()
    until = datetime.now(timezone.utc) + MUTE_DURATION
    try:
        await chat.restrict_member(
            user.id,
            ChatPermissions(
                can_send_messages=False,
                can_send_audios=False,
                can_send_documents=False,
                can_send_photos=False,
                can_send_videos=False,
                can_send_video_notes=False,
                can_send_voice_notes=False,
                can_send_polls=False,
                can_send_other_messages=False,
                can_add_web_page_previews=False,
            ),
            until_date=until,
        )
        warn = await msg.reply_text(
            f"🔇 {user.mention_html()} đã bị <b>mute 1 ngày</b> vì spam lệnh.\n"
            f"🔇 {user.mention_html()} has been <b>muted for 1 day</b> for spamming commands.",
            parse_mode="HTML",
        )
        asyncio.create_task(_delayed_delete(warn, 15))
    except Exception as e:
        logging.warning("Mute failed: %s", e)
    return False

def spam_protected(func):
    async def wrapper(update: Update, context: ContextTypes.DEFAULT_TYPE):
        if not await _spam_guard(update, context):
            return
        return await func(update, context)
    return wrapper

# ---------------- Link filter ----------------
async def delete_link_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    msg = update.effective_message
    chat = update.effective_chat
    user = update.effective_user
    if msg is None or chat is None:
        return
    if await _is_privileged(chat, user):
        return
    try:
        await msg.delete()
    except Exception as e:
        logging.warning("Không xoá được tin nhắn link: %s", e)
        return
    try:
        warn = await chat.send_message(
            f"⚠️ {user.mention_html() if user else 'User'}, không gửi link trong nhóm!\n"
            f"⚠️ Links are not allowed in this group!",
            parse_mode="HTML",
        )
        asyncio.create_task(_delayed_delete(warn, 10))
    except Exception:
        pass

# ---------------- Command handlers ----------------
@spam_protected
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_message:
        await update.effective_message.reply_text(render("start"))

@spam_protected
async def help_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_message:
        await update.effective_message.reply_text(render("help"))

@spam_protected
async def id_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_message and update.effective_user:
        await update.effective_message.reply_text(
            f"Your Telegram ID: {update.effective_user.id}"
        )

def make_command(key: str):
    @spam_protected
    async def callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
        if update.effective_message:
            await update.effective_message.reply_text(render(key))
    return callback

@spam_protected
async def keyword_reply(update: Update, context: ContextTypes.DEFAULT_TYPE):
    message = update.effective_message
    if not message or not message.text:
        return
    text = message.text.lower()
    if "shinn" in text:
        await message.reply_text(render("shinn"))
    elif "key" in text or "mua key" in text or "buy key" in text:
        await message.reply_text(render("key"))

# ---------------- Main ----------------
def main():
    app = Application.builder().token(BOT_TOKEN).build()

    # Commands
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("help", help_cmd))
    app.add_handler(CommandHandler("id", id_cmd))
    for command in ("shinn", "key", "buy", "owner", "update", "repo",
                    "support", "rules", "about", "ad"):
        app.add_handler(CommandHandler(command, make_command(command)))

    # Link deleter — đặt TRƯỚC keyword_reply để chặn tin có link
    app.add_handler(MessageHandler(URL_FILTER & ~filters.COMMAND, delete_link_message))

    # Keyword auto-reply (không áp dụng cho lệnh)
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, keyword_reply))

    logging.info("ShinnCheat bot is running.")
    app.run_polling(allowed_updates=Update.ALL_TYPES)

if __name__ == "__main__":
    main()