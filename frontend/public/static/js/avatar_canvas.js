import React, { useEffect, useRef } from 'react';

const CallScreen = () => {
  const canvasRef = useRef(null);

  useEffect(() => {
    const baseImg = new Image();
    baseImg.src = process.env.PUBLIC_URL + '/static/images/남자아바타.png';
    
    baseImg.onload = () => {
      const canvas = canvasRef.current;
      if (!canvas) return;
      const ctx = canvas.getContext('2d');
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.drawImage(baseImg, 0, 0, canvas.width, canvas.height);
    };

    baseImg.onerror = () => console.error('이미지 로딩 실패:', baseImg.src);
  }, []);

  return (
    <canvas ref={canvasRef} width={256} height={256} />
  );
};

export default CallScreen;


