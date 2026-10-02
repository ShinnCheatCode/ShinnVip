import os
import logging
from telegram import Update
from telegram.ext import (
    Application, CommandHandler, MessageHandler, ContextTypes, filters
)

logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)
logging.getLogger("httpx").setLevel(logging.WARNING)

BOT_TOKEN =("8751726089:AAE991LNO6G15hICWl7jSX5JzVMzRwPIiTY
", "").strip()
OWNER_USERNAME = os.getenv("OWNER_USERNAME", "ShinnThieuu").strip().lstrip("@")
APP_NAME = "ShinnCheat"

if not BOT_TOKEN:
    raise RuntimeError("Missing BOT_TOKEN secret. Add it in GitHub repository Secrets.")

TEXTS = {
    "start": (
        "ð ChÃ o má»«ng báº¡n Äáº¿n vá»i ShinnCheat!\n"
        "DÃ¹ng /help Äá» xem cÃ¡c lá»nh cá»§a bot.\n\n"
        "ð Welcome to ShinnCheat!\n"
        "Use /help to see the bot commands."
    ),
    "help": (
        "ð SHINNCHEAT â DANH SÃCH Lá»NH\n\n"
        "/shinn â ThÃ´ng tin á»©ng dá»¥ng\n"
        "/key â ThÃ´ng tin key\n"
        "/buy â LiÃªn há» mua key\n"
        "/owner â LiÃªn há» Owner\n"
        "/update â ThÃ´ng tin cáº­p nháº­t\n"
        "/repo â ThÃ´ng tin repository\n"
        "/support â Nháº­n há» trá»£\n"
        "/rules â Ná»i quy nhÃ³m\n"
        "/about â Giá»i thiá»u bot\n"
        "/ad â ThÃ´ng bÃ¡o Owner Äang báº­n/ngá»§\n"
        "/id â Xem ID Telegram\n\n"
        "ð ENGLISH\n"
        "/shinn â App information\n"
        "/key â Key information\n"
        "/buy â Buy a key\n"
        "/owner â Contact the owner\n"
        "/update â App updates\n"
        "/repo â Repository information\n"
        "/support â Get support\n"
        "/rules â Group rules\n"
        "/about â About the bot\n"
        "/ad â Owner status notice\n"
        "/id â Show Telegram ID"
    ),
    "shinn": (
        "ð± SHINNCHEAT\n\n"
        "ð»ð³ ShinnCheat lÃ  á»©ng dá»¥ng Patch vá»i giao diá»n ÄÆ°á»£c thiáº¿t káº¿ láº¡i "
        "vÃ  cÃ¡c cáº£i thiá»n vá» tráº£i nghiá»m sá»­ dá»¥ng.\n"
        "ð Key: ShinnCheat / ShinnCheatTest\n"
        "ð Mua key: @{owner}\n\n"
        "ð¬ð§ ShinnCheat is a patch app with a redesigned interface and "
        "usability improvements.\n"
        "ð Keys: ShinnCheat / ShinnCheatTest\n"
        "ð Buy a key: @{owner}"
    ),
    "key": (
        "ð SHINNCHEAT KEYS\n\n"
        "Available keys:\n"
        "â¢ ShinnCheat\n"
        "â¢ ShinnCheatTest\n\n"
        "ð»ð³ Cáº§n mua key? Nháº¯n Owner: @{owner}\n"
        "ð¬ð§ To purchase a key, contact the Owner: @{owner}\n"
        "ð± Theo thÃ´ng tin hiá»n táº¡i, key khÃ´ng giá»i háº¡n thiáº¿t bá».\n"
        "ð± Keys support unlimited devices."
    ),
    "buy": (
        "ð MUA KEY / BUY A KEY\n\n"
        "ð»ð³ Äá» mua key ShinnCheat, hÃ£y nháº¯n trá»±c tiáº¿p Owner.\n"
        "ð¬ð§ To purchase a ShinnCheat key, message the Owner directly.\n\n"
        "ð¤ Owner: @{owner}"
    ),
    "owner": (
        "ð SHINNCHEAT OWNER\n\n"
        "ð»ð³ LiÃªn há» Owner Äá» mua key hoáº·c cáº§n há» trá»£.\n"
        "ð¬ð§ Contact the Owner for keys or support.\n\n"
        "ð© @{owner}"
    ),
    "update": (
        "ð SHINNCHEAT â UPDATE\n\n"
        "â¨ Giao diá»n ÄÆ°á»£c thiáº¿t káº¿ láº¡i\n"
        "ð¨ Cáº£i thiá»n mÃ u sáº¯c vÃ  hiá»n thá»\n"
        "ð¼ï¸ Há» trá»£ cáº­p nháº­t áº£nh Äáº¡i diá»n\n"
        "ð§ Cáº£i thiá»n Apply / Restore Patch\n"
        "â¡ Tá»i Æ°u hiá»u suáº¥t vÃ  sá»­a lá»i\n"
        "ð Cáº£i thiá»n Äá»ng bá» Repository\n\n"
        "ð¬ð§ Redesigned interface, improved visuals, avatar updates, "
        "Apply/Restore improvements, performance fixes and better repository sync."
    ),
    "repo": (
        "ð¦ REPOSITORY\n\n"
        "ð»ð³ Theo dÃµi thÃ´ng bÃ¡o trong nhÃ³m Äá» nháº­n liÃªn káº¿t repository má»i nháº¥t.\n"
        "ð¬ð§ Check group announcements for the latest repository links.\n"
        "â ï¸ Chá» táº£i file tá»« nguá»n mÃ  báº¡n tin tÆ°á»ng. / Only download from trusted sources."
    ),
    "support": (
        "ð ï¸ Há» TRá»¢ / SUPPORT\n\n"
        "ð»ð³ MÃ´ táº£ lá»i, phiÃªn báº£n iOS vÃ  cÃ¡c bÆ°á»c gÃ¢y ra lá»i; khÃ´ng gá»­i máº­t kháº©u hoáº·c token.\n"
        "ð¬ð§ Describe the issue, iOS version, and steps to reproduce it. Never send passwords or tokens.\n\n"
        "ð¤ Owner: @{owner}"
    ),
    "rules": (
        "ð Ná»I QUY NHÃM / GROUP RULES\n\n"
        "1. TÃ´n trá»ng má»i thÃ nh viÃªn / Respect all members.\n"
        "2. KhÃ´ng spam hoáº·c quáº£ng cÃ¡o trÃ¡i phÃ©p / No spam or unauthorized ads.\n"
        "3. KhÃ´ng giáº£ máº¡o Owner / Do not impersonate the Owner.\n"
        "4. KhÃ´ng chia sáº» thÃ´ng tin cÃ¡ nhÃ¢n cá»§a ngÆ°á»i khÃ¡c / Do not share others' private information.\n"
        "5. LiÃªn há» admin khi cáº§n há» trá»£ / Contact an admin for help."
    ),
    "about": (
        "ð¤ SHINNCHEAT BOT\n\n"
        "Bot há» trá»£ cá»ng Äá»ng ShinnCheat: thÃ´ng tin á»©ng dá»¥ng, key, cáº­p nháº­t vÃ  há» trá»£.\n"
        "A community bot for ShinnCheat app, key, update, and support information."
    ),
    "ad": (
        "ð THÃNG BÃO Tá»ª OWNER\n\n"
        "Shinn ngá»§ rá»i. Náº¿u báº¡n cÃ³ viá»c gáº¥p, hÃ£y liÃªn há» trá»±c tiáº¿p nhÃ©!\n"
        "ð© Owner: @{owner}\n\n"
        "ð OWNER NOTICE\n"
        "Shinn is asleep. If your matter is urgent, you can contact the Owner directly.\n"
        "ð© Owner: @{owner}"
    ),
}

def render(key: str) -> str:
    return TEXTS[key].format(owner=OWNER_USERNAME)

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_message:
        await update.effective_message.reply_text(render("start"))

async def help_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_message:
        await update.effective_message.reply_text(render("help"))

async def id_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_message and update.effective_user:
        await update.effective_message.reply_text(
            f"Your Telegram ID: {update.effective_user.id}"
        )

def make_command(key: str):
    async def callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
        if update.effective_message:
            await update.effective_message.reply_text(render(key))
    return callback

async def keyword_reply(update: Update, context: ContextTypes.DEFAULT_TYPE):
    message = update.effective_message
    if not message or not message.text:
        return
    text = message.text.lower()
    if "shinn" in text:
        await message.reply_text(render("shinn"))
    elif "key" in text or "mua key" in text or "buy key" in text:
        await message.reply_text(render("key"))

def main():
    app = Application.builder().token(BOT_TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("help", help_cmd))
    app.add_handler(CommandHandler("id", id_cmd))

    for command in ("shinn", "key", "buy", "owner", "update", "repo",
                    "support", "rules", "about", "ad"):
        app.add_handler(CommandHandler(command, make_command(command)))

    # Optional keyword auto-replies in groups. Avoid replying to the bot's own messages.
    app.add_handler(MessageHandler(
        filters.TEXT & ~filters.COMMAND & ~filters.User(user_id=[]),
        keyword_reply
    ))

    logging.info("ShinnCheat bot is running.")
    app.run_polling(allowed_updates=Update.ALL_TYPES)

if __name__ == "__main__":
    main()
