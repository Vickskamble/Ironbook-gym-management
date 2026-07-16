import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../core/utils/error_handler.dart';
import '../supabase_config.dart';

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
      final email = staff['email'] as String?;
      if (email == null || email.isEmpty) {
        throw Exception('Email is required to create staff login');
      }
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }

      final phone = staff['phone'] as String?;
      if (phone != null && phone.isNotEmpty && !_isValidPhone(phone)) {
        throw Exception('Invalid phone number');
      }

      final password = staff['password'] as String?;
      if (password == null || password.isEmpty) {
        throw Exception('Password is required to create staff login');
      }

      final avatarPath = staff['avatar_url'] as String?;
      String? avatarUrl;
      if (avatarPath != null && avatarPath.isNotEmpty && !avatarPath.startsWith('http')) {
        avatarUrl = await _uploadAvatar(avatarPath);
      }

      final currentUser = _client.auth.currentUser;
      if (currentUser != null && currentUser.email == email) {
        throw Exception('Cannot use your own email for a staff member');
      }

      final token = _client.auth.currentSession?.accessToken;
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated. Please log in again.');
      }

      final response = await http.post(
        Uri.parse('${SupabaseConfig.url}/functions/v1/create-staff'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'apikey': SupabaseConfig.publishableKey,
        },
        body: jsonEncode({
          'name': staff['name'],
          'email': email,
          'password': password,
          'phone': staff['phone'],
          'role': staff['role'] == 'superadmin' ? 'staff' : staff['role'],
          'gym_id': staff['gym_id'],
          'is_active': staff['is_active'] ?? true,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        }),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(body['error'] ?? 'Failed to add staff');
      }

      return ProfileModel.fromJson(body['staff']);
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
      const allowedFields = {'name', 'phone', 'email', 'avatar_url', 'role', 'is_active'};
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

      // Use RPC with security definer to bypass RLS - only admins can update
      final response = await _client.rpc('update_staff_profile', params: {
        'p_target_user_id': id,
        if (filtered.containsKey('name')) 'p_name': filtered['name'],
        if (filtered.containsKey('phone')) 'p_phone': filtered['phone'],
        if (filtered.containsKey('role')) 'p_role': filtered['role'],
        if (filtered.containsKey('gym_id')) 'p_gym_id': gymId,
        'p_is_active': filtered['is_active'] ?? true,
        if (filtered.containsKey('avatar_url')) 'p_avatar_url': filtered['avatar_url'],
      });

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
