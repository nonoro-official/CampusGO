import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event.name);
    _descriptionController =
        TextEditingController(text: widget.event.description);
    _locationController = TextEditingController(text: widget.event.location);
    _startDate = widget.event.date;
    _endDate = widget.event.endDate;
    _startTime = TimeOfDay.fromDateTime(_startDate);
    _endTime = TimeOfDay.fromDateTime(_endDate);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _updateEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final eventService = ref.read(eventServiceProvider);

    final fullStartDate = _combineDateAndTime(_startDate, _startTime);
    final fullEndDate = _combineDateAndTime(_endDate, _endTime);

    if (fullEndDate.isBefore(fullStartDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End time cannot be before start time")),
      );
      return;
    }

    await eventService.updateEvent(widget.event.id, {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'date': fullStartDate,
      'endDate': fullEndDate,
      'location': _locationController.text,
      'status': 'approved', // Automatically approved for testing
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
              title: const Text("Start Date & Time"),
              subtitle: Text(
                  "${DateFormat('MMM dd, yyyy').format(_startDate)} at ${_startTime.format(context)}"),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  if (context.mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _startTime,
                    );
                    if (time != null) {
                      setState(() {
                        _startDate = date;
                        _startTime = time;
                      });
                    }
                  }
                }
              },
            ),
            ListTile(
              title: const Text("End Date & Time"),
              subtitle: Text(
                  "${DateFormat('MMM dd, yyyy').format(_endDate)} at ${_endTime.format(context)}"),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate,
                  firstDate: _startDate,
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  if (context.mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _endTime,
                    );
                    if (time != null) {
                      setState(() {
                        _endDate = date;
                        _endTime = time;
                      });
                    }
                  }
                }
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