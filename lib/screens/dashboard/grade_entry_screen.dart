import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GradeEntryScreen extends StatefulWidget {
  const GradeEntryScreen({super.key});

  @override
  State<GradeEntryScreen> createState() => _GradeEntryScreenState();
}

class _GradeEntryScreenState extends State<GradeEntryScreen> {
  bool _didInit = false;
  String _email = '';

  // Step 1: select class + subject
  String? _selectedLop;
  final _monHocController = TextEditingController();

  // Step 2: grade table data
  bool _showGradeTable = false;
  bool _loadingStudents = false;
  bool _saving = false;

  List<_StudentGradeRow> _rows = [];
  List<String> _classOptions = [];
  bool _loadingClasses = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _email = (args?['email'] as String?) ?? '';
    _loadClassOptions();
  }

  Future<void> _loadClassOptions() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('student_profiles')
          .get();
      final classes = <String>{};
      for (final doc in snap.docs) {
        final lop = (doc.data()['lop'] as String?)?.trim();
        if (lop != null && lop.isNotEmpty) classes.add(lop);
      }
      final sorted = classes.toList()..sort();
      if (mounted) {
        setState(() {
          _classOptions = sorted;
          _loadingClasses = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingClasses = false);
    }
  }

  Future<void> _loadStudentsForClass() async {
    final lop = _selectedLop;
    final monHoc = _monHocController.text.trim();

    if (lop == null || lop.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn lớp học.')));
      return;
    }
    if (monHoc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên môn học.')),
      );
      return;
    }

    setState(() => _loadingStudents = true);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('student_profiles')
          .where('lop', isEqualTo: lop)
          .get();

      // Load existing grades for this lop + monHoc if any
      final existingSnap = await FirebaseFirestore.instance
          .collection('grades')
          .where('lop', isEqualTo: lop)
          .where('monHoc', isEqualTo: monHoc)
          .get();

      final existingMap = <String, Map<String, dynamic>>{};
      for (final doc in existingSnap.docs) {
        final data = doc.data();
        existingMap[data['studentEmail'] as String? ?? ''] = data;
      }

      final rows = snap.docs.map((doc) {
        final data = doc.data();
        final email = (data['email'] as String?) ?? doc.id;
        final existing = existingMap[email];
        return _StudentGradeRow(
          docId: doc.id,
          studentEmail: email,
          studentId: (data['studentId'] as String?) ?? doc.id,
          studentName: (data['fullName'] as String?) ?? 'Chưa có tên',
          cc1: existing != null
              ? (existing['chuyenCan1'] as num?)?.toDouble() ?? 0.0
              : 0.0,
          cc2: existing != null
              ? (existing['chuyenCan2'] as num?)?.toDouble() ?? 0.0
              : 0.0,
          giuaKi: existing != null
              ? (existing['giuaKi'] as num?)?.toDouble() ?? 0.0
              : 0.0,
          cuoiKi: existing != null
              ? (existing['cuoiKi'] as num?)?.toDouble() ?? 0.0
              : 0.0,
        );
      }).toList();

      rows.sort((a, b) => a.studentName.compareTo(b.studentName));

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _showGradeTable = true;
        _loadingStudents = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingStudents = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải sinh viên: $e')));
      }
    }
  }

  Future<void> _saveAllGrades() async {
    final lop = _selectedLop ?? '';
    final monHoc = _monHocController.text.trim();
    if (lop.isEmpty || monHoc.isEmpty || _rows.isEmpty) return;

    setState(() => _saving = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final gradesCol = FirebaseFirestore.instance.collection('grades');

      for (final row in _rows) {
        // Use composite doc id: lop_monHoc_studentEmail
        final docId = '${lop}_${monHoc}_${row.studentEmail}'.replaceAll(
          ' ',
          '_',
        );
        final ref = gradesCol.doc(docId);
        batch.set(ref, {
          'studentEmail': row.studentEmail,
          'studentId': row.studentId,
          'studentName': row.studentName,
          'lop': lop,
          'monHoc': monHoc,
          'chuyenCan1': row.cc1,
          'chuyenCan2': row.cc2,
          'giuaKi': row.giuaKi,
          'cuoiKi': row.cuoiKi,
          'diemTB': row.diemTB,
          'lecturerEmail': _email,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();

      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu bảng điểm thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lưu thất bại: $e')));
      }
    }
  }

  @override
  void dispose() {
    _monHocController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
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
          'NHẬP ĐIỂM',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 1, color: Colors.black26),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Step 1: Select class + subject ---
                  const Text(
                    'THÔNG TIN MÔN HỌC',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'LỚP HỌC',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_loadingClasses)
                    const SizedBox(
                      height: 52,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedLop,
                      hint: const Text('Chọn lớp học'),
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
                      items: _classOptions
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedLop = val;
                          _showGradeTable = false;
                          _rows = [];
                        });
                      },
                    ),
                  const SizedBox(height: 14),
                  const Text(
                    'TÊN MÔN HỌC',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _monHocController,
                    decoration: InputDecoration(
                      hintText: 'VD: Lập trình di động',
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
                    onChanged: (_) {
                      if (_showGradeTable) {
                        setState(() {
                          _showGradeTable = false;
                          _rows = [];
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _loadingStudents ? null : _loadStudentsForClass,
                    icon: _loadingStudents
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.search),
                    label: const Text('Tải danh sách sinh viên'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),

                  // --- Step 2: Grade table ---
                  if (_showGradeTable) ...[
                    const SizedBox(height: 28),
                    const Divider(color: Colors.black38),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'BẢNG ĐIỂM (${_rows.length} sinh viên)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            border: Border.all(color: Colors.blue.shade200),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'TB = CC1×10% + CC2×10% + GK×30% + CK×50%',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_rows.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('Không có sinh viên trong lớp này.'),
                        ),
                      )
                    else
                      ..._rows.map((row) => _buildStudentGradeCard(row)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _saveAllGrades,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_saving ? 'Đang lưu...' : 'Lưu tất cả điểm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentGradeCard(_StudentGradeRow row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.studentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'MSSV: ${row.studentId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              _buildDiemTBBadge(row),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildScoreField(
                  label: 'Chuyên cần 1',
                  controller: row.cc1Controller,
                  onChanged: (v) {
                    row.cc1 = double.tryParse(v) ?? 0.0;
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildScoreField(
                  label: 'Chuyên cần 2',
                  controller: row.cc2Controller,
                  onChanged: (v) {
                    row.cc2 = double.tryParse(v) ?? 0.0;
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildScoreField(
                  label: 'Giữa kỳ',
                  controller: row.giuaKiController,
                  onChanged: (v) {
                    row.giuaKi = double.tryParse(v) ?? 0.0;
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildScoreField(
                  label: 'Cuối kỳ',
                  controller: row.cuoiKiController,
                  onChanged: (v) {
                    row.cuoiKi = double.tryParse(v) ?? 0.0;
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiemTBBadge(_StudentGradeRow row) {
    final tb = row.diemTB;
    Color color;
    if (tb >= 8.0) {
      color = Colors.green.shade600;
    } else if (tb >= 6.5) {
      color = Colors.blue.shade600;
    } else if (tb >= 5.0) {
      color = Colors.orange.shade700;
    } else {
      color = Colors.red.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            'Điểm TB',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            tb.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
          ],
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8F8F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: const BorderSide(color: Colors.black38),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: const BorderSide(color: Colors.black38),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: const BorderSide(color: Colors.black87, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }
}

class _StudentGradeRow {
  final String docId;
  final String studentEmail;
  final String studentId;
  final String studentName;

  double cc1;
  double cc2;
  double giuaKi;
  double cuoiKi;

  late final TextEditingController cc1Controller;
  late final TextEditingController cc2Controller;
  late final TextEditingController giuaKiController;
  late final TextEditingController cuoiKiController;

  _StudentGradeRow({
    required this.docId,
    required this.studentEmail,
    required this.studentId,
    required this.studentName,
    required this.cc1,
    required this.cc2,
    required this.giuaKi,
    required this.cuoiKi,
  }) {
    cc1Controller = TextEditingController(
      text: cc1 == 0.0 ? '' : cc1.toStringAsFixed(1),
    );
    cc2Controller = TextEditingController(
      text: cc2 == 0.0 ? '' : cc2.toStringAsFixed(1),
    );
    giuaKiController = TextEditingController(
      text: giuaKi == 0.0 ? '' : giuaKi.toStringAsFixed(1),
    );
    cuoiKiController = TextEditingController(
      text: cuoiKi == 0.0 ? '' : cuoiKi.toStringAsFixed(1),
    );
  }

  double get diemTB =>
      _clamp(cc1) * 0.1 +
      _clamp(cc2) * 0.1 +
      _clamp(giuaKi) * 0.3 +
      _clamp(cuoiKi) * 0.5;

  double _clamp(double v) => v.clamp(0.0, 10.0);

  void dispose() {
    cc1Controller.dispose();
    cc2Controller.dispose();
    giuaKiController.dispose();
    cuoiKiController.dispose();
  }
}
