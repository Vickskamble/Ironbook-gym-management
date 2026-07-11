import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../models/gym_model.dart';
import '../../core/constants/app_colors.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _gymNameCtrl = TextEditingController();
  final _gymAddressCtrl = TextEditingController();
  final _gymPhoneCtrl = TextEditingController();
  final _gymWebsiteCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;
  File? _pendingImage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _gymNameCtrl.dispose();
    _gymAddressCtrl.dispose();
    _gymPhoneCtrl.dispose();
    _gymWebsiteCtrl.dispose();
    super.dispose();
  }

  void _initEdit() {
    final p = ref.read(authProvider).profile;
    final g = ref.read(authProvider).gym;
    if (p == null) return;
    _nameCtrl.text = p.name;
    _phoneCtrl.text = p.phone;
    _gymNameCtrl.text = g?.name ?? '';
    _gymAddressCtrl.text = g?.address ?? '';
    _gymPhoneCtrl.text = g?.phone ?? '';
    _gymWebsiteCtrl.text = g?.website ?? '';
    setState(() => _editing = true);
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _pendingImage = null;
    });
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) setState(() => _pendingImage = File(file.path));
  }

  Future<String?> _uploadAvatar(String userId) async {
    if (_pendingImage == null) return null;
    try {
      final bytes = await _pendingImage!.readAsBytes();
      if (bytes.length > 5242880) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File too large (max 5MB)'), backgroundColor: AppColors.danger),
          );
        }
        return null;
      }
      String ext = 'jpg';
      String mime = 'image/jpeg';
      if (bytes.length >= 4) {
        if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
          ext = 'png'; mime = 'image/png';
        } else if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
          ext = 'jpg'; mime = 'image/jpeg';
        } else if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
          ext = 'gif'; mime = 'image/gif';
        } else if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) {
          ext = 'webp'; mime = 'image/webp';
        }
      }
      final path = 'avatars/$userId.$ext';
      await Supabase.instance.client.storage.from('avatars').uploadBinary(
        path, bytes,
        fileOptions: FileOptions(upsert: true, contentType: mime),
      );
      return Supabase.instance.client.storage.from('avatars').getPublicUrl(path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo upload failed: $e'), backgroundColor: AppColors.danger),
        );
      }
      return null;
    }
  }

  Future<void> _save() async {
    final auth = ref.read(authProvider);
    final profile = auth.profile;
    final gym = auth.gym;
    if (profile == null) return;
    setState(() => _saving = true);
    try {
      String? avatarUrl;
      if (_pendingImage != null) avatarUrl = await _uploadAvatar(profile.id);

      final profileData = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      };
      if (avatarUrl != null) profileData['avatar_url'] = avatarUrl;
      final updatedProfile = await ref.read(authRepositoryProvider).updateProfile(profile.id, profileData);

      GymModel? updatedGym;
      if (gym != null) {
        final gymData = <String, dynamic>{
          'name': _gymNameCtrl.text.trim(),
          'address': _gymAddressCtrl.text.trim(),
          'phone': _gymPhoneCtrl.text.trim(),
          'website': _gymWebsiteCtrl.text.trim(),
        };
        updatedGym = await ref.read(gymRepositoryProvider).updateGym(gym.id, gymData);
      }

      ref.read(authProvider.notifier).updateProfileData(updatedProfile, updatedGym ?? gym);
      setState(() {
        _editing = false;
        _pendingImage = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _capitalize(String s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s;

  Widget _infoTile(IconData icon, String label, String value, {Color? iconColor, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor ?? AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final profile = auth.profile;
    final gym = auth.gym;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => context.pop()),
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          if (!_editing)
            IconButton(icon: const Icon(Icons.edit_rounded, color: AppColors.primary), onPressed: _initEdit),
        ],
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _avatarSection(profile.avatarUrl),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                    child: Column(
                      children: [
                        _infoTile(Icons.person_rounded, 'Name', profile.name, iconColor: AppColors.primary, trailing: _editing ? _editField(_nameCtrl) : null),
                        const Divider(color: AppColors.border, height: 16),
                        _infoTile(Icons.email_rounded, 'Email', profile.email, iconColor: const Color(0xFFF59E0B)),
                        const Divider(color: AppColors.border, height: 16),
                        _infoTile(Icons.phone_rounded, 'Phone', profile.phone, iconColor: const Color(0xFF10B981), trailing: _editing ? _editField(_phoneCtrl) : null),
                        const Divider(color: AppColors.border, height: 16),
                        _infoTile(Icons.badge_rounded, 'Role', _capitalize(profile.role), iconColor: const Color(0xFFB15CF6)),
                        const Divider(color: AppColors.border, height: 16),
                        _infoTile(Icons.language_rounded, 'Language', profile.language.toUpperCase(), iconColor: const Color(0xFF0EA5E9)),
                        const Divider(color: AppColors.border, height: 16),
                        _infoTile(Icons.calendar_month_rounded, 'Member Since', _formatDate(profile.createdAt), iconColor: const Color(0xFFEC4899)),
                      ],
                    ),
                  ),
                  if (gym != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(width: 3, height: 16, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 10),
                              const Text('GYM DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _infoTile(Icons.store_rounded, 'Gym Name', gym.name, iconColor: AppColors.primary, trailing: _editing ? _editField(_gymNameCtrl) : null),
                          const Divider(color: AppColors.border, height: 16),
                          _infoTile(Icons.location_on_rounded, 'Address', gym.address, iconColor: const Color(0xFFF59E0B), trailing: _editing ? _editField(_gymAddressCtrl) : null),
                          const Divider(color: AppColors.border, height: 16),
                          _infoTile(Icons.phone_rounded, 'Phone', gym.phone, iconColor: const Color(0xFF10B981), trailing: _editing ? _editField(_gymPhoneCtrl) : null),
                          const Divider(color: AppColors.border, height: 16),
                          _infoTile(Icons.language_rounded, 'Website', gym.website ?? 'N/A', iconColor: const Color(0xFF0EA5E9), trailing: _editing ? _editField(_gymWebsiteCtrl) : null),
                          const Divider(color: AppColors.border, height: 16),
                          _infoTile(Icons.people_alt_rounded, 'Capacity', '${gym.totalCapacity} members', iconColor: const Color(0xFFB15CF6)),
                          const Divider(color: AppColors.border, height: 16),
                          _infoTile(Icons.subscriptions_rounded, 'Subscription', '${_capitalize(gym.subscription)}${gym.subscriptionExpiresAt != null ? ' (expires ${_formatDate(gym.subscriptionExpiresAt)})' : ''}', iconColor: const Color(0xFFEC4899)),
                          if (gym.establishedYear != null) ...[
                            const Divider(color: AppColors.border, height: 16),
                            _infoTile(Icons.cake_rounded, 'Established', gym.establishedYear.toString(), iconColor: const Color(0xFFF59E0B)),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (_editing) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _cancelEdit,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _saving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _editField(TextEditingController ctrl) {
    return SizedBox(
      width: 140,
      height: 32,
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
          isDense: true,
        ),
      ),
    );
  }

  Widget _avatarSection(String? avatarUrl) {
    return GestureDetector(
      onTap: _editing ? _pickImage : null,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.surface,
            backgroundImage: _pendingImage != null
                ? FileImage(_pendingImage!)
                : (avatarUrl != null && avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(avatarUrl) as ImageProvider
                    : null),
            child: _pendingImage == null && (avatarUrl == null || avatarUrl.isEmpty)
                ? const Icon(Icons.person_rounded, size: 44, color: AppColors.primary)
                : null,
          ),
          if (_editing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: AppColors.background, width: 2)),
                child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
