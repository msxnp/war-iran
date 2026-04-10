#!/bin/bash
# Script to generate HTML from markdown updates

UPDATE_DIR="/root/.openclaw/workspace-bunny/war-iran/updates"
OUTPUT_FILE="/root/.openclaw/workspace-bunny/war-iran/index.html"

# Read all update files and create HTML
UPDATES_HTML=""

for file in $(ls -t "$UPDATE_DIR"/*.md 2>/dev/null | head -5); do
    # Extract date from filename (e.g., 20260410-1200.md)
    FILENAME=$(basename "$file" .md)
    # Parse: YYYYMMDD-HHMM -> Thai time
    YEAR=$(echo $FILENAME | cut -c1-4)
    MONTH=$(echo $FILENAME | cut -c5-6)
    DAY=$(echo $FILENAME | cut -c7-8)
    HOUR=$(echo $FILENAME | cut -c10-11)
    MIN=$(echo $FILENAME | cut -c12-13)
    TIMESTAMP=$(TZ='Asia/Bangkok' date -d "$YEAR-$MONTH-$DAY $HOUR:$MIN" +"%-d เม.ย. %Y เวลา %H:%M น." 2>/dev/null || echo "$FILENAME")
    
    # Read file content
    CONTENT=$(cat "$file")
    
    # Convert to HTML items
    ITEMS_HTML=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^### ]]; then
            # Header
            ITEMS_HTML+="<h3 style='color:#ff8888;margin:15px 0 10px;'>${line### }</h3>"
        elif [[ "$line" =~ ^- ]]; then
            # Bullet point
            ITEMS_HTML+="<div class='update-item'><span class='update-icon'>📍</span><span class='update-text'>${line:1}</span></div>"
        fi
    done < "$file"
    
    UPDATES_HTML+="
    <div class='update-section'>
        <div class='update-header'>
            <span class='update-time'>$TIMESTAMP</span>
            <span class='update-source'>Auto-generated</span>
        </div>
        <div class='update-content'>
            $ITEMS_HTML
        </div>
    </div>"
done

# Calculate days since war started (Feb 28, 2026)
WAR_START="2026-02-28"
TODAY=$(date +%Y-%m-%d)
DAY_COUNT=$(( ($(date -d "$TODAY" +%s) - $(date -d "$WAR_START" +%s)) / 86400 + 1 ))
CURRENT_DATE=$(TZ='Asia/Bangkok' date +"%-d เม.ย. %Y %H:%M น.")

# Get commit count
COMMIT_COUNT=$(git rev-list --count HEAD 2>/dev/null || echo "0")

# If no updates, show message
if [ -z "$UPDATES_HTML" ]; then
    UPDATES_HTML="<div class='no-update'>ยังไม่มีข้อมูลอัพเดท</div>"
fi

# Generate full HTML
cat > "$OUTPUT_FILE" << EOF
<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>US-Iran War Updates | ข่าวสงครามอิหร่าน</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0a0a0f; color: #e0e0e0; min-height: 100vh; }
        .container { max-width: 800px; margin: 0 auto; padding: 20px; }
        header { text-align: center; padding: 40px 20px; border-bottom: 1px solid #222; margin-bottom: 30px; }
        h1 { font-size: 2.5rem; color: #ff4444; margin-bottom: 10px; }
        .subtitle { color: #888; font-size: 1.1rem; }
        .live-indicator { display: inline-flex; align-items: center; gap: 8px; background: #ff4444; color: white; padding: 8px 16px; border-radius: 20px; font-size: 0.9rem; font-weight: bold; margin-top: 15px; }
        .live-dot { width: 10px; height: 10px; background: white; border-radius: 50%; animation: pulse 1.5s infinite; }
        @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.3; } }
        .status-box { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 30px; }
        .status-item { background: #1a1a25; border: 1px solid #333; border-radius: 10px; padding: 20px; text-align: center; }
        .status-item .label { color: #888; font-size: 0.85rem; margin-bottom: 5px; }
        .status-item .value { font-size: 1.5rem; font-weight: bold; }
        .status-item.danger .value { color: #ff4444; }
        .status-item.warning .value { color: #ffaa00; }
        .status-item.safe .value { color: #44ff44; }
        .update-section { margin-bottom: 40px; }
        .update-header { display: flex; justify-content: space-between; align-items: center; padding: 15px 20px; background: linear-gradient(135deg, #1a1a25, #252535); border-radius: 10px 10px 0 0; border: 1px solid #333; border-bottom: none; }
        .update-time { font-size: 1.2rem; font-weight: bold; color: #ff6666; }
        .update-source { color: #666; font-size: 0.85rem; }
        .update-content { background: #151520; border: 1px solid #333; border-top: none; border-radius: 0 0 10px 10px; padding: 20px; }
        .update-item { display: flex; gap: 12px; margin-bottom: 15px; padding-bottom: 15px; border-bottom: 1px solid #222; }
        .update-item:last-child { margin-bottom: 0; padding-bottom: 0; border-bottom: none; }
        .update-icon { font-size: 1.2rem; min-width: 30px; }
        .update-text { flex: 1; line-height: 1.6; }
        .no-update { text-align: center; padding: 40px; color: #666; }
        footer { text-align: center; padding: 30px; color: #555; font-size: 0.85rem; border-top: 1px solid #222; margin-top: 50px; }
        .refresh-btn { background: #ff4444; color: white; border: none; padding: 12px 30px; border-radius: 25px; font-size: 1rem; cursor: pointer; transition: all 0.3s; }
        .refresh-btn:hover { background: #ff6666; transform: scale(1.05); }
        @media (max-width: 600px) { h1 { font-size: 1.8rem; } .container { padding: 15px; } .status-box { grid-template-columns: 1fr 1fr; } }
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
            <div class="status-item danger"><div class="label">วันที่</div><div class="value">$CURRENT_DATE</div></div>
            <div class="status-item danger"><div class="label">Day of Conflict</div><div class="value">$DAY_COUNT</div></div>
            <div class="status-item safe"><div class="label">Hormuz Status</div><div class="value">✓ เปิด</div></div>
            <div class="status-item"><div class="label">Updates</div><div class="value">$COMMIT_COUNT</div></div>
        </div>
        
        <div style="text-align: center; margin: 30px 0;">
            <button class="refresh-btn" onclick="location.reload()">🔄 Refresh</button>
        </div>
        
        <div class="update-section" id="updates">
EOF

echo "$UPDATES_HTML" >> "$OUTPUT_FILE"

cat >> "$OUTPUT_FILE" << 'EOF'
        </div>
        
        <footer>
            <p>ข้อมูลจาก ABC News, Al Jazeera, Reuters, CNN</p>
            <p>อัพเดททุกชั่วโมง | <a href="https://github.com/msxnp/war-iran" style="color: #ff6666;">GitHub Repository</a></p>
        </footer>
    </div>
    
    <script>
        setTimeout(() => location.reload(), 300000);
    </script>
</body>
</html>
EOF

echo "Generated: $OUTPUT_FILE"