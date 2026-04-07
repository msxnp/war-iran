#!/bin/bash
# US-Iran War Update Script
# ดึงข้อมูลล่าสุดทุกชั่วโมง

TIMESTAMP=$(date +"%Y%m%d-%H%M")
FILE="/root/.openclaw/workspace/war-iran/updates/$TIMESTAMP.md"

# ค้นหาข่าว
NEWS=$(curl -s "https://news.google.com/rss/search?q=US+Iran+war+April+2026&hl=en-US&gl=US&ceid=US:en" 2>/dev/null | head -50)

# สร้างไฟล์
cat > "$FILE" << 'HEADER'
# US-Iran War Update - TIMESTAMP_PLACEHOLDER

## Latest Updates

HEADER

sed -i "s/TIMESTAMP_PLACEHOLDER/$TIMESTAMP/g" "$FILE"

echo "Updated: $FILE"
