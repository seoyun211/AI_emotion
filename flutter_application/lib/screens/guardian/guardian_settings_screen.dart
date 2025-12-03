import 'package:flutter/material.dart';
import 'guardian_analysis_screen.dart';

class GuardianSettingsScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onLogout;
  final int guardianUserId;      // ✅ 추가
  final String accessToken;      // ✅ 추가

  const GuardianSettingsScreen({
    super.key,
    required this.onBack,
    required this.onLogout,
    required this.guardianUserId,    // ✅ 추가
    required this.accessToken,       // ✅ 추가
  });

  @override
  State<GuardianSettingsScreen> createState() => _GuardianSettingsScreenState();
}

class _GuardianSettingsScreenState extends State<GuardianSettingsScreen> {
  bool _pushNotificationEnabled = true;
  String _selectedFontSize = '기본';
  String _reportFrequency = '매일';

  int _selectedIndex = 2; // ✅ 설정 탭 선택 상태

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5D4037)),
          onPressed: widget.onBack,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ✅ 기존 설정 내용은 그대로, 스크롤 영역으로 Expanded 안에 넣음
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF66BB6A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: Color(0xFF66BB6A),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '설정',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '보호자 앱 설정을 관리해요',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF8D6E63),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 알림 설정
                    _buildSectionCard(
                      title: '알림 설정',
                      icon: Icons.notifications_active,
                      iconColor: const Color(0xFFFFB74D),
                      children: [
                        _buildSwitchTile(
                          title: '푸시 알림',
                          subtitle: '중요한 알림을 받아요',
                          value: _pushNotificationEnabled,
                          onChanged: (value) {
                            setState(() {
                              _pushNotificationEnabled = value;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? '알림이 활성화되었어요'
                                      : '알림이 비활성화되었어요',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 사용자 정보 관리
                    _buildSectionCard(
                      title: '사용자 정보 관리',
                      icon: Icons.person,
                      iconColor: const Color(0xFF66BB6A),
                      children: [
                        _buildMenuTile(
                          title: '비밀번호 변경',
                          icon: Icons.lock,
                          onTap: () => _showPasswordChangeDialog(),
                        ),
                        Divider(height: 1, color: Colors.grey[200]),
                        _buildMenuTile(
                          title: '프로필 수정',
                          icon: Icons.edit,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('프로필 수정 화면')),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 접근성 설정
                    _buildSectionCard(
                      title: '접근성 설정',
                      icon: Icons.accessibility_new,
                      iconColor: const Color(0xFF64B5F6),
                      children: [
                        _buildFontSizeSelector(),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 요약 발송 설정
                    _buildSectionCard(
                      title: '요약 발송 설정',
                      icon: Icons.email,
                      iconColor: const Color(0xFF9575CD),
                      children: [
                        _buildMenuTile(
                          title: '리포트 받기',
                          subtitle: '어르신의 감정 리포트를 이메일로 받아요',
                          icon: Icons.description,
                          trailing: Switch(
                            value: true,
                            onChanged: (value) {},
                            activeColor: const Color(0xFF66BB6A),
                          ),
                          onTap: null,
                        ),
                        Divider(height: 1, color: Colors.grey[200]),
                        _buildReportFrequencySelector(),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 앱 정보 / 피드백
                    _buildSectionCard(
                      title: '앱 정보 / 피드백',
                      icon: Icons.info,
                      iconColor: const Color(0xFFEF5350),
                      children: [
                        _buildMenuTile(
                          title: '버전 정보',
                          subtitle: 'v1.0.0',
                          icon: Icons.app_settings_alt,
                          onTap: () {},
                        ),
                        Divider(height: 1, color: Colors.grey[200]),
                        _buildMenuTile(
                          title: '개발팀 문의',
                          subtitle: 'support@maldong.com',
                          icon: Icons.contact_mail,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('메일 앱이 열립니다'),
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: Colors.grey[200]),
                        _buildMenuTile(
                          title: '피드백 보내기',
                          icon: Icons.feedback,
                          onTap: () => _showFeedbackDialog(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // 로그아웃 버튼
                    GestureDetector(
                      onTap: () {
                        _showLogoutDialog();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.logout, color: Colors.white, size: 24),
                            SizedBox(width: 8),
                            Text(
                              '로그아웃',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ 하단 네비게이션 추가
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
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
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required String title,
    String? subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: const Color(0xFF66BB6A)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: Colors.grey[400],
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5D4037),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF66BB6A),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeSelector() {
    final fontSizes = ['작은', '기본', '크게', '아주 크게'];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '글자 크기',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 16),
          ...fontSizes.map((size) {
            final isSelected = _selectedFontSize == size;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFontSize = size;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('글자 크기: $size')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF66BB6A).withOpacity(0.1)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF66BB6A)
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? const Color(0xFF66BB6A)
                            : Colors.grey[400],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        size,
                        style: TextStyle(
                          fontSize: _getFontSize(size),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: const Color(0xFF5D4037),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildReportFrequencySelector() {
    final frequencies = ['매일', '매주', '매월'];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '리포트 빈도',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: frequencies.map((freq) {
              final isSelected = _reportFrequency == freq;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _reportFrequency = freq;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('리포트 빈도: $freq')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF66BB6A)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        freq,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  double _getFontSize(String size) {
    switch (size) {
      case '작은':
        return 14;
      case '기본':
        return 16;
      case '크게':
        return 18;
      case '아주 크게':
        return 20;
      default:
        return 16;
    }
  }

  void _showPasswordChangeDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: const Color(0xFFFFF8F0),
        title: const Text(
          '비밀번호 변경',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPasswordField('현재 비밀번호', currentPasswordController),
            const SizedBox(height: 16),
            _buildPasswordField('새 비밀번호', newPasswordController),
            const SizedBox(height: 16),
            _buildPasswordField('비밀번호 확인', confirmPasswordController),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '취소',
              style: TextStyle(color: Color(0xFF8D6E63)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 비밀번호 변경 로직
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('비밀번호가 변경되었어요')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF66BB6A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: const Color(0xFFFFF8F0),
        title: Row(
          children: const [
            Icon(Icons.feedback, color: Color(0xFF66BB6A)),
            SizedBox(width: 12),
            Text(
              '피드백 보내기',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '개선하고 싶은 점이나 건의사항을 알려주세요',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8D6E63),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '피드백을 입력해주세요',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '취소',
              style: TextStyle(color: Color(0xFF8D6E63)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 피드백 전송 로직
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('피드백을 보내주셔서 감사합니다! 💚'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF66BB6A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('보내기'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: const Color(0xFFFFF8F0),
        title: const Text(
          '로그아웃',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
          ),
        ),
        content: const Text(
          '정말 로그아웃 하시겠어요?',
          style: TextStyle(color: Color(0xFF5D4037)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '취소',
              style: TextStyle(color: Color(0xFF8D6E63)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF66BB6A),
            width: 2,
          ),
        ),
      ),
    );
  }

  // ✅ 하단 네비게이션 바 (수정됨)
  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 홈
          _buildNavItem(
            icon: Icons.home,
            label: '홈',
            isSelected: _selectedIndex == 0,
            onTap: () {
              setState(() => _selectedIndex = 0);
              // ✅ Navigator.pop으로 이전 화면(GuardianHomeScreen)으로 돌아가기
              Navigator.pop(context);
            },
          ),
          // 상세 분석
          _buildNavItem(
            icon: Icons.insert_chart,
            label: '상세 분석',
            isSelected: _selectedIndex == 1,
            onTap: () {
              setState(() => _selectedIndex = 1);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>  GuardianAnalysisScreen(
                    guardianUserId: widget.guardianUserId,        
                    accessToken: widget.accessToken, 
                  ),
                ),
              );
            },
          ),
          // 설정 (현재 화면)
          _buildNavItem(
            icon: Icons.settings,
            label: '설정',
            isSelected: _selectedIndex == 2,
            onTap: () {
              setState(() => _selectedIndex = 2);
              // 이미 설정 화면이므로 아무 동작 X
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 28,
            color: isSelected ? const Color(0xFF66BB6A) : Colors.grey[400],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isSelected ? const Color(0xFF66BB6A) : Colors.grey[400],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}