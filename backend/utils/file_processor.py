# 📁 파일 처리
import base64
import io
from typing import Tuple

def encode_file_to_base64(file_data: bytes) -> str:
    """파일 데이터를 base64로 인코딩"""
    return base64.b64encode(file_data).decode('utf-8')

def decode_base64_to_file(base64_string: str) -> bytes:
    """base64 문자열을 파일 데이터로 디코딩"""
    return base64.b64decode(base64_string)

def validate_image_file(file_data: bytes, max_size: int = 10 * 1024 * 1024) -> Tuple[bool, str]:
    """이미지 파일 유효성 검사"""
    if len(file_data) > max_size:
        return False, f"파일 크기가 {max_size//1024//1024}MB를 초과합니다"
    
    # 간단한 이미지 형식 확인
    if file_data[:4] in [b'\xff\xd8\xff\xe0', b'\x89PNG', b'GIF8']:
        return True, "유효한 이미지 파일"
    
    return False, "지원하지 않는 이미지 형식입니다"

def validate_audio_file(file_data: bytes, max_size: int = 5 * 1024 * 1024) -> Tuple[bool, str]:
    """오디오 파일 유효성 검사"""
    if len(file_data) > max_size:
        return False, f"파일 크기가 {max_size//1024//1024}MB를 초과합니다"
    
    # WAV 파일 시그니처 확인
    if file_data[:4] == b'RIFF' and file_data[8:12] == b'WAVE':
        return True, "유효한 WAV 파일"
    
    # MP3 파일 시그니처 확인
    if file_data[:3] == b'ID3' or file_data[:2] == b'\xff\xfb':
        return True, "유효한 MP3 파일"
    
    return False, "지원하지 않는 오디오 형식입니다"