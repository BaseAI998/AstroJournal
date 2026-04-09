import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/database/database.dart';
import '../../../core/widgets/city_autocomplete.dart';
import '../../../providers/profile_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameController = TextEditingController();
  DateTime? _selectedDate;
  String _cityName = '';
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _initFromProfile(Profile profile) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = profile.displayName;
    _cityName = profile.birthPlaceName;
    _selectedDate = profile.birthDateTime;
  }

  void _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: _selectedDate != null
            ? TimeOfDay.fromDateTime(_selectedDate!)
            : TimeOfDay.now(),
      );
      if (time != null && mounted) {
        setState(() {
          _selectedDate = DateTime(
            date.year, date.month, date.day, time.hour, time.minute,
          );
        });
      }
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    final place = _cityName.trim();

    if (name.isEmpty || place.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写完整信息')),
      );
      return;
    }

    final current = ref.read(profileProvider).value;
    if (current == null) return;

    final updated = Profile(
      id: current.id,
      displayName: name,
      birthDateTime: _selectedDate!,
      birthPlaceName: place,
      createdAt: current.createdAt,
    );

    ref.read(profileProvider.notifier).saveProfile(updated);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('个人资料', style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppTheme.accentGold),
            onPressed: _save,
          ),
        ],
      ),
      body: profileState.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('未找到资料'));
          }
          _initFromProfile(profile);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar area
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.panel,
                        child: Text(
                          profile.displayName.isNotEmpty
                              ? profile.displayName[0]
                              : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            fontFamily: 'serif',
                            color: AppTheme.accentGold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '创建于 ${DateFormat('yyyy-MM-dd').format(profile.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Name
                Text('称呼',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),

                // Birth date/time
                Text('出生时间',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDateTime,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      suffixIcon: const Icon(Icons.calendar_today,
                          size: 18, color: AppTheme.textSecondary),
                    ),
                    child: Text(
                      _selectedDate != null
                          ? DateFormat('yyyy-MM-dd HH:mm')
                              .format(_selectedDate!)
                          : '选择出生日期和时间',
                      style: TextStyle(
                        fontFamily: 'serif',
                        color: _selectedDate != null
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Birth place
                Text('出生城市',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                CityAutocomplete(
                  initialValue: _cityName,
                  onSelected: (city) {
                    setState(() {
                      _cityName = city.displayName;
                    });
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
