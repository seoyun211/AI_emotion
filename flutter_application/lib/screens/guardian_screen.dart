import 'package:flutter/material.dart';

class GuardianScreen extends StatefulWidget {
  const GuardianScreen({super.key});

  @override
  State<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends State<GuardianScreen> {
  List<Guardian> guardians = [];

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
                '보호자 수정',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '최대 3명까지 등록할 수 있어요',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF8D6E63),
                ),
              ),
              const SizedBox(height: 40),

              // 보호자 목록
              if (guardians.isNotEmpty) ...[
                ...guardians.asMap().entries.map((entry) {
                  int index = entry.key;
                  Guardian guardian = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _GuardianCard(
                      guardian: guardian,
                      index: index,
                      onEdit: () => _editGuardian(index),
                      onDelete: () => _deleteGuardian(index),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
              ],

              // 보호자 추가 버튼
              if (guardians.length < 3)
                _AddGuardianButton(
                  onTap: _addGuardian,
                ),

              if (guardians.length >= 3)
                Container(
                  padding: const EdgeInsets.all(20),
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB74D).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Color(0xFFFF9800),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '최대 3명까지 등록할 수 있어요',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF5D4037),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _addGuardian() {
    if (guardians.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('보호자는 최대 3명까지 등록할 수 있어요')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GuardianForm(
        onSave: (guardian) {
          setState(() {
            guardians.add(guardian);
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('보호자를 추가했어요')),
          );
        },
      ),
    );
  }

  void _editGuardian(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GuardianForm(
        guardian: guardians[index],
        onSave: (guardian) {
          setState(() {
            guardians[index] = guardian;
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('보호자 정보를 수정했어요')),
          );
        },
      ),
    );
  }

  void _deleteGuardian(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '보호자 삭제',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
          ),
        ),
        content: const Text(
          '이 보호자를 삭제하시겠어요?',
          style: TextStyle(color: Color(0xFF5D4037)),
        ),
        backgroundColor: const Color(0xFFFFF8F0),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '취소',
              style: TextStyle(color: Color(0xFF8D6E63)),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                guardians.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('보호자를 삭제했어요')),
              );
            },
            child: const Text(
              '삭제',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Guardian {
  final String name;
  final String relationship;
  final String phoneNumber;

  Guardian({
    required this.name,
    required this.relationship,
    required this.phoneNumber,
  });
}

class _GuardianCard extends StatelessWidget {
  final Guardian guardian;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GuardianCard({
    required this.guardian,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          guardian.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB74D).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            guardian.relationship,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFFF9800),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 16,
                          color: Color(0xFF8D6E63),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          guardian.phoneNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8D6E63),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit,
                    size: 18,
                    color: Color(0xFFFF9800),
                  ),
                  label: const Text(
                    '수정',
                    style: TextStyle(color: Color(0xFFFF9800)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Color(0xFFFF9800)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  label: const Text(
                    '삭제',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddGuardianButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddGuardianButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFF9800),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF9800).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '보호자 추가',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '보호자 연락처를 추가해주세요',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF8D6E63),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuardianForm extends StatefulWidget {
  final Guardian? guardian;
  final Function(Guardian) onSave;

  const _GuardianForm({
    this.guardian,
    required this.onSave,
  });

  @override
  State<_GuardianForm> createState() => _GuardianFormState();
}

class _GuardianFormState extends State<_GuardianForm> {
  late TextEditingController _nameController;
  late TextEditingController _relationshipController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.guardian?.name ?? '');
    _relationshipController =
        TextEditingController(text: widget.guardian?.relationship ?? '');
    _phoneController =
        TextEditingController(text: widget.guardian?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8F0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  widget.guardian == null ? '보호자 추가' : '보호자 수정',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '보호자 정보를 입력해주세요',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF8D6E63),
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              controller: _nameController,
              label: '이름',
              hint: '홍길동',
              icon: Icons.person,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _relationshipController,
              label: '관계',
              hint: '아버지, 어머니, 자녀 등',
              icon: Icons.family_restroom,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _phoneController,
              label: '전화번호',
              hint: '010-1234-5678',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () {
                if (_nameController.text.isEmpty ||
                    _relationshipController.text.isEmpty ||
                    _phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('모든 항목을 입력해주세요')),
                  );
                  return;
                }

                widget.onSave(
                  Guardian(
                    name: _nameController.text,
                    relationship: _relationshipController.text,
                    phoneNumber: _phoneController.text,
                  ),
                );
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
                child: Text(
                  widget.guardian == null ? '추가하기' : '수정하기',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5D4037),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFFF9800),
                width: 2,
              ),
            ),
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}