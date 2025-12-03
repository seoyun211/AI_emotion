# models/clients/face_client.py
import torch
from torchvision import transforms
from PIL import Image
import os

LABELS = ["기쁨", "분노", "불안", "슬픔"]

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
WEIGHT_PATH = os.path.join(BASE_DIR, "model_weights", "image_model.pt")

device = "cuda" if torch.cuda.is_available() else "cpu"

# TODO: 팀원이 만든 실제 이미지 모델 클래스로 교체
from .some_image_model_def import ImageEmotionModel  # 예시

_image_model = ImageEmotionModel(num_classes=4)
_image_model.load_state_dict(torch.load(WEIGHT_PATH, map_location=device))
_image_model.to(device)
_image_model.eval()

_img_transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    # Normalization 있으면 추가
])

def predict_face_probs(image_path: str) -> list[float]:
    """
    image_path: 로컬 이미지 파일 경로
    return: [기쁨, 분노, 불안, 슬픔] 확률 리스트 (길이 4)
    """
    img = Image.open(image_path).convert("RGB")
    x = _img_transform(img).unsqueeze(0).to(device)

    with torch.no_grad():
        logits = _image_model(x)
        probs = torch.softmax(logits, dim=-1)[0].cpu().tolist()
    return probs
