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

  bool get _canViewClassSections =>
      _role == 'Giảng viên' || _role == 'Quản trị';
  bool get _canManageClassSections => _role == 'Quản trị';

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

  Future<Map<String, String>> _loadLecturerOptions() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Giảng viên')
        .get();

    final lecturers = <String, String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final email = (data['email'] as String?)?.trim();
      if (email == null || email.isEmpty) continue;
      final name = (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String).trim()
          : 'Chưa có tên';
      lecturers[email] = name;
    }

    final sortedEntries = lecturers.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    return {for (final entry in sortedEntries) entry.key: entry.value};
  }

  Future<List<String>> _loadSubjectOptions() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('subjects')
        .get();

    final subjects = <String>{};
    for (final doc in snapshot.docs) {
      final name = (doc.data()['name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) {
        subjects.add(name);
      }
    }

    final sorted = subjects.toList()..sort();
    return sorted;
  }

  Future<void> _showSubjectForm() async {
    if (!_canManageClassSections) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chỉ quản trị viên được tạo môn học.')),
        );
      }
      return;
    }

    final subjectNameController = TextEditingController();
    final subjectCodeController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm môn học'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectNameController,
                decoration: const InputDecoration(labelText: 'Tên môn học'),
              ),
              TextField(
                controller: subjectCodeController,
                decoration: const InputDecoration(
                  labelText: 'Mã môn học (không bắt buộc)',
                ),
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
      ),
    );

    if (saved != true) return;

    final subjectName = subjectNameController.text.trim();
    final subjectCode = subjectCodeController.text.trim();

    if (subjectName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tên môn học không được để trống.')),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('subjects').add({
        'name': subjectName,
        'code': subjectCode,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã thêm môn học.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể thêm môn học: $e')));
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _role = (args?['role'] as String?) ?? '';
    _ensureDefaultAdminUser();
  }

  Future<void> _showClassForm({
    DocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    if (!_canManageClassSections) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chỉ quản trị viên được tạo/sửa lớp học phần.'),
          ),
        );
      }
      return;
    }

    final data = doc?.data() ?? <String, dynamic>{};

    final results = await Future.wait([
      _loadFacultyAndClassOptions(),
      _loadLecturerOptions(),
      _loadSubjectOptions(),
    ]);

    final options = results[0] as Map<String, List<String>>;
    final lecturerMap = results[1] as Map<String, String>;
    final subjectOptions = results[2] as List<String>;
    if (!mounted) return;
    final facultyOptions = options['faculties'] ?? <String>[];
    final classOptions = options['classes'] ?? <String>[];
    final lecturerEmails = lecturerMap.keys.toList();

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

    if (lecturerEmails.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa có tài khoản giảng viên để gán lớp học phần.'),
          ),
        );
      }
      return;
    }

    if (subjectOptions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa có môn học. Vui lòng thêm môn học trước.'),
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

    String selectedSubject =
        (data['className'] as String?)?.trim() ?? subjectOptions.first;
    if (!subjectOptions.contains(selectedSubject)) {
      selectedSubject = subjectOptions.first;
    }

    String selectedLecturerEmail =
        (data['lecturerEmail'] as String?)?.trim() ?? lecturerEmails.first;
    if (!lecturerMap.containsKey(selectedLecturerEmail)) {
      final existingName = (data['lecturerName'] as String?)?.trim();
      if (selectedLecturerEmail.isNotEmpty) {
        lecturerMap[selectedLecturerEmail] = existingName?.isNotEmpty == true
            ? existingName!
            : 'Chưa có tên';
        lecturerEmails.add(selectedLecturerEmail);
        lecturerEmails.sort(
          (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
        );
      } else {
        selectedLecturerEmail = lecturerEmails.first;
      }
    }
    String selectedLecturerName =
        lecturerMap[selectedLecturerEmail] ?? 'Chưa có tên';
    final lecturerNameController = TextEditingController(
      text: selectedLecturerName,
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
                    DropdownButtonFormField<String>(
                      initialValue: selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'Tên môn học',
                      ),
                      items: subjectOptions
                          .map(
                            (subject) => DropdownMenuItem<String>(
                              value: subject,
                              child: Text(subject),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedSubject = value);
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: selectedLecturerEmail,
                      decoration: const InputDecoration(
                        labelText: 'Email giảng viên',
                      ),
                      items: lecturerEmails
                          .map(
                            (email) => DropdownMenuItem<String>(
                              value: email,
                              child: Text(email),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedLecturerEmail = value;
                          selectedLecturerName =
                              lecturerMap[selectedLecturerEmail] ??
                              'Chưa có tên';
                          lecturerNameController.text = selectedLecturerName;
                        });
                      },
                    ),
                    TextField(
                      controller: lecturerNameController,
                      readOnly: true,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Tên giảng viên',
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
    final className = selectedSubject.trim();
    final maxStudents = int.tryParse(maxStudentsController.text.trim()) ?? 0;
    final currentStudents =
        int.tryParse(currentStudentsController.text.trim()) ?? 0;

    if (classCode.isEmpty || className.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã lớp và tên môn học không được để trống.'),
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
      'lecturerName': selectedLecturerName,
      'lecturerEmail': selectedLecturerEmail,
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
    if (!_canManageClassSections) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chỉ quản trị viên được xóa lớp học phần.'),
          ),
        );
      }
      return;
    }

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
            Text('Môn học: ${d['className'] ?? ''}'),
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
    if (!_canViewClassSections) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lớp học phần')),
        body: const Center(
          child: Text('Chỉ giảng viên và quản trị viên được xem lớp học phần.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _canManageClassSections ? 'Quản lý lớp học phần' : 'Xem lớp học phần',
        ),
        actions: _canManageClassSections
            ? [
                IconButton(
                  onPressed: _showSubjectForm,
                  icon: const Icon(Icons.menu_book_outlined),
                  tooltip: 'Thêm môn học',
                ),
                IconButton(
                  onPressed: () => _showClassForm(),
                  icon: const Icon(Icons.add),
                  tooltip: 'Thêm lớp học phần',
                ),
              ]
            : null,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('classes').snapshots(),
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
                return (classCounts[code] ?? 0) > 0;
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
                                  if (_canManageClassSections)
                                    IconButton(
                                      onPressed: () => _showClassForm(doc: doc),
                                      icon: const Icon(Icons.edit),
                                      tooltip: 'Sửa lớp',
                                    ),
                                  if (_canManageClassSections)
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
      floatingActionButton: _canManageClassSections
          ? FloatingActionButton.extended(
              onPressed: () => _showClassForm(),
              label: const Text('Thêm lớp học phần'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }
}
