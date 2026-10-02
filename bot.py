import os
import re
import json
import html
import time
import random
import logging
import asyncio
import secrets
import string
import aiohttp
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
#  CẤU HÌNH
# ==================================================================
# Token lấy từ biến môi trường BOT_TOKEN (an toàn hơn ghi thẳng vào code).
# Nếu muốn ghi thẳng: BOT_TOKEN = "123456:ABC..."
BOT_TOKEN = os.environ.get("BOT_TOKEN", "")
OWNER_USERNAME = "ShinnThieuu"
APP_NAME = "ShinnCheat"
ALLOWED_CHAT_ID = -1004446959502

LINK_TELEGRAM = "https://t.me/ShinnThieuu"
LINK_FACEBOOK = "https://www.facebook.com/share/19ZuAnvjt4/?mibextid=wwXIfr"
LINK_TIKTOK = "https://www.tiktok.com/@._ngvuminhhieuu"

if not BOT_TOKEN or ":" not in BOT_TOKEN:
    raise RuntimeError("BOT_TOKEN chưa được gắn hoặc sai định dạng.")

SHINN_FILE_ID = "BQACAgUAAxkBAAFVYx5qv_BWrk5XVyhzPR2ra1ZC7WeFoAACPCgAAkdrAVYeuSJySFyo-D0E"
SHINN_FILE_NAME = "ShinnCheatV2Free.ipa"
SHINN_FILE_CAPTION = (
    "📱 <b>SHINNCHEAT — FILE APP</b>\n\n"
    "🇻🇳 <b>Phiên bản:</b> V2 Free\n"
    "📦 <b>Dung lượng:</b> ~8.6 MB\n"
    "🔑 <b>Key test:</b> <code>ShinnCheatTest</code>\n"
    "🛒 <b>Mua key:</b> @{owner}\n\n"
    "🇬🇧 <b>Version:</b> V2 Free\n"
    "📦 <b>Size:</b> ~8.6 MB\n"
    "🔑 <b>Trial key:</b> <code>ShinnCheatTest</code>\n"
    "🛒 <b>Buy key:</b> @{owner}\n\n"
    "⚠️ <i>Chỉ tải từ nhóm chính thức</i>"
)

VN_TZ = timezone(timedelta(hours=7))
MORNING_HOUR, MORNING_MINUTE = 7, 0
NIGHT_HOUR, NIGHT_MINUTE = 22, 0

SPAM_WINDOW = 10
SPAM_THRESHOLD = 5
MUTE_DURATION = timedelta(days=1)
URL_FILTER = filters.TEXT & filters.Regex(r"(?i)(https?://|www\.|t\.me/|telegram\.me/)")

VERIFY_TIMEOUT_SEC = 180
VERIFY_MAX_ATTEMPTS = 2

CHECKIN_POINTS = 2
QUIZ_POINTS = 3
QUIZ_TIMEOUT_SEC = 180
QUIZ_INTERVAL_MIN = 45
POINTS_RESET_DAYS = 15
QUIZ_MAX_WINNERS = 3

user_points: dict[int, int] = defaultdict(int)
user_checkin_date: dict[int, str] = {}
user_checkin_streak: dict[int, int] = defaultdict(int)
last_points_reset: float = time.time()
quiz_state: dict | None = None
user_cmd_times: dict[int, deque] = defaultdict(deque)
user_msg_count: Counter = Counter()
user_msg_text: dict[int, str] = {}
user_first_seen: dict[int, float] = {}
user_name_cache: dict[int, str] = {}
warn_count: dict[int, int] = defaultdict(int)
WARN_LIMIT = 3
pending_verifications: dict[int, dict] = {}

# ---------------- Lưu dữ liệu ra file ----------------
DATA_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "shinn_data.json")


def _save_data():
    try:
        data = {
            "points": {str(k): v for k, v in user_points.items()},
            "checkin_date": {str(k): v for k, v in user_checkin_date.items()},
            "streak": {str(k): v for k, v in user_checkin_streak.items()},
            "names": {str(k): v for k, v in user_name_cache.items()},
            "last_reset": last_points_reset,
        }
        tmp = DATA_FILE + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False)
        os.replace(tmp, DATA_FILE)
    except Exception as e:
        logging.warning("Save data failed: %s", e)


def _load_data():
    global last_points_reset
    try:
        with open(DATA_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
    except FileNotFoundError:
        return
    except Exception as e:
        logging.warning("Load data failed: %s", e)
        return
    for k, v in data.get("points", {}).items():
        user_points[int(k)] = int(v)
    for k, v in data.get("checkin_date", {}).items():
        user_checkin_date[int(k)] = v
    for k, v in data.get("streak", {}).items():
        user_checkin_streak[int(k)] = int(v)
    for k, v in data.get("names", {}).items():
        user_name_cache[int(k)] = v
    last_points_reset = data.get("last_reset", last_points_reset)


def _remember_user(user):
    if user is None or user.is_bot:
        return
    name = user.full_name or user.username or str(user.id)
    if user_name_cache.get(user.id) != name:
        user_name_cache[user.id] = name
        _save_data()


def _mention(uid: int) -> str:
    name = html.escape(user_name_cache.get(uid, f"User {uid}"))
    return f"<a href='tg://user?id={uid}'>{name}</a>"


def _today_checkin_list(limit: int = 30) -> str:
    today = datetime.now(VN_TZ).strftime("%Y-%m-%d")
    ids = [uid for uid, d in user_checkin_date.items() if d == today]
    if not ids:
        return "—"
    lines = [f"{i}. {_mention(uid)}" for i, uid in enumerate(ids[:limit], 1)]
    if len(ids) > limit:
        lines.append(f"... và {len(ids) - limit} người khác")
    return "\n".join(lines)


_exchange_locks = defaultdict(asyncio.Lock)

# Supabase
SUPABASE_URL = "https://efhqbzdnrtifqjqlqseb.supabase.co"
SUPABASE_KEY = "sb_publishable_jnycTCgXRMrluvwJORd_4g_B7ojwi9R"
SUPABASE_TABLE = "shinn_keys"

OWNER_USER_IDS = {8987709740}
OWNER_USERNAMES = {"shinnthieuu"}

KEY_PREFIX = "SHINN"
KEY_DURATIONS = {
    "test": 3600,
    "1h": 3600, "3h": 3*3600, "6h": 6*3600, "12h": 12*3600,
    "1d": 86400, "3d": 3*86400, "5d": 5*86400, "7d": 7*86400,
    "15d": 15*86400, "30d": 30*86400,
}
MAX_KEYS_PER_REQUEST = 50

SHOP_PRICES = {
    "1h": 10, "1d": 20, "3d": 50, "5d": 80,
    "7d": 100, "15d": 200, "30d": 400,
}
SHOP_ALIASES = {
    "1h": "1h", "1gio": "1h", "1 gio": "1h", "1hour": "1h",
    "1d": "1d", "1ngay": "1d", "1 ngay": "1d", "1day": "1d",
    "3d": "3d", "3ngay": "3d", "3 ngay": "3d", "3day": "3d",
    "5d": "5d", "5ngay": "5d", "5 ngay": "5d", "5day": "5d",
    "7d": "7d", "7ngay": "7d", "7 ngay": "7d", "7day": "7d",
    "15d": "15d", "15ngay": "15d", "15 ngay": "15d", "15day": "15d",
    "30d": "30d", "30ngay": "30d", "30 ngay": "30d", "30day": "30d",
}
SHOP_MAX_QTY = 10

UNLIMITED_POINTS_IDS = {8987709740}
UNLIMITED_POINTS_LABEL = "∞ (Vô hạn)"
UNLIMITED_POINTS_VALUE = 999_999_999

# ==================== KEYBOARDS ====================
def contact_keyboard() -> InlineKeyboardMarkup:
    return InlineKeyboardMarkup([
        [InlineKeyboardButton("📩 Telegram", url=LINK_TELEGRAM),
         InlineKeyboardButton("📘 Facebook", url=LINK_FACEBOOK)],
        [InlineKeyboardButton("🎵 TikTok", url=LINK_TIKTOK)],
    ])

def buy_keyboard() -> InlineKeyboardMarkup:
    return InlineKeyboardMarkup([
        [InlineKeyboardButton("📩 Telegram", url=LINK_TELEGRAM),
         InlineKeyboardButton("📘 Facebook", url=LINK_FACEBOOK)],
        [InlineKeyboardButton("🎵 TikTok", url=LINK_TIKTOK),
         InlineKeyboardButton("👑 Owner Info", callback_data="show_owner")],
    ])

def support_keyboard() -> InlineKeyboardMarkup:
    return contact_keyboard()

def key_keyboard() -> InlineKeyboardMarkup:
    return InlineKeyboardMarkup([
        [InlineKeyboardButton("📩 Nhắn Owner", url=LINK_TELEGRAM),
         InlineKeyboardButton("📘 Facebook", url=LINK_FACEBOOK)],
        [InlineKeyboardButton("🎵 TikTok", url=LINK_TIKTOK)],
    ])

# ==================== TEXTS ====================
TEXTS = {
    "start": (
        "👋 <b>CHÀO MỪNG ĐẾN SHINNCHEAT</b>\n"
        "───────────────\n\n"
        "🤖 <b>ShinnCheat Support Bot</b>\n"
        "💎 <i>Bot hỗ trợ cộng đồng chuyên nghiệp</i>\n\n"
        "📌 <b>Bắt đầu nhanh:</b>\n"
        "📱 /shinn — Tải file app\n"
        "🔑 /key — Danh sách key\n"
        "🛒 /buy — Mua key\n"
        "🛍️ /shop — Đổi điểm lấy key\n"
        "👑 /owner — Liên hệ Owner\n"
        "🛠️ /support — Nhận hỗ trợ\n\n"
        "───────────────\n"
        "📖 Gõ /help để xem hướng dẫn."
    ),
    "help": (
        "📖 <b>SHINNCHEAT — TRUNG TÂM HỖ TRỢ</b>\n"
        "───────────────\n\n"
        "📱 <b>ỨNG DỤNG</b>\n"
        "/shinn — Tải file app\n"
        "/update — Cập nhật\n"
        "/repo — Repository\n\n"
        "🔑 <b>KEY</b>\n"
        "/key — Danh sách key\n"
        "/buy — Mua key\n"
        "/shop — Đổi điểm lấy key\n\n"
        "🎮 <b>ĐIỂM & EVENT</b>\n"
        "/diemdanh — Điểm danh +2đ\n"
        "/diem — Xem điểm\n"
        "/bxh — BXH top\n"
        "/doikey — Đổi điểm lấy key\n\n"
        "👑 <b>LIÊN HỆ</b>\n"
        "/owner — Owner\n"
        "/support — Hỗ trợ\n"
        "/rules — Nội quy\n"
        "/about — Giới thiệu\n\n"
        "📊 <b>CÁ NHÂN</b>\n"
        "/id /chatid /info /stats /top\n\n"
        "🛡️ <b>QUẢN TRỊ</b>\n"
        "/pin /unpin /del /mute /unmute\n"
        "/warn /unwarn /kick /ban /unban\n"
        "/say /tagall /setfile"
    ),
    "shinn": (
        "📱 <b>SHINNCHEAT</b>\n\n"
        "Gõ /shinn để nhận file app!"
    ),
    "key": (
        "🔑 <b>SHINNCHEAT KEYS</b>\n"
        "───────────────\n\n"
        "🎫 <b>Danh sách key:</b>\n"
        "• <code>ShinnCheat</code> — Key chính thức\n"
        "• <code>ShinnCheatTest</code> — Key dùng thử\n\n"
        "🇻🇳 <b>Đặc điểm:</b>\n"
        "✅ Không giới hạn thiết bị\n"
        "✅ Kích hoạt nhanh chóng\n"
        "✅ Hỗ trợ đầy đủ tính năng\n\n"
        "🇬🇧 <b>Features:</b>\n"
        "✅ Unlimited devices\n"
        "✅ Fast activation\n"
        "✅ Full features\n\n"
        "───────────────\n"
        "🛍️ <b>Đổi điểm lấy key free:</b> /shop\n"
        "🛒 <b>Mua key:</b> Nhấn nút bên dưới"
    ),
    "key_test": (
        "🔑 <b>KEY TEST — SHINNCHEAT</b>\n"
        "───────────────\n\n"
        "🎫 <b>Key dùng thử:</b>\n"
        "<code>ShinnCheatTest</code>\n\n"
        "🇻🇳 <b>Thông tin:</b>\n"
        "⏱️ Thời hạn: <b>1 giờ</b>\n"
        "🎯 Một số tính năng bị giới hạn\n"
        "💳 Nâng cấp để dùng full\n\n"
        "🇬🇧 <b>Info:</b>\n"
        "⏱️ Duration: <b>1 hour</b>\n"
        "🎯 Some features may be limited\n"
        "💳 Upgrade for full access\n\n"
        "───────────────\n"
        "🛍️ <b>Đổi điểm lấy key free:</b> /shop\n"
        "🛒 Nâng cấp: @{owner}"
    ),
    "key_official": (
        "🔑 <b>KEY CHÍNH THỨC</b>\n"
        "───────────────\n\n"
        "🎫 <b>Key chính thức:</b>\n"
        "<code>ShinnCheat</code>\n\n"
        "🇻🇳 <b>Quyền lợi:</b>\n"
        "✅ Mở khóa toàn bộ tính năng\n"
        "✅ Không giới hạn thiết bị\n"
        "✅ Hỗ trợ ưu tiên\n"
        "✅ Cập nhật mới nhất\n\n"
        "───────────────\n"
        "🛒 <b>Mua key:</b> @{owner}\n"
        "🛍️ <b>Đổi điểm free:</b> /shop"
    ),
    "buy": (
        "🛒 <b>MUA KEY / BUY KEY</b>\n"
        "───────────────\n\n"
        "🇻🇳 Chọn kênh liên hệ bên dưới để mua key.\n"
        "🇬🇧 Choose a contact channel below to buy.\n\n"
        "💡 <b>Hoặc đổi điểm MIỄN PHÍ:</b>\n"
        "• /diemdanh — Kiếm điểm mỗi ngày\n"
        "• /shop — Xem bảng giá điểm\n"
        "• /doikey — Đổi key\n\n"
        "───────────────\n"
        "👇 <b>Chọn kênh:</b>"
    ),
    "owner": (
        "👑 <b>SHINNCHEAT OWNER</b>\n"
        "───────────────\n\n"
        "🇻🇳 Liên hệ Owner để mua key hoặc hỗ trợ.\n"
        "🇬🇧 Contact Owner for keys or support.\n\n"
        "📱 <b>Telegram:</b> @{owner}\n"
        "📘 <b>Facebook:</b> NgVuMinhHieuu\n"
        "🎵 <b>TikTok:</b> @._ngvuminhhieuu\n\n"
        "───────────────\n"
        "💡 <i>Nếu Telegram không phản hồi,\n"
        "thử Facebook/TikTok nhé!</i>"
    ),
    "update": (
        "🚀 <b>CẬP NHẬT / UPDATE</b>\n"
        "───────────────\n\n"
        "🇻🇳 <b>Phiên bản mới nhất:</b>\n"
        "✨ Giao diện thiết kế lại\n"
        "🎨 Màu sắc & hiển thị đẹp hơn\n"
        "🖼️ Hỗ trợ cập nhật ảnh đại diện\n"
        "🔧 Apply/Restore Patch mượt\n"
        "⚡ Tối ưu hiệu suất\n"
        "🔄 Đồng bộ Repository tốt\n\n"
        "🇬🇧 <b>Latest:</b>\n"
        "✨ Redesigned interface\n"
        "🎨 Better colors & display\n"
        "🖼️ Avatar updates\n"
        "🔧 Smoother Apply/Restore\n"
        "⚡ Performance boost\n"
        "🔄 Better repo sync"
    ),
    "repo": (
        "📦 <b>REPOSITORY</b>\n"
        "───────────────\n\n"
        "🇻🇳 Theo dõi thông báo trong nhóm để nhận link repo mới nhất.\n"
        "🇬🇧 Check group for latest repo links.\n\n"
        "⚠️ <b>Cảnh báo:</b> Chỉ tải từ nguồn uy tín!"
    ),
    "support": (
        "🛠️ <b>HỖ TRỢ / SUPPORT</b>\n"
        "───────────────\n\n"
        "🇻🇳 <b>Khi cần hỗ trợ cung cấp:</b>\n"
        "• Mô tả lỗi cụ thể\n"
        "• Phiên bản iOS\n"
        "• Các bước gây lỗi\n\n"
        "🇬🇧 <b>When requesting help:</b>\n"
        "• Detailed issue\n"
        "• iOS version\n"
        "• Steps to reproduce\n\n"
        "🔒 <b>Bảo mật:</b> Không gửi password/token\n\n"
        "───────────────\n"
        "💡 <i>Nếu Telegram không phản hồi,\n"
        "thử Facebook/TikTok!</i>\n\n"
        "👇 <b>Chọn kênh:</b>"
    ),
    "rules": (
        "📜 <b>NỘI QUY NHÓM</b>\n"
        "───────────────\n\n"
        "1️⃣ Tôn trọng mọi thành viên\n"
        "2️⃣ Không spam / quảng cáo trái phép\n"
        "3️⃣ Không giả mạo Owner\n"
        "4️⃣ Không chia sẻ thông tin cá nhân\n"
        "5️⃣ Liên hệ admin khi cần hỗ trợ\n\n"
        "⚠️ Vi phạm → mute/kick/ban!"
    ),
    "about": (
        "🤖 <b>SHINNCHEAT BOT</b>\n"
        "───────────────\n\n"
        "🇻🇳 Bot hỗ trợ cộng đồng ShinnCheat:\n"
        "• Thông tin app\n"
        "• Key & mua key\n"
        "• Cập nhật phiên bản\n"
        "• Hỗ trợ kỹ thuật\n"
        "• Event đổi điểm lấy key\n\n"
        "───────────────\n"
        "👑 <b>Owner:</b> @{owner}\n"
        "📘 <b>FB:</b> NgVuMinhHieuu\n"
        "🎵 <b>TikTok:</b> @._ngvuminhhieuu"
    ),
    "ad": (
        "🌙 <b>THÔNG BÁO TỪ OWNER</b>\n"
        "───────────────\n\n"
        "🇻🇳 Shinn đã ngủ. Nếu gấp, liên hệ trực tiếp!\n"
        "🇬🇧 Shinn is asleep. Contact directly!\n\n"
        "───────────────\n"
        "💡 <i>Nếu Telegram không phản hồi,\n"
        "thử Facebook/TikTok!</i>\n\n"
        "👇 <b>Chọn kênh:</b>"
    ),
    "checkin_success": (
        "✅ <b>ĐIỂM DANH THÀNH CÔNG</b>\n"
        "───────────────\n\n"
        "👤 <b>{name}</b>\n"
        "📅 Ngày: <b>{today}</b>\n"
        "🔥 Chuỗi: <b>{streak} ngày</b>\n\n"
        "🎁 Nhận được: <b>+{points} điểm</b>\n"
        "💎 Tổng điểm: <b>{total} điểm</b>\n"
        "🏆 Xếp hạng: <b>#{rank}/{total_users}</b>\n\n"
        "👥 <b>Đã điểm danh hôm nay:</b>\n{today_list}\n\n"
        "───────────────\n"
        "📌 Xem BXH: /bxh\n"
        "🛍️ Đổi điểm lấy key: /shop"
    ),
    "checkin_dup": (
        "⏰ Bạn đã điểm danh hôm nay rồi!\n"
        "📅 Quay lại vào ngày mai nhé.\n\n"
        "💎 Điểm hiện tại: <b>{total} điểm</b>\n"
        "🛍️ Đổi key ngay: /shop"
    ),
    "mydiem": (
        "💎 <b>ĐIỂM CỦA BẠN</b>\n"
        "───────────────\n\n"
        "👤 <b>{name}</b>\n"
        "🎯 Tổng điểm: <b>{total}</b>\n"
        "🔥 Chuỗi: <b>{streak} ngày</b>\n"
        "📅 Lần cuối: <b>{last}</b>\n"
        "🏆 Xếp hạng: <b>#{rank}/{total_users}</b>\n\n"
        "───────────────\n"
        "📌 Điểm danh: /diemdanh\n"
        "🛍️ Đổi key: /shop"
    ),
    "bxh": (
        "🏆 <b>BẢNG XẾP HẠNG</b>\n"
        "───────────────\n\n"
        "🥇 Top 1 → Key 7 ngày\n"
        "🥈 Top 2 → Key 3 ngày\n"
        "🥉 Top 3 → Key 1 ngày\n\n"
        "{lines}\n\n"
        "───────────────\n"
        "⏱️ Reset sau: <b>{days_left} ngày</b>\n"
        "📌 Điểm danh: /diemdanh"
    ),
    "quiz_start": (
        "🎯 <b>CÂU HỎI NHANH</b>\n"
        "───────────────\n\n"
        "❓ {question}\n\n"
        "⚡ <b>3 người đúng đầu tiên</b> nhận <b>+3 điểm</b>!\n"
        "⏱️ Thời gian: <b>3 phút</b>\n"
        "📝 Trả lời bằng tin nhắn thường"
    ),
    "quiz_win": (
        "🎉 <b>Chính xác!</b> {mention}\n"
        "➕ <b>+{points} điểm</b> (vị trí #{pos})\n"
        "💎 Tổng điểm: <b>{total}</b>"
    ),
    "quiz_end": (
        "⏰ <b>Hết giờ câu hỏi!</b>\n\n"
        "✅ Đáp án: <b>{answer}</b>\n"
        "🎁 Người thắng: {winners}"
    ),
    "quiz_already": "✅ Bạn đã trả lời đúng câu này rồi!\n⏳ Chờ câu hỏi tiếp theo nhé.",
    "shop": (
        "🛍️ <b>CỬA HÀNG ĐỔI KEY</b>\n"
        "───────────────\n\n"
        "🇻🇳 Dùng điểm để đổi key miễn phí!\n\n"
        "💰 <b>BẢNG GIÁ:</b>\n"
        "🔑 <b>1h</b> — 10 điểm\n"
        "🔑 <b>1d</b> (1 ngày) — 20 điểm\n"
        "🔑 <b>3d</b> — 50 điểm\n"
        "🔑 <b>5d</b> — 80 điểm\n"
        "🔑 <b>7d</b> — 100 điểm\n"
        "🔑 <b>15d</b> — 200 điểm\n"
        "🔑 <b>30d</b> — 400 điểm\n\n"
        "💎 <b>Điểm của bạn:</b> {points}\n\n"
        "───────────────\n"
        "📝 <b>Cách đổi:</b> <code>/doikey 1d</code>\n"
        "📩 Key gửi vào <b>tin nhắn riêng</b>\n"
        "📌 Kiếm điểm: /diemdanh\n"
        "📊 Xem BXH: /bxh"
    ),
    "shop_success": (
        "✅ <b>ĐỔI KEY THÀNH CÔNG</b>\n"
        "───────────────\n\n"
        "🔑 <b>Key của bạn:</b>\n"
        "<code>{key}</code>\n\n"
        "⏱️ <b>Thời hạn:</b> {label}\n"
        "📅 <b>Hết hạn:</b> {expires}\n"
        "📱 <b>Max devices:</b> 1\n\n"
        "💸 <b>Đã trừ:</b> {cost}\n"
        "💎 <b>Còn lại:</b> {remaining}\n\n"
        "🎉 Cảm ơn bạn đã tham gia ShinnCheat!"
    ),
    "shop_not_enough": (
        "❌ <b>KHÔNG ĐỦ ĐIỂM</b>\n"
        "───────────────\n\n"
        "💰 <b>Key muốn đổi:</b> {label}\n"
        "💵 <b>Giá:</b> {cost} điểm\n"
        "💎 <b>Bạn có:</b> {points} điểm\n"
        "❗ <b>Còn thiếu:</b> <b>{missing} điểm</b>\n\n"
        "💡 <b>Cách kiếm điểm:</b>\n"
        "• /diemdanh — +2 điểm/ngày\n"
        "• Trả lời quiz — +3 điểm\n"
        "• Leo TOP BXH nhận key thưởng\n\n"
        "📌 Điểm danh ngay: /diemdanh"
    ),
    "shop_bad_label": (
        "❌ Loại key <b>{label}</b> không hợp lệ.\n\n"
        "💰 <b>Các loại hợp lệ:</b>\n"
        "<code>1h</code> — 10 điểm\n"
        "<code>1d</code> — 20 điểm\n"
        "<code>3d</code> — 50 điểm\n"
        "<code>5d</code> — 80 điểm\n"
        "<code>7d</code> — 100 điểm\n"
        "<code>15d</code> — 200 điểm\n"
        "<code>30d</code> — 400 điểm\n\n"
        "📝 VD: <code>/doikey 1d</code>"
    ),
    "shop_error": "❌ <b>Lỗi tạo key:</b>\n<code>{err}</code>",
}

def render(key: str) -> str:
    return TEXTS[key].format(owner=OWNER_USERNAME)

def render_plain(key: str, **kwargs) -> str:
    return TEXTS[key].format(owner=OWNER_USERNAME, **kwargs)

# ==================== HELPERS ====================
BOT_START_TIME = time.time()
_bot_app = None

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
        return "Ẩn danh"
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
            f"🔇 {user.mention_html()} đã bị <b>mute 1 ngày</b> vì spam.",
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

def group_or_shop_dm(func):
    """Cho phép dùng trong group chính HOẶC nhắn riêng (DM) với bot."""
    async def wrapper(update: Update, context: ContextTypes.DEFAULT_TYPE):
        chat = update.effective_chat
        if chat is None:
            return
        if chat.id == ALLOWED_CHAT_ID:
            return await func(update, context)
        if chat.type == "private":
            return await func(update, context)
        return
    return wrapper

def admin_only(func):
    async def wrapper(update: Update, context: ContextTypes.DEFAULT_TYPE):
        if not await _is_privileged(update.effective_chat, update.effective_user):
            if update.effective_message:
                await update.effective_message.reply_text(
                    "⛔ Chỉ admin/Owner mới dùng được."
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

def _is_owner(update: Update) -> bool:
    user = update.effective_user
    if user is None:
        return False
    if user.id in OWNER_USER_IDS:
        return True
    if user.username and user.username.lower() in OWNER_USERNAMES:
        return True
    return False

def owner_only(func):
    async def wrapper(update: Update, context: ContextTypes.DEFAULT_TYPE):
        if not _is_owner(update):
            u = update.effective_user
            logging.info(
                "Non-owner tried owner-cmd: id=%s username=%s",
                u.id if u else "?", u.username if u else "?"
            )
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
            f"không gửi link trong nhóm!",
            parse_mode="HTML",
        )
        asyncio.create_task(_delayed_delete(warn, 10))
    except Exception:
        pass

# ==================== ĐIỂM SYSTEM ====================
def _today_str() -> str:
    return datetime.now(VN_TZ).strftime("%Y-%m-%d")

def _yesterday_str() -> str:
    return (datetime.now(VN_TZ) - timedelta(days=1)).strftime("%Y-%m-%d")

def _points_reset_days_left() -> int:
    elapsed = time.time() - last_points_reset
    remain = POINTS_RESET_DAYS * 86400 - elapsed
    return max(0, int(remain // 86400))

def _rank_of(user_id: int) -> tuple[int, int]:
    if not user_points:
        return (0, 0)
    sorted_users = sorted(user_points.items(), key=lambda x: -x[1])
    for i, (uid, _) in enumerate(sorted_users, 1):
        if uid == user_id:
            return (i, len(sorted_users))
    return (0, len(sorted_users))

def _points_display(user_id: int) -> str:
    if user_id in UNLIMITED_POINTS_IDS:
        return UNLIMITED_POINTS_LABEL
    return f"{user_points.get(user_id, 0)} điểm"

async def _do_checkin(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user = update.effective_user
    msg = update.effective_message
    if user is None or msg is None:
        return
    _remember_user(user)
    today = _today_str()
    if user_checkin_date.get(user.id) == today:
        await msg.reply_text(
            render_plain("checkin_dup", total=user_points.get(user.id, 0)),
            parse_mode="HTML",
        )
        return
    yesterday = _yesterday_str()
    last = user_checkin_date.get(user.id)
    if last == yesterday:
        user_checkin_streak[user.id] += 1
    else:
        user_checkin_streak[user.id] = 1
    user_checkin_date[user.id] = today
    user_points[user.id] += CHECKIN_POINTS
    _save_data()
    rank, total_users = _rank_of(user.id)
    await msg.reply_text(
        TEXTS["checkin_success"].format(
            name=html.escape(_display_name(user)),
            today=datetime.now(VN_TZ).strftime("%d/%m/%Y"),
            streak=user_checkin_streak[user.id],
            points=CHECKIN_POINTS,
            total=user_points[user.id],
            rank=rank,
            total_users=total_users,
            today_list=_today_checkin_list(),
        ),
        parse_mode="HTML",
    )

async def _show_mydiem(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user = update.effective_user
    msg = update.effective_message
    if user is None or msg is None:
        return
    rank, total_users = _rank_of(user.id)
    last = user_checkin_date.get(user.id, "—")
    try:
        last_fmt = datetime.strptime(last, "%Y-%m-%d").strftime("%d/%m/%Y")
    except Exception:
        last_fmt = "—"
    total_display = _points_display(user.id)
    await msg.reply_text(
        TEXTS["mydiem"].format(
            name=html.escape(_display_name(user)),
            total=total_display,
            streak=user_checkin_streak.get(user.id, 0),
            last=last_fmt,
            rank=rank,
            total_users=total_users,
        ),
        parse_mode="HTML",
    )

async def _show_bxh(update: Update, context: ContextTypes.DEFAULT_TYPE):
    msg = update.effective_message
    if msg is None:
        return
    if not user_points:
        await msg.reply_text("📭 Chưa có ai điểm danh. Gõ /diemdanh để bắt đầu!")
        return
    top = sorted(user_points.items(), key=lambda x: -x[1])[:10]
    medals = ["🥇", "🥈", "🥉"]
    lines = []
    for i, (uid, pts) in enumerate(top):
        medal = medals[i] if i < 3 else f"<b>{i+1}.</b>"
        lines.append(f"{medal} {_mention(uid)} — <b>{pts}</b> điểm")
    await msg.reply_text(
        TEXTS["bxh"].format(
            lines="\n".join(lines),
            days_left=_points_reset_days_left(),
        ),
        parse_mode="HTML",
    )

async def _announce_prize():
    if not user_points:
        return
    top = sorted(user_points.items(), key=lambda x: -x[1])[:3]
    prizes = {1: "Key 7 ngày", 2: "Key 3 ngày", 3: "Key 1 ngày"}
    lines = []
    for i, (uid, pts) in enumerate(top, 1):
        name = _mention(uid)
        lines.append(f"{i}. {name} — <b>{pts}</b> điểm → 🎁 {prizes[i]}")
    text = (
        "🎊 <b>KẾT THÚC KỲ ĐIỂM DANH</b>\n"
        "───────────────\n\n"
        "🏆 <b>TOP 3 NHẬN THƯỞNG:</b>\n\n"
        + "\n".join(lines)
        + "\n\n───────────────\n"
        f"📩 Liên hệ @{OWNER_USERNAME} để nhận key!\n"
        "🔄 BXH đã reset — bắt đầu kỳ mới!"
    )
    try:
        if _bot_app:
            await _bot_app.bot.send_message(ALLOWED_CHAT_ID, text, parse_mode="HTML")
    except Exception as e:
        logging.warning("Announce prize failed: %s", e)

async def _reset_points_if_due():
    global last_points_reset
    if time.time() - last_points_reset < POINTS_RESET_DAYS * 86400:
        return
    await _announce_prize()
    user_points.clear()
    user_checkin_date.clear()
    user_checkin_streak.clear()
    last_points_reset = time.time()
    _save_data()
    logging.info("Đã reset điểm sau %d ngày", POINTS_RESET_DAYS)

# ==================== QUIZ ====================
# (câu hỏi, [các đáp án], vị trí đáp án đúng bắt đầu từ 0)
QUIZ_BANK = [
    ("2 + 3 × 4 = ?", ["10", "14", "20", "24"], 1),
    ("Thủ đô Việt Nam là gì?", ["Hồ Chí Minh", "Đà Nẵng", "Hà Nội", "Huế"], 2),
    ("Con vật nào có vòi dài nhất?", ["Con voi", "Con hươu", "Con khỉ", "Con gấu"], 0),
    ("1 ngày có bao nhiêu giây?", ["3600", "86400", "1440", "43200"], 1),
    ("Nước nào đông dân nhất?", ["Mỹ", "Ấn Độ", "Nhật Bản", "Brazil"], 1),
    ("Ai là tác giả Truyện Kiều?", ["Nguyễn Trãi", "Nguyễn Du", "Hồ Xuân Hương", "Nguyễn Khuyến"], 1),
    ("5! = ?", ["60", "100", "120", "720"], 2),
    ("100 - 25 × 2 = ?", ["150", "50", "75", "25"], 1),
    ("Hành tinh nào lớn nhất?", ["Sao Thổ", "Sao Mộc", "Sao Hỏa", "Trái Đất"], 1),
    ("Trái Đất quay quanh gì?", ["Mặt Trăng", "Sao Hỏa", "Mặt Trời", "Sao Kim"], 2),
    ("Kim tự tháp nổi tiếng ở đâu?", ["Ai Cập", "Hy Lạp", "Nhật Bản", "Ý"], 0),
    ("12 + 8 × 3 = ?", ["60", "36", "30", "24"], 1),
    ("Nước sôi ở bao nhiêu độ C?", ["90", "100", "120", "80"], 1),
    ("Hệ Mặt Trời có bao nhiêu hành tinh?", ["7", "8", "9", "10"], 1),
    ("6 × 7 = ?", ["36", "42", "48", "49"], 1),
    ("Ngọn núi cao nhất thế giới?", ["Everest", "Phan Xi Păng", "Fuji", "Kilimanjaro"], 0),
    ("1 năm (không nhuận) có bao nhiêu ngày?", ["364", "365", "366", "360"], 1),
    ("Vịnh Hạ Long ở tỉnh nào?", ["Hải Phòng", "Quảng Ninh", "Thanh Hóa", "Khánh Hòa"], 1),
    ("Đại dương lớn nhất?", ["Đại Tây Dương", "Ấn Độ Dương", "Thái Bình Dương", "Bắc Băng Dương"], 2),
    ("3^3 = ?", ["9", "18", "27", "81"], 2),
]

QUIZ_LETTERS = ["A", "B", "C", "D"]

def _normalize_answer(s: str) -> str:
    return re.sub(r"\s+", " ", s.lower().strip())

def _quiz_start_text(question: str, options=None) -> str:
    text = (
        "🎯 <b>CÂU HỎI NHANH</b>\n"
        "───────────────\n\n"
        f"❓ {html.escape(question)}\n\n"
    )
    if options:
        text += "\n".join(
            f"<b>{QUIZ_LETTERS[i]}.</b> {html.escape(o)}" for i, o in enumerate(options)
        ) + "\n\n"
    text += (
        f"⚡ <b>{QUIZ_MAX_WINNERS} người đúng đầu tiên</b> nhận <b>+{QUIZ_POINTS} điểm</b>!\n"
        f"⏱️ Thời gian: <b>{QUIZ_TIMEOUT_SEC // 60} phút</b>\n"
    )
    if options:
        text += "👇 Bấm nút bên dưới để chọn (mỗi người chỉ được chọn 1 lần)"
    else:
        text += "📝 Trả lời bằng tin nhắn thường"
    return text

def _quiz_keyboard(options) -> InlineKeyboardMarkup:
    row = [
        InlineKeyboardButton(QUIZ_LETTERS[i], callback_data=f"quiz:{i}")
        for i in range(len(options))
    ]
    return InlineKeyboardMarkup([row])

async def _launch_quiz(context, question, options=None, correct=None, text_answer=None):
    """Gửi câu hỏi lên group. options != None -> trắc nghiệm, ngược lại -> tự gõ đáp án."""
    global quiz_state
    markup = _quiz_keyboard(options) if options else None
    sent = await context.bot.send_message(
        ALLOWED_CHAT_ID,
        _quiz_start_text(question, options),
        parse_mode="HTML",
        reply_markup=markup,
    )
    if options:
        raw_answer = f"{QUIZ_LETTERS[correct]}. {options[correct]}"
        answer_norm = None
    else:
        raw_answer = text_answer
        answer_norm = _normalize_answer(text_answer)
    quiz_state = {
        "chat_id": ALLOWED_CHAT_ID,
        "message_id": sent.message_id,
        "question": question,
        "options": options,
        "correct": correct,
        "answer": answer_norm,
        "raw_answer": raw_answer,
        "answered": set(),
        "winners": [],
    }
    quiz_state["task"] = asyncio.create_task(_end_quiz(context))
    return sent

async def _send_quiz(context: ContextTypes.DEFAULT_TYPE):
    await _reset_points_if_due()
    if quiz_state is not None:
        return
    q, opts, correct_idx = random.choice(QUIZ_BANK)
    pairs = list(enumerate(opts))
    random.shuffle(pairs)
    options = [p[1] for p in pairs]
    correct = next(i for i, p in enumerate(pairs) if p[0] == correct_idx)
    try:
        await _launch_quiz(context, q, options=options, correct=correct)
    except Exception as e:
        logging.warning("Gửi quiz thất bại: %s", e)

async def _end_quiz(context: ContextTypes.DEFAULT_TYPE, instant: bool = False):
    global quiz_state
    if not instant:
        await asyncio.sleep(QUIZ_TIMEOUT_SEC)
    qs = quiz_state
    if qs is None:
        return
    quiz_state = None  # đóng quiz trước để không ai bấm thêm được
    winners = qs["winners"]
    winner_text = ", ".join(_mention(uid) for uid in winners) if winners else "Không có ai 😢"
    if qs.get("options"):
        try:
            await context.bot.edit_message_reply_markup(
                qs["chat_id"], qs["message_id"], reply_markup=None
            )
        except Exception:
            pass
    try:
        await context.bot.send_message(
            qs["chat_id"],
            TEXTS["quiz_end"].format(
                answer=html.escape(qs["raw_answer"]),
                winners=winner_text,
            ),
            parse_mode="HTML",
        )
    except Exception as e:
        logging.warning("Gửi quiz end thất bại: %s", e)

@group_only
async def quiz_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    user = query.from_user
    qs = quiz_state
    if (qs is None or not qs.get("options") or query.message is None
            or query.message.message_id != qs["message_id"]):
        await query.answer("⏰ Câu hỏi này đã kết thúc.", show_alert=True)
        return
    try:
        idx = int(query.data.split(":")[1])
    except Exception:
        await query.answer()
        return
    if user.id in pending_verifications:
        await query.answer("🔐 Hãy xác thực thành viên trước đã.", show_alert=True)
        return
    if user.id in qs["answered"]:
        await query.answer("⚠️ Bạn đã chọn rồi, mỗi người chỉ được chọn 1 lần!", show_alert=True)
        return
    if len(qs["winners"]) >= QUIZ_MAX_WINNERS:
        await query.answer("⏰ Đã đủ người trả lời đúng.", show_alert=True)
        return

    qs["answered"].add(user.id)
    _remember_user(user)

    if idx != qs["correct"]:
        await query.answer("❌ Sai rồi! Chúc bạn may mắn lần sau.", show_alert=True)
        return

    qs["winners"].append(user.id)
    user_points[user.id] += QUIZ_POINTS
    _save_data()
    pos = len(qs["winners"])
    await query.answer(f"✅ Chính xác! +{QUIZ_POINTS} điểm", show_alert=True)
    try:
        await context.bot.send_message(
            qs["chat_id"],
            TEXTS["quiz_win"].format(
                mention=user.mention_html(),
                points=QUIZ_POINTS,
                pos=pos,
                total=user_points[user.id],
            ),
            parse_mode="HTML",
            reply_to_message_id=qs["message_id"],
        )
    except Exception as e:
        logging.warning("Gửi thông báo thắng thất bại: %s", e)
    if len(qs["winners"]) >= QUIZ_MAX_WINNERS:
        old = qs.get("task")
        if old:
            old.cancel()
        asyncio.create_task(_end_quiz(context, instant=True))

async def _check_quiz_answer(update: Update, context: ContextTypes.DEFAULT_TYPE, text: str) -> bool:
    """Chỉ dùng cho câu hỏi kiểu tự gõ đáp án (owner tạo bằng /taocauhoi 2 phần)."""
    if quiz_state is None or quiz_state.get("options"):
        return False
    if update.effective_chat is None or update.effective_chat.id != quiz_state["chat_id"]:
        return False
    user = update.effective_user
    msg = update.effective_message
    if user is None or msg is None:
        return False
    if _normalize_answer(text) != quiz_state["answer"]:
        return False
    if user.id in quiz_state["winners"]:
        await msg.reply_text(TEXTS["quiz_already"], parse_mode="HTML")
        return True
    if len(quiz_state["winners"]) >= QUIZ_MAX_WINNERS:
        return False
    quiz_state["winners"].append(user.id)
    user_points[user.id] += QUIZ_POINTS
    _remember_user(user)
    _save_data()
    pos = len(quiz_state["winners"])
    try:
        await msg.reply_text(
            TEXTS["quiz_win"].format(
                mention=user.mention_html(),
                points=QUIZ_POINTS,
                pos=pos,
                total=user_points[user.id],
            ),
            parse_mode="HTML",
        )
    except Exception:
        pass
    if len(quiz_state["winners"]) >= QUIZ_MAX_WINNERS:
        old = quiz_state.get("task")
        if old:
            old.cancel()
        asyncio.create_task(_end_quiz(context, instant=True))
    return True

# ==================== MESSAGE TRACKER ====================
@group_only
async def track_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user = update.effective_user
    msg = update.effective_message
    if user is None or msg is None or not msg.text:
        return
    user_msg_count[user.id] += 1
    user_msg_text[user.id] = msg.text[:100]
    _remember_user(user)
    if user.id not in user_first_seen:
        user_first_seen[user.id] = time.time()
    handled = await _check_quiz_answer(update, context, msg.text)
    if handled:
        return

# ==================== XÁC THỰC ====================
def _gen_math_question():
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
            f"⏱️ Thành viên <a href='tg://user?id={user_id}'>này</a> "
            f"bị kick do không xác thực trong {VERIFY_TIMEOUT_SEC // 60} phút.",
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
        _remember_user(new_user)
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
            "🎉 <b>CHÀO MỪNG THÀNH VIÊN MỚI</b>\n"
            "───────────────\n\n"
            f"👤 <b>{mention}</b>\n"
            f"📆 Tham gia: <i>{datetime.now(VN_TZ).strftime('%d/%m/%Y %H:%M')}</i>\n"
            f"🎫 Thành viên thứ: <b>{member_count}</b>\n\n"
            "🔐 <b>XÁC THỰC ĐỂ CHAT</b>\n"
            f"❓ Câu hỏi: <code>{question} = ?</code>\n"
            "👉 Chọn 1 trong 2 đáp án:\n"
            f"⏱️ Hết hạn sau <b>{VERIFY_TIMEOUT_SEC // 60} phút</b>."
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
        await query.answer("⚠️ Lỗi dữ liệu.", show_alert=True)
        return
    if query.from_user.id != user_id:
        await query.answer("⚠️ Không phải câu hỏi của bạn.", show_alert=True)
        return
    info = pending_verifications.get(user_id)
    if not info:
        await query.answer("⚠️ Phiên đã hết hạn.", show_alert=True)
        try:
            await query.message.delete()
        except Exception:
            pass
        return
    safe_name = html.escape(query.from_user.full_name)
    if chosen == info["answer"]:
        try:
            await context.bot.restrict_chat_member(info["chat_id"], user_id, _full_perms())
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
            "✅ <b>XÁC THỰC THÀNH CÔNG</b>\n"
            "───────────────\n\n"
            f"🎊 Chào mừng <a href='tg://user?id={user_id}'>{safe_name}</a>!\n\n"
            "💬 <b>Bạn có thể chat ngay bây giờ.</b>\n\n"
            "📋 <b>Lệnh hữu ích:</b>\n"
            "• /help — Hướng dẫn\n"
            "• /diemdanh — Kiếm điểm +2\n"
            "• /shop — Đổi điểm lấy key\n"
            "• /bxh — BXH\n"
            "• /rules — Nội quy\n\n"
            "🎉 Chúc bạn trải nghiệm vui vẻ!",
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
                f"🚫 <a href='tg://user?id={user_id}'>{safe_name}</a> "
                f"đã bị kick do sai {VERIFY_MAX_ATTEMPTS} lần.",
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
                    "⚠️ <b>SAI RỒI, THỬ LẠI</b>\n"
                    "───────────────\n\n"
                    f"👤 <a href='tg://user?id={user_id}'>{safe_name}</a>\n"
                    f"❌ Lần thử: <b>{info['attempts']}/{VERIFY_MAX_ATTEMPTS}</b>\n\n"
                    f"❓ Câu hỏi: <code>{question} = ?</code>",
                    parse_mode="HTML",
                    reply_markup=keyboard,
                )
            except Exception as e:
                logging.warning("Edit verify msg failed: %s", e)
    await query.answer()

@group_or_shop_dm
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
    name = html.escape(_display_name(left))
    user_msg_count.pop(left.id, None)
    user_msg_text.pop(left.id, None)
    warn_count.pop(left.id, None)
    pending_verifications.pop(left.id, None)
    try:
        member_count = await context.bot.get_chat_member_count(chat.id)
    except Exception:
        member_count = "?"
    text = (
        "👋 <b>TẠM BIỆT THÀNH VIÊN</b>\n"
        "───────────────\n\n"
        f"👤 <b>{mention}</b>\n"
        f"📆 Rời: <i>{datetime.now(VN_TZ).strftime('%d/%m/%Y %H:%M')}</i>\n"
        f"🎫 Còn lại: <b>{member_count}</b>\n\n"
        f"💫 Chúc <b>{name}</b> mọi điều tốt lành!\n"
        "🚪 Cánh cửa luôn mở cho bạn trở lại."
    )
    try:
        await chat.send_message(text, parse_mode="HTML", disable_web_page_preview=True)
    except Exception as e:
        logging.warning("Goodbye failed: %s", e)

# ==================== MORNING / NIGHT ====================
def _morning_text():
    today = datetime.now(VN_TZ).strftime("%d/%m/%Y")
    quotes = [
        "Hôm nay là ngày mới, hãy bắt đầu với năng lượng tích cực! 💪",
        "Chúc bạn một ngày tràn đầy niềm vui và thành công! 🌟",
        "Sáng nay uống đủ nước, làm việc hiệu quả nhé! ☕",
        "Mỗi sáng thức dậy là một cơ hội mới. Cố lên! 🔥",
        "Chúc cả nhóm một ngày tuyệt vời! 🍀",
    ]
    return (
        "☀️ <b>CHÀO BUỔI SÁNG</b> ☀️\n"
        "───────────────\n\n"
        f"📅 Hôm nay: <b>{today}</b>\n"
        f"🕖 Bây giờ: <b>{MORNING_HOUR:02d}:{MORNING_MINUTE:02d}</b>\n\n"
        f"💬 {random.choice(quotes)}\n\n"
        "───────────────\n"
        "📌 Đừng quên điểm danh: /diemdanh\n"
        "🌤️ <i>ShinnCheat Team</i>"
    )

def _night_text():
    today = datetime.now(VN_TZ).strftime("%d/%m/%Y")
    quotes = [
        "Ngủ ngon nhé, mai lại là ngày mới tuyệt vời! 🌙",
        "Chúc bạn có những giấc mơ đẹp! 💤",
        "Đêm nay ngủ đủ giấc, mai dậy thật khỏe! ✨",
        "Chúc cả nhóm ngủ ngon! 🌌",
        "Nghỉ ngơi thôi, sức khỏe là vàng! 💛",
    ]
    return (
        "🌙 <b>CHÚC NGỦ NGON</b> 🌙\n"
        "───────────────\n\n"
        f"📅 Hôm nay: <b>{today}</b>\n"
        f"🕙 Bây giờ: <b>{NIGHT_HOUR:02d}:{NIGHT_MINUTE:02d}</b>\n\n"
        f"💬 {random.choice(quotes)}\n\n"
        "💤 <i>ShinnCheat Team</i>"
    )

async def morning_job(context: ContextTypes.DEFAULT_TYPE):
    try:
        await context.bot.send_message(
            ALLOWED_CHAT_ID, _morning_text(),
            parse_mode="HTML", disable_web_page_preview=True,
        )
    except Exception as e:
        logging.warning("Morning job failed: %s", e)

async def night_job(context: ContextTypes.DEFAULT_TYPE):
    try:
        await context.bot.send_message(
            ALLOWED_CHAT_ID, _night_text(),
            parse_mode="HTML", disable_web_page_preview=True,
        )
    except Exception as e:
        logging.warning("Night job failed: %s", e)

# ==================== SUPABASE API ====================
def _gen_key_string() -> str:
    alphabet = string.ascii_uppercase + string.digits
    parts = ["".join(secrets.choice(alphabet) for _ in range(4)) for _ in range(3)]
    return f"{KEY_PREFIX}-" + "-".join(parts)

async def sb_create_keys(label, quantity, key_type, owner_id):
    seconds = KEY_DURATIONS[label]
    now = datetime.now(timezone.utc)
    expires = now + timedelta(seconds=seconds)
    rows = [{
        "key": _gen_key_string(),
        "role": "member",
        "kind": key_type,
        "label": label,
        "expires_at": expires.isoformat(),
        "max_devices": 1,
        "unlimited_devices": False,
    } for _ in range(quantity)]
    url = f"{SUPABASE_URL}/rest/v1/{SUPABASE_TABLE}"
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=representation",
    }
    async with aiohttp.ClientSession() as session:
        async with session.post(url, json=rows, headers=headers) as resp:
            text = await resp.text()
            if resp.status not in (200, 201):
                raise RuntimeError(f"Supabase {resp.status}: {text[:300]}")
            return await resp.json()

async def sb_list_keys(limit=20):
    url = (f"{SUPABASE_URL}/rest/v1/{SUPABASE_TABLE}"
           f"?select=*&order=created_at.desc&limit={limit}")
    headers = {"apikey": SUPABASE_KEY, "Authorization": f"Bearer {SUPABASE_KEY}"}
    async with aiohttp.ClientSession() as session:
        async with session.get(url, headers=headers) as resp:
            if resp.status != 200:
                raise RuntimeError(f"Supabase {resp.status}")
            return await resp.json()

async def sb_get_key(key_str):
    url = f"{SUPABASE_URL}/rest/v1/{SUPABASE_TABLE}?key=eq.{key_str}&select=*"
    headers = {"apikey": SUPABASE_KEY, "Authorization": f"Bearer {SUPABASE_KEY}"}
    async with aiohttp.ClientSession() as session:
        async with session.get(url, headers=headers) as resp:
            if resp.status != 200:
                return None
            data = await resp.json()
            return data[0] if data else None

async def sb_delete_key(key_str):
    url = f"{SUPABASE_URL}/rest/v1/{SUPABASE_TABLE}?key=eq.{key_str}"
    headers = {"apikey": SUPABASE_KEY, "Authorization": f"Bearer {SUPABASE_KEY}"}
    async with aiohttp.ClientSession() as session:
        async with session.delete(url, headers=headers) as resp:
            return resp.status in (200, 204)

async def sb_stats():
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Prefer": "count=exact", "Range-Unit": "items", "Range": "0-0",
    }
    async def _count(q):
        async with aiohttp.ClientSession() as s:
            async with s.get(
                f"{SUPABASE_URL}/rest/v1/{SUPABASE_TABLE}?select=key{q}",
                headers=headers,
            ) as r:
                cr = r.headers.get("Content-Range", "0-0/0")
                try:
                    return int(cr.split("/")[-1])
                except Exception:
                    return 0
    total = await _count("")
    used = await _count("&last_used_at=not.is.null")
    now_iso = datetime.now(timezone.utc).isoformat()
    expired = await _count(f"&expires_at=lt.{now_iso}")
    return {"total": total, "used": used, "expired": expired}

# ==================== OWNER KEY COMMANDS ====================
_DUR_READABLE = {
    3600: "1 giờ", 3*3600: "3 giờ", 6*3600: "6 giờ", 12*3600: "12 giờ",
    86400: "1 ngày", 3*86400: "3 ngày", 5*86400: "5 ngày",
    7*86400: "7 ngày", 15*86400: "15 ngày", 30*86400: "30 ngày",
}

async def _owner_create_keys(update, context, label):
    msg = update.effective_message
    user = update.effective_user
    if msg is None or user is None:
        return
    if not context.args:
        await msg.reply_text(
            f"⚠️ Dùng: <code>/key{label} &lt;số_lượng&gt;</code>",
            parse_mode="HTML",
        )
        return
    try:
        qty = int(context.args[0])
    except ValueError:
        await msg.reply_text("⚠️ Số phải là số nguyên.")
        return
    if qty < 1 or qty > MAX_KEYS_PER_REQUEST:
        await msg.reply_text(f"⚠️ Số lượng từ 1 đến {MAX_KEYS_PER_REQUEST}.")
        return
    key_type = "test" if label == "test" else "vip"
    sent = await msg.reply_text(f"⏳ Đang tạo {qty} key <b>{label}</b>...", parse_mode="HTML")
    try:
        result = await sb_create_keys(label, qty, key_type, user.id)
    except Exception as e:
        await sent.edit_text(f"❌ Lỗi: <code>{html.escape(str(e))}</code>", parse_mode="HTML")
        return
    keys = [r["key"] for r in result]
    secs = KEY_DURATIONS[label]
    readable = _DUR_READABLE.get(secs, f"{secs}s")
    header = (
        f"🔑 <b>ĐÃ TẠO {len(keys)} KEY</b>\n"
        "───────────────\n\n"
        f"📦 Loại: {key_type}\n"
        f"⏱️ Thời hạn: {readable}\n"
        f"🎯 Số lượng: {len(keys)}\n\n"
        "───────────────\n"
    )
    body = header + "\n".join(f"<code>{k}</code>" for k in keys)
    delivered = False
    if update.effective_chat and update.effective_chat.type in ("group", "supergroup"):
        try:
            if len(body) > 4000:
                await context.bot.send_message(user.id, header, parse_mode="HTML")
                for i in range(0, len(keys), 40):
                    ct = "\n".join(f"<code>{k}</code>" for k in keys[i:i+40])
                    await context.bot.send_message(user.id, ct, parse_mode="HTML")
            else:
                await context.bot.send_message(user.id, body, parse_mode="HTML")
            delivered = True
        except Exception as e:
            logging.warning("Không gửi DM: %s", e)
    if delivered:
        await sent.edit_text(
            f"✅ Đã tạo <b>{len(keys)}</b> key <b>{label}</b>.\n"
            f"📩 Danh sách đã gửi vào DM.",
            parse_mode="HTML",
        )
    else:
        await sent.edit_text(f"✅ Đã tạo {len(keys)} key:", parse_mode="HTML")
        if len(body) > 4000:
            for i in range(0, len(keys), 40):
                ct = "\n".join(f"<code>{k}</code>" for k in keys[i:i+40])
                await msg.reply_text(ct, parse_mode="HTML")
        else:
            await msg.reply_text(body, parse_mode="HTML")

@group_or_shop_dm
@owner_only
async def keytest_cmd(u, c): await _owner_create_keys(u, c, "test")
@group_or_shop_dm
@owner_only
async def key1h_cmd(u, c): await _owner_create_keys(u, c, "1h")
@group_or_shop_dm
@owner_only
async def key1d_cmd(u, c): await _owner_create_keys(u, c, "1d")
@group_or_shop_dm
@owner_only
async def key3d_cmd(u, c): await _owner_create_keys(u, c, "3d")
@group_or_shop_dm
@owner_only
async def key5d_cmd(u, c): await _owner_create_keys(u, c, "5d")
@group_or_shop_dm
@owner_only
async def key7d_cmd(u, c): await _owner_create_keys(u, c, "7d")
@group_or_shop_dm
@owner_only
async def key15d_cmd(u, c): await _owner_create_keys(u, c, "15d")
@group_or_shop_dm
@owner_only
async def key30d_cmd(u, c): await _owner_create_keys(u, c, "30d")

@group_or_shop_dm
@owner_only
async def keylist_cmd(update, context):
    msg = update.effective_message
    sent = await msg.reply_text("⏳ Đang tải...")
    try:
        items = await sb_list_keys(30)
    except Exception as e:
        await sent.edit_text(f"❌ Lỗi: <code>{html.escape(str(e))}</code>", parse_mode="HTML")
        return
    if not items:
        await sent.edit_text("📭 Chưa có key.")
        return
    now = datetime.now(timezone.utc)
    lines = [
        "📋 <b>30 KEY GẦN NHẤT</b>",
        "───────────────\n",
    ]
    for it in items:
        exp = it.get("expires_at")
        status = "🔓"
        if exp:
            try:
                exp_dt = datetime.fromisoformat(exp.replace("Z", "+00:00"))
                status = "⛔" if exp_dt < now else "🔓"
            except Exception:
                pass
        if it.get("last_used_at"):
            status = "✅"
        lines.append(f"{status} <code>{it['key']}</code> — <b>{it.get('label','?')}</b>")
    await sent.edit_text("\n".join(lines), parse_mode="HTML")

@group_or_shop_dm
@owner_only
async def keyinfo_cmd(update, context):
    msg = update.effective_message
    if not context.args:
        await msg.reply_text("⚠️ Dùng: /keyinfo <key>")
        return
    info = await sb_get_key(context.args[0].strip())
    if not info:
        await msg.reply_text("❌ Không tìm thấy.")
        return
    used = "✅ Đã dùng" if info.get("last_used_at") else "🔓 Chưa dùng"
    text = (
        "🔍 <b>THÔNG TIN KEY</b>\n"
        "───────────────\n\n"
        f"🔑 <code>{info['key']}</code>\n"
        f"📦 Kind: {info.get('kind','?')}\n"
        f"👤 Role: {info.get('role','?')}\n"
        f"⏱️ Label: {info.get('label','?')}\n"
        f"🎯 {used}\n"
        f"📱 Max devices: {info.get('max_devices','?')}\n"
        f"📅 Tạo: {str(info.get('created_at',''))[:19]}\n"
        f"⏰ Hết hạn: {str(info.get('expires_at',''))[:19]}\n"
    )
    await msg.reply_text(text, parse_mode="HTML")

@group_or_shop_dm
@owner_only
async def keydel_cmd(update, context):
    msg = update.effective_message
    if not context.args:
        await msg.reply_text("⚠️ Dùng: /keydel <key>")
        return
    key_str = context.args[0].strip()
    ok = await sb_delete_key(key_str)
    await msg.reply_text(
        f"✅ Đã xoá <code>{html.escape(key_str)}</code>." if ok else "❌ Xoá thất bại.",
        parse_mode="HTML",
    )

@group_or_shop_dm
@owner_only
async def keystats_cmd(update, context):
    msg = update.effective_message
    try:
        s = await sb_stats()
    except Exception as e:
        await msg.reply_text(f"❌ Lỗi: <code>{html.escape(str(e))}</code>", parse_mode="HTML")
        return
    avail = s["total"] - s["used"] - s["expired"]
    text = (
        "📊 <b>THỐNG KÊ KEY</b>\n"
        "───────────────\n\n"
        f"🔢 Tổng: {s['total']}\n"
        f"✅ Đã dùng: {s['used']}\n"
        f"⛔ Hết hạn: {s['expired']}\n"
        f"🔓 Còn dùng: {avail}\n"
    )
    await msg.reply_text(text, parse_mode="HTML")

# ==================== SHOP COMMANDS ====================
async def _show_shop(update, context):
    msg = update.effective_message
    user = update.effective_user
    if msg is None or user is None:
        return
    points = _points_display(user.id)
    await msg.reply_text(
        TEXTS["shop"].format(points=points),
        parse_mode="HTML",
        disable_web_page_preview=True,
    )

async def _do_exchange(update, context):
    msg = update.effective_message
    user = update.effective_user
    chat = update.effective_chat
    if msg is None or user is None or chat is None:
        return
    _remember_user(user)
    if not context.args:
        await _show_shop(update, context)
        return
    raw_label = context.args[0].lower().strip()
    label = SHOP_ALIASES.get(raw_label, raw_label)
    if label not in SHOP_PRICES:
        await msg.reply_text(
            TEXTS["shop_bad_label"].format(label=html.escape(raw_label)),
            parse_mode="HTML",
        )
        return
    qty = 1
    if len(context.args) > 1:
        try:
            qty = int(context.args[1])
        except ValueError:
            await msg.reply_text("⚠️ Số lượng phải là số nguyên.")
            return
    if qty < 1 or qty > SHOP_MAX_QTY:
        await msg.reply_text(f"⚠️ Số lượng từ 1 đến {SHOP_MAX_QTY}.")
        return

    cost = SHOP_PRICES[label] * qty
    is_unlimited = user.id in UNLIMITED_POINTS_IDS
    readable = _DUR_READABLE.get(KEY_DURATIONS[label], label)

    async with _exchange_locks[user.id]:
        current = user_points.get(user.id, 0)
        if not is_unlimited and current < cost:
            await msg.reply_text(
                TEXTS["shop_not_enough"].format(
                    label=f"{qty}× {label} ({readable})", cost=cost,
                    points=current, missing=cost - current),
                parse_mode="HTML",
            )
            return

        sent = await msg.reply_text("⏳ Đang tạo key...")
        if not is_unlimited:
            user_points[user.id] -= cost          # trừ điểm trước
            _save_data()

        def _refund():
            if not is_unlimited:
                user_points[user.id] += cost
                _save_data()

        try:
            result = await sb_create_keys(label, qty, "vip", user.id)
        except Exception as e:
            _refund()
            await sent.edit_text(
                TEXTS["shop_error"].format(err=html.escape(str(e)[:300])),
                parse_mode="HTML",
            )
            return

        keys = [r["key"] for r in result]
        if is_unlimited:
            remaining, cost_display = UNLIMITED_POINTS_LABEL, "— (Owner)"
        else:
            remaining, cost_display = f"{user_points[user.id]} điểm", f"{cost} điểm"

        exp_iso = result[0].get("expires_at", "")
        try:
            exp_dt = datetime.fromisoformat(exp_iso.replace("Z", "+00:00"))
            exp_fmt = exp_dt.astimezone(VN_TZ).strftime("%d/%m/%Y %H:%M")
        except Exception:
            exp_fmt = exp_iso[:19]

        if qty == 1:
            dm_text = TEXTS["shop_success"].format(
                key=keys[0], label=f"{label} ({readable})",
                expires=exp_fmt, cost=cost_display, remaining=remaining)
        else:
            dm_text = (
                f"✅ <b>ĐỔI {qty} KEY THÀNH CÔNG</b>\n───────────────\n\n"
                f"⏱️ Thời hạn: {label} ({readable})\n📅 Hết hạn: {exp_fmt}\n"
                f"💸 Đã trừ: {cost_display}\n💎 Còn lại: {remaining}\n\n"
                "───────────────\n📋 <b>DANH SÁCH KEY:</b>\n\n"
                + "\n".join(f"<code>{k}</code>" for k in keys)
                + "\n\n🎉 Cảm ơn bạn!"
            )

        try:
            if len(dm_text) <= 4000:
                await context.bot.send_message(user.id, dm_text, parse_mode="HTML")
            else:
                for i in range(0, len(keys), 40):
                    ct = "\n".join(f"<code>{k}</code>" for k in keys[i:i+40])
                    await context.bot.send_message(user.id, ct, parse_mode="HTML")
        except Exception as e:
            logging.warning("DM fail user %s: %s", user.id, e)
            _refund()
            for k in keys:                        # xoá key, không để lộ ở group
                try:
                    await sb_delete_key(k)
                except Exception:
                    pass
            await sent.edit_text(
                "⚠️ Không gửi được key vào DM.\n"
                f"👉 Bấm vào @{context.bot.username} → <b>Start</b> rồi đổi lại.\n"
                "💎 Điểm của bạn đã được hoàn.",
                parse_mode="HTML",
            )
            return

        await sent.edit_text(
            "✅ <b>Đổi key thành công!</b>\n\n"
            f"🔑 Số lượng: {qty} key <b>{label}</b>\n"
            f"💸 Đã trừ: {cost_display}\n💎 Còn lại: {remaining}\n\n"
            "📩 <b>Key đã gửi vào DM riêng của bạn!</b>",
            parse_mode="HTML",
        )

@group_or_shop_dm
@spam_protected
async def shop_cmd(update, context):
    await _show_shop(update, context)

@group_or_shop_dm
@spam_protected
async def doikey_cmd(update, context):
    await _do_exchange(update, context)

# ==================== START DM ====================
async def start_dm(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat = update.effective_chat
    user = update.effective_user
    if chat is None or chat.type != "private" or user is None:
        return
    points_line = f"💎 <b>Điểm của bạn:</b> {_points_display(user.id)}"

    if _is_owner(update):
        text = (
            "👑 <b>OWNER CONSOLE</b>\n"
            "───────────────\n\n"
            f"👋 Chào <b>{html.escape(user.full_name)}</b>!\n"
            f"{points_line}\n\n"
            "🛍️ <b>SHOP (DM):</b>\n"
            "• /shop — Xem bảng giá\n"
            "• /doikey 1d — Đổi key\n"
            "• /diem — Xem điểm\n\n"
            "🎯 <b>TẠO QUIZ / THÔNG BÁO:</b>\n"
            "• /taocauhoi — Tạo câu hỏi (trắc nghiệm A/B/C/D hoặc tự gõ), gõ lệnh để xem mẫu\n"
            "• /thongbao &lt;nội_dung&gt;\n"
            "• /tbcustom &lt;HTML&gt;\n"
            "• /tagall &lt;nội_dung&gt;\n"
            "• /pinmess &lt;message_id&gt;\n\n"
            "🔑 <b>TẠO KEY (dùng trong group hoặc DM):</b>\n"
            "• /keytest /key1h /key1d /key3d\n"
            "• /key5d /key7d /key15d /key30d\n"
            "• /keylist /keyinfo /keydel /keystats"
        )
    else:
        text = (
            "🛍️ <b>SHOP ĐỔI KEY</b>\n"
            "───────────────\n\n"
            "👋 Chào bạn! Đây là kênh <b>đổi điểm lấy key</b> riêng tư.\n"
            "Key sẽ được gửi kín đáo.\n\n"
            f"{points_line}\n\n"
            "───────────────\n"
            "📌 <b>Các lệnh dùng được:</b>\n"
            "• /shop — Xem bảng giá\n"
            "• /doikey 1d — Đổi key 1 ngày\n"
            "• /doikey 1d 2 — Đổi 2 key\n"
            "• /diem — Xem điểm\n"
            "• /bxh — Xem BXH"
        )
    await chat.send_message(text, parse_mode="HTML", disable_web_page_preview=True)

# ==================== OWNER DM COMMANDS ====================
async def taocauhoi_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    global quiz_state
    chat = update.effective_chat
    msg = update.effective_message
    if chat is None or msg is None:
        return
    if chat.type != "private":
        await msg.reply_text("⚠️ Lệnh này chỉ dùng trong DM riêng của bot.")
        return
    if not _is_owner(update):
        await msg.reply_text("⛔ Chỉ Owner dùng được lệnh này.")
        return
    if not context.args:
        await msg.reply_text(
            "📝 <b>Cách tạo câu hỏi:</b>\n\n"
            "🔘 <b>Trắc nghiệm (bấm nút A/B/C/D):</b>\n"
            "<code>/taocauhoi câu hỏi | đáp án A | đáp án B | đáp án C | đáp án D | A</code>\n"
            "Phần cuối là chữ cái của đáp án đúng. Có thể dùng 2-4 đáp án.\n\n"
            "VD: <code>/taocauhoi 2 + 2 = ? | 3 | 4 | 5 | 6 | B</code>\n\n"
            "⌨️ <b>Tự gõ đáp án:</b>\n"
            "<code>/taocauhoi câu hỏi | đáp án</code>\n"
            "VD: <code>/taocauhoi Thủ đô Việt Nam? | hà nội</code>",
            parse_mode="HTML",
        )
        return
    parts_all = msg.text.split(maxsplit=1)
    content = parts_all[1] if len(parts_all) > 1 else ""
    if "|" in content:
        parts = [p.strip() for p in content.split("|")]
    elif "---" in content:
        parts = [p.strip() for p in content.split("---", 1)]
    else:
        await msg.reply_text(
            "⚠️ Sai format. Dùng <code>|</code> giữa các phần. Gõ /taocauhoi để xem mẫu.",
            parse_mode="HTML",
        )
        return
    if any(not p for p in parts):
        await msg.reply_text("⚠️ Không được để trống phần nào.")
        return

    question = parts[0]
    options = None
    correct = None
    text_answer = None
    if len(parts) == 2:
        text_answer = parts[1]
    elif 4 <= len(parts) <= 6:
        options = parts[1:-1]
        letter = parts[-1].upper()
        if letter not in QUIZ_LETTERS[:len(options)]:
            await msg.reply_text(
                f"⚠️ Đáp án đúng phải là một trong: {', '.join(QUIZ_LETTERS[:len(options)])}."
            )
            return
        correct = QUIZ_LETTERS.index(letter)
    else:
        await msg.reply_text(
            "⚠️ Sai format. Trắc nghiệm cần 2-4 đáp án + chữ cái đáp án đúng. "
            "Gõ /taocauhoi để xem mẫu."
        )
        return

    if quiz_state is not None:
        old = quiz_state.get("task")
        if old:
            old.cancel()
        quiz_state = None
    try:
        await _launch_quiz(context, question, options=options, correct=correct,
                           text_answer=text_answer)
    except Exception as e:
        await msg.reply_text(
            f"❌ Không gửi được lên group: <code>{html.escape(str(e))}</code>",
            parse_mode="HTML",
        )
        return
    shown = quiz_state["raw_answer"] if quiz_state else ""
    await msg.reply_text(
        f"✅ <b>Đã gửi câu hỏi lên group!</b>\n\n"
        f"❓ Câu hỏi: {html.escape(question)}\n"
        f"✅ Đáp án: <code>{html.escape(shown)}</code>",
        parse_mode="HTML",
    )

async def thongbao_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat = update.effective_chat
    msg = update.effective_message
    if chat is None or msg is None:
        return
    if chat.type != "private":
        await msg.reply_text("⚠️ Lệnh này chỉ dùng trong DM riêng của bot.")
        return
    if not _is_owner(update):
        await msg.reply_text("⛔ Chỉ Owner dùng được lệnh này.")
        return
    if not context.args:
        await msg.reply_text(
            "📝 <b>Cách gửi thông báo:</b>\n\n"
            "<code>/thongbao &lt;nội_dung&gt;</code>\n\n"
            "VD: <code>/thongbao Bảo trì app lúc 22h hôm nay</code>",
            parse_mode="HTML",
        )
        return
    content = msg.text.split(maxsplit=1)[1] if len(msg.text.split(maxsplit=1)) > 1 else ""
    if not content.strip():
        await msg.reply_text("⚠️ Nội dung không được trống.")
        return
    text_send = (
        "📢 <b>THÔNG BÁO TỪ OWNER</b>\n"
        "───────────────\n\n"
        f"{html.escape(content)}\n\n"
        "───────────────\n"
        f"👑 <b>Owner:</b> @{OWNER_USERNAME}"
    )
    try:
        await context.bot.send_message(ALLOWED_CHAT_ID, text_send, parse_mode="HTML")
        await msg.reply_text("✅ Đã gửi thông báo lên group!")
    except Exception as e:
        await msg.reply_text(f"❌ Lỗi: <code>{html.escape(str(e))}</code>", parse_mode="HTML")

async def tbcustom_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat = update.effective_chat
    msg = update.effective_message
    if chat is None or msg is None:
        return
    if chat.type != "private":
        await msg.reply_text("⚠️ Lệnh này chỉ dùng trong DM.")
        return
    if not _is_owner(update):
        await msg.reply_text("⛔ Chỉ Owner dùng được.")
        return
    if not context.args:
        await msg.reply_text(
            "📝 <b>Thông báo HTML thô:</b>\n\n"
            "<code>/tbcustom &lt;nội_dung_HTML&gt;</code>\n\n"
            "VD: <code>/tbcustom &lt;b&gt;Chào&lt;/b&gt; mọi người</code>",
            parse_mode="HTML",
        )
        return
    content = msg.text.split(maxsplit=1)[1] if len(msg.text.split(maxsplit=1)) > 1 else ""
    try:
        await context.bot.send_message(ALLOWED_CHAT_ID, content, parse_mode="HTML")
        await msg.reply_text("✅ Đã gửi lên group!")
    except Exception as e:
        await msg.reply_text(f"❌ Lỗi: <code>{html.escape(str(e))}</code>", parse_mode="HTML")

async def tagall_dm_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat = update.effective_chat
    msg = update.effective_message
    if chat is None or msg is None:
        return
    if chat.type != "private":
        await msg.reply_text("⚠️ Lệnh này chỉ dùng trong DM.")
        return
    if not _is_owner(update):
        await msg.reply_text("⛔ Chỉ Owner dùng được.")
        return
    content = html.escape(" ".join(context.args)) if context.args else "📢 Thông báo từ admin"
    if not user_name_cache:
        await msg.reply_text("⚠️ Chưa có user nào trong cache.")
        return
    parts = [_mention(uid) for uid in user_name_cache]
    text = (
        "📢 <b>" + content + "</b>\n"
        "───────────────\n\n"
        + " ".join(parts)
    )
    try:
        await context.bot.send_message(ALLOWED_CHAT_ID, text, parse_mode="HTML")
        await msg.reply_text(f"✅ Đã tag <b>{len(parts)}</b> thành viên.", parse_mode="HTML")
    except Exception as e:
        await msg.reply_text(f"❌ Lỗi: <code>{html.escape(str(e))}</code>", parse_mode="HTML")

async def pinmess_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat = update.effective_chat
    msg = update.effective_message
    if chat is None or msg is None:
        return
    if chat.type != "private":
        await msg.reply_text("⚠️ Lệnh này chỉ dùng trong DM.")
        return
    if not _is_owner(update):
        await msg.reply_text("⛔ Chỉ Owner dùng được.")
        return
    if not context.args:
        await msg.reply_text(
            "📝 Dùng: <code>/pinmess &lt;message_id&gt;</code>",
            parse_mode="HTML",
        )
        return
    try:
        message_id = int(context.args[0])
    except ValueError:
        await msg.reply_text("⚠️ Message ID phải là số.")
        return
    try:
        await context.bot.pin_chat_message(ALLOWED_CHAT_ID, message_id)
        await msg.reply_text("✅ Đã ghim tin nhắn.")
    except Exception as e:
        await msg.reply_text(f"❌ Lỗi: <code>{html.escape(str(e))}</code>", parse_mode="HTML")

# ==================== KEYWORD AUTO-REPLY ====================
KEYWORD_MAP = [
    (["shinncheattest", "shinncheat test", "key test", "key trial", "test key",
      "dùng thử", "dung thu", "trial key"], "key_test", "key"),
    (["shinncheat", "shinn cheat", "key chính thức", "key chinh thuc",
      "official key"], "key_official", "key"),
    (["key là gì", "key la gi", "key nào", "key nao",
      "danh sách key", "danh sach key", "key free", "key miễn phí", "key mien phi",
      "xin key", "cho key", "lấy key", "lay key", "có key không", "co key khong",
      "xem key", "list key"], "key", "key"),
    (["mua key", "buy key", "giá key", "gia key", "bao nhiêu", "bao nhieu",
      "price", "giá bao", "gia bao", "mua ở đâu", "mua o dau"], "buy", "buy"),
    (["owner là ai", "owner la ai", "admin là ai", "admin la ai",
      "liên hệ owner", "lien he owner", "contact owner",
      "ai làm bot", "ai lam bot", "chủ bot", "chu bot"], "owner", "contact"),
    (["update", "cập nhật", "cap nhat", "bản mới", "ban moi",
      "version", "phiên bản", "phien ban"], "update", None),
    (["repo", "repository", "nguồn tải", "nguon tai",
      "tải ở đâu", "tai o dau", "download", "link tải", "link tai"], "repo", None),
    (["support", "hỗ trợ", "ho tro", "help me", "giúp với", "giup voi",
      "bị lỗi", "bi loi", "không dùng được", "khong dung duoc"], "support", "support"),
    (["nội quy", "noi quy", "rules", "quy định", "quy dinh",
      "luật nhóm", "luat nhom"], "rules", None),
    (["bot là gì", "bot la gi", "about", "giới thiệu", "gioi thieu"], "about", "contact"),
    (["owner ngủ", "owner ngu", "owner bận", "owner ban",
      "owner offline", "ad ơi", "ad oi", "admin ơi", "admin oi"], "ad", "contact"),
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

    if any(kw in text for kw in ["điểm danh", "diem danh", "check in", "checkin"]):
        await _do_checkin(update, context)
        return
    if any(kw in text for kw in ["điểm của tôi", "diem cua toi", "xem điểm",
                                  "xem diem", "my score"]):
        await _show_mydiem(update, context)
        return
    if any(kw in text for kw in ["bxh điểm", "bxh diem", "top điểm", "top diem",
                                  "bảng xếp hạng", "bang xep hang", "leaderboard"]):
        await _show_bxh(update, context)
        return
    if any(kw in text for kw in ["shop", "cửa hàng", "cua hang",
                                  "đổi key", "doi key", "đổi điểm", "doi diem"]):
        await _show_shop(update, context)
        return

    if "shinn" in text:
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
                    logging.warning("Gửi file fail: %s", e)

    for keywords, reply_key, kb_kind in KEYWORD_MAP:
        if any(kw in text for kw in keywords):
            await message.reply_text(
                render(reply_key),
                parse_mode="HTML",
                reply_markup=_get_keyboard(kb_kind),
                disable_web_page_preview=True,
            )
            return

# ==================== SETFILE ====================
@group_only
@admin_only
async def setfile_cmd(update, context):
    msg = update.effective_message
    if not msg.reply_to_message:
        await msg.reply_text("📎 Reply vào file rồi gõ /setfile.")
        return
    doc = msg.reply_to_message.document
    if doc is None:
        await msg.reply_text("⚠️ Không có file.")
        return
    text = (
        "📎 <b>FILE_ID</b>\n"
        "───────────────\n\n"
        f"📄 Tên: <code>{html.escape(doc.file_name or '')}</code>\n"
        f"📦 Size: <b>{doc.file_size / 1024 / 1024:.2f} MB</b>\n\n"
        f"<code>{doc.file_id}</code>"
    )
    await msg.reply_text(text, parse_mode="HTML")

# ==================== INFO ====================
@group_or_shop_dm
@spam_protected
async def start(update, context):
    if update.effective_chat and update.effective_chat.type == "private":
        return  # DM đã có start_dm xử lý
    if update.effective_message:
        await update.effective_message.reply_text(
            render("start"), parse_mode="HTML",
            reply_markup=contact_keyboard(),
            disable_web_page_preview=True,
        )

@group_or_shop_dm
@spam_protected
async def help_cmd(update, context):
    if update.effective_message:
        await update.effective_message.reply_text(render("help"), parse_mode="HTML")

@group_only
@spam_protected
async def id_cmd(update, context):
    if update.effective_message and update.effective_user:
        await update.effective_message.reply_text(
            f"👤 Tên: <b>{html.escape(_display_name(update.effective_user))}</b>\n"
            f"🆔 ID: <code>{update.effective_user.id}</code>\n"
            f"💬 Chat ID: <code>{update.effective_chat.id}</code>",
            parse_mode="HTML",
        )

@group_only
@spam_protected
async def chatid_cmd(update, context):
    if update.effective_message:
        await update.effective_message.reply_text(
            f"💬 Chat ID: <code>{update.effective_chat.id}</code>",
            parse_mode="HTML",
        )

def make_command(key):
    @group_or_shop_dm
    @spam_protected
    async def callback(update, context):
        if not update.effective_message:
            return
        if key == "shinn":
            if SHINN_FILE_ID:
                try:
                    await update.effective_message.reply_document(
                        document=SHINN_FILE_ID,
                        filename=SHINN_FILE_NAME,
                        caption=SHINN_FILE_CAPTION.format(owner=OWNER_USERNAME),
                        parse_mode="HTML",
                        reply_markup=contact_keyboard(),
                    )
                    return
                except Exception as e:
                    logging.warning("Gửi file fail: %s", e)
            await update.effective_message.reply_text(
                render("shinn"), parse_mode="HTML",
                reply_markup=contact_keyboard(),
            )
            return
        kb = None
        if key in ("owner", "about", "ad"):
            kb = contact_keyboard()
        elif key == "buy":
            kb = buy_keyboard()
        elif key == "support":
            kb = support_keyboard()
        elif key == "key":
            kb = key_keyboard()
        await update.effective_message.reply_text(
            render(key), parse_mode="HTML",
            reply_markup=kb, disable_web_page_preview=True,
        )
    return callback

# ==================== ADMIN ====================
@group_only
@admin_only
async def pin_cmd(update, context):
    msg = update.effective_message
    if not msg.reply_to_message:
        await msg.reply_text("⚠️ Reply tin cần ghim.")
        return
    try:
        await msg.reply_to_message.pin()
        await msg.reply_text("📌 Đã ghim.")
    except Exception as e:
        await msg.reply_text(f"❌ {e}")

@group_only
@admin_only
async def unpin_cmd(update, context):
    try:
        await update.effective_chat.unpin_all_messages()
        await update.effective_message.reply_text("📌 Đã bỏ ghim.")
    except Exception as e:
        await update.effective_message.reply_text(f"❌ {e}")

@group_only
@admin_only
async def del_cmd(update, context):
    msg = update.effective_message
    if not msg.reply_to_message:
        await msg.reply_text("⚠️ Reply tin cần xoá.")
        return
    try:
        await msg.reply_to_message.delete()
        await msg.delete()
    except Exception as e:
        await msg.reply_text(f"❌ {e}")

@group_only
@admin_only
async def mute_cmd(update, context):
    msg = update.effective_message
    if not msg.reply_to_message or not msg.reply_to_message.from_user:
        await msg.reply_text("⚠️ Reply user. VD: /mute 1d")
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
        await update.effective_chat.restrict_member(target.id, _muted_perms(), until_date=until)
        await msg.reply_text(f"🔇 Đã mute {target.mention_html()} trong {duration}.", parse_mode="HTML")
    except Exception as e:
        await msg.reply_text(f"❌ {e}")

@group_only
@admin_only
async def unmute_cmd(update, context):
    msg = update.effective_message
    if not msg.reply_to_message or not msg.reply_to_message.from_user:
        await msg.reply_text("⚠️ Reply user.")
        return
    target = msg.reply_to_message.from_user
    try:
        await update.effective_chat.restrict_member(target.id, _full_perms())
        await msg.reply_text(f"🔊 Đã unmute {target.mention_html()}.", parse_mode="HTML")
    except Exception as e:
        await msg.reply_text(f"❌ {e}")

@group_only
@admin_only
async def warn_cmd(update, context):
    msg = update.effective_message
    if not msg.reply_to_message or not msg.reply_to_message.from_user:
        await msg.reply_text("⚠️ Reply user.")
        return
    target = msg.reply_to_message.from_user
    warn_count[target.id] += 1
    count = warn_count[target.id]
    if count >= WARN_LIMIT:
        until = datetime.now(timezone.utc) + MUTE_DURATION
        try:
            await update.effective_chat.restrict_member(target.id, _muted_perms(), until_date=until)
            warn_count[target.id] = 0
            await msg.reply_text(f"🔇 {target.mention_html()} đủ warn → mute 1 ngày.", parse_mode="HTML")
        except Exception as e:
            await msg.reply_text(f"❌ {e}")
    else:
        await msg.reply_text(f"⚠️ {target.mention_html()} warn ({count}/{WARN_LIMIT}).", parse_mode="HTML")

@group_only
@admin_only
async def unwarn_cmd(update, context):
    msg = update.effective_message
    if not msg.reply_to_message or not msg.reply_to_message.from_user:
        await msg.reply_text("⚠️ Reply user.")
        return
    target = msg.reply_to_message.from_user
    warn_count[target.id] = 0
    await msg.reply_text(f"✅ Đã xoá warn cho {target.mention_html()}.", parse_mode="HTML")

@group_only
@admin_only
async def kick_cmd(update, context):
    msg = update.effective_message
    if not msg.reply_to_message or not msg.reply_to_message.from_user:
        await msg.reply_text("⚠️ Reply user.")
        return
    target = msg.reply_to_message.from_user
    try:
        await update.effective_chat.ban_member(target.id)
        await update.effective_chat.unban_member(target.id)
        await msg.reply_text(f"👢 Đã kick {target.mention_html()}.", parse_mode="HTML")
    except Exception as e:
        await msg.reply_text(f"❌ {e}")

@group_only
@admin_only
async def ban_cmd(update, context):
    msg = update.effective_message
    if not msg.reply_to_message or not msg.reply_to_message.from_user:
        await msg.reply_text("⚠️ Reply user.")
        return
    target = msg.reply_to_message.from_user
    try:
        await update.effective_chat.ban_member(target.id)
        await msg.reply_text(f"🚫 Đã ban {target.mention_html()}.", parse_mode="HTML")
    except Exception as e:
        await msg.reply_text(f"❌ {e}")

@group_only
@admin_only
async def unban_cmd(update, context):
    msg = update.effective_message
    if not context.args or not context.args[0].lstrip("-").isdigit():
        await msg.reply_text("⚠️ Dùng: /unban <user_id>")
        return
    target_id = int(context.args[0])
    try:
        await update.effective_chat.unban_member(target_id)
        await msg.reply_text(f"✅ Đã gỡ ban {target_id}.", parse_mode="HTML")
    except Exception as e:
        await msg.reply_text(f"❌ {e}")

@group_only
@admin_only
async def say_cmd(update, context):
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
async def tagall_cmd(update, context):
    msg = update.effective_message
    if not user_name_cache:
        await msg.reply_text("⚠️ Chưa có user.")
        return
    content = html.escape(" ".join(context.args)) if context.args else "📢 Thông báo từ admin"
    parts = [_mention(uid) for uid in user_name_cache]
    text = (
        "📢 <b>" + content + "</b>\n"
        "───────────────\n\n"
        + " ".join(parts)
    )
    try:
        await update.effective_chat.send_message(text, parse_mode="HTML")
    except Exception as e:
        await msg.reply_text(f"❌ {e}")

# ==================== STATS ====================
@group_only
@spam_protected
async def info_cmd(update, context):
    msg = update.effective_message
    target = (msg.reply_to_message.from_user
              if msg.reply_to_message and msg.reply_to_message.from_user
              else update.effective_user)
    count = user_msg_count.get(target.id, 0)
    first = user_first_seen.get(target.id)
    first_str = datetime.fromtimestamp(first, VN_TZ).strftime("%d/%m/%Y %H:%M") if first else "—"
    warns = warn_count.get(target.id, 0)
    last_msg = html.escape(user_msg_text.get(target.id, "—"))
    pts = _points_display(target.id)
    text = (
        "👤 <b>THÔNG TIN THÀNH VIÊN</b>\n"
        "───────────────\n\n"
        f"👤 Tên: <b>{html.escape(_display_name(target))}</b>\n"
        f"🆔 ID: <code>{target.id}</code>\n"
        f"🔗 Username: @{target.username if target.username else '—'}\n"
        f"💬 Tin nhắn: <b>{count}</b>\n"
        f"💎 Điểm: <b>{pts}</b>\n"
        f"⚠️ Warn: <b>{warns}</b>\n"
        f"⏰ Lần đầu: {first_str}\n"
        f"📝 Tin cuối: <i>{last_msg}</i>"
    )
    await msg.reply_text(text, parse_mode="HTML")

@group_only
@spam_protected
async def stats_cmd(update, context):
    total_msgs = sum(user_msg_count.values())
    total_users = len(user_msg_count)
    delta = timedelta(seconds=int(time.time() - BOT_START_TIME))
    try:
        import resource
        mem = f"{resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024:.1f}"
    except Exception:
        mem = "?"
    text = (
        "📊 <b>THỐNG KÊ BOT</b>\n"
        "───────────────\n\n"
        f"👥 Users: <b>{total_users}</b>\n"
        f"💬 Tin nhắn: <b>{total_msgs}</b>\n"
        f"💎 Users có điểm: <b>{len(user_points)}</b>\n"
        f"🔐 Chờ verify: <b>{len(pending_verifications)}</b>\n"
        f"⏱️ Uptime: <b>{delta}</b>\n"
        f"🧠 RAM: <b>{mem} MB</b>\n"
        f"🌏 Timezone: <b>UTC+7</b>"
    )
    await update.effective_message.reply_text(text, parse_mode="HTML")

@group_only
@spam_protected
async def top_cmd(update, context):
    if not user_msg_count:
        await update.effective_message.reply_text("⚠️ Chưa có dữ liệu.")
        return
    top = user_msg_count.most_common(10)
    lines = [
        "🏆 <b>TOP 10 ACTIVE</b>",
        "───────────────\n",
    ]
    medals = ["🥇", "🥈", "🥉"]
    for i, (uid, count) in enumerate(top):
        medal = medals[i] if i < 3 else f"<b>{i+1}.</b>"
        lines.append(f"{medal} {_mention(uid)} — <b>{count}</b>")
    await update.effective_message.reply_text("\n".join(lines), parse_mode="HTML")

@group_or_shop_dm
@spam_protected
async def diemdanh_cmd(update, context):
    # Điểm danh chỉ trong group để tránh gian lận
    if update.effective_chat.type == "private":
        await update.effective_message.reply_text(
            "📌 Hãy điểm danh trong nhóm chính nhé!"
        )
        return
    await _do_checkin(update, context)

@group_or_shop_dm
@spam_protected
async def mydiem_cmd(update, context): await _show_mydiem(update, context)

@group_or_shop_dm
@spam_protected
async def bxh_cmd(update, context): await _show_bxh(update, context)

@group_only
@admin_only
async def resetdiem_cmd(update, context):
    global last_points_reset
    await _announce_prize()
    user_points.clear()
    user_checkin_date.clear()
    user_checkin_streak.clear()
    last_points_reset = time.time()
    _save_data()
    await update.effective_message.reply_text("✅ Đã reset điểm & BXH.")

# ==================== MAIN ====================
def main():
    global _bot_app
    app = Application.builder().token(BOT_TOKEN).build()
    _bot_app = app

    _load_data()

    async def remember_user_handler(update, context):
        chat = update.effective_chat
        if chat and chat.id == ALLOWED_CHAT_ID:
            _remember_user(update.effective_user)

    async def on_error(update, context):
        logging.error("Lỗi handler:", exc_info=context.error)

    app.add_handler(MessageHandler(filters.ALL, remember_user_handler), group=-2)
    app.add_error_handler(on_error)

    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("help", help_cmd))
    app.add_handler(CommandHandler("id", id_cmd))
    app.add_handler(CommandHandler("chatid", chatid_cmd))
    for cmd in ("shinn", "key", "buy", "owner", "update", "repo",
                "support", "rules", "about", "ad"):
        app.add_handler(CommandHandler(cmd, make_command(cmd)))

    app.add_handler(CommandHandler("diemdanh", diemdanh_cmd))
    app.add_handler(CommandHandler("checkin", diemdanh_cmd))
    app.add_handler(CommandHandler("diem", mydiem_cmd))
    app.add_handler(CommandHandler("mydiem", mydiem_cmd))
    app.add_handler(CommandHandler("bxh", bxh_cmd))
    app.add_handler(CommandHandler("topdiem", bxh_cmd))
    app.add_handler(CommandHandler("resetdiem", resetdiem_cmd))

    app.add_handler(CommandHandler("shop", shop_cmd))
    app.add_handler(CommandHandler("doikey", doikey_cmd))
    app.add_handler(CommandHandler("exchange", doikey_cmd))

    app.add_handler(CommandHandler("keytest", keytest_cmd))
    app.add_handler(CommandHandler("key1h", key1h_cmd))
    app.add_handler(CommandHandler("key1d", key1d_cmd))
    app.add_handler(CommandHandler("key3d", key3d_cmd))
    app.add_handler(CommandHandler("key5d", key5d_cmd))
    app.add_handler(CommandHandler("key7d", key7d_cmd))
    app.add_handler(CommandHandler("key15d", key15d_cmd))
    app.add_handler(CommandHandler("key30d", key30d_cmd))
    app.add_handler(CommandHandler("keylist", keylist_cmd))
    app.add_handler(CommandHandler("keyinfo", keyinfo_cmd))
    app.add_handler(CommandHandler("keydel", keydel_cmd))
    app.add_handler(CommandHandler("keystats", keystats_cmd))

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
    app.add_handler(CallbackQueryHandler(quiz_callback, pattern=r"^quiz:"))

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

    # DM handlers ưu tiên cao (group -1)
    app.add_handler(CommandHandler("start", start_dm), group=-1)
    app.add_handler(CommandHandler("tagall", tagall_dm_cmd), group=-1)

    # Owner DM commands
    app.add_handler(CommandHandler("taocauhoi", taocauhoi_cmd))
    app.add_handler(CommandHandler("thongbao", thongbao_cmd))
    app.add_handler(CommandHandler("tbcustom", tbcustom_cmd))
    app.add_handler(CommandHandler("pinmess", pinmess_cmd))

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
        app.job_queue.run_repeating(
            _send_quiz,
            interval=QUIZ_INTERVAL_MIN * 60,
            first=600,
            name="quiz_job",
        )
        logging.info(
            "Đã đặt lịch: sáng %02d:%02d, tối %02d:%02d, quiz mỗi %d phút",
            MORNING_HOUR, MORNING_MINUTE, NIGHT_HOUR, NIGHT_MINUTE, QUIZ_INTERVAL_MIN,
        )
    else:
        logging.warning("JobQueue KHÔNG khả dụng!")

    logging.info("ShinnCheat bot is running. Chat ID: %s", ALLOWED_CHAT_ID)
    app.run_polling(allowed_updates=Update.ALL_TYPES)

if __name__ == "__main__":
    main()