import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/app_image.dart';
import '../../../data/models/inspection_model.dart';

class PartInspectionDialog extends StatefulWidget {
  final InspectionPartItem part;
  final Function(InspectionPartItem updated) onSave;
  final VoidCallback? onDelete;

  const PartInspectionDialog({
    super.key,
    required this.part,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<PartInspectionDialog> createState() => _PartInspectionDialogState();
}

class _PartInspectionDialogState extends State<PartInspectionDialog> {
  late final TextEditingController _partNameController;
  late final TextEditingController _conditionController;
  late final TextEditingController _damageDescController;
  late final TextEditingController _notesController;

  late List<String> _photoUrls;
  bool _hasDamage = false;
  bool _isUploading = false;

  final List<String> _quickSuggestions = [
    'Good',
    'Minor scratch',
    'Deep scratch',
    'Small dent',
    'Heavy dent',
    'Paint chipped',
    'Swirl marks',
    'No damage',
  ];

  @override
  void initState() {
    super.initState();
    _partNameController = TextEditingController(text: widget.part.partName);
    _conditionController = TextEditingController(text: widget.part.condition);
    _damageDescController = TextEditingController(text: widget.part.damageDescription ?? '');
    _notesController = TextEditingController(text: widget.part.notes ?? '');
    _photoUrls = List.from(widget.part.photoUrls);
    _hasDamage = widget.part.hasDamage;
  }

  void _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 80);
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      final businessId = AuthService.to.businessId;
      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last;
      final url = await StorageService.uploadFile(
        bytes: bytes,
        path: 'businesses/$businessId/inspections/parts/${const Uuid().v4()}.$ext',
      );
      if (url != null) {
        setState(() {
          _photoUrls.add(url);
          _hasDamage = true;
        });
        Get.snackbar('Photo Uploaded', 'Damage photo attached to part', backgroundColor: AppColors.success.withValues(alpha: 0.2));
      }
    } catch (e) {
      Get.snackbar('Upload Error', 'Failed to upload photo: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _save() {
    final updated = widget.part.copyWith(
      condition: _conditionController.text.trim().isNotEmpty ? _conditionController.text.trim() : 'Good',
      damageDescription: _damageDescController.text.trim().isNotEmpty ? _damageDescController.text.trim() : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      photoUrls: _photoUrls,
      hasDamage: _hasDamage || _damageDescController.text.trim().isNotEmpty,
    );
    widget.onSave(updated);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.build_circle_outlined, color: AppColors.primaryLight),
          const SizedBox(width: 8),
          Expanded(child: Text('Inspect Part: ${widget.part.partName}', maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Part Name
              if (widget.part.view == 'Custom') ...[
                TextFormField(
                  controller: _partNameController,
                  decoration: const InputDecoration(labelText: 'Part Name *'),
                ),
                const SizedBox(height: 14),
              ],

              // Condition: User types free text per Section 17 & 19
              TextFormField(
                controller: _conditionController,
                decoration: const InputDecoration(
                  labelText: 'Condition * (Type actual observed condition)',
                  hintText: 'e.g., Minor scratch on left side, Good, Small dent',
                  prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 8),

              // Quick suggestion chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _quickSuggestions.map((s) {
                  return ActionChip(
                    label: Text(s, style: const TextStyle(fontSize: 11)),
                    onPressed: () {
                      setState(() {
                        _conditionController.text = s;
                        if (s.toLowerCase().contains('scratch') || s.toLowerCase().contains('dent') || s.toLowerCase().contains('chip')) {
                          _hasDamage = true;
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Damage Toggle & Description
              CheckboxListTile(
                title: const Text('Mark as Damaged / Pre-existing Scratch or Dent', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                value: _hasDamage,
                activeColor: AppColors.error,
                onChanged: (val) => setState(() => _hasDamage = val ?? false),
                contentPadding: EdgeInsets.zero,
              ),
              if (_hasDamage) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _damageDescController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Damage Description',
                    hintText: 'Describe dent depth, scratch length, or paint peeling...',
                    prefixIcon: Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.error),
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Customer informed before service, etc...',
                  prefixIcon: Icon(Icons.notes_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              // Photos Section (Upload to Firebase Storage per Section 20)
              const Text('Inspection Photos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isUploading ? null : () => _pickPhoto(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 16),
                    label: const Text('Camera'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _isUploading ? null : () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: const Text('Gallery'),
                  ),
                  if (_isUploading) ...[
                    const SizedBox(width: 12),
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 6),
                    const Text('Uploading photo...', style: TextStyle(fontSize: 11)),
                  ],
                ],
              ),
              if (_photoUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _photoUrls.map((url) {
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        AppImage(
                          imagePath: url,
                          width: 72,
                          height: 72,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: AppColors.error, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(() => _photoUrls.remove(url)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (widget.onDelete != null)
          TextButton(
            onPressed: () {
              widget.onDelete!();
              Get.back();
            },
            child: const Text('Remove Part', style: TextStyle(color: AppColors.error)),
          ),
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save Part Condition')),
      ],
    );
  }
}
