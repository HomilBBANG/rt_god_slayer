@echo off
chcp 65001 >nul
cd /d "%~dp0\.."
echo [God Slayer] 밸런스 자동 변환 감시 시작...
start "God Slayer Balance Watcher" python tools/watcher.py
