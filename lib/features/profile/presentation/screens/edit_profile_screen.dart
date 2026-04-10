import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input_field.dart';
import '../../data/models/player_profile_models.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedSkill = 'beginner';
  bool _showMatchHistory = true;
  final Set<String> _selectedRoles = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final map = args.cast<String, dynamic>();
      _nameController.text = (map['name'] ?? '').toString();
      final skill = (map['skillLevelRaw'] ?? 'beginner').toString();
      _selectedSkill =
          const ['beginner', 'intermediate', 'advanced'].contains(skill)
              ? skill
              : 'beginner';
      _showMatchHistory = map['showMatchHistory'] != false;
      final roles = map['preferredRoles'];
      if (roles is List) {
        _selectedRoles
          ..clear()
          ..addAll(roles.whereType<String>());
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Name is required';
    if (trimmed.length < 2) return 'Name must be at least 2 characters';
    if (trimmed.length > 100) return 'Name must be 100 characters or less';
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      UpdateProfileRequest(
        name: _nameController.text.trim(),
        skillLevel: _selectedSkill,
        preferredRoles: _selectedRoles.toList(growable: false),
        showMatchHistory: _showMatchHistory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppInputField(
                  label: 'Name',
                  hint: 'Your display name',
                  controller: _nameController,
                  validator: _validateName,
                  maxLength: 100,
                  showCounter: false,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSkill,
                  decoration: const InputDecoration(labelText: 'Skill Level'),
                  items: const [
                    DropdownMenuItem(
                        value: 'beginner', child: Text('Beginner')),
                    DropdownMenuItem(
                      value: 'intermediate',
                      child: Text('Intermediate'),
                    ),
                    DropdownMenuItem(
                        value: 'advanced', child: Text('Advanced')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedSkill = value);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text('Preferred Roles'),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final role in const [
                      'goalkeeper',
                      'defender',
                      'midfielder',
                      'striker'
                    ])
                      FilterChip(
                        label: Text(role),
                        selected: _selectedRoles.contains(role),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedRoles.add(role);
                            } else {
                              _selectedRoles.remove(role);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show Match History Publicly'),
                  value: _showMatchHistory,
                  onChanged: (value) =>
                      setState(() => _showMatchHistory = value),
                ),
                const Spacer(),
                AppButton(label: 'Save Changes', onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
