import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/reward_image_picker.dart';

class AddEventScreen extends ConsumerStatefulWidget {
  const AddEventScreen({super.key});

  @override
  ConsumerState<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends ConsumerState<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _floorController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  File? _selectedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _floorController.dispose();
    super.dispose();
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(currentUserProvider);
      final eventService = ref.read(eventServiceProvider);

      if (user?.organizerId == null) {
        setState(() => _isSubmitting = false);
        return;
      }

      final fullStartDate = _combineDateAndTime(_startDate, _startTime);
      final fullEndDate = _combineDateAndTime(_endDate, _endTime);

      if (fullEndDate.isBefore(fullStartDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("End time cannot be before start time")),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final newEvent = EventModel(
        id: '',
        name: _nameController.text,
        description: _descriptionController.text,
        date: fullStartDate,
        endDate: fullEndDate,
        location: _locationController.text,
        floor: _floorController.text.isNotEmpty ? _floorController.text : null,
        creatorId: user!.organizerId!,
        status: 'approved',
      );

      final eventId = await eventService.createEvent(newEvent);

      if (_selectedImage != null) {
        await eventService.uploadEventImage(eventId, _selectedImage!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Event created successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Event"),
        centerTitle: true,
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  RewardImagePicker(
                    onImagePicked: (file) =>
                        setState(() => _selectedImage = file),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Event Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.event),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location / Building',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _floorController,
                          decoration: const InputDecoration(
                            labelText: 'Floor/Room',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text("Event Schedule",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.surfaceContainerLow
                        : Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.outlineVariant
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text("Start Date & Time"),
                          subtitle: Text(
                              "${DateFormat('MMM dd, yyyy').format(_startDate)} at ${_startTime.format(context)}"),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime.now(),
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
                                    if (_combineDateAndTime(_endDate, _endTime)
                                        .isBefore(_combineDateAndTime(
                                            _startDate, _startTime))) {
                                      _endDate = _startDate;
                                      _endTime = _startTime;
                                    }
                                  });
                                }
                              }
                            }
                          },
                        ),
                        const Divider(height: 1),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).colorScheme.onPrimary
                                : Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _submitEvent,
                      child: const Text("Create Event",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
