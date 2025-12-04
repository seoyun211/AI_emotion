import os
import torch

def ensure_dir(path):
    """폴더가 없으면 생성"""
    if not os.path.exists(path):
        os.makedirs(path)

def save_cache(data, path):
    """캐시 저장"""
    ensure_dir(os.path.dirname(path))
    torch.save(data, path)
    print(f" 캐시 저장 완료: {path}")

def load_cache(path):
    """캐시 불러오기"""
    if os.path.exists(path):
        print(f" 캐시 로드 중: {path}")
        return torch.load(path)
    else:
        print(" 캐시 파일이 존재하지 않습니다.")
        return None
