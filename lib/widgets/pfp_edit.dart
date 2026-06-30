import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/organizer_provider.dart';

class EditProfilePicture extends ConsumerStatefulWidget {
  final bool isOrganizer;
  const EditProfilePicture({super.key, this.isOrganizer = false});

  @override
  ConsumerState<EditProfilePicture> createState() => _EditProfilePictureState();
}

class _EditProfilePictureState extends ConsumerState<EditProfilePicture> {
  File? _localFile;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.isOrganizer
        ? ref.watch(myOrganizerProvider).value?.imageUrl
        : ref.watch(userDocProvider).value?.imageUrl;

    final primaryColor = Theme.of(context).primaryColor;

    return Center(
      child: Stack(
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: (imageUrl != null && imageUrl.isNotEmpty) || _localFile != null
                  ? Colors.white
                  : primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: ClipOval(
              child: _localFile != null
                  ? Image.file(_localFile!, fit: BoxFit.cover)
                  : (imageUrl != null && imageUrl.isNotEmpty)
                      ? CachedNetworkImage(
                          key: ValueKey(imageUrl), // Forces a clean swap
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          // Shows white while loading
                          placeholder: (context, url) =>
                              Container(color: Colors.white),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        )
                      : Center(
                          child: Icon(
                            widget.isOrganizer ? Icons.store : Icons.person,
                            size: 80,
                            color: primaryColor,
                          ),
                        ),
            ),
          ),

          // Spinner overlay only appears during the actual upload
          if (_isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.7,
                  ), // Whiten the screen while uploading
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),

          Positioned(
            bottom: 0,
            right: 5,
            child: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              radius: 18,
              child: IconButton(
                onPressed: _pickAndUploadImage,
                icon: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);

      final oldUrl = widget.isOrganizer
          ? ref.read(myOrganizerProvider).value?.imageUrl
          : ref.read(userDocProvider).value?.imageUrl;

      setState(() {
        _localFile = file;
        _isUploading = true;
      });

      try {
        if (widget.isOrganizer) {
          await ref
              .read(organizerStatusProvider.notifier)
              .uploadOrganizerPhoto(file);
        } else {
          await ref.read(authServiceProvider).updateProfileImage(file);
        }

        // 1. Evict the old cache so it's gone
        if (oldUrl != null) {
          await CachedNetworkImage.evictFromCache(oldUrl);
        }

        // 2. WAIT for the Provider to actually change.
        // We stay in this 'try' block while the local file is still showing.
        // We wait until the watch(imageUrl) produces a DIFFERENT string than oldUrl.
        int attempts = 0;
        while (attempts < 10) {
          final currentUrl = widget.isOrganizer
              ? ref.read(myOrganizerProvider).value?.imageUrl
              : ref.read(userDocProvider).value?.imageUrl;

          if (currentUrl != oldUrl) break; // New URL has arrived!

          await Future.delayed(const Duration(milliseconds: 500));
          attempts++;
        }
      } catch (e) {
        // error handling...
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
            _localFile = null; // ONLY now do we reveal the network image
          });
        }
      }
    }
  }
}
