from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import torch

app = FastAPI()

# 모델 불러오기
model = torch.load("model/model.pt")
model.eval()

# 요청 데이터 정의
class InputData(BaseModel):
    text: str

@app.get("/")
def read_root():
    return {"message": "말동이 백엔드 서버 정상 작동!"}

@app.post("/predict")
def predict(data: InputData):
    try:
        # 예시: text -> 모델 입력 tensor 변환
        input_tensor = torch.tensor([len(data.text)])  # 간단 예시
        output = model(input_tensor)                   # 모델 예측
        return {"prediction": output.item()}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
