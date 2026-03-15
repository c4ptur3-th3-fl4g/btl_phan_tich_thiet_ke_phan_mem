import 'package:flutter/material.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final _nameController = TextEditingController(text: 'Nguyễn Văn A');
  final _dobController = TextEditingController();
  final _idNumberController = TextEditingController(text: '00120300XXXX');
  final _emailController = TextEditingController(text: 'vi-du@email.edu.vn');
  final _addressController = TextEditingController();
  String? _selectedKhoa;
  String? _selectedLop;

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _idNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF3F3F3),
        foregroundColor: Colors.black,
        title: const Text(
          'Hồ sơ sinh viên',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDEDED),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFCACACA),
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 52,
                                  color: Color(0xFFACACAC),
                                ),
                              ),
                              Positioned(
                                right: -8,
                                bottom: -2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1F2227),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: IconButton(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.camera_alt,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Ảnh đại diện',
                            style: TextStyle(
                              fontSize: 44 / 2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'PNG, JPG • TỐI ĐA 5MB',
                            style: TextStyle(
                              fontSize: 18 / 2,
                              color: Color(0xFF9D9D9D),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('HỌ VÀ TÊN'),
                    _buildTextField(_nameController, hint: 'Nguyễn Văn A'),
                    const SizedBox(height: 14),
                    _buildLabel('NGÀY SINH'),
                    _buildTextField(
                      _dobController,
                      hint: 'DD/MM/YYYY',
                      suffix: const Icon(
                        Icons.calendar_month,
                        color: Color(0xFF9B9B9B),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildLabel('SỐ CMND/CCCD'),
                    _buildTextField(_idNumberController, hint: '00120300XXXX'),
                    const SizedBox(height: 18),
                    const Divider(color: Color(0xFFE1E1E1)),
                    const SizedBox(height: 18),
                    _buildLabel('ĐỊA CHỈ EMAIL'),
                    _buildTextField(
                      _emailController,
                      hint: 'vi-du@email.edu.vn',
                    ),
                    const SizedBox(height: 14),
                    _buildLabel('ĐỊA CHỈ THƯỜNG TRÚ'),
                    _buildTextField(
                      _addressController,
                      hint: 'Nhập địa chỉ đầy đủ...',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: Color(0xFFE1E1E1)),
                    const SizedBox(height: 18),
                    _buildLabel('KHOA'),
                    _buildDropdown(
                      value: _selectedKhoa,
                      hint: 'Chọn khoa đào tạo',
                      items: const [
                        'Công nghệ thông tin',
                        'Kinh tế',
                        'Điện tử',
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedKhoa = value),
                    ),
                    const SizedBox(height: 14),
                    _buildLabel('LỚP SINH HOẠT'),
                    _buildDropdown(
                      value: _selectedLop,
                      hint: 'Chọn lớp',
                      items: const ['CNTT-01', 'CNTT-02', 'KTPM-01'],
                      onChanged: (value) =>
                          setState(() => _selectedLop = value),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
              decoration: const BoxDecoration(
                color: Color(0xFFF3F3F3),
                border: Border(top: BorderSide(color: Color(0xFFE2E2E2))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.maybePop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Color(0xFFD0D0D0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          fontSize: 18 / 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã lưu hồ sơ sinh viên'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1C1C1E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Lưu hồ sơ',
                        style: TextStyle(
                          fontSize: 18 / 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF787878),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    required String hint,
    Widget? suffix,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF717A8C)),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF2F2F2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFD5D5D5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFD5D5D5)),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      hint: Text(hint, style: const TextStyle(color: Color(0xFF1A1A1A))),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF2F2F2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFD5D5D5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFD5D5D5)),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: onChanged,
      icon: const Icon(Icons.expand_more, color: Color(0xFF8E8E93)),
    );
  }
}
