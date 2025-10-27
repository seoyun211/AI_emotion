from fastapi import FastAPI
import uvicorn

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "테스트 서버 작동!"}

@app.get("/health")
def health_check():
    return {"status": "ok"}

if __name__ == "__main__":
    print("🧪 테스트 서버 시작...")
    uvicorn.run(app, host="0.0.0.0", port=8080)