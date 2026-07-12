import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../core/utils/error_handler.dart';

class StaffRepository {
  final SupabaseClient _client;

  StaffRepository(this._client);

  Future<List<ProfileModel>> getStaff(
    String gymId, {
    String? role,
    String status = 'Active',
  }) async {
    ErrorHandler.logStep('StaffRepository.getStaff', 'called');
    try {
      dynamic query = _client
          .from('profiles')
          .select();
      query = query.eq('gym_id', gymId);
      query = query.order('created_at', ascending: false);

      if (role != null && role.isNotEmpty) {
        query = query.eq('role', role);
      }

      final response = await query;
      return (response as List)
          .map((json) => ProfileModel.fromJson(json))
          .toList();
    } catch (e, stack) {
      ErrorHandler.logError('StaffRepository.getStaff', e, stack);
      throw Exception('Failed to load staff: ${e.toString()}');
    }
  }

  bool _isValidPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    return clean.length >= 10 && clean.length <= 15;
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
    return regex.hasMatch(email);
  }

  Future<ProfileModel> addStaff(Map<String, dynamic> staff) async {
    ErrorHandler.logStep('StaffRepository.addStaff', 'called');
    try {
      const allowedFields = {'id', 'name', 'phone', 'email', 'role', 'gym_id', 'avatar_url', 'is_active'};
      var filtered = Map<String, dynamic>.fromEntries(
        staff.entries.where((e) => allowedFields.contains(e.key)),
      );

      final email = filtered['email'] as String?;
      if (email == null || email.isEmpty) {
        throw Exception('Email is required to create staff login');
      }

      if (!_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }

      final phone = filtered['phone'] as String?;
      if (phone != null && phone.isNotEmpty && !_isValidPhone(phone)) {
        throw Exception('Invalid phone number');
      }

      final password = staff['password'] as String?;
      if (password == null || password.isEmpty) {
        throw Exception('Password is required to create staff login');
      }

      if (filtered['role'] == 'superadmin') {
        filtered['role'] = 'staff';
      }

      final avatarPath = filtered['avatar_url'] as String?;
      if (avatarPath != null && avatarPath.isNotEmpty && !avatarPath.startsWith('http')) {
        final url = await _uploadAvatar(avatarPath);
        filtered['avatar_url'] = url;
      }

      final currentUser = _client.auth.currentUser;
      if (currentUser != null && currentUser.email == email) {
        throw Exception('Cannot use your own email for a staff member');
      }

      final prev = _client.auth.currentSession;
      AuthResponse authRes;
      try {
        authRes = await _client.auth.signUp(
          email: email,
          password: password,
          data: {'name': filtered['name'], 'role': filtered['role']},
        );
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('already registered') || msg.contains('already exists')) {
          throw Exception('Email "$email" is already registered. Use a different email.');
        }
        rethrow;
      }
      if (authRes.user == null) throw Exception('Failed to create auth user');

      // Restore admin session (auth.signUp hijacks it when email confirmation is OFF)
      if (prev != null && authRes.session != null) {
        try {
          if (prev.refreshToken != null && prev.refreshToken!.isNotEmpty) {
            await _client.auth.setSession(prev.refreshToken!, accessToken: prev.accessToken);
          }
        } catch (e, stack) {
          ErrorHandler.logError('StaffRepository.addStaff.sessionRestore', e, stack);
        }
      }

      // Auto-profile trigger already created a minimal profile.
      // Update it with our additional fields (gym_id, role, etc.)
      filtered.remove('password');
      filtered.remove('email');
      final response = await _client
          .from('profiles')
          .update(filtered)
          .eq('id', authRes.user!.id)
          .select()
          .single();

      return ProfileModel.fromJson(response);
    } catch (e, stack) {
      ErrorHandler.logError('StaffRepository.addStaff', e, stack);
      throw Exception('Failed to add staff: ${e.toString()}');
    }
  }

  Future<ProfileModel> updateStaff(
    String gymId,
    String id,
    Map<String, dynamic> data,
  ) async {
    ErrorHandler.logStep('StaffRepository.updateStaff', 'called');
    try {
      const allowedFields = {'name', 'phone', 'email', 'avatar_url'};
      final filtered = Map<String, dynamic>.fromEntries(
        data.entries.where((e) => allowedFields.contains(e.key)),
      );

      final phone = filtered['phone'] as String?;
      if (phone != null && phone.isNotEmpty && !_isValidPhone(phone)) {
        throw Exception('Invalid phone number');
      }

      final avatarPath = filtered['avatar_url'] as String?;
      if (avatarPath != null && avatarPath.isNotEmpty && !avatarPath.startsWith('http')) {
        final url = await _uploadAvatar(avatarPath);
        filtered['avatar_url'] = url;
      }

      final response = await _client
          .from('profiles')
          .update(filtered)
          .eq('gym_id', gymId)
          .eq('id', id)
          .select()
          .single();

      return ProfileModel.fromJson(response);
    } catch (e, stack) {
      ErrorHandler.logError('StaffRepository.updateStaff', e, stack);
      throw Exception('Failed to update staff: ${e.toString()}');
    }
  }

  Future<void> terminateStaff(String gymId, String id) async {
    ErrorHandler.logStep('StaffRepository.terminateStaff', 'called');
    try {
      await _client
          .from('profiles')
          .update({'is_active': false})
          .eq('gym_id', gymId)
          .eq('id', id);
    } catch (e, stack) {
      ErrorHandler.logError('StaffRepository.terminateStaff', e, stack);
      throw Exception('Failed to terminate staff: ${e.toString()}');
    }
  }

  Future<String> _uploadAvatar(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      final ext = filePath.split('.').last.toLowerCase();
      const allowedExtensions = {'png', 'jpg', 'jpeg', 'gif', 'webp'};
      if (!allowedExtensions.contains(ext)) {
        throw Exception('Invalid file type: $ext. Allowed: png, jpg, jpeg, gif, webp');
      }

      final fileSize = await file.length();
      if (fileSize > 5242880) {
        throw Exception('File too large. Maximum size is 5MB');
      }

      final raf = await file.open(mode: FileMode.read);
      try {
        final header = await raf.read(4);
        if (ext == 'png') {
          if (header.length < 4 || header[0] != 0x89 || header[1] != 0x50 || header[2] != 0x4E || header[3] != 0x47) {
            throw Exception('Invalid PNG file');
          }
        } else if (ext == 'jpg' || ext == 'jpeg') {
          if (header.length < 3 || header[0] != 0xFF || header[1] != 0xD8 || header[2] != 0xFF) {
            throw Exception('Invalid JPEG file');
          }
        }
      } finally {
        await raf.close();
      }

      final bytes = await file.readAsBytes();
      final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final fileName =
          'staff_avatars/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _client.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );

      return _client.storage.from('avatars').getPublicUrl(fileName);
    } catch (e, stack) {
      ErrorHandler.logError('StaffRepository._uploadAvatar', e, stack);
      throw Exception('Failed to upload avatar: ${e.toString()}');
    }
  }
}
