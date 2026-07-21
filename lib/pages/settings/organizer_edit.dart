import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/modal.dart';
import '../../../widgets/pfp_edit.dart';
import '../../../models/organizer_model.dart';
import '../../../models/faq_model.dart';
import '../../../providers/organizer_provider.dart';

void editOrganizerProfile(
  BuildContext context,
  OrganizerModel organizer,
  WidgetRef ref,
) {
  final nameController = TextEditingController(text: organizer.organizerName);
  final emailController = TextEditingController(text: organizer.contactEmail);
  final contactController = TextEditingController(text: organizer.contactNumber);
  final descriptionController = TextEditingController(
    text: organizer.description ?? '',
  );

  // copy existing FAQs
  List<FAQModel> editedFaqs = List.from(organizer.faqs);

  ModalContainer.show(
    context: context,
    child: StatefulBuilder(
      builder: (context, setModalState) {
        bool isLoading = false;

        Future<void> handleSave() async {
          final name = nameController.text.trim();
          final email = emailController.text.trim();
          final contact = contactController.text.trim();
          final description = descriptionController.text.trim();

          // Validation Logic
          if (name.isEmpty) {
            _showError(context, "Organizer name is required");
            return;
          }
          if (!RegExp(r"^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+$").hasMatch(email)) {
            _showError(context, "Enter a valid email address");
            return;
          }
          if (contact.length < 8) {
            _showError(context, "Enter a valid contact number");
            return;
          }

          setModalState(() => isLoading = true);
          try {
            final Map<String, dynamic> data = {
              'organizerName': name,
              'contactEmail': email,
              'contactNumber': contact,
              'description': description,
              'faqs': editedFaqs.map((f) => f.toMap()).toList(),
            };


            await ref
                .read(organizerServiceProvider)
                .updateOrganizerData(organizerId: organizer.id, data: data);

            if (context.mounted) {
              Navigator.pop(context);
              _showSuccess(context, 'Organizer profile updated!');
            }
          } catch (e) {
            if (context.mounted) _showError(context, e.toString());
          } finally {
            if (context.mounted) setModalState(() => isLoading = false);
          }
        }

        void addFaq() {
          final qController = TextEditingController();
          final aController = TextEditingController();

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Add FAQ"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: qController,
                    decoration: const InputDecoration(labelText: "Question"),
                  ),
                  TextField(
                    controller: aController,
                    decoration: const InputDecoration(labelText: "Answer"),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (qController.text.isNotEmpty &&
                        aController.text.isNotEmpty) {
                      setModalState(() {
                        editedFaqs.add(
                          FAQModel(
                            question: qController.text,
                            answer: aController.text,
                          ),
                        );
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Edit Organizer Profile",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 20),
              const EditProfilePicture(isOrganizer: true),
              const SizedBox(height: 20),
              _buildTextField(nameController, "Organizer Name", context),
              const SizedBox(height: 10),
              _buildTextField(emailController, "Email", context),
              const SizedBox(height: 10),
              _buildTextField(contactController, "Phone", context),
              const SizedBox(height: 10),
              _buildTextField(
                descriptionController,
                "Description",
                context,
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // FAQ Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FAQ Section',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: addFaq,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Add FAQ"),
                  ),
                ],
              ),
              if (editedFaqs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("No FAQs added yet.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ...editedFaqs.asMap().entries.map((entry) {
                final index = entry.key;
                final faq = entry.value;
                return ListTile(
                  title: Text(faq.question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text(faq.answer, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () {
                      setModalState(() {
                        editedFaqs.removeAt(index);
                      });
                    },
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }),

              const SizedBox(height: 20),

              // Organizer hours editor
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Organizer Hours',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : handleSave,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Widget _buildTextField(
  TextEditingController controller,
  String label,
  BuildContext context, {
  TextInputType type = TextInputType.text,
  String? helper,
  int maxLines = 1,
}) {
  return TextField(
    controller: controller,
    keyboardType: type,
    maxLines: maxLines,
    style: Theme.of(context).textTheme.bodyMedium,
    decoration: InputDecoration(
      labelText: label,
      helperText: helper,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      border: const OutlineInputBorder(),
    ),
  );
}

// Helper methods for snackbars to keep code clean
void _showError(BuildContext context, String msg) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

void _showSuccess(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
