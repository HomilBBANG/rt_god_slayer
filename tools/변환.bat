@echo off
chcp 65001 >nul
cd /d "%~dp0\.."
echo [God Slayer] balance.xlsx → data/balance.json 변환 중...
python tools/excel_to_godot.py
if %errorlevel% neq 0 (
    echo.
    echo ❌ 변환 실패! 오류를 확인하세요.
) else (
    echo.
    echo ✅ 완료! Godot을 재시작하거나 F5로 실행하면 적용됩니다.
)
pause
