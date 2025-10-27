import uvicorn
from config import APP_CONFIG

if __name__ == "__main__":
    print("🚀 말동이 백엔드 서버 시작...")
    uvicorn.run(
        "main:app",
        host=APP_CONFIG["host"],
        port=APP_CONFIG["port"],
        reload=True
    )