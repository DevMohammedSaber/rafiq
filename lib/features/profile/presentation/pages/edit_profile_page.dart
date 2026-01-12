import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

/// Edit Profile Page
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  bool _hasChanges = false;
  bool _initialized = false;
  String? _originalName;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nameController.addListener(_onNameChanged);

    // Try to set initial value if profile is already loaded
    final profile = context.read<ProfileCubit>().currentProfile;
    if (profile != null) {
      _nameController.text = profile.name;
      _originalName = profile.name;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _initializeFromProfile(dynamic profile) {
    if (!_initialized && profile != null) {
      _nameController.text = profile.name;
      _originalName = profile.name;
      _initialized = true;
    }
  }

  void _onNameChanged() {
    final hasChanges =
        _originalName != null && _nameController.text.trim() != _originalName;
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profile.edit'.tr()),
        centerTitle: true,
        actions: [
          BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              final isSaving = state is ProfileSaving;
              return TextButton(
                onPressed: (_hasChanges && !isSaving) ? _saveProfile : null,
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'common.save'.tr(),
                        style: TextStyle(
                          color: _hasChanges ? AppColors.primary : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            _initializeFromProfile(state.profile);
          } else if (state is ProfileSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message.tr()),
                backgroundColor: AppColors.primary,
              ),
            );
            context.pop();
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final profile = context.read<ProfileCubit>().currentProfile;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: NetworkImage(
                            profile?.avatarUrl ??
                                'https://ui-avatars.com/api/?name=U&background=006D5B&color=fff&size=200',
                          ),
                        ),
                      ),
                      // Edit avatar button (placeholder for future)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'profile.avatar_coming_soon'.tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'profile.name'.tr(),
                      hintText: 'profile.name_hint'.tr(),
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'profile.name_required'.tr();
                      }
                      if (value.trim().length < 2) {
                        return 'profile.name_too_short'.tr();
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Email field (read-only for auth users)
                  if (profile != null && profile.email != null)
                    TextFormField(
                      initialValue: profile.email,
                      readOnly: true,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'profile.email'.tr(),
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).disabledColor.withValues(alpha: 0.1),
                      ),
                    ),

                  if (profile != null && profile.email != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'profile.email_readonly'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Save button (alternative to AppBar button)
                  SizedBox(
                    width: double.infinity,
                    child: BlocBuilder<ProfileCubit, ProfileState>(
                      builder: (context, state) {
                        final isSaving = state is ProfileSaving;
                        return ElevatedButton(
                          onPressed: (_hasChanges && !isSaving)
                              ? _saveProfile
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'common.save'.tr(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      context.read<ProfileCubit>().updateName(name);
    }
  }
}
