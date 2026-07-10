import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';

class EditEventScreen extends ConsumerStatefulWidget {
  final EventModel event;
  const EditEventScreen({super.key, required this.event});

  @override
  ConsumerState<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends ConsumerState<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event.name);
    _descriptionController = TextEditingController(text: widget.event.description);
    _locationController = TextEditingController(text: widget.event.location);
    _startDate = widget.event.date;
    _endDate = widget.event.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _updateEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final eventService = ref.read(eventServiceProvider);

    await eventService.updateEvent(widget.event.id, {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'date': _startDate,
      'endDate': _endDate,
      'location': _locationController.text,
      'status': 'pending', // Resets to a pending for approval state when updated
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Event")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Event Name'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            ListTile(
              title: Text("Start Date: ${_startDate.toLocal()}".split(' ')[0]), 
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2030),
                );
                if (date != null) setState(() => _startDate = date);
              },
            ),
            ListTile(
              title: Text("End Date: ${_endDate.toLocal()}".split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate,
                  firstDate: _startDate,
                  lastDate: DateTime(2030),
                );
                if (date != null) setState(() => _endDate = date);
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _updateEvent,
              child: const Text("Save Changes"),
            )
          ],
        ),
      ),
    );
  }
}