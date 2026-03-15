import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManagerStudentListScreen extends StatefulWidget {
  const ManagerStudentListScreen({super.key});

  @override
  State<ManagerStudentListScreen> createState() =>
      _ManagerStudentListScreenState();
}

class _ManagerStudentListScreenState extends State<ManagerStudentListScreen> {
  final _searchController = TextEditingController();
  String _selectedClass = 'Tất cả Lớp';
  String _selectedKhoa = 'Tất cả Khoa';
  int _currentPage = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> _applyFilters(List<Map<String, String>> students) {
    final query = _searchController.text.trim().toLowerCase();
    return students.where((student) {
      final classOk =
          _selectedClass == 'Tất cả Lớp' || student['class'] == _selectedClass;
      final khoaOk =
          _selectedKhoa == 'Tất cả Khoa' || student['khoa'] == _selectedKhoa;
      final searchOk =
          query.isEmpty ||
          (student['name'] ?? '').toLowerCase().contains(query) ||
          (student['id'] ?? '').toLowerCase().contains(query);
      return classOk && khoaOk && searchOk;
    }).toList();
  }

  List<Map<String, String>> _mapSnapshotToStudents(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': (data['studentId'] as String?) ?? doc.id,
        'name':
            (data['fullName'] as String?) ??
            (data['name'] as String?) ??
            'Chưa có tên',
        'dob': (data['dob'] as String?) ?? '--/--/----',
        'class': (data['lop'] as String?) ?? '---',
        'khoa': (data['khoa'] as String?) ?? '---',
        'email': (data['email'] as String?) ?? '---',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F4),
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'QUẢN LÝ HỒ SƠ SINH VIÊN',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.menu, size: 28),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.account_circle_outlined, size: 30),
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1, color: Colors.black26),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 24),
                      label: const Text(
                        'Thêm sinh viên',
                        style: TextStyle(
                          fontSize: 34 / 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.upload_file_outlined),
                            label: const Text(
                              'Import Excel',
                              style: TextStyle(fontSize: 34 / 2),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.black54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(0),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.file_download_outlined),
                            label: const Text(
                              'Export danh sách',
                              style: TextStyle(fontSize: 34 / 2),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.black54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(0),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1, color: Colors.black45),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
                    child: const Text(
                      'TÌM KIẾM',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 32 / 2,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên hoặc MSSV',
                        hintStyle: const TextStyle(
                          color: Color(0xFF717A8C),
                          fontSize: 20,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 30,
                          color: Colors.black87,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          borderSide: const BorderSide(color: Colors.black54),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          borderSide: const BorderSide(color: Colors.black54),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            title: 'LỚP',
                            value: _selectedClass,
                            items: const [
                              'Tất cả Lớp',
                              'CNTT-01',
                              'CNTT-02',
                              'KT-01',
                            ],
                            onChanged: (val) => setState(
                              () => _selectedClass = val ?? 'Tất cả Lớp',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            title: 'KHOA',
                            value: _selectedKhoa,
                            items: const [
                              'Tất cả Khoa',
                              'Công nghệ thông tin',
                              'Kinh tế',
                              'Điện tử',
                            ],
                            onChanged: (val) => setState(
                              () => _selectedKhoa = val ?? 'Tất cả Khoa',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('student_profiles')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final allStudents = snapshot.hasData
                            ? _mapSnapshotToStudents(snapshot.data!)
                            : <Map<String, String>>[];
                        final students = _applyFilters(allStudents);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'DANH SÁCH SINH VIÊN (${students.length})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 40 / 2,
                                  ),
                                ),
                                const Text(
                                  'Sắp xếp: Tên A-Z',
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.fromLTRB(0, 8, 0, 8),
                              child: Divider(height: 1, color: Colors.black38),
                            ),
                            if (snapshot.connectionState ==
                                ConnectionState.waiting)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (students.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text('Chưa có dữ liệu sinh viên'),
                                ),
                              )
                            else
                              Column(
                                children: students
                                    .map(
                                      (student) => _buildStudentCard(student),
                                    )
                                    .toList(),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _pageButton(icon: Icons.chevron_left, onTap: () {}),
                      const SizedBox(width: 8),
                      _pageNumber(1),
                      const SizedBox(width: 8),
                      _pageNumber(2),
                      const SizedBox(width: 8),
                      _pageNumber(3),
                      const SizedBox(width: 8),
                      _pageButton(icon: Icons.chevron_right, onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF4F4F4),
              border: Border(top: BorderSide(color: Colors.black45)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _BottomTab(icon: Icons.groups, label: 'HỒ SƠ', active: true),
                _BottomTab(icon: Icons.bookmark_border, label: 'LỚP HỌC'),
                _BottomTab(icon: Icons.settings, label: 'CÀI ĐẶT'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 32 / 2),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: const BorderSide(color: Colors.black54),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: const BorderSide(color: Colors.black54),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          icon: const Icon(Icons.expand_more),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 20)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildStudentCard(Map<String, String> student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black45),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MÃ SINH VIÊN',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.blueGrey.shade400,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    student['id']!,
                    style: const TextStyle(
                      fontSize: 40 / 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _iconSquare(Icons.edit, onTap: () {}),
                  const SizedBox(width: 8),
                  _iconSquare(Icons.delete_outline, onTap: () {}),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _infoCell('HỌ TÊN', student['name']!)),
              Expanded(child: _infoCell('NGÀY SINH', student['dob']!)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _infoCell('LỚP', student['class']!)),
              Expanded(child: _infoCell('EMAIL', student['email']!)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCell(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            color: Colors.blueGrey.shade400,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 36 / 2)),
      ],
    );
  }

  Widget _iconSquare(IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(border: Border.all(color: Colors.black54)),
        child: Icon(icon, size: 20),
      ),
    );
  }

  Widget _pageNumber(int page) {
    final active = _currentPage == page;
    return InkWell(
      onTap: () => setState(() => _currentPage = page),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Colors.black : Colors.white,
          border: Border.all(color: Colors.black54),
        ),
        child: Text(
          '$page',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _pageButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(border: Border.all(color: Colors.black54)),
        child: Icon(icon),
      ),
    );
  }
}

class _BottomTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _BottomTab({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.black : const Color(0xFFABABAB);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
