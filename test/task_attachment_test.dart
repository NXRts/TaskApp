import 'package:flutter_test/flutter_test.dart';
import 'package:taskapp/models/task.dart';
import 'package:taskapp/services/task_attachment_service.dart';

void main() {
  group('TaskAttachmentService Unit Tests', () {
    test('getAttachmentType correctly detects images, pdf, and web links', () {
      expect(
        TaskAttachmentService.getAttachmentType('https://drive.google.com/file/d/123'),
        AttachmentType.link,
      );
      expect(
        TaskAttachmentService.getAttachmentType('http://lms.kampus.ac.id/assignment/1'),
        AttachmentType.link,
      );
      expect(
        TaskAttachmentService.getAttachmentType('/storage/app/task_attachments/papan_tulis.jpg'),
        AttachmentType.image,
      );
      expect(
        TaskAttachmentService.getAttachmentType('catatan.PNG'),
        AttachmentType.image,
      );
      expect(
        TaskAttachmentService.getAttachmentType('/path/to/diagram.webp'),
        AttachmentType.image,
      );
      expect(
        TaskAttachmentService.getAttachmentType('/path/to/soal_uas.pdf'),
        AttachmentType.pdf,
      );
      expect(
        TaskAttachmentService.getAttachmentType('SOAL_TUGAS.PDF'),
        AttachmentType.pdf,
      );
      expect(
        TaskAttachmentService.getAttachmentType('/path/to/makalah.docx'),
        AttachmentType.file,
      );
    });

    test('isLocalFile distinguishes local paths from web URLs', () {
      expect(TaskAttachmentService.isLocalFile('https://example.com'), isFalse);
      expect(TaskAttachmentService.isLocalFile('http://example.com'), isFalse);
      expect(TaskAttachmentService.isLocalFile('/data/user/0/taskapp/catatan.jpg'), isTrue);
      expect(TaskAttachmentService.isLocalFile('task_attachments/soal.pdf'), isTrue);
    });

    test('getDisplayName formats filenames and cleans system timestamp prefixes', () {
      expect(
        TaskAttachmentService.getDisplayName('/data/user/0/taskapp/task_attachments/att_1732019283741_catatan_kalkulus.jpg'),
        'catatan_kalkulus.jpg',
      );
      expect(
        TaskAttachmentService.getDisplayName('att_1700000000000_soal_praktikum_bab2.pdf'),
        'soal_praktikum_bab2.pdf',
      );
      expect(
        TaskAttachmentService.getDisplayName('/path/with/slashes/slide_dosen.pdf'),
        'slide_dosen.pdf',
      );
      expect(
        TaskAttachmentService.getDisplayName('https://drive.google.com/open?id=123'),
        'drive.google.com/open?id=123',
      );
    });

    test('TaskAttachmentInfo formats file sizes into human readable strings', () {
      const infoBytes = TaskAttachmentInfo(
        rawPath: 'test.jpg',
        type: AttachmentType.image,
        displayName: 'test.jpg',
        resolvedPath: 'test.jpg',
        sizeInBytes: 850,
      );
      expect(infoBytes.formattedSize, '850 B');

      const infoKb = TaskAttachmentInfo(
        rawPath: 'test.jpg',
        type: AttachmentType.image,
        displayName: 'test.jpg',
        resolvedPath: 'test.jpg',
        sizeInBytes: 256 * 1024,
      );
      expect(infoKb.formattedSize, '256.0 KB');

      const infoMb = TaskAttachmentInfo(
        rawPath: 'test.pdf',
        type: AttachmentType.pdf,
        displayName: 'test.pdf',
        resolvedPath: 'test.pdf',
        sizeInBytes: 3145728, // 3 MB
      );
      expect(infoMb.formattedSize, '3.0 MB');
    });

    test('TaskItem stores and copies multiple attachments correctly', () {
      final task = TaskItem(
        id: 'task-att-1',
        title: 'Tugas Praktikum Jaringan',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        attachments: [
          '/app_storage/task_attachments/att_1_topologi.png',
          '/app_storage/task_attachments/att_2_modul.pdf',
          'https://cisco.netacad.com',
        ],
      );

      expect(task.attachments.length, 3);
      expect(TaskAttachmentService.getAttachmentType(task.attachments[0]), AttachmentType.image);
      expect(TaskAttachmentService.getAttachmentType(task.attachments[1]), AttachmentType.pdf);
      expect(TaskAttachmentService.getAttachmentType(task.attachments[2]), AttachmentType.link);

      final updatedTask = task.copyWith(
        attachments: [
          ...task.attachments,
          '/app_storage/task_attachments/att_3_hasil_uji.jpg',
        ],
      );

      expect(updatedTask.attachments.length, 4);
      expect(TaskAttachmentService.getAttachmentType(updatedTask.attachments.last), AttachmentType.image);

      final map = updatedTask.toMap();
      final fromMap = TaskItem.fromMap(map);
      expect(fromMap.attachments.length, 4);
      expect(fromMap.attachments[1], '/app_storage/task_attachments/att_2_modul.pdf');
    });
  });
}
