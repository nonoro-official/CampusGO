import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/event_service.dart';

class DeleteEventScreen extends ConsumerStatefulWidget {
  final String eventId;
  const DeleteEventScreen({super.key, required this.eventId});

  @override
  ConsumerState<DeleteEventScreen> createState() => _DeleteEventScreenState();
}

class _DeleteEventScreenState extends ConsumerState<DeleteEventScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    setState(() => _isLoading = true);
    
    final eventService = ref.read(eventServiceProvider);
    final isPasswordCorrect =  await eventService.verifyPassword(_passwordController.text);

    if (isPasswordCorrect) {
      await eventService.deleteEvent(widget.eventId);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Incorrect password. Action cancelled."))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Confirm Deletion"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("This action cannot be undone. Please verify your account password  to proceed."),
          const SizedBox(height: 15),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Password",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _isLoading ? null : _handleDelete,
          child: _isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("Delete Permanently", style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }
}