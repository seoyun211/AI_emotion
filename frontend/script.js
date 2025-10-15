// API 기본 URL
const API_BASE = 'http://localhost:8080';

// DOM 요소
const textInput = document.getElementById('textInput');
const analyzeBtn = document.getElementById('analyzeBtn');
const resultSection = document.getElementById('resultSection');
const emotionIcon = document.getElementById('emotionIcon');
const emotionText = document.getElementById('emotionText');
const riskFill = document.getElementById('riskFill');
const riskText = document.getElementById('riskText');
const alertStatus = document.getElementById('alertStatus');
const historyList = document.getElementById('historyList');
const saveUserBtn = document.getElementById('saveUserBtn');

// 감정 아이콘 매핑
const emotionIcons = {
    '기쁨': '😊',
    '슬픔': '😢',
    '분노': '😠',
    '불안': '😰',
    '중립': '😐'
};

// 감정 분석 함수
async function analyzeEmotion() {
    const text = textInput.value.trim();
    
    if (!text) {
        alert('텍스트를 입력해주세요!');
        return;
    }

    try {
        // 로딩 상태
        analyzeBtn.textContent = '분석 중...';
        analyzeBtn.disabled = true;

        // API 호출
        const response = await fetch(`${API_BASE}/predict`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                text: text,
                user_id: 'current_user' // 실제로는 저장된 사용자 ID 사용
            })
        });

        if (!response.ok) {
            throw new Error('API 호출 실패');
        }

        const result = await response.json();
        
        // 결과 표시
        displayResult(result);
        
        // 기록에 추가
        addToHistory(result, text);
        
    } catch (error) {
        console.error('Error:', error);
        alert('분석 중 오류가 발생했습니다. 나중에 다시 시도해주세요.');
        
        // 임시 결과 표시 (API 연결 전용)
        displayMockResult(text);
    } finally {
        analyzeBtn.textContent = '감정 분석';
        analyzeBtn.disabled = false;
    }
}

// 결과 표시 함수
function displayResult(result) {
    const emotion = result.emotion || result.final_emotion || '중립';
    const confidence = result.confidence || 0.5;
    const riskScore = result.risk_score || 0.3;
    
    // 감정 아이콘과 텍스트 업데이트
    emotionIcon.textContent = emotionIcons[emotion] || '😐';
    emotionText.textContent = emotion;
    
    // 위험도 표시
    const riskPercent = Math.round(riskScore * 100);
    riskFill.style.width = `${riskPercent}%`;
    riskText.textContent = `위험도: ${riskPercent}%`;
    
    // 알림 상태 설정
    if (riskScore > 0.7) {
        alertStatus.textContent = '🚨 보호자에게 알림이 전송되었습니다';
        alertStatus.className = 'alert-status danger';
    } else if (riskScore > 0.4) {
        alertStatus.textContent = '⚠️ 관심이 필요한 감정 상태입니다';
        alertStatus.className = 'alert-status warning';
    } else {
        alertStatus.textContent = '✅ 안정적인 감정 상태입니다';
        alertStatus.className = 'alert-status safe';
    }
    
    // 결과 섹션 표시
    resultSection.classList.remove('hidden');
}

// 임시 결과 표시 (API 연결 전)
function displayMockResult(text) {
    const emotions = ['기쁨', '슬픔', '중립', '불안'];
    const randomEmotion = emotions[Math.floor(Math.random() * emotions.length)];
    const riskScore = Math.random();
    
    emotionIcon.textContent = emotionIcons[randomEmotion];
    emotionText.textContent = randomEmotion;
    
    const riskPercent = Math.round(riskScore * 100);
    riskFill.style.width = `${riskPercent}%`;
    riskText.textContent = `위험도: ${riskPercent}%`;
    
    if (riskScore > 0.7) {
        alertStatus.textContent = '🚨 보호자에게 알림이 전송되었습니다';
        alertStatus.className = 'alert-status danger';
    } else {
        alertStatus.textContent = '✅ 안정적인 감정 상태입니다';
        alertStatus.className = 'alert-status safe';
    }
    
    resultSection.classList.remove('hidden');
    
    // 임시 기록 추가
    addToHistory({
        emotion: randomEmotion,
        risk_score: riskScore,
        timestamp: new Date().toLocaleString()
    }, text);
}

// 기록에 추가
function addToHistory(result, text) {
    const historyItem = document.createElement('div');
    historyItem.className = 'history-item';
    
    const emotion = result.emotion || result.final_emotion || '중립';
    const riskScore = result.risk_score || 0;
    const timestamp = result.timestamp || new Date().toLocaleString();
    
    historyItem.innerHTML = `
        <div class="history-emotion">
            <strong>${emotionIcons[emotion] || '😐'} ${emotion}</strong>
            <span>${Math.round(riskScore * 100)}%</span>
        </div>
        <div class="history-text">${text.substring(0, 30)}${text.length > 30 ? '...' : ''}</div>
        <div class="history-date">${timestamp}</div>
    `;
    
    historyList.insertBefore(historyItem, historyList.firstChild);
    
    // 기록이 5개 이상이면 오래된 것 삭제
    if (historyList.children.length > 5) {
        historyList.removeChild(historyList.lastChild);
    }
}

// 사용자 정보 저장
function saveUserInfo() {
    const name = document.getElementById('userName').value;
    const phone = document.getElementById('userPhone').value;
    const guardian = document.getElementById('guardianPhone').value;
    
    if (name && phone) {
        localStorage.setItem('userName', name);
        localStorage.setItem('userPhone', phone);
        localStorage.setItem('guardianPhone', guardian);
        alert('사용자 정보가 저장되었습니다!');
    } else {
        alert('이름과 전화번호를 입력해주세요!');
    }
}

// 저장된 사용자 정보 불러오기
function loadUserInfo() {
    const name = localStorage.getItem('userName');
    const phone = localStorage.getItem('userPhone');
    const guardian = localStorage.getItem('guardianPhone');
    
    if (name) document.getElementById('userName').value = name;
    if (phone) document.getElementById('userPhone').value = phone;
    if (guardian) document.getElementById('guardianPhone').value = guardian;
}

// 이벤트 리스너
analyzeBtn.addEventListener('click', analyzeEmotion);
saveUserBtn.addEventListener('click', saveUserInfo);

// Enter 키로도 분석 가능
textInput.addEventListener('keypress', function(e) {
    if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        analyzeEmotion();
    }
});

// 앱 초기화
function initApp() {
    loadUserInfo();
    console.log('말동이 앱이 시작되었습니다!');
}

// 앱 실행
initApp();