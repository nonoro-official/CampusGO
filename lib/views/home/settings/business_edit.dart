import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/categories.dart';
import '../widgets/modal.dart';
import '../widgets/pfp_edit.dart';
import '../../../models/business_model.dart';
import '../../../models/business_hours.dart';
import '../../../models/faq_model.dart';
import '../../../providers/business_provider.dart';

void editBusinessProfile(
  BuildContext context,
  BusinessModel business,
  WidgetRef ref,
) {
  final nameController = TextEditingController(text: business.businessName);
  final emailController = TextEditingController(text: business.contactEmail);
  final contactController = TextEditingController(text: business.contactNumber);
  final descriptionController = TextEditingController(
    text: business.description ?? '',
  );

  // mutable state for the modal
  String selectedCategory = shopCategories.any((c) => c.label == business.category)
      ? business.category!
      : shopCategories.first.label;

  // copy existing hours so we can modify (not final to allow updates)
  Map<String, BusinessHours> editedHours = Map.from(
    business.businessHours ?? {},
  );

  // copy existing FAQs
  List<FAQModel> editedFaqs = List.from(business.faqs);

  // bulk‑apply times
  TimeOfDay? allStart;
  TimeOfDay? allEnd;

  final List<String> weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

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
            _showError(context, "Business name is required");
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
              'businessName': name,
              'contactEmail': email,
              'contactNumber': contact,
              'description': description,
              'category': selectedCategory,
              'faqs': editedFaqs.map((f) => f.toMap()).toList(),
            };
            if (editedHours.isNotEmpty) {
              data['businessHours'] = editedHours.map(
                (k, v) => MapEntry(k, v.toMap()),
              );
            }

            await ref
                .read(businessServiceProvider)
                .updateBusinessData(businessId: business.id, data: data);

            if (context.mounted) {
              Navigator.pop(context);
              _showSuccess(context, 'Business profile updated!');
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
                  "Edit Business Profile",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 20),
              const EditProfilePicture(isBusiness: true),
              const SizedBox(height: 20),
              _buildTextField(nameController, "Business Name", context),
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
              const SizedBox(height: 10),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                style: Theme.of(context).textTheme.bodyMedium,
                initialValue: selectedCategory,
                items: shopCategories
                    .map((c) => DropdownMenuItem(value: c.label, child: Text(c.label)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setModalState(() => selectedCategory = v);
                },
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 10,
                  ),
                ),
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

              // Business hours editor
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Business Hours',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              // bulk controls
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      'All days:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime:
                              allStart ?? const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (t != null) setModalState(() => allStart = t);
                      },
                      child: Text(
                        allStart != null ? allStart!.format(context) : 'Start',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    Text(
                      ' - ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime:
                              allEnd ?? const TimeOfDay(hour: 17, minute: 0),
                        );
                        if (t != null) setModalState(() => allEnd = t);
                      },
                      child: Text(
                        allEnd != null ? allEnd!.format(context) : 'End',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: (allStart != null && allEnd != null)
                          ? () {
                              setModalState(() {
                                for (var day in weekdays) {
                                  editedHours[day] = BusinessHours(
                                    open: allStart!.hour * 100 + allStart!.minute,
                                    close: allEnd!.hour * 100 + allEnd!.minute,
                                  );
                                }
                              });
                            }
                          : null,
                      child: const Text('Apply'),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear all hours',
                      onPressed: editedHours.isNotEmpty
                          ? () {
                              setModalState(() => editedHours.clear());
                            }
                          : null,
                    ),
                  ],
                ),
              ),
              Column(
                children: weekdays.map((day) {
                  final bh = editedHours[day];
                  TimeOfDay? start = bh != null
                      ? TimeOfDay(hour: bh.open ~/ 100, minute: bh.open % 100)
                      : null;
                  TimeOfDay? end = bh != null
                      ? TimeOfDay(hour: bh.close ~/ 100, minute: bh.close % 100)
                      : null;
                  String startText = start != null
                      ? start.format(context)
                      : 'Set';
                  String endText = end != null ? end.format(context) : 'Set';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 90,
                            child: Text(
                              day,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime:
                                    start ?? TimeOfDay(hour: 9, minute: 0),
                              );
                              if (t != null) {
                                setModalState(() {
                                  final existing = editedHours[day];
                                  editedHours[day] = BusinessHours(
                                    open: t.hour * 100 + t.minute,
                                    close:
                                        existing?.close ??
                                        t.hour * 100 + t.minute,
                                  );
                                });
                              }
                            },
                            child: Text(
                              startText,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                  ),
                            ),
                          ),
                          Text(
                            ' - ',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Theme.of(context).primaryColor),
                          ),
                          TextButton(
                            onPressed: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime:
                                    end ?? TimeOfDay(hour: 17, minute: 0),
                              );
                              if (t != null) {
                                setModalState(() {
                                  final existing = editedHours[day];
                                  editedHours[day] = BusinessHours(
                                    open:
                                        existing?.open ?? t.hour * 100 + t.minute,
                                    close: t.hour * 100 + t.minute,
                                  );
                                });
                              }
                            },
                            child: Text(
                              endText,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                  ),
                            ),
                          ),
                          if (bh != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setModalState(() {
                                  editedHours.remove(day);
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
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
