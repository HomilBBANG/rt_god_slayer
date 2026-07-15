"""
balance.xlsx 변경 감지 → 자동 변환 (백그라운드 감시)
종료: Ctrl+C 또는 창 닫기
"""
import os, sys, time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
XLS  = os.path.join(ROOT, "tools", "balance.xlsx")

sys.path.insert(0, ROOT)

# excel_to_godot의 main을 직접 import
from tools.excel_to_godot import main as convert

def get_mtime():
    try:
        return os.path.getmtime(XLS)
    except FileNotFoundError:
        return 0.0

last_mtime = get_mtime()
print("=" * 50)
print(" God Slayer — 밸런스 자동 변환 감시 중")
print(f" 감시 파일: {XLS}")
print(" Excel 저장 시 자동으로 balance.json 변환됩니다.")
print(" 종료하려면 이 창을 닫으세요.")
print("=" * 50)

while True:
    time.sleep(0.8)
    mtime = get_mtime()
    if mtime != last_mtime and mtime != 0.0:
        last_mtime = mtime
        time.sleep(0.4)  # Excel이 파일 쓰기 완료할 때까지 잠깐 대기
        try:
            convert()
        except Exception as e:
            print(f"[오류] 변환 실패: {e}")
