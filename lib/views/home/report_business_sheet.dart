import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';

class ReportBusinessSheet extends ConsumerStatefulWidget {
  final String businessId;
  final String businessName;

  const ReportBusinessSheet({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  ConsumerState<ReportBusinessSheet> createState() =>
      _ReportBusinessSheetState();
}

class _ReportBusinessSheetState extends ConsumerState<ReportBusinessSheet> {
  String selectedReason = "Fake Business";
  final descController = TextEditingController();
  bool loading = false;

  final reasons = [
    "Fake Business",
    "Scam / Fraud",
    "Inappropriate Products",
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
            "Report Business",
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

    await ref.read(reportBusinessProvider).submitReport(
          reporterId: user.uid,
          businessId: widget.businessId,
          businessName: widget.businessName,
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