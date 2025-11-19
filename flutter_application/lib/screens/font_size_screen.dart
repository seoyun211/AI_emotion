import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../font_size_provider.dart';

class FontSizeScreen extends StatelessWidget {
  const FontSizeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5D4037)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '글씨 크기',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '편하게 읽을 수 있는 크기를 선택해주세요',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF8D6E63),
                ),
              ),
              const SizedBox(height: 40),

              // 미리보기 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Consumer<FontSizeProvider>(
                  builder: (context, fontProvider, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '미리보기',
                          style: TextStyle(
                            fontSize: 16 * fontProvider.fontScale,
                            color: const Color(0xFF8D6E63),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '말동이와 함께\n대화해요',
                          style: TextStyle(
                            fontSize: 28 * fontProvider.fontScale,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5D4037),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '이 크기로 앱의 모든 글씨가\n표시됩니다.',
                          style: TextStyle(
                            fontSize: 18 * fontProvider.fontScale,
                            color: const Color(0xFF8D6E63),
                            height: 1.4,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // 글씨 크기 옵션들
              Consumer<FontSizeProvider>(
                builder: (context, fontProvider, child) {
                  return Column(
                    children: FontSizeOption.values.map((option) {
                      final isSelected =
                          fontProvider.currentFontSize == option;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FontSizeOptionCard(
                          option: option,
                          isSelected: isSelected,
                          onTap: () {
                            fontProvider.setFontSize(option);
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 24),

              // 저장 버튼
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('글씨 크기를 저장했어요'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  Future.delayed(const Duration(milliseconds: 800), () {
                    Navigator.pop(context);
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9800).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    '이 글씨 크기로 사용할게요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FontSizeOptionCard extends StatelessWidget {
  final FontSizeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _FontSizeOptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF9800) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFFFF9800).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            // 라디오 버튼
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? const Color(0xFFFF9800) : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // 옵션 텍스트
            Expanded(
              child: Text(
                option.label,
                style: TextStyle(
                  fontSize: 20 * option.scale,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF5D4037)
                      : const Color(0xFF8D6E63),
                ),
              ),
            ),

            // 배율 표시
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFB74D).withOpacity(0.2)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(option.scale * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFFFF9800)
                      : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}