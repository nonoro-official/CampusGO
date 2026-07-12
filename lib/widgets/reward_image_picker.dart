import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RewardImagePicker extends StatefulWidget {
  final String? initialImageUrl;
  final Function(File) onImagePicked;

  const RewardImagePicker({
    super.key,
    this.initialImageUrl,
    required this.onImagePicked,
  });

  @override
  State<RewardImagePicker> createState() => _RewardImagePickerState();
}

class _RewardImagePickerState extends State<RewardImagePicker> {
  File? _selectedFile;

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      setState(() => _selectedFile = file);
      widget.onImagePicked(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _selectedFile != null
              ? Image.file(_selectedFile!, fit: BoxFit.cover)
              : (widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: widget.initialImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text(
          "Add Reward Photo",
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      ],
    );
  }
}
