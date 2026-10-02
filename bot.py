import os
import re
import time
import random
import logging
import asyncio
from collections import defaultdict, deque, Counter
from datetime import datetime, timedelta, timezone, time as dt_time

from telegram import (
    Update, ChatPermissions, InlineKeyboardButton, InlineKeyboardMarkup
)
from telegram.ext import (
    Application, CommandHandler, MessageHandler, CallbackQueryHandler,
    ContextTypes, filters
)

# ---------------- Logging ----------------
logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)
logging.getLogger("httpx").setLevel(logging.WARNING)

# ==================================================================
#  CẤU HÌNH / CONFIG
# ==================================================================
BOT_TOKEN = "8751726089:AAEfZt4cYvuPdkNxyDdWbPFL4-5dHhr5bpo"
OWNER_USERNAME = "ShinnThieuu"
APP_NAME = "ShinnCheat"
ALLOWED_CHAT_ID = -1004446959502

# === Mạng xã hội / Social links ===
LINK_TELEGRAM = "https://t.me/ShinnThieuu"
LINK_FACEBOOK = "https://www.facebook.com/share/19ZuAnvjt4/?mibextid=wwXIfr"
LINK_TIKTOK = "https://www.tiktok.com/@._ngvuminhhieuu"

if not BOT_TOKEN or ":" not in BOT_TOKEN:
    raise RuntimeError("BOT_TOKEN chưa được gắn hoặc sai định dạng.")

# === File app ===
SHINN_FILE_ID = "BQACAgUAAxkBAAFVYx5qv_BWrk5XVyhzPR2ra1ZC7WeFoAACPCgAAkdrAVYeuSJySFyo-D0E"
SHINN_FILE_NAME = "ShinnCheatV2Free.ipa"
SHINN_FILE_CAPTION = (
    "╭────────────────────────────╮\n"
    "   📱 <b>SHINNCHEAT — FILE APP</b>\n"
    "╰────────────────────────────╯\n\n"
    "🇻🇳 <b>Phiên bản:</b> V2 Free\n"
    "📦 <b>Dung lượng:</b> ~8.6 MB\n"
    "🔑 <b>Key test:</b> <code>ShinnCheatTest</code>\n"
    "🛒 <b>Mua key:</b> @{owner}\n\n"
    "━━━━━━━━━━━━━━━━━━━━━\n"
    "🇬🇧 <b>Version:</b> V2 Free\n"
    "📦 <b>Size:</b> ~8.6 MB\n"
    "🔑 <b>Trial key:</b> <code>ShinnCheatTest</code>\n"
    "🛒 <b>Buy key:</b> @{owner}\n"
    "━━━━━━━━━━━━━━━━━━━━━\n\n"
    "⚠️ <i>Chỉ tải từ nhóm chính thức / Official group only</i>"
)

VN_TZ = timezone(timedelta(hours=7))

# === Giờ auto ===
MORNING_HOUR, MORNING_MINUTE = 7, 0
NIGHT_HOUR, NIGHT_MINUTE = 22, 0

# === Anti-spam ===
SPAM_WINDOW = 10
SPAM_THRESHOLD = 5
MUTE_DURATION = timedelta(days=1)
URL_FILTER = filters.TEXT & filters.Regex(r"(?i)(https?://|www\.|t\.me/|telegram\.me/)")

# === Xác thực ===
VERIFY_TIMEOUT_SEC = 180
VERIFY_MAX_ATTEMPTS = 2

# === Bộ nhớ ===
user_cmd_times: dict[int, deque] = defaultdict(deque)
user_msg_count: Counter = Counter()
user_msg_text: dict[int, str] = {}
user_first_seen: dict[int, float] = {}
user_name_cache: dict[int, str] = {}
warn_count: dict[int, int] = defaultdict(int)
WARN_LIMIT = 3
pending_verifications: dict[int, dict] = {}

# ==================== KEYBOARDS ====================
def contact_keyboard() -> InlineKeyboardMarkup:
    return InlineKeyboardMarkup([
        [
            InlineKeyboardButton("📩 Telegram", url=LINK_TELEGRAM),
            InlineKeyboardButton("📘 Facebook", url=LINK_FACEBOOK),
        ],
        [InlineKeyboardButton("🎵 TikTok", url=LINK_TIKTOK)],
    ])

def buy_keyboard() -> InlineKeyboardMarkup:
    return InlineKeyboardMarkup([
        [
            InlineKeyboardButton("📩 Telegram", url=LINK_TELEGRAM),
            InlineKeyboardButton("📘 Facebook", url=LINK_FACEBOOK),
        ],
        [
            InlineKeyboardButton("🎵 TikTok", url=LINK_TIKTOK),
            InlineKeyboardButton("👑 Owner Info", callback_data="show_owner"),
        ],
    ])

def support_keyboard() -> InlineKeyboardMarkup:
    return contact_keyboard()

def key_keyboard() -> InlineKeyboardMarkup:
    return InlineKeyboardMarkup([
        [
            InlineKeyboardButton("📩 Nhắn Owner", url=LINK_TELEGRAM),
            InlineKeyboardButton("📘 Facebook", url=LINK_FACEBOOK),
        ],
        [InlineKeyboardButton("🎵 TikTok", url=LINK_TIKTOK)],
    ])

# ==================== TEXT SONG NGỮ ====================
TEXTS = {
    "start": (
        "╭────────────────────────────╮\n"
        "   👋 <b>CHÀO MỪNG / WELCOME</b>\n"
        "╰────────────────────────────╯\n\n"
        "🤖 <b>ShinnCheat Support Bot</b>\n"
        "🤖 <b>Bot hỗ trợ cộng đồng ShinnCheat</b>\n\n"
        "━━━ 🇻🇳 <b>TIẾNG VIỆT</b> ━━━\n"
        "Bạn có thể <b>nhắn tự nhiên</b>, không cần dùng lệnh!\n\n"
        "Thử gõ:\n"
        "  • <code>shinn</code> → 📎 Nhận file app\n"
        "  • <code>key</code> → 🔑 Xem key\n"
        "  • <code>mua key</code> → 🛒 Mua key\n"
        "  • <code>owner</code> → 👑 Liên hệ Owner\n"
        "  • <code>hỗ trợ</code> → 🛠️ Cần giúp đỡ\n\n"
        "━━━ 🇬🇧 <b>ENGLISH</b> ━━━\n"
        "You can <b>type naturally</b>, no commands needed!\n\n"
        "Try:\n"
        "  • <code>shinn</code> → 📎 Get app file\n"
        "  • <code>key</code> → 🔑 View keys\n"
        "  • <code>buy key</code> → 🛒 Buy a key\n"
        "  • <code>owner</code> → 👑 Contact Owner\n"
        "  • <code>support</code> → 🛠️ Get help\n\n"
        "📖 Gõ <code>/help</code> để xem đầy đủ / Type /help for full guide."
    ),
    "help": (
        "╭────────────────────────────╮\n"
        "   📋 <b>SHINNCHEAT — HƯỚNG DẪN / GUIDE</b>\n"
        "╰────────────────────────────╯\n\n"
        "💬 <b>NHẮN TỰ NHIÊN / NATURAL CHAT</b>:\n"
        "  • <code>shinn</code> → 📎 File app\n"
        "  • <code>ShinnCheatTest</code> → 🔑 Key test info\n"
        "  • <code>ShinnCheat</code> → 🔑 Key chính thức\n"
        "  • <code>key</code> / <code>xin key</code> → 🔑 Info key\n"
        "  • <code>mua key</code> / <code>buy key</code> → 🛒 Mua key\n"
        "  • <code>owner</code> / <code>admin</code> → 👑 Liên hệ Owner\n"
        "  • <code>update</code> → 🚀 Cập nhật mới\n"
        "  • <code>repo</code> / <code>tải</code> → 📦 Repository\n"
        "  • <code>hỗ trợ</code> / <code>support</code> → 🛠️ Trợ giúp\n"
        "  • <code>nội quy</code> / <code>rules</code> → 📜 Nội quy\n"
        "  • <code>about</code> → 🤖 Giới thiệu bot\n"
        "  • <code>ad ơi</code> → 🌙 Trạng thái Owner\n\n"
        "🛠️ <b>QUẢN LÝ / ADMIN:</b>\n"
        "  /pin /unpin /del\n"
        "  /mute [time] /unmute\n"
        "  /warn /unwarn /kick /ban /unban\n"
        "  /say /tagall /setfile\n\n"
        "📊 <b>THỐNG KÊ / STATS:</b>\n"
        "  /info /stats /top /id /chatid"
    ),
    "shinn": (
        "📱 <b>SHINNCHEAT</b>\n\n"
        "Gõ <code>shinn</code> để bot gửi file app nhé!\n"
        "Type <code>shinn</code> to receive the app file!"
    ),
    "key": (
        "╭────────────────────────────╮\n"
        "   🔑 <b>SHINNCHEAT KEYS</b>\n"
        "╰────────────────────────────╯\n\n"
        "🎫 <b>Danh sách key / Available keys:</b>\n\n"
        "  • <code>ShinnCheat</code> — Key chính thức / Official\n"
        "  • <code>ShinnCheatTest</code> — Key dùng thử / Trial\n\n"
        "━━━━━━━━━━━━━━━━━━━━━\n"
        "🇻🇳 <b>Đặc điểm:</b>\n"
        "  ✅ Không giới hạn thiết bị\n"
        "  ✅ Kích hoạt nhanh chóng\n"
        "  ✅ Hỗ trợ đầy đủ tính năng\n\n"
        "🇬🇧 <b>Features:</b>\n"
        "  ✅ Unlimited devices\n"
        "  ✅ Fast activation\n"
        "  ✅ Full features\n"
        "━━━━━━━━━━━━━━━━━━━━━\n\n"
        "🛒 <b>Mua key / Buy key:</b> Nhấn nút bên dưới\n"
        "👇 Choose a contact channel:"
    ),
    "key_test": (
        "╭────────────────────────────╮\n"
        "   🔑 <b>KEY TEST — SHINNCHEAT</b>\n"
        "╰────────────────────────────╯\n\n"
        "🎫 <b>Key dùng thử / Trial key:</b>\n"
        "  <code>ShinnCheatTest</code>\n\n"
        "━━━━━━━━━━━━━━━━━━━━━\n"
        "🇻🇳 <b>Thông tin key test:</b>\n"
        "  ⏱️ Dùng thử để trải nghiệm app\n"
        "  🎯 Một số tính năng có thể bị giới hạn\n"
        "  💳 Nâng cấp lên key chính thức để dùng full\n\n"
        "🇬🇧 <b>Trial key info:</b>\n"
        "  ⏱️ Trial to experience the app\n"
        "  🎯 Some features may be limited\n"
        "  💳 Upgrade to official key for full access\n"
        "━━━━━━━━━━━━━━━━━━━━━\n\n"
        "📱 <b>Cách dùng / How to use:</b>\n"
        "  • <code>ShinnCheatTest</code> → Key test\n"
        "  • <code>ShinnCheat</code> → Key chính thức\n\n"
        "🛒 Nâng cấp key / Upgrade: @{owner}\n"
        "👇 Chọn kênh liên hệ / Choose channel:"
    ),
    "key_official": (
        "╭────────────────────────────╮\n"
        "   🔑 <b>KEY CHÍNH THỨC / OFFICIAL KEY</b>\n"
        "╰────────────────────────────╯\n\n"
        "🎫 <b>Key chính thức / Official key:</b>\n"
        "  <code>ShinnCheat</code>\n\n"
        "━━━━━━━━━━━━━━━━━━━━━\n"
        "🇻🇳 <b>Quyền lợi:</b>\n"
        "  ✅ Mở khóa toàn bộ tính năng\n"
        "  ✅ Không giới hạn thiết bị\n"
        "  ✅ Hỗ trợ ưu tiên từ Owner\n"
        "  ✅ Cập nhật phiên bản mới nhất\n\n"
        "🇬🇧 <b>Benefits:</b>\n"
        "  ✅ Unlock all features\n"
        "  ✅ Unlimited devices\n"
        "  ✅ Priority support from Owner\n"
        "  ✅ Latest version updates\n"
        "━━━━━━━━━━━━━━━━━━━━━\n\n"
        "🛒 <b>Mua key / Buy key:</b> @{owner}\n"
        "👇 Chọn kênh liên hệ / Choose channel:"
    ),
    "buy": (
        "╭────────────────────────────╮\n"
        "   🛒 <b>MUA KEY / BUY KEY</b>\n"
        "╰────────────────────────────╯\n\n"
        "🇻🇳 <b>Để mua key ShinnCheat:</b>\n"
        "Hãy chọn kênh liên hệ bên dưới để được hỗ trợ nhanh nhất.\n\n"
        "🇬🇧 <b>To purchase a ShinnCheat key:</b>\n"
        "Choose a contact channel below for the fastest support.\n\n"
        "━━━━━━━━━━━━━━━━━━━━━\n"
        "💡 <b>Lưu ý / Note:</b>\n"
        "Nếu nhắn Telegram không thấy phản hồi, "
        "bạn có thể thử liên hệ qua <b>Facebook</b> hoặc <b>TikTok</b>!\n\n"
        "If Telegram doesn't respond, you can try contacting via "
        "<b>Facebook</b> or <b>TikTok</b>!\n"
        "━━━━━━━━━━━━━━━━━━━━━\n\n"
        "👇 <b>Chọn kênh / Choose channel:</b>"
    ),
    "owner": (
        "╭────────────────────────────╮\n"
        "   👑 <b>SHINNCHEAT OWNER</b>\n"
        "╰────────────────────────────╯\n\n"
        "🇻🇳 Liên hệ Owner để mua key hoặc cần hỗ trợ.\n"
        "🇬🇧 Contact the Owner for keys or support.\n\n"
        "━━━━━━━━━━━━━━━━━━━━━\n"
        "📱 <b>Telegram:</b> @{owner}\n"
        "📘 <b>Facebook:</b> NgVuMinhHieuu\n"
        "🎵 <b>TikTok:</b> @._ngvuminhhieuu\n"
        "━━━━━━━━━━━━━━━━━━━━━\n\n"
        "💡 <i>Nếu nhắn Telegram không thấy mình trả lời, "
        "bạn hãy thử nhắn qua Facebook hoặc TikTok nhé!</i>\n\n"
        "💡 <i>If Telegram doesn't respond, try contacting via "
        "Facebook or TikTok!</i>"
    ),
    "update": (
        "╭────────────────────────────╮\n"
        "   🚀 <b>CẬP NHẬT / UPDATE</b>\n"
        "╰────────────────────────────╯\n\n"
        "🇻🇳 <b>Phiên bản mới nhất:</b>\n"
        "  ✨ Giao diện được thiết kế lại\n"
        "  🎨 Cải thiện màu sắc và hiển thị\n"
        "  🖼️ Hỗ trợ cập nhật ảnh đại diện\n"
        "  🔧 Cải thiện Apply / Restore Patch\n"
        "  ⚡ Tối ưu hiệu suất và sửa lỗi\n"
        "  🔄 Cải thiện đồng bộ Repository\n\n"
        "🇬🇧 <b>Latest version:</b>\n"
        "  ✨ Redesigned interface\n"
        "  🎨 Improved colors & display\n"
        "  🖼️ Avatar update support\n"
        "  🔧 Better Apply/Restore Patch\n"
        "  ⚡ Performance boost & bug fixes\n"
        "  🔄 Better repository sync"
    ),
    "repo": (
        "╭────────────────────────────╮\n"
        "   📦 <b>REPOSITORY</b>\n"
        "╰────────────────────────────╯\n\n"
        "🇻🇳 Theo dõi thông báo trong nhóm để nhận liên kết repository mới nhất.\n"
        "🇬🇧 Check group announcements for the latest repository links.\n\n"
        "⚠️ <b>Cảnh báo / Warning:</b>\n"
        "🇻🇳 Chỉ tải file từ nguồn uy tín\n"
        "🇬🇧 Only download from trusted sources"
    ),
    "support": (
        "╭────────────────────────────╮\n"
        "   🛠️ <b>HỖ TRỢ / SUPPORT</b>\n"
        "╰────────────────────────────╯\n\n"
        "🇻🇳 <b>Khi cần hỗ trợ, hãy cung cấp:</b>\n"
        "  • Mô tả lỗi cụ thể\n"
        "  • Phiên bản iOS đang dùng\n"
        "  • Các bước gây ra lỗi\n\n"
        "🇬🇧 <b>When requesting support, provide:</b>\n"
        "  • Detailed issue description\n"
        "  • Your iOS version\n"
        "  • Steps to reproduce\n\n"
        "🔒 <b>Bảo mật / Security:</b>\n"
        "🇻🇳 Không gửi mật khẩu hoặc token cho bất kỳ ai\n"
        "🇬🇧 Never send passwords or tokens to anyone\n\n"
        "━━━━━━━━━━━━━━━━━━━━━\n"
        "💡 <i>Nếu nhắn Telegram không thấy phản hồi, "
        "hãy thử liên hệ qua Facebook hoặc TikTok bên dưới!</i>\n"
        "💡 <i>If Telegram doesn't respond, try Facebook or TikTok below!</i>\n"
        "━━━━━━━━━━━━━━━━━━━━━\n\n"
        "👇 <b>Chọn kênh / Choose channel:</b>"
    ),
    "rules": (
        "╭────────────────────────────╮\n"
        "   📜 <b>NỘI QUY NHÓM / GROUP RULES</b>\n"
        "╰────────────────────────────╯\n\n"
        "1️⃣ Tôn trọng mọi thành viên / Respect all members\n"
        "2️⃣ Không spam, không quảng cáo trái phép\n"
        "   No spam, no unauthorized ads\n"
        "3️⃣ Không giả mạo Owner / Do not impersonate Owner\n"
        "4️⃣ Không chia sẻ thông tin cá nhân người khác\n"
        "   Do not share others' private info\n"
        "5️⃣ Liên hệ admin khi cần hỗ trợ\n"
        "   Contact admins when you need help\n\n"
        "⚠️ <b>Vi phạm sẽ bị mute/kick/ban tùy mức độ!</b>\n"
        "⚠️ <b>Violations will result in mute/kick/ban!</b>"
    ),
    "about": (
        "╭────────────────────────────╮\n"
        "   🤖 <b>SHINNCHEAT BOT</b>\n"
        "╰────────────────────────────╯\n\n"
        "🇻🇳 Bot hỗ trợ cộng đồng ShinnCheat:\n"
        "  • Thông tin ứng dụng\n"
        "  • Key và mua key\n"
        "  • Cập nhật phiên bản\n"
        "  • Hỗ trợ kỹ thuật\n"
        "  • Quản lý nhóm tự động\n\n"
        "🇬🇧 A community bot for ShinnCheat:\n"
        "  • App information\n"
        "  • Keys and purchasing\n"
        "  • Version updates\n"
        "  • Technical support\n"
        "  • Automated group management\n\n"
        "━━━━━━━━━━━━━━━━━━━━━\n"
        "👑 <b>Owner:</b> @{owner}\n"
        "📘 <b>Facebook:</b> NgVuMinhHieuu\n"
        "🎵 <b>TikTok:</b> @._ngvuminhhieuu\n"
        "━━━━━━━━━━━━━━━━━━━━━\n\n"
        "💬 <b>Nhắn tự nhiên, không cần lệnh!</b>\n"
        "💬 <b>Type naturally, no commands needed!</b>"
    ),
    "ad": (
        "╭────────────────────────────╮\n"
        "   🌙 <b>THÔNG BÁO TỪ OWNER</b>\n"
        "╰────────────────────────────╯\n\n"
        "🇻🇳 Shinn đã ngủ. Nếu có việc gấp, liên hệ trực tiếp nhé!\n"
        "🇬🇧 Shinn is asleep. For urgent matters, contact directly!\n\n"
        "━━━━━━━━━━━━━━━━━━━━━\n"
        "💡 <i>Nếu nhắn Telegram không thấy mình trả lời, "
        "bạn hãy thử nhắn qua Facebook hoặc TikTok nhé!</i>\n\n"
        "💡 <i>If Telegram doesn't respond, try contacting via "
        "Facebook or TikTok!</i>\n"
        "━━━━━━━━━━━━━━━━━━━━━\n\n"
        "👇 <b>Chọn kênh / Choose channel:</b>"
    ),
}

def render(key: str) -> str:
    return TEXTS[key].format(owner=OWNER_USERNAME)

# ==================== HELPERS ====================
BOT_START_TIME = time.time()

def _is_allowed_chat(update: Update) -> bool:
    chat = update.effective_chat
    return chat is not None and chat.id == ALLOWED_CHAT_ID

async def _is_privileged(chat, user) -> bool:
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

def _display_name(user) -> str:
    if user is None:
        return "Ẩn danh / Anonymous"
    return user.full_name or user.username or str(user.id)

async def _delayed_delete(message, delay: float):
    await asyncio.sleep(delay)
    try:
        await message.delete()
    except Exception:
        pass

def _full_perms() -> ChatPermissions:
    return ChatPermissions(
        can_send_messages=True, can_send_audios=True, can_send_documents=True,
        can_send_photos=True, can_send_videos=True, can_send_video_notes=True,
        can_send_voice_notes=True, can_send_polls=True,
        can_send_other_messages=True, can_add_web_page_previews=True,
        can_invite_users=True,
    )

def _muted_perms() -> ChatPermissions:
    return ChatPermissions(
        can_send_messages=False, can_send_audios=False, can_send_documents=False,
        can_send_photos=False, can_send_videos=False, can_send_video_notes=False,
        can_send_voice_notes=False, can_send_polls=False,
        can_send_other_messages=False, can_add_web_page_previews=False,
    )

async def _spam_guard(update: Update, context: ContextTypes.DEFAULT_TYPE) -> bool:
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
        await chat.restrict_member(user.id, _muted_perms(), until_date=until)
        warn = await msg.reply_text(
            f"🔇 {user.mention_html()} đã bị <b>mute 1 ngày</b> vì spam.\n"
            f"🔇 {user.mention_html()} has been <b>muted for 1 day</b> for spamming.",
            parse_mode="HTML",
        )
        asyncio.create_task(_delayed_delete(warn, 15))
    except Exception as e:
        logging.warning("Mute failed: %s", e)
    return False

# ==================== DECORATORS ====================
def group_only(func):
    async def wrapper(update: Update, context: ContextTypes.DEFAULT_TYPE):
        if not _is_allowed_chat(update):
            return
        return await func(update, context)
    return wrapper

def admin_only(func):
    async def wrapper(update: Update, context: ContextTypes.DEFAULT_TYPE):
        if not await _is_privileged(update.effective_chat, update.effective_user):
            if update.effective_message:
                await update.effective_message.reply_text(
                    "⛔ Chỉ admin hoặc Owner mới dùng được lệnh này.\n"
                    "⛔ Only admins or Owner can use this command."
                )
            return
        return await func(update, context)
    return wrapper

def spam_protected(func):
    async def wrapper(update: Update, context: ContextTypes.DEFAULT_TYPE):
        if not await _spam_guard(update, context):
            return
        return await func(update, context)
    return wrapper

# ==================== LINK FILTER ====================
@group_only
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
        logging.warning("Không xoá được link: %s", e)
        return
    try:
        warn = await chat.send_message(
            f"⚠️ {user.mention_html() if user else 'User'}, "
            f"không gửi link trong nhóm! / Links are not allowed!",
            parse_mode="HTML",
        )
        asyncio.create_task(_delayed_delete(warn, 10))
    except Exception:
        pass

# ==================== MESSAGE TRACKER ====================
@group_only
async def track_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user = update.effective_user
    msg = update.effective_message
    if user is None or msg is None or not msg.text:
        return
    user_msg_count[user.id] += 1
    user_msg_text[user.id] = msg.text[:100]
    user_name_cache[user.id] = _display_name(user)
    if user.id not in user_first_seen:
        user_first_seen[user.id] = time.time()

# ==================== XÁC THỰC THÀNH VIÊN MỚI ====================
def _gen_math_question() -> tuple[str, int, list[int]]:
    a = random.randint(3, 15)
    b = random.randint(2, 10)
    op = random.choice(["+", "-", "*"])
    if op == "+":
        ans = a + b
    elif op == "-":
        if a < b:
            a, b = b, a
        ans = a - b
    else:
        a = random.randint(2, 9)
        b = random.randint(2, 9)
        ans = a * b
    wrong = ans + random.choice([-3, -2, -1, 1, 2, 3])
    if wrong < 1 or wrong == ans:
        wrong = ans + 2
    options = [ans, wrong]
    random.shuffle(options)
    return f"{a} {op} {b}", ans, options

async def _kick_after_timeout(context: ContextTypes.DEFAULT_TYPE, user_id: int):
    await asyncio.sleep(VERIFY_TIMEOUT_SEC)
    info = pending_verifications.get(user_id)
    if not info:
        return
    try:
        await context.bot.ban_chat_member(info["chat_id"], user_id)
        await context.bot.unban_chat_member(info["chat_id"], user_id)
        try:
            await context.bot.delete_message(info["chat_id"], info["message_id"])
        except Exception:
            pass
        await context.bot.send_message(
            info["chat_id"],
            f"⏱️ Thành viên <a href=\"tg://user?id={user_id}\">này</a> "
            f"đã bị kick do không xác thực trong {VERIFY_TIMEOUT_SEC // 60} phút.\n"
            f"⏱️ Member was kicked for not verifying within {VERIFY_TIMEOUT_SEC // 60} minutes.",
            parse_mode="HTML",
        )
    except Exception as e:
        logging.warning("Kick timeout failed: %s", e)
    pending_verifications.pop(user_id, None)

@group_only
async def welcome_new_member(update: Update, context: ContextTypes.DEFAULT_TYPE):
    msg = update.effective_message
    chat = update.effective_chat
    if msg is None or chat is None or not msg.new_chat_members:
        return

    for new_user in msg.new_chat_members:
        if new_user.is_bot:
            continue

        user_name_cache[new_user.id] = _display_name(new_user)
        user_first_seen.setdefault(new_user.id, time.time())

        try:
            member_count = await context.bot.get_chat_member_count(chat.id)
        except Exception:
            member_count = "?"

        mention = new_user.mention_html()

        try:
            await chat.restrict_member(new_user.id, _muted_perms())
        except Exception as e:
            logging.warning("Không mute được user mới: %s", e)

        question, answer, options = _gen_math_question()
        buttons = [[
            InlineKeyboardButton(str(options[0]), callback_data=f"verify:{new_user.id}:{options[0]}"),
            InlineKeyboardButton(str(options[1]), callback_data=f"verify:{new_user.id}:{options[1]}"),
        ]]
        keyboard = InlineKeyboardMarkup(buttons)

        text = (
            "╔════════════════════════╗\n"
            "   🎉 <b>CHÀO MỪNG / WELCOME</b> 🎉\n"
            "╚════════════════════════╝\n\n"
            f"👤 <b>{mention}</b>\n"
            f"📆 Tham gia / Joined: <i>{datetime.now(VN_TZ).strftime('%d/%m/%Y %H:%M')}</i>\n"
            f"🎫 Thành viên thứ / Member #: <b>{member_count}</b>\n\n"
            "━━━━━━━━━━━━━━━━━━━━━\n"
            "🔐 <b>XÁC THỰC ĐỂ CHAT</b>\n"
            "🔐 <b>VERIFY TO CHAT</b>\n"
            "━━━━━━━━━━━━━━━━━━━━━\n"
            f"❓ Câu hỏi / Question: <code>{question} = ?</code>\n"
            "👉 Chọn đáp án / Choose answer:\n"
            f"⏱️ Hết hạn / Expires: <b>{VERIFY_TIMEOUT_SEC // 60} phút / min</b>."
        )

        try:
            sent = await chat.send_message(
                text, parse_mode="HTML",
                reply_markup=keyboard,
                disable_web_page_preview=True,
            )
        except Exception as e:
            logging.warning("Không gửi được tin chào: %s", e)
            continue

        pending_verifications[new_user.id] = {
            "answer": answer,
            "options": options,
            "chat_id": chat.id,
            "message_id": sent.message_id,
            "attempts": 0,
        }

        task = asyncio.create_task(_kick_after_timeout(context, new_user.id))
        pending_verifications[new_user.id]["task"] = task

@group_only
async def verify_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    data = query.data
    if not data.startswith("verify:"):
        return
    try:
        _, user_id_str, chosen_str = data.split(":")
        user_id = int(user_id_str)
        chosen = int(chosen_str)
    except Exception:
        await query.answer("⚠️ Lỗi dữ liệu / Data error.", show_alert=True)
        return

    if query.from_user.id != user_id:
        await query.answer("⚠️ Không phải câu hỏi của bạn / Not your question.", show_alert=True)
        return

    info = pending_verifications.get(user_id)
    if not info:
        await query.answer("⚠️ Phiên đã hết hạn / Session expired.", show_alert=True)
        try:
            await query.message.delete()
        except Exception:
            pass
        return

    if chosen == info["answer"]:
        try:
            await context.bot.restrict_member(user_id, _full_perms())
        except Exception as e:
            logging.warning("Unmute failed: %s", e)

        try:
            await query.message.delete()
        except Exception:
            pass

        t = info.get("task")
        if t:
            t.cancel()
        pending_verifications.pop(user_id, None)

        await context.bot.send_message(
            info["chat_id"],
            "╔════════════════════════╗\n"
            "   ✅ <b>XÁC THỰC THÀNH CÔNG / VERIFIED</b>\n"
            "╚════════════════════════╝\n\n"
            f"🎊 Chào mừng <a href=\"tg://user?id={user_id}\">{query.from_user.full_name}</a>!\n\n"
            "━━━━━━━━━━━━━━━━━━━━━\n"
            "💬 <b>Bạn có thể chat ngay / You can chat now</b>\n"
            "━━━━━━━━━━━━━━━━━━━━━\n\n"
            "📋 <b>Lệnh hữu ích / Helpful commands:</b>\n"
            "  • /help — Hướng dẫn / Guide\n"
            "  • /rules — Nội quy / Rules\n"
            "  • /info — Thông tin / Your info\n"
            "  • <code>shinn</code> — Nhận file app / Get app file\n"
            "  • <code>key</code> — Xem key / View keys\n"
            "  • <code>mua key</code> — Mua key / Buy key\n"
            "  • <code>hỗ trợ</code> — Cần giúp / Get help\n\n"
            "🎉 <b>Chúc bạn trải nghiệm vui vẻ!</b>\n"
            "🎉 <b>Have a great experience!</b>",
            parse_mode="HTML",
            disable_web_page_preview=True,
        )
    else:
        info["attempts"] += 1
        if info["attempts"] >= VERIFY_MAX_ATTEMPTS:
            try:
                await context.bot.ban_chat_member(info["chat_id"], user_id)
                await context.bot.unban_chat_member(info["chat_id"], user_id)
            except Exception as e:
                logging.warning("Kick failed: %s", e)

            t = info.get("task")
            if t:
                t.cancel()
            pending_verifications.pop(user_id, None)

            try:
                await query.message.delete()
            except Exception:
                pass

            await context.bot.send_message(
                info["chat_id"],
                f"🚫 <a href=\"tg://user?id={user_id}\">{query.from_user.full_name}</a> "
                f"đã bị kick do trả lời sai {VERIFY_MAX_ATTEMPTS} lần.\n"
                f"🚫 Kicked for failing {VERIFY_MAX_ATTEMPTS} times.",
                parse_mode="HTML",
            )
        else:
            question, answer, options = _gen_math_question()
            info["answer"] = answer
            info["options"] = options

            buttons = [[
                InlineKeyboardButton(str(options[0]), callback_data=f"verify:{user_id}:{options[0]}"),
                InlineKeyboardButton(str(options[1]), callback_data=f"verify:{user_id}:{options[1]}"),
            ]]
            keyboard = InlineKeyboardMarkup(buttons)

            try:
                await query.edit_message_text(
                    "╔════════════════════════╗\n"
                    "   ⚠️ <b>SAI RỒI / WRONG</b>\n"
                    "╚════════════════════════╝\n\n"
                    f"👤 <a href=\"tg://user?id={user_id}\">{query.from_user.full_name}</a>\n"
                    f"❌ Lần thử / Attempts: <b>{info['attempts']}/{VERIFY_MAX_ATTEMPTS}</b>\n\n"
                    "━━━━━━━━━━━━━━━━━━━━━\n"
                    "🔐 <b>XÁC THỰC LẠI / RETRY</b>\n"
                    "━━━━━━━━━━━━━━━━━━━━━\n"
                    f"❓ Câu hỏi: <code>{question} = ?</code>",
                    parse_mode="HTML",
                    reply_markup=keyboard,
                )
            except Exception as e:
                logging.warning("Edit verify msg failed: %s", e)

    await query.answer()

# ==================== OWNER CALLBACK ====================
@group_only
async def owner_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    try:
        await query.edit_message_text(
            render("owner"),
            parse_mode="HTML",
            reply_markup=contact_keyboard(),
            disable_web_page_preview=True,
        )
    except Exception as e:
        logging.warning("Owner callback failed: %s", e)

# ==================== TẠM BIỆT ====================
@group_only
async def goodbye_member(update: Update, context: ContextTypes.DEFAULT_TYPE):
    msg = update.effective_message
    chat = update.effective_chat
    if msg is None or chat is None:
        return
    left = msg.left_chat_member
    if left is None or left.is_bot:
        return

    mention = left.mention_html()
    name = _display_name(left)

    user_msg_count.pop(left.id, None)
    user_msg_text.pop(left.id, None)
    user_name_cache.pop(left.id, None)
    warn_count.pop(left.id, None)
    pending_verifications.pop(left.id, None)

    try:
        member_count = await context.bot.get_chat_member_count(chat.id)
    except Exception:
        member_count = "?"

    text = (
        "╭────────────────────────────╮\n"
        "   👋 <b>TẠM BIỆT / GOODBYE</b>\n"
        "╰────────────────────────────╯\n\n"
        f"👤 <b>{mention}</b>\n"
        f"📆 Rời nhóm / Left: <i>{datetime.now(VN_TZ).strftime('%d/%m/%Y %H:%M')}</i>\n"
        f"🎫 Còn lại / Remaining: <b>{member_count}</b>\n\n"
        f"💫 Chúc <b>{name}</b> mọi điều tốt lành!\n"
        f"💫 Best wishes to <b>{name}</b>!\n\n"
        "🚪 Cánh cửa nhóm luôn mở rộng chào đón bạn trở lại.\n"
        "🚪 The door is always open for your return."
    )
    try:
        await chat.send_message(text, parse_mode="HTML", disable_web_page_preview=True)
    except Exception as e:
        logging.warning("Không gửi được tin tạm biệt: %s", e)

# ==================== CHÀO SÁNG / NGỦ NGON ====================
def _morning_text() -> str:
    today = datetime.now(VN_TZ).strftime("%d/%m/%Y")
    quotes = [
        "Hôm nay là một ngày mới, hãy bắt đầu với năng lượng tích cực! 💪\nA new day begins with positive energy!",
        "Chúc bạn một ngày tràn đầy niềm vui và thành công! 🌟\nWishing you a joyful and successful day!",
        "Sáng nay uống đủ nước, làm việc hiệu quả nhé! ☕\nStay hydrated and work efficiently!",
        "Mỗi sáng thức dậy là một cơ hội mới. Cố lên! 🔥\nEvery morning is a new opportunity. Keep going!",
        "Chúc cả nhóm một ngày tuyệt vời và nhiều điều may mắn! 🍀\nWishing everyone a wonderful and lucky day!",
    ]
    return (
        "╔════════════════════════╗\n"
        "   ☀️ <b>CHÀO BUỔI SÁNG / GOOD MORNING</b> ☀️\n"
        "╚════════════════════════╝\n\n"
        f"📅 Hôm nay / Today: <b>{today}</b>\n"
        f"🕖 <b>{MORNING_HOUR:02d}:{MORNING_MINUTE:02d}</b>\n\n"
        "━━━━━━━━━━━━━━━━━━━━━\n"
        f"💬 {random.choice(quotes)}\n"
        "━━━━━━━━━━━━━━━━━━━━━\n\n"
        "☕ <b>Chúc cả nhóm một ngày mới tràn đầy năng lượng!</b>\n"
        "☕ <b>Have a wonderful day, everyone!</b>\n\n"
        "🌤️ <i>ShinnCheat Team</i>"
    )

def _night_text() -> str:
    today = datetime.now(VN_TZ).strftime("%d/%m/%Y")
    quotes = [
        "Ngủ ngon nhé, mai lại là một ngày mới tuyệt vời! 🌙\nSleep well, tomorrow is another wonderful day!",
        "Hãy để những muộn phiền ngủ yên, chúc bạn ngủ ngon! 💤\nLet worries sleep, good night!",
        "Đêm nay ngủ đủ giấc, mai dậy thật khỏe nhé! ✨\nSleep well tonight, wake up refreshed!",
        "Chúc cả nhóm có những giấc mơ đẹp! 🌌\nSweet dreams to everyone!",
        "Nghỉ ngơi thôi, sức khỏe là vàng! 💛\nTime to rest — health is gold!",
    ]
    return (
        "╔════════════════════════╗\n"
        "   🌙 <b>CHÚC NGỦ NGON / GOOD NIGHT</b> 🌙\n"
        "╚════════════════════════╝\n\n"
        f"📅 Hôm nay / Today: <b>{today}</b>\n"
        f"🕙 <b>{NIGHT_HOUR:02d}:{NIGHT_MINUTE:02d}</b>\n\n"
        "━━━━━━━━━━━━━━━━━━━━━\n"
        f"💬 {random.choice(quotes)}\n"
        "━━━━━━━━━━━━━━━━━━━━━\n\n"
        "😴 <b>Chúc cả nhóm ngủ ngon và có những giấc mơ đẹp!</b>\n"
        "😴 <b>Good night and sweet dreams, everyone!</b>\n\n"
        "💤 <i>ShinnCheat Team</i>"
    )

async def morning_job(context: ContextTypes.DEFAULT_TYPE):
    try:
        await context.bot.send_message(
            chat_id=ALLOWED_CHAT_ID,
            text=_morning_text(),
            parse_mode="HTML",
            disable_web_page_preview=True,
        )
        logging.info("Đã gửi lời chào buổi sáng.")
    except Exception as e:
        logging.warning("Morning job failed: %s", e)

async def night_job(context: ContextTypes.DEFAULT_TYPE):
    try:
        await context.bot.send_message(
            chat_id=ALLOWED_CHAT_ID,
            text=_night_text(),
            parse_mode="HTML",
            disable_web_page_preview=True,
        )
        logging.info("Đã gửi lời chúc ngủ ngon.")
    except Exception as e:
        logging.warning("Night job failed: %s", e)

# ==================== KEYWORD AUTO-REPLY ====================
# (keywords, text_key, keyboard_kind)
KEYWORD_MAP = [
    # ⭐ KEY TEST / OFFICIAL KEY — ưu tiên cao, đặt trước "key"
    (["shinncheattest", "shinncheat test", "key test", "key trial", "test key",
      "dùng thử", "dung thu", "trial key"], "key_test", "key"),

    (["shinncheat", "shinn cheat", "key chính thức", "key chinh thuc",
      "official key"], "key_official", "key"),

    # Key generic
    (["key là gì", "key la gi", "key nào", "key nao",
      "danh sách key", "danh sach key", "key free", "key miễn phí", "key mien phi",
      "xin key", "cho key", "lấy key", "lay key", "có key không", "co key khong",
      "xem key", "list key"], "key", "key"),

    # Mua key
    (["mua key", "buy key", "giá key", "gia key", "bao nhiêu", "bao nhieu",
      "price", "giá bao", "gia bao", "mua ở đâu", "mua o dau",
      "purchase", "order key"], "buy", "buy"),

    # Owner
    (["owner là ai", "owner la ai", "admin là ai", "admin la ai",
      "liên hệ owner", "lien he owner", "contact owner",
      "ai làm bot", "ai lam bot", "chủ bot", "chu bot",
      "gặp owner", "gap owner"], "owner", "contact"),

    # Update
    (["update", "cập nhật", "cap nhat", "bản mới", "ban moi",
      "version", "phiên bản", "phien ban", "new version"], "update", None),

    # Repo
    (["repo", "repository", "nguồn tải", "nguon tai",
      "tải ở đâu", "tai o dau", "download", "link tải", "link tai",
      "download link"], "repo", None),

    # Support
    (["support", "hỗ trợ", "ho tro", "help me", "giúp với", "giup voi",
      "bị lỗi", "bi loi", "không dùng được", "khong dung duoc",
      "issue", "problem", "error"], "support", "support"),

    # Rules
    (["nội quy", "noi quy", "rules", "quy định", "quy dinh",
      "luật nhóm", "luat nhom", "quy tắc", "quy tac"], "rules", None),

    # About
    (["bot là gì", "bot la gi", "about", "giới thiệu", "gioi thieu",
      "bot này là gì", "bot nay la gi", "what is bot"], "about", "contact"),

    # Ad
    (["owner ngủ", "owner ngu", "owner bận", "owner ban",
      "owner offline", "ad ơi", "ad oi", "admin ơi", "admin oi",
      "chủ ơi", "chu oi"], "ad", "contact"),
]

def _get_keyboard(kind):
    if kind == "contact":
        return contact_keyboard()
    if kind == "buy":
        return buy_keyboard()
    if kind == "support":
        return support_keyboard()
    if kind == "key":
        return key_keyboard()
    return None

@group_only
@spam_protected
async def keyword_reply(update: Update, context: ContextTypes.DEFAULT_TYPE):
    message = update.effective_message
    if not message or not message.text:
        return
    text = message.text.lower().strip()
    if len(text) < 2:
        return

    # ⭐ ƯU TIÊN CAO NHẤT: "shinn" đơn lẻ hoặc chứa "shinn" → gửi FILE APP
    # nhưng KHÔNG gửi file khi user chỉ nói về key (ShinnCheatTest, ShinnCheat key...)
    if "shinn" in text:
        # Nếu là nói về key → chuyển sang keyword map (không gửi file)
        is_about_key = any(kw in text for kw in [
            "shinncheattest", "shinncheat test", "key test", "key trial",
            "key chính thức", "key chinh thuc", "key là gì", "key la gi",
            "key nào", "key nao", "official key", "trial key",
        ])
        if not is_about_key:
            if SHINN_FILE_ID:
                try:
                    await message.reply_document(
                        document=SHINN_FILE_ID,
                        filename=SHINN_FILE_NAME,
                        caption=SHINN_FILE_CAPTION.format(owner=OWNER_USERNAME),
                        parse_mode="HTML",
                        reply_markup=contact_keyboard(),
                    )
                    return
                except Exception as e:
                    logging.warning("Gửi file thất bại: %s", e)
                    await message.reply_text(
                        render("shinn"), parse_mode="HTML",
                        reply_markup=contact_keyboard(),
                    )
                    return
            else:
                await message.reply_text(
                    render("shinn"), parse_mode="HTML",
                    reply_markup=contact_keyboard(),
                )
                return

    # Duyệt bảng từ khoá
    for keywords, reply_key, kb_kind in KEYWORD_MAP:
        if any(kw in text for kw in keywords):
            await message.reply_text(
                render(reply_key),
                parse_mode="HTML",
                reply_markup=_get_keyboard(kb_kind),
                disable_web_page_preview=True,
            )
            return

# ==================== /setfile ====================
@group_only
@admin_only
async def setfile_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    msg = update.effective_message
    if not msg.reply_to_message:
        await msg.reply_text(
            "📎 <b>Cách dùng /setfile:</b>\n\n"
            "1. Reply vào 1 tin nhắn có file (document)\n"
            "2. Gõ /setfile\n"
            "3. Bot in ra file_id → copy → dán vào <code>SHINN_FILE_ID</code> trong bot.py\n\n"
            "📎 <b>How to use /setfile:</b>\n"
            "Reply to a file message, then /setfile.",
            parse_mode="HTML",
        )
        return

    doc = msg.reply_to_message.document
    if doc is None:
        await msg.reply_text("⚠️ Tin nhắn không có file document. / No document found.")
        return

    text = (
        "╭────────────────────────────╮\n"
        "   📎 <b>FILE_ID</b>\n"
        "╰────────────────────────────╯\n\n"
        f"📄 <b>Tên / Name:</b> <code>{doc.file_name}</code>\n"
        f"📦 <b>Dung lượng / Size:</b> <b>{doc.file_size / 1024 / 1024:.2f} MB</b>\n"
        f"🎭 <b>MIME:</b> <code>{doc.mime_type}</code>\n\n"
        "━━━━━━━━━━━━━━━━━━━━━\n"
        "📋 <b>FILE_ID:</b>\n"
        "━━━━━━━━━━━━━━━━━━━━━\n"
        f"<code>{doc.file_id}</code>\n\n"
        "━━━━━━━━━━━━━━━━━━━━━\n"
        "👉 Dán vào <code>SHINN_FILE_ID</code> trong bot.py\n"
        "👉 Paste into <code>SHINN_FILE_ID</code> in bot.py"
    )
    await msg.reply_text(text, parse_mode="HTML")

# ==================== INFO COMMANDS ====================
@group_only
@spam_protected
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_message:
        await update.effective_message.reply_text(
            render("start"), parse_mode="HTML",
            reply_markup=contact_keyboard(),
            disable_web_page_preview=True,
        )

@group_only
@spam_protected
async def help_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_message:
        await update.effective_message.reply_text(render("help"), parse_mode="HTML")

@group_only
@spam_protected
async def id_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_message and update.effective_user:
        await update.effective_message.reply_text(
            f"👤 Tên / Name: <b>{_display_name(update.effective_user)}</b>\n"
            f"🆔 ID: <code>{update.effective_user.id}</code>\n"
            f"💬 Chat ID: <code>{update.effective_chat.id}</code>",
            parse_mode="HTML",
        )

@group_only
@spam_protected
async def chatid_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_message:
        await update.effective_message.reply_text(
            f"💬 Chat ID: <code>{update.effective_chat.id}</code>",
            parse_mode="HTML",
        )

def make_command(key: str):
    @group_only
    @spam_protected
    async def callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
        if not update.effective_message:
            return
        kb = None
        if key in ("owner", "about", "ad"):
            kb = contact_keyboard()
        elif key == "buy":
            kb = buy_keyboard()
        elif key == "support":
            kb = support_keyboard()
        elif key in ("key", "shinn"):
            kb = key_keyboard() if key == "key" else contact_keyboard()
        await update.effective_message.reply_text(
            render(key), parse_mode="HTML",
            reply_markup=kb, disable_web_page_preview=True,
        )
    return callback

# ==================== ADMIN COMMANDS ====================
@group_only
@admin_only
async def pin_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    msg = update.effective_message
    if not msg.reply_to_message:
        await msg.reply_text("⚠️ Reply vào tin nhắn cần ghim. / Reply to pin.")
        return
    try:
        await msg.reply_to_message.pin(disable_notification=False)
        await msg.reply_text("📌 Đã ghim. / Pinned.")
    except Exception as e:
        await msg.reply_text(f"❌ {e}")

@group_only
@admin_only
async def unpin_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        await update.effective_chat.unpin_all_messages()
        await update.effective_message.reply_text("📌 Đã bỏ ghim. / Unpinned.")
    except Exception as e:
        await update.effective_message.reply_text(f"❌ {e}")

@group_only
@admin_only
async def del_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    msg = update.effective_message
    if not msg.reply_to_message:
        await msg.reply_text("⚠️ Reply vào tin nhắn cần xoá. / Reply to delete.")
        return
    try:
        await msg.reply_to_message.delete()
        await msg.delete()
    except Exception as e:
        await msg.reply_text(f"❌ {e}")

@group_only
@admin_only
async def mute_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    msg = update.effective_message
    if not msg.reply_to_message or not msg.reply_to_message.from_user:
        await msg.reply_text("⚠️ Reply user cần mute. VD: /mute 1d hoặc /mute 30m")
        return
    target = msg.reply_to_message.from_user
    duration = MUTE_DURATION
    if context.args:
        m = re.match(r"^(\d+)([mhd])$", context.args[0].lower())
        if m:
            num, unit = int(m.group(1)), m.group(2)
            duration = timedelta(minutes=num) if unit == "m" else \
                       timedelta(hours=num) if unit == "h" else \
                       timedelta(days=num)
    until = datetime.now(timezone.utc) + duration
    try:
        await update.effective_chat.restrict_member(
            target.id, _muted_perms(), until_date=until
        )
        await msg.reply_text(
            f"🔇 Đã mute {target.mention_html()} trong <b>{duration}</b>.\n"
            f"🔇 Muted for <b>{duration}</b>.",
            parse_mode="HTML",
        )
    except Exception as e:
        await msg.reply_text(f"❌ {e}")

@group_only
@admin_only
async def unmute_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    msg = update.effective_message
    if not msg.reply_to_message or not msg.reply_to_message.from_user:
        await msg.reply_text("⚠️ Reply user cần unmute. / Reply to unmute.")
        return
    target = msg.reply_to_message.from_user
    try:
        await update.effective_chat.restrict_member(target.id, _full_perms())
        await msg.reply_text(
            f"🔊 Đã gỡ mute cho {target.mention_html()}. / Unmuted.",
            parse_mode="HTML",
        )
    except Exception as e:
        await msg.reply_text(f"❌ {e}")

@group_only
@admin_only
async def warn_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    msg = update.effective_message
    if not msg.reply_to_message or not msg.reply_to_message.from_user:
        await msg.reply_text("⚠️ Reply user cần cảnh cáo. / Reply to warn.")
        return
    target = msg.reply_to_message.from_user
    warn_count[target.id] += 1
    count = warn_count[target.id]
    if count >= WARN_LIMIT:
        until = datetime.now(timezone.utc) + MUTE_DURATION
        try:
            await update.effective_chat.restrict_member(
                target.id, _muted_perms(), until_date=until
            )
            warn_count[target.id] = 0
            await msg.reply_text(
                f"🔇 {target.mention_html()} đủ {WARN_LIMIT} warn → mute 1 ngày.\n"
                f"🔇 Reached {WARN_LIMIT} warns → muted 1 day.",
                parse_mode="HTML",
            )
        except Exception as e:
            await msg.reply_text(f"❌ {e}")
    else:
        await msg.reply_text(
            f"⚠️ {target.mention_html()} bị cảnh cáo ({count}/{WARN_LIMIT}).\n"
            f"⚠️ Warned ({count}/{WARN_LIMIT}).",
            parse_mode="HTML",
        )

@group_only
@admin_only
async def unwarn_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    msg = update.effective_message
    if not msg.reply_to_message or not msg.reply_to_message.from_user:
        await msg.reply_text("⚠️ Reply user cần gỡ warn. / Reply to unwarn.")
        return
    target = msg.reply_to_message.from_user
    warn_count[target.id] = 0
    await msg.reply_text(
        f"✅ Đã xoá warn cho {target.mention_html()}. / Warn cleared.",
        parse_mode="HTML",
    )

@group_only
@admin_only
async def kick_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    msg = update.effective_message
    if not msg.reply_to_message or not msg.reply_to_message.from_user:
        await msg.reply_text("⚠️ Reply user cần kick. / Reply to kick.")
        return
    target = msg.reply_to_message.from_user
    try:
        await update.effective_chat.ban_member(target.id)
        await update.effective_chat.unban_member(target.id)
        await msg.reply_text(
            f"👢 Đã kick {target.mention_html()}. / Kicked.",
            parse_mode="HTML",
        )
    except Exception as e:
        await msg.reply_text(f"❌ {e}")

@group_only
@admin_only
async def ban_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    msg = update.effective_message
    if not msg.reply_to_message or not msg.reply_to_message.from_user:
        await msg.reply_text("⚠️ Reply user cần ban. / Reply to ban.")
        return
    target = msg.reply_to_message.from_user
    try:
        await update.effective_chat.ban_member(target.id)
        await msg.reply_text(
            f"🚫 Đã ban {target.mention_html()}. / Banned.",
            parse_mode="HTML",
        )
    except Exception as e:
        await msg.reply_text(f"❌ {e}")

@group_only
@admin_only
async def unban_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    msg = update.effective_message
    if not context.args or not context.args[0].lstrip("-").isdigit():
        await msg.reply_text("⚠️ Dùng: /unban <user_id>")
        return
    target_id = int(context.args[0])
    try:
        await update.effective_chat.unban_member(target_id)
        await msg.reply_text(
            f"✅ Đã gỡ ban cho <code>{target_id}</code>. / Unbanned.",
            parse_mode="HTML",
        )
    except Exception as e:
        await msg.reply_text(f"❌ {e}")

@group_only
@admin_only
async def say_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    msg = update.effective_message
    if not context.args:
        await msg.reply_text("⚠️ Dùng: /say <nội dung>")
        return
    text = " ".join(context.args)
    try:
        await msg.delete()
    except Exception:
        pass
    await update.effective_chat.send_message(text)

@group_only
@admin_only
async def tagall_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    msg = update.effective_message
    if not user_name_cache:
        await msg.reply_text("⚠️ Chưa có user nào để tag. / No users to tag.")
        return
    content = " ".join(context.args) if context.args else "📢 Thông báo từ admin"
    mentions = [f'<a href="tg://user?id={uid}">{name}</a>'
                for uid, name in user_name_cache.items()]
    text = (
        "╭────────────────────────────╮\n"
        f"   <b>{content}</b>\n"
        "╰────────────────────────────╯\n\n"
        + " ".join(mentions)
    )
    try:
        await update.effective_chat.send_message(text, parse_mode="HTML")
    except Exception as e:
        await msg.reply_text(f"❌ {e}")

# ==================== STATS ====================
@group_only
@spam_protected
async def info_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    msg = update.effective_message
    target = (msg.reply_to_message.from_user
              if msg.reply_to_message and msg.reply_to_message.from_user
              else update.effective_user)
    count = user_msg_count.get(target.id, 0)
    first = user_first_seen.get(target.id)
    first_str = (datetime.fromtimestamp(first, VN_TZ).strftime("%d/%m/%Y %H:%M")
                 if first else "—")
    warns = warn_count.get(target.id, 0)
    last_msg = user_msg_text.get(target.id, "—")
    text = (
        "╭────────────────────────────╮\n"
        "   👤 <b>THÔNG TIN / USER INFO</b>\n"
        "╰────────────────────────────╯\n\n"
        f"👤 Tên / Name: <b>{_display_name(target)}</b>\n"
        f"🆔 ID: <code>{target.id}</code>\n"
        f"🔗 Username: @{target.username if target.username else '—'}\n"
        f"💬 Tin nhắn / Messages: <b>{count}</b>\n"
        f"⚠️ Warn: <b>{warns}</b>\n"
        f"⏰ Lần đầu / First seen: {first_str}\n"
        f"📝 Tin cuối / Last msg: <i>{last_msg}</i>"
    )
    await msg.reply_text(text, parse_mode="HTML")

@group_only
@spam_protected
async def stats_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    total_msgs = sum(user_msg_count.values())
    total_users = len(user_msg_count)
    delta = timedelta(seconds=int(time.time() - BOT_START_TIME))
    try:
        import resource
        mem = f"{resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024:.1f}"
    except Exception:
        mem = "?"
    text = (
        "╭────────────────────────────╮\n"
        "   📊 <b>THỐNG KÊ / STATS</b>\n"
        "╰────────────────────────────╯\n\n"
        f"👥 User đã thấy / Users seen: <b>{total_users}</b>\n"
        f"💬 Tổng tin nhắn / Total msgs: <b>{total_msgs}</b>\n"
        f"🔐 Chờ xác thực / Pending verify: <b>{len(pending_verifications)}</b>\n"
        f"📎 File app: <b>{'Có / Yes' if SHINN_FILE_ID else 'Chưa / No'}</b>\n"
        f"⏱️ Uptime: <b>{delta}</b>\n"
        f"🧠 RAM: <b>{mem} MB</b>\n"
        f"🌏 Timezone: <b>UTC+7</b>"
    )
    await update.effective_message.reply_text(text, parse_mode="HTML")

@group_only
@spam_protected
async def top_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not user_msg_count:
        await update.effective_message.reply_text("⚠️ Chưa có dữ liệu / No data.")
        return
    top = user_msg_count.most_common(10)
    lines = [
        "╭────────────────────────────╮",
        "   🏆 <b>TOP 10 ACTIVE</b>",
        "╰────────────────────────────╯",
        "",
    ]
    medals = ["🥇", "🥈", "🥉"]
    for i, (uid, count) in enumerate(top):
        medal = medals[i] if i < 3 else f"<b>{i+1}.</b>"
        name = user_name_cache.get(uid, str(uid))
        lines.append(
            f"{medal} <a href=\"tg://user?id={uid}\">{name}</a> — <b>{count}</b>"
        )
    await update.effective_message.reply_text("\n".join(lines), parse_mode="HTML")

# ==================== MAIN ====================
def main():
    app = Application.builder().token(BOT_TOKEN).build()

    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("help", help_cmd))
    app.add_handler(CommandHandler("id", id_cmd))
    app.add_handler(CommandHandler("chatid", chatid_cmd))
    for command in ("shinn", "key", "buy", "owner", "update", "repo",
                    "support", "rules", "about", "ad"):
        app.add_handler(CommandHandler(command, make_command(command)))

    app.add_handler(CommandHandler("pin", pin_cmd))
    app.add_handler(CommandHandler("unpin", unpin_cmd))
    app.add_handler(CommandHandler("del", del_cmd))
    app.add_handler(CommandHandler("mute", mute_cmd))
    app.add_handler(CommandHandler("unmute", unmute_cmd))
    app.add_handler(CommandHandler("warn", warn_cmd))
    app.add_handler(CommandHandler("unwarn", unwarn_cmd))
    app.add_handler(CommandHandler("kick", kick_cmd))
    app.add_handler(CommandHandler("ban", ban_cmd))
    app.add_handler(CommandHandler("unban", unban_cmd))
    app.add_handler(CommandHandler("say", say_cmd))
    app.add_handler(CommandHandler("tagall", tagall_cmd))
    app.add_handler(CommandHandler("setfile", setfile_cmd))

    app.add_handler(CommandHandler("info", info_cmd))
    app.add_handler(CommandHandler("stats", stats_cmd))
    app.add_handler(CommandHandler("top", top_cmd))

    app.add_handler(CallbackQueryHandler(verify_callback, pattern=r"^verify:"))
    app.add_handler(CallbackQueryHandler(owner_callback, pattern=r"^show_owner$"))

    app.add_handler(MessageHandler(
        filters.StatusUpdate.NEW_CHAT_MEMBERS, welcome_new_member
    ))
    app.add_handler(MessageHandler(
        filters.StatusUpdate.LEFT_CHAT_MEMBER, goodbye_member
    ))

    app.add_handler(MessageHandler(URL_FILTER & ~filters.COMMAND, delete_link_message))

    app.add_handler(MessageHandler(
        filters.TEXT & ~filters.COMMAND, track_message
    ), group=0)

    app.add_handler(MessageHandler(
        filters.TEXT & ~filters.COMMAND, keyword_reply
    ), group=1)

    if app.job_queue:
        app.job_queue.run_daily(
            morning_job,
            time=dt_time(hour=MORNING_HOUR, minute=MORNING_MINUTE, tzinfo=VN_TZ),
            name="morning_greeting",
        )
        app.job_queue.run_daily(
            night_job,
            time=dt_time(hour=NIGHT_HOUR, minute=NIGHT_MINUTE, tzinfo=VN_TZ),
            name="night_greeting",
        )
        logging.info(
            "Đã đặt lịch: chào sáng %02d:%02d, chúc ngủ ngon %02d:%02d (UTC+7)",
            MORNING_HOUR, MORNING_MINUTE, NIGHT_HOUR, NIGHT_MINUTE,
        )
    else:
        logging.warning("JobQueue KHÔNG khả dụng. Cài: pip install 'python-telegram-bot[job-queue]'")

    logging.info("ShinnCheat bot is running. Only active in chat_id=%s", ALLOWED_CHAT_ID)
    app.run_polling(allowed_updates=Update.ALL_TYPES)

if __name__ == "__main__":
    main()