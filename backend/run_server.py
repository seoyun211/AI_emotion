import uvicorn

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",  # 모든 IP에서 접속 가능
        port=8080,       # 8080 포트 사용
        reload=True,     # 코드 변경시 자동 재시작
        access_log=True  # 접속 로그 표시
    )