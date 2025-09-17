import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../config/global_color.dart';
import '../../model/notification_draft.dart';

class NotificationComposeDialog extends StatefulWidget {
  const NotificationComposeDialog({super.key, required this.isDark});

  final bool isDark;

  @override
  State<NotificationComposeDialog> createState() =>
      _NotificationComposeDialogState();
}

class _NotificationComposeDialogState extends State<NotificationComposeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late final TextEditingController _linkCtrl;
  late final TextEditingController _targetCtrl;

  NotificationAttachment? _attachment;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _bodyCtrl = TextEditingController();
    _linkCtrl = TextEditingController();
    _targetCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _linkCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.first;
    setState(() {
      _attachment = NotificationAttachment(
        fileName: file.name,
        bytes: file.bytes,
        filePath: file.path,
        size: file.size,
      );
    });
  }

  void _removeAttachment() {
    setState(() {
      _attachment = null;
    });
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '';
    const units = ['B', 'KB', 'MB', 'GB'];
    double value = bytes.toDouble();
    int unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    return '${value.toStringAsFixed(unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final draft = NotificationDraft(
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      link: _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),
      targetVersion:
          _targetCtrl.text.trim().isEmpty ? null : _targetCtrl.text.trim(),
      attachment: _attachment,
    );

    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final dialogColor = isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg;
    final textColor = isDark ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText;
    final accent = GlobalColors.accentByIsDark(isDark);

    return AlertDialog(
      backgroundColor: dialogColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          Icon(Icons.notifications_active_outlined, color: accent),
          const SizedBox(width: 8),
          const Text('Gửi thông báo mới'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  style: TextStyle(color: textColor),
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Tiêu đề không được để trống';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bodyCtrl,
                  style: TextStyle(color: textColor),
                  decoration: const InputDecoration(
                    labelText: 'Nội dung',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  minLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập nội dung thông báo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _linkCtrl,
                  style: TextStyle(color: textColor),
                  decoration: const InputDecoration(
                    labelText: 'Liên kết (tuỳ chọn)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _targetCtrl,
                  style: TextStyle(color: textColor),
                  decoration: const InputDecoration(
                    labelText: 'Target version (tuỳ chọn)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      side: BorderSide(color: accent.withOpacity(0.6)),
                    ),
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Đính kèm tệp (tuỳ chọn)'),
                  ),
                ),
                if (_attachment != null)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(isDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.insert_drive_file, color: accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _attachment!.fileName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_attachment!.size != null)
                                Text(
                                  _formatFileSize(_attachment!.size),
                                  style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Gỡ tệp',
                          onPressed: _removeAttachment,
                          icon: Icon(Icons.close, color: accent),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Huỷ'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
          ),
          child: const Text('Gửi thông báo'),
        ),
      ],
    );
  }
}
