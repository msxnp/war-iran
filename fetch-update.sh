#!/bin/bash
# US-Iran War Update Script
# ดึงข้อมูลล่าสุด + rebuild HTML + commit + push

cd /root/.openclaw/workspace-bunny/war-iran

TIMESTAMP=$(date +"%Y%m%d-%H%M")
FILE="/root/.openclaw/workspace-bunny/war-iran/updates/$TIMESTAMP.md"

# ค้นหาข่าว
NEWS=$(curl -s "https://news.google.com/rss/search?q=US+Iran+war+April+2026&hl=en-US&gl=US&ceid=US:en" 2>/dev/null | head -50)

# สร้างไฟล์
cat > "$FILE" << HEADER
# US-Iran War Update - $TIMESTAMP

## Latest Updates

HEADER

echo "Created: $FILE"

# Rebuild HTML using Python
python3 << 'PYEOF'
import os
from datetime import datetime

UPDATE_DIR = 'updates'
TRUTH_DIR = 'truth-posts'
HORMUZ_FILE = 'hormuz-status.txt'

today = datetime.now()
day_count = (today - datetime(2026, 2, 28)).days + 1
current_date = today.strftime('%-d เม.ย. %Y เวลา %H:%M น.')

try:
    with open(HORMUZ_FILE) as f:
        hormuz = f.read().strip()
except:
    hormuz = "✗ ปิด (Blockade)"
hormuz_class = "safe" if "เปิด" in hormuz else "danger"

try:
    commit_count = os.popen('git -C . rev-list --count HEAD').read().strip()
except:
    commit_count = "0"

# Build updates HTML
updates_html = ""
if os.path.exists(UPDATE_DIR):
    files = sorted([f for f in os.listdir(UPDATE_DIR) if f.endswith('.md')], reverse=True)[:10]
    for fname in files:
        with open(os.path.join(UPDATE_DIR, fname)) as f:
            lines = f.readlines()
        try:
            ts = datetime.strptime(fname.replace('.md',''), '%Y%m%d-%H%M')
            ts = ts.strftime('%-d เม.ย. %Y เวลา %H:%M น.')
        except:
            ts = fname
        items = ""
        for line in lines:
            line = line.strip()
            if line.startswith('###'):
                items += f"<h3 style='color:#ff8888;margin:15px 0 10px;'>{line[3:].strip()}</h3>"
            elif line.startswith('-'):
                items += f"<div class='update-item'><span class='update-icon'>📍</span><span class='update-text'>{line[1:].strip()}</span></div>"
        updates_html += f"<div class='update-section'><div class='update-header'><span class='update-time'>{ts}</span><span class='update-source'>Auto-generated</span></div><div class='update-content'>{items}</div></div>"

# Build truth HTML
truth_html = ""
if os.path.exists(TRUTH_DIR) and os.listdir(TRUTH_DIR):
    files = sorted([f for f in os.listdir(TRUTH_DIR) if f.endswith('.md')], reverse=True)[:5]
    for fname in files:
        with open(os.path.join(TRUTH_DIR, fname)) as f:
            content = f.read()
        try:
            ts = datetime.strptime(fname.replace('.md',''), '%Y%m%d-%H%M')
            ts = ts.strftime('%-d เม.ย. %Y เวลา %H:%M น.')
        except:
            ts = fname
        
        lines = content.strip().split('\n')
        items = ""
        for line in lines:
            line = line.strip()
            if line.startswith('###'):
                items += f"<h3 style='color:#88ddff;margin:15px 0 10px;'>{line[3:].strip()}</h3>"
            elif '🇺🇸' in line and '**"' in line:
                en_part = line.split('🇹🇭')[0].strip() if '🇹🇭' in line else line
                items += f"<div class='truth-block'><div class='truth-en'>{en_part}</div>"
            elif '🇹🇭' in line:
                th_part = line.replace('🇹🇭', '').strip()
                items += f"<div class='truth-th'>{th_part}</div></div>"
            elif '⏰' in line:
                items += f"<div class='truth-time'>{line}</div>"
            elif line.startswith('-') and '🇺🇸' not in line:
                items += f"<div class='update-item'><span class='update-icon'>🐦</span><span class='update-text'>{line[1:].strip()}</span></div>"
        
        truth_html += f"<div class='update-section truth-section'><div class='update-header truth-header'><span class='update-time'>{ts}</span><span class='update-source'>Truth Social</span></div><div class='update-content truth-content'>{items}</div></div>"
else:
    truth_html = "<div class='no-update'>ยังไม่มีโพสต์ Trump's Truth Social</div>"

html = f'''<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>US-Iran War Updates | ข่าวสงครามอิหร่าน</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0a0a0f; color: #e0e0e0; min-height: 100vh; }}
        .container {{ max-width: 800px; margin: 0 auto; padding: 20px; }}
        header {{ text-align: center; padding: 40px 20px; border-bottom: 1px solid #222; margin-bottom: 30px; }}
        h1 {{ font-size: 2.5rem; color: #ff4444; margin-bottom: 10px; }}
        .subtitle {{ color: #888; font-size: 1.1rem; }}
        .live-indicator {{ display: inline-flex; align-items: center; gap: 8px; background: #ff4444; color: white; padding: 8px 16px; border-radius: 20px; font-size: 0.9rem; font-weight: bold; margin-top: 15px; }}
        .live-dot {{ width: 10px; height: 10px; background: white; border-radius: 50%; animation: pulse 1.5s infinite; }}
        @keyframes pulse {{ 0%, 100% {{ opacity: 1; }} 50% {{ opacity: 0.3; }} }}
        .status-box {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 30px; }}
        .status-item {{ background: #1a1a25; border: 1px solid #333; border-radius: 10px; padding: 20px; text-align: center; }}
        .status-item .label {{ color: #888; font-size: 0.85rem; margin-bottom: 5px; }}
        .status-item .value {{ font-size: 1.5rem; font-weight: bold; }}
        .status-item.danger .value {{ color: #ff4444; }}
        .status-item.warning .value {{ color: #ffaa00; }}
        .status-item.safe .value {{ color: #44ff44; }}
        .tab-nav {{ display: flex; gap: 10px; margin-bottom: 20px; flex-wrap: wrap; }}
        .tab-btn {{ background: #1a1a25; color: #888; border: 1px solid #333; padding: 12px 24px; border-radius: 25px; cursor: pointer; font-size: 1rem; transition: all 0.3s; }}
        .tab-btn.active {{ background: #ff4444; color: white; border-color: #ff4444; }}
        .tab-btn:hover {{ background: #333; }}
        .tab-content {{ display: none; }}
        .tab-content.active {{ display: block; }}
        .update-section {{ margin-bottom: 40px; }}
        .update-header {{ display: flex; justify-content: space-between; align-items: center; padding: 15px 20px; background: linear-gradient(135deg, #1a1a25, #252535); border-radius: 10px 10px 0 0; border: 1px solid #333; border-bottom: none; }}
        .update-time {{ font-size: 1.2rem; font-weight: bold; color: #ff6666; }}
        .update-source {{ color: #666; font-size: 0.85rem; }}
        .update-content {{ background: #151520; border: 1px solid #333; border-top: none; border-radius: 0 0 10px 10px; padding: 20px; }}
        .truth-header {{ background: linear-gradient(135deg, #1a1a25, #1a2530); }}
        .truth-section .update-time {{ color: #88ddff; }}
        .update-item {{ display: flex; gap: 12px; margin-bottom: 15px; padding-bottom: 15px; border-bottom: 1px solid #222; }}
        .update-item:last-child {{ margin-bottom: 0; padding-bottom: 0; border-bottom: none; }}
        .update-icon {{ font-size: 1.2rem; min-width: 30px; }}
        .update-text {{ flex: 1; line-height: 1.6; }}
        .truth-content {{ background: #0d1520; }}
        .truth-block {{ background: #1a2535; border-left: 4px solid #88ddff; padding: 15px; margin-bottom: 20px; border-radius: 0 8px 8px 0; }}
        .truth-en {{ color: #ffffff; font-size: 1.1rem; line-height: 1.6; margin-bottom: 8px; font-style: italic; }}
        .truth-time {{ color: #888; font-size: 0.85rem; margin-bottom: 8px; }}
        .truth-th {{ color: #ffcc00; font-size: 1rem; line-height: 1.6; padding-left: 15px; border-left: 2px solid #ffcc00; }}
        .no-update {{ text-align: center; padding: 40px; color: #666; }}
        footer {{ text-align: center; padding: 30px; color: #555; font-size: 0.85rem; border-top: 1px solid #222; margin-top: 50px; }}
        .refresh-btn {{ background: #ff4444; color: white; border: none; padding: 12px 30px; border-radius: 25px; font-size: 1rem; cursor: pointer; transition: all 0.3s; }}
        .refresh-btn:hover {{ background: #ff6666; transform: scale(1.05); }}
        @media (max-width: 600px) {{ h1 {{ font-size: 1.8rem; }} .container {{ padding: 15px; }} .status-box {{ grid-template-columns: 1fr 1fr; }} }}
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🔥 US-Iran War Updates</h1>
            <p class="subtitle">ติดตามสงครามสหรัฐ-อิหร่าน แบบเรียลไทม์</p>
            <div class="live-indicator"><span class="live-dot"></span>LIVE UPDATE</div>
        </header>
        
        <div class="status-box">
            <div class="status-item danger"><div class="label">วันที่</div><div class="value">{current_date}</div></div>
            <div class="status-item danger"><div class="label">Day of Conflict</div><div class="value">{day_count}</div></div>
            <div class="status-item {hormuz_class}"><div class="label">Hormuz Status</div><div class="value">{hormuz}</div></div>
            <div class="status-item"><div class="label">Updates</div><div class="value">{commit_count}</div></div>
        </div>
        
        <div class="tab-nav">
            <button class="tab-btn active" id="tab-btn-updates" onclick="showTab('updates')">📰 ข่าวอัพเดท</button>
            <button class="tab-btn" id="tab-btn-truth" onclick="showTab('truth')">🐦 Trump's Truth Social</button>
        </div>
        
        <div style="text-align: center; margin: 30px 0;">
            <button class="refresh-btn" onclick="location.reload()">🔄 Refresh</button>
        </div>
        
        <div id="tab-updates" class="tab-content active">
{updates_html}
        </div>
        
        <div id="tab-truth" class="tab-content">
{truth_html}
        </div>
        
        <footer>
            <p>ข้อมูลจาก ABC News, Al Jazeera, Reuters, CNN</p>
            <p>Trump's Truth Social จาก Tavily Search | อัพเดททุก 2 ชั่วโมง</p>
            <p><a href="https://github.com/msxnp/war-iran" style="color: #ff6666;">GitHub Repository</a></p>
        </footer>
    </div>
    
    <script>
        function showTab(tab) {{
            document.querySelectorAll(".tab-content").forEach(function(el){{el.classList.remove("active")}});
            document.querySelectorAll(".tab-btn").forEach(function(el){{el.classList.remove("active")}});
            document.getElementById("tab-" + tab).classList.add("active");
            document.getElementById("tab-btn-" + tab).classList.add("active");
        }}
        setTimeout(function(){{location.reload()}}, 300000);
    </script>
</body>
</html>'''

with open('index.html', 'w') as f:
    f.write(html)

print(f'Rebuilt index.html - Updates: {len(updates_html)} chars, Truth: {len(truth_html)} chars')
PYEOF

# Commit and push
git add -A
git commit -m "Update $(date +'%Y%m%d %H:%M')" 2>/dev/null
git push 2>&1

echo "Done - pushed to GitHub"
