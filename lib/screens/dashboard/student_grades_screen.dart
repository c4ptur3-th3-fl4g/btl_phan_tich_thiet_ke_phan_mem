import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentGradesScreen extends StatefulWidget {
  const StudentGradesScreen({super.key});

  @override
  State<StudentGradesScreen> createState() => _StudentGradesScreenState();
}

class _StudentGradesScreenState extends State<StudentGradesScreen> {
  bool _didInit = false;
  String _email = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _email = (args?['email'] as String?) ?? '';
  }

  String _xepLoai(double tb) {
    if (tb >= 9.0) return 'Xuất sắc';
    if (tb >= 8.0) return 'Giỏi';
    if (tb >= 7.0) return 'Khá';
    if (tb >= 5.0) return 'Trung bình';
    return 'Yếu';
  }

  Color _xepLoaiColor(double tb) {
    if (tb >= 8.0) return Colors.green.shade700;
    if (tb >= 7.0) return Colors.blue.shade700;
    if (tb >= 5.0) return Colors.orange.shade700;
    return Colors.red.shade700;
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
          'BẢNG ĐIỂM',
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
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('grades')
                  .where('studentEmail', isEqualTo: _email)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: Colors.black26,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Chưa có điểm nào được nhập.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                docs.sort((a, b) {
                  final aTime = a.data()['updatedAt'] as Timestamp?;
                  final bTime = b.data()['updatedAt'] as Timestamp?;
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

                // Calculate GPA summary
                final allTb = docs.map((doc) {
                  return (doc.data()['diemTB'] as num?)?.toDouble() ?? 0.0;
                }).toList();
                final avgGpa = allTb.isEmpty
                    ? 0.0
                    : allTb.reduce((a, b) => a + b) / allTb.length;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Summary card
                      _buildSummaryCard(avgGpa, docs.length),
                      const SizedBox(height: 20),
                      Text(
                        'CHI TIẾT ĐIỂM (${docs.length} môn)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...docs.map((doc) => _buildGradeCard(doc.data())),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double avgGpa, int subjectCount) {
    final color = _xepLoaiColor(avgGpa);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ĐIỂM TRUNG BÌNH TÍCH LŨY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  avgGpa.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  _xepLoai(avgGpa),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Số môn học',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
              Text(
                '$subjectCount',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradeCard(Map<String, dynamic> data) {
    final monHoc = (data['monHoc'] as String?) ?? 'Chưa rõ';
    final lop = (data['lop'] as String?) ?? '---';
    final cc1 = (data['chuyenCan1'] as num?)?.toDouble() ?? 0.0;
    final cc2 = (data['chuyenCan2'] as num?)?.toDouble() ?? 0.0;
    final giuaKi = (data['giuaKi'] as num?)?.toDouble() ?? 0.0;
    final cuoiKi = (data['cuoiKi'] as num?)?.toDouble() ?? 0.0;
    final diemTB = (data['diemTB'] as num?)?.toDouble() ?? 0.0;
    final color = _xepLoaiColor(diemTB);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monHoc,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Lớp: $lop',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    border: Border.all(color: color),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Điểm TB',
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        diemTB.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                      Text(
                        _xepLoai(diemTB),
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Grade detail grid
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildScoreCell(
                    label: 'Chuyên cần 1',
                    value: cc1,
                    weight: '×10%',
                  ),
                ),
                Expanded(
                  child: _buildScoreCell(
                    label: 'Chuyên cần 2',
                    value: cc2,
                    weight: '×10%',
                  ),
                ),
                Expanded(
                  child: _buildScoreCell(
                    label: 'Giữa kỳ',
                    value: giuaKi,
                    weight: '×30%',
                  ),
                ),
                Expanded(
                  child: _buildScoreCell(
                    label: 'Cuối kỳ',
                    value: cuoiKi,
                    weight: '×50%',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCell({
    required String label,
    required double value,
    required String weight,
  }) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.black45,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(1),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        Text(
          weight,
          style: const TextStyle(fontSize: 10, color: Colors.black38),
        ),
      ],
    );
  }
}
