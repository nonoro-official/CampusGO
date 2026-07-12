import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';

class ReportOrganizerSheet extends ConsumerStatefulWidget {
  final String organizerId;
  final String organizerName;

  const ReportOrganizerSheet({
    super.key,
    required this.organizerId,
    required this.organizerName,
  });

  @override
  ConsumerState<ReportOrganizerSheet> createState() =>
      _ReportOrganizerSheetState();
}

class _ReportOrganizerSheetState extends ConsumerState<ReportOrganizerSheet> {
  String selectedReason = "Fake Organizer";
  final descController = TextEditingController();
  bool loading = false;

  final reasons = [
    "Fake Organizer",
    "Scam / Fraud",
    "Inappropriate Rewards",
    "Harassment",
    "Other",
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Report Organizer",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          DropdownButtonFormField(
            initialValue: selectedReason,
            items: reasons
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (val) => setState(() => selectedReason = val!),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: descController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Additional details (optional)",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: loading ? null : _submit,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit Report"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);

    if (user == null) return;

    setState(() => loading = true);

    await ref.read(reportOrganizerProvider).submitReport(
          reporterId: user.uid,
          organizerId: widget.organizerId,
          organizerName: widget.organizerName,
          reason: selectedReason,
          description: descController.text.trim(),
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Report submitted")),
      );
    }
  }
}