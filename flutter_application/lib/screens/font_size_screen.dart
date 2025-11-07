import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../font_size_provider.dart';

class FontSizeScreen extends StatelessWidget {
  const FontSizeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 상단 그라디언트 헤더
          Container(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text(
                    '뒤로가기',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '글씨 크기',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              ],
            ),
          ),

          Expanded(
            child: Container(
              color: const Color(0xFFF5F5F5),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // 미리보기 카드
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 4,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        child: Consumer<FontSizeProvider>(
                          builder: (context, fontProvider, child) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '미리보기',
                                  style: TextStyle(
                                    fontSize: 16 * fontProvider.fontScale,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '말동이와 함께\n대화해요',
                                  style: TextStyle(
                                    fontSize: 28 * fontProvider.fontScale,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '이 크기로 앱의 모든 글씨가\n표시됩니다.',
                                  style: TextStyle(
                                    fontSize: 18 * fontProvider.fontScale,
                                    color: Colors.grey[700],
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
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

                    // ⭐ 여기부터 새로 추가된 "글씨 크기 등록" 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          // 이미 선택 시점에 setFontSize로 저장까지 되니까
                          // 여기서는 그냥 안내 + 돌아가기 정도만 해줘도 됨.
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('글씨 크기를 저장했어요.'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          Future.delayed(const Duration(milliseconds: 800), () {
                            Navigator.pop(context); // 설정 화면으로 돌아가기
                          });
                        },
                        child: const Text(
                          '이 글씨 크기로 사용할게요',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
            color: isSelected ? const Color(0xFFFFA726) : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFFFFA726).withOpacity(0.3),
                blurRadius: 8,
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
                      isSelected ? const Color(0xFFFFA726) : Colors.grey[400]!,
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
                          color: Color(0xFFFFA726),
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
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.black87 : Colors.grey[700],
                ),
              ),
            ),

            // 배율 표시
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFA726).withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(option.scale * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFFFFA726)
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
