// lib/features/profile/presentation/screens/my_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_appbar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/data/models/user_me_response.dart';
import '../../domain/profile_repository.dart';
import 'edit_profile_screen.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  late Future<UserMeResponse> _future;
  bool _savingBio = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<UserMeResponse> _load() {
    final ProfileRepository repo = ref.read(profileRepositoryProvider);
    return repo.getMyProfile();
  }

  void _reload() => setState(() => _future = _load());

  void _toast(String msg) {
    final m = ScaffoldMessenger.maybeOf(context);
    m?.hideCurrentSnackBar();
    m?.showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _safe(Object? v, {String fallback = '—'}) {
    final s = (v ?? '').toString().trim();
    return s.isEmpty ? fallback : s;
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (_savingBio) return;

    setState(() => _savingBio = true);
    try {
      final ProfileRepository repo = ref.read(profileRepositoryProvider);
      await repo.updateMyProfile(biometricsEnabled: value);
      _reload();
    } catch (_) {
      _toast('Unable to update biometrics');
    } finally {
      if (mounted) setState(() => _savingBio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(title: 'My Profile'),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradientSoft),
        child: SafeArea(
          child: FutureBuilder<UserMeResponse>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snap.hasData || snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 36),
                        const SizedBox(height: 10),
                        const Text('Unable to load profile'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _reload,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final me = snap.data!;

              final role = _safe(me.role, fallback: 'USER');
              final email = _safe(me.email);
              final phone = _safe(me.phone);
              final schoolCode = _safe(me.schoolCode);
              final isActive = me.isActive == true;
              final mustChangePassword = me.mustChangePassword == true;
              final biometricsEnabled = me.biometricsEnabled == true;

              final lastLoginAt = _safe(me.lastLoginAt);
              final createdAt = _safe(me.createdAt);

              final avatarText = (email.isNotEmpty ? email[0] : role[0]).toUpperCase();

              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: AppColors.brandTeal.withAlpha(18),
                            child: Text(
                              avatarText,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppColors.brandTeal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  role,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'School Code: $schoolCode',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isActive ? 'Account Active' : 'Account Disabled',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: isActive ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Contact',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 12),
                          _row(context, icon: Icons.email_rounded, label: 'Email', value: email),
                          const SizedBox(height: 10),
                          _row(context, icon: Icons.phone_rounded, label: 'Phone', value: phone),
                          const SizedBox(height: 10),
                          _row(context, icon: Icons.login_rounded, label: 'Last Login', value: lastLoginAt),
                          const SizedBox(height: 10),
                          _row(context, icon: Icons.event_rounded, label: 'Created', value: createdAt),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final bool? updated = await Navigator.of(context).push<bool>(
                                MaterialPageRoute<bool>(
                                  builder: (_) => EditProfileScreen(initialMe: me),
                                ),
                              );
                              if (updated == true) _reload();
                            },
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Edit Profile'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Security',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 10),

                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.lock_rounded, color: AppColors.brandTeal),
                            title: const Text('Change Password'),
                            subtitle: Text(
                              mustChangePassword
                                  ? 'Required (first login / temp password)'
                                  : 'Update your password anytime',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.of(context).pushNamed('/change-password'),
                          ),
                          const Divider(height: 1),

                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.fingerprint_rounded, color: AppColors.brandTeal),
                            title: const Text('Biometrics'),
                            subtitle: Text(biometricsEnabled ? 'Enabled' : 'Disabled'),
                            trailing: Switch(
                              value: biometricsEnabled,
                              onChanged: _savingBio ? null : _toggleBiometrics,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.brandTeal),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
