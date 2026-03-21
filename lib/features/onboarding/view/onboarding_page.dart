import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';
import '../../../providers/profile_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _nameController = TextEditingController();
  final _placeController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _nameController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final name = _nameController.text.trim();
    final place = _placeController.text.trim();

    if (name.isEmpty || place.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写完整的必填信息')),
      );
      return;
    }

    final profile = Profile(
      id: const Uuid().v4(),
      displayName: name,
      birthDateTime: _selectedDate!,
      birthPlaceName: place,
      createdAt: DateTime.now(),
    );

    ref.read(profileProvider.notifier).saveProfile(profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '欢迎来到 AstroJournal',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '请留下您的出生印记，开启星空之旅',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '如何称呼您',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    if (!mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null && mounted) {
                      setState(() {
                        _selectedDate = DateTime(
                          date.year, date.month, date.day, time.hour, time.minute
                        );
                      });
                    }
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '出生时间',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _selectedDate != null 
                        ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')} ${_selectedDate!.hour.toString().padLeft(2, '0')}:${_selectedDate!.minute.toString().padLeft(2, '0')}'
                        : '选择出生日期和时间',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _placeController,
                decoration: const InputDecoration(
                  labelText: '出生城市',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  onPressed: _saveProfile,
                  child: Text(
                    '启程',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.brightness == Brightness.dark 
                          ? Colors.white 
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
