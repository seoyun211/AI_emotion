import torch
from torchvision import transforms
from torchvision.models import efficientnet_b0, EfficientNet_B0_Weights
from PIL import Image
from facenet_pytorch import MTCNN
import os

# ========================
# 설정
# ========================
MODEL_PATH = "C:/AI_emotion/models/expression_model.pt"
IMAGE_PATH = "C:/AI_emotion/test_images"  # 폴더 전체 가능
DEVICE = 'cuda' if torch.cuda.is_available() else 'cpu'

# ========================
# 클래스 이름 (학습 순서 그대로!)
# ========================
classes = ['기쁨', '당황', '분노', '불안', '상처', '슬픔', '중립']

# ========================
# 모델 로드
# ========================
model = efficientnet_b0(weights=None)
model.classifier[1] = torch.nn.Linear(1280, len(classes))
model.load_state_dict(torch.load(MODEL_PATH, map_location=DEVICE))
model = model.to(DEVICE)
model.eval()

# ========================
# 전처리 정의 (EfficientNet 기본 transform)
# ========================
weights = EfficientNet_B0_Weights.IMAGENET1K_V1
transform = weights.transforms()

# ========================
# 얼굴 검출기(MTCNN)
# ========================
mtcnn = MTCNN(keep_all=False, device=DEVICE)

# ========================
# 이미지 처리 함수
# ========================
def predict_image(image_path):
    img = Image.open(image_path).convert('RGB')
    # 얼굴 검출
    face = mtcnn(img)
    if face is None:
        print(f"[❌] 얼굴을 찾을 수 없음: {image_path}")
        return
    
    # face: (3, H, W) → PIL 이미지로 변환 후 transform
    face_img = transforms.ToPILImage()(face.cpu())
    input_tensor = transform(face_img).unsqueeze(0).to(DEVICE)

    with torch.no_grad():
        outputs = model(input_tensor)
        probs = torch.softmax(outputs, dim=1)
        confidence, predicted = torch.max(probs, 1)
        emotion = classes[predicted.item()]
        top3 = torch.topk(probs, 1)  # 상위 1개만
    
    print(f"📁 {os.path.basename(image_path)} → {emotion} ({confidence.item()*100:.2f}%)")

# ========================
# 폴더 전체 이미지 예측
# ========================
for fname in os.listdir(IMAGE_PATH):
    if fname.lower().endswith(('.jpg', '.png', '.jpeg')):
        predict_image(os.path.join(IMAGE_PATH, fname))
