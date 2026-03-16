import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  bool _didInit = false;
  String _role = '';
  String _email = '';

  bool get _canManageClasses => _role == 'Giảng viên' || _role == 'Quản trị';

  Future<void> _ensureDefaultAdminUser() async {
    await FirebaseFirestore.instance.collection('users').doc('ad min').set({
      'username': 'ad min',
      'email': 'ad min',
      'password': 'admin',
      'role': 'Quản trị',
      'name': 'Administrator',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, List<String>>> _loadFacultyAndClassOptions() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('student_profiles')
        .get();

    final faculties = <String>{};
    final classes = <String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final khoa = (data['khoa'] as String?)?.trim();
      final lop = (data['lop'] as String?)?.trim();
      if (khoa != null && khoa.isNotEmpty) faculties.add(khoa);
      if (lop != null && lop.isNotEmpty) classes.add(lop);
    }

    final sortedFaculties = faculties.toList()..sort();
    final sortedClasses = classes.toList()..sort();

    return {'faculties': sortedFaculties, 'classes': sortedClasses};
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _role = (args?['role'] as String?) ?? '';
    _email = (args?['email'] as String?) ?? '';
    _ensureDefaultAdminUser();
  }

  Future<void> _showClassForm({
    DocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final data = doc?.data() ?? <String, dynamic>{};

    final options = await _loadFacultyAndClassOptions();
    if (!mounted) return;
    final facultyOptions = options['faculties'] ?? <String>[];
    final classOptions = options['classes'] ?? <String>[];

    if (classOptions.isEmpty || facultyOptions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa có dữ liệu ngành/lớp từ sinh viên để chọn.'),
          ),
        );
      }
      return;
    }

    String selectedFaculty =
        (data['faculty'] as String?) ?? facultyOptions.first;
    if (!facultyOptions.contains(selectedFaculty)) {
      selectedFaculty = facultyOptions.first;
    }
    String selectedClass =
        (data['classCode'] as String?) ??
        (data['className'] as String?) ??
        classOptions.first;
    if (!classOptions.contains(selectedClass)) {
      selectedClass = classOptions.first;
    }

    final lecturerNameController = TextEditingController(
      text: (data['lecturerName'] as String?) ?? '',
    );
    final maxStudentsController = TextEditingController(
      text: ((data['maxStudents'] as num?) ?? 50).toString(),
    );
    final currentStudentsController = TextEditingController(
      text: ((data['currentStudents'] as num?) ?? 0).toString(),
    );
    final descriptionController = TextEditingController(
      text: (data['description'] as String?) ?? '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(doc == null ? 'Thêm lớp học' : 'Sửa lớp học'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedClass,
                      decoration: const InputDecoration(
                        labelText: 'Lớp (từ dữ liệu sinh viên)',
                      ),
                      items: classOptions
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedClass = value);
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: selectedFaculty,
                      decoration: const InputDecoration(
                        labelText: 'Ngành/Khoa (từ dữ liệu sinh viên)',
                      ),
                      items: facultyOptions
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedFaculty = value);
                      },
                    ),
                    TextField(
                      controller: lecturerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Giảng viên',
                      ),
                    ),
                    TextField(
                      controller: maxStudentsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sĩ số tối đa',
                      ),
                    ),
                    TextField(
                      controller: currentStudentsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sĩ số hiện tại',
                      ),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Mô tả'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;

    final classCode = selectedClass.trim();
    final className = selectedClass.trim();
    final maxStudents = int.tryParse(maxStudentsController.text.trim()) ?? 0;
    final currentStudents =
        int.tryParse(currentStudentsController.text.trim()) ?? 0;

    if (classCode.isEmpty || className.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã lớp và tên lớp không được để trống.'),
          ),
        );
      }
      return;
    }

    if (maxStudents <= 0 ||
        currentStudents < 0 ||
        currentStudents > maxStudents) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sĩ số không hợp lệ. Vui lòng kiểm tra lại.'),
          ),
        );
      }
      return;
    }

    final payload = <String, dynamic>{
      'classCode': classCode,
      'className': className,
      'faculty': selectedFaculty,
      'lecturerName': lecturerNameController.text.trim(),
      'lecturerEmail': _email,
      'maxStudents': maxStudents,
      'currentStudents': currentStudents,
      'description': descriptionController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _ensureDefaultAdminUser();
      if (doc == null) {
        payload['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('classes').add(payload);
      } else {
        await doc.reference.set(payload, SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              doc == null
                  ? 'Đã thêm lớp vào database.'
                  : 'Đã cập nhật lớp trong database.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể lưu lớp: $e')));
      }
    }
  }

  Future<void> _deleteClass(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lớp học'),
        content: const Text('Bạn có chắc muốn xóa lớp này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await doc.reference.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa lớp khỏi database.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Không thể xóa lớp: $e')));
        }
      }
    }
  }

  void _showClassInfo(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin lớp',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Text('Mã lớp: ${d['classCode'] ?? ''}'),
            Text('Tên lớp: ${d['className'] ?? ''}'),
            Text('Khoa: ${d['faculty'] ?? ''}'),
            Text('Giảng viên: ${d['lecturerName'] ?? ''}'),
            Text(
              'Sĩ số: ${d['currentStudents'] ?? 0}/${d['maxStudents'] ?? 0}',
            ),
            const SizedBox(height: 8),
            Text('Mô tả: ${d['description'] ?? ''}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_canManageClasses) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quản lý lớp học')),
        body: const Center(
          child: Text('Chỉ giảng viên và quản trị viên được quản lý lớp học.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý lớp học'),
        actions: [
          IconButton(
            onPressed: () => _showClassForm(),
            icon: const Icon(Icons.add),
            tooltip: 'Thêm lớp',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _role == 'Quản trị'
            ? FirebaseFirestore.instance.collection('classes').snapshots()
            : FirebaseFirestore.instance
                  .collection('classes')
                  .where('lecturerEmail', isEqualTo: _email)
                  .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final classDocs = snapshot.data?.docs ?? [];

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('student_profiles')
                .snapshots(),
            builder: (context, studentSnapshot) {
              if (studentSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final classCounts = <String, int>{};
              if (studentSnapshot.hasData) {
                for (final sDoc in studentSnapshot.data!.docs) {
                  final lop = (sDoc.data()['lop'] as String?)?.trim();
                  if (lop != null && lop.isNotEmpty) {
                    classCounts[lop] = (classCounts[lop] ?? 0) + 1;
                  }
                }
              }

              final docs = classDocs.where((doc) {
                final data = doc.data();
                final code = (data['classCode'] as String?)?.trim() ?? '';
                final name = (data['className'] as String?)?.trim() ?? '';
                return (classCounts[code] ?? 0) > 0 ||
                    (classCounts[name] ?? 0) > 0;
              }).toList();

              if (docs.isEmpty) {
                return const Center(
                  child: Text('Chưa có lớp nào có sinh viên đăng ký.'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final d = doc.data();
                  final code = (d['classCode'] as String?)?.trim() ?? '';
                  final name = (d['className'] as String?)?.trim() ?? '';
                  final current = classCounts[code] ?? classCounts[name] ?? 0;
                  final max = ((d['maxStudents'] as num?)?.toInt() ?? 1).clamp(
                    1,
                    1000000,
                  );
                  final ratio = (current / max).clamp(0.0, 1.0);

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                color: const Color(0xFFE7EFEA),
                                child: Text('${d['classCode'] ?? ''}'),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => _showClassInfo(doc),
                                    icon: const Icon(Icons.info_outline),
                                    tooltip: 'Thông tin lớp',
                                  ),
                                  IconButton(
                                    onPressed: () => _showClassForm(doc: doc),
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Sửa lớp',
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteClass(doc),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Xóa lớp',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${d['className'] ?? ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Khoa: ${d['faculty'] ?? ''}'),
                          Text('Giảng viên: ${d['lecturerName'] ?? ''}'),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(value: ratio),
                          const SizedBox(height: 6),
                          Text('Sĩ số hiện tại: $current/$max'),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClassForm(),
        label: const Text('Thêm lớp'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
