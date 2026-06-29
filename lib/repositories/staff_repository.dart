import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class StaffRepository {
  final SupabaseClient _client;

  StaffRepository(this._client);

  Future<List<ProfileModel>> getStaff(
    String gymId, {
    String? role,
    String status = 'Active',
  }) async {
    try {
      dynamic query = _client
          .from('profiles')
          .select();
      query = query.eq('gym_id', gymId);
      query = query.order('created_at', ascending: false);

      if (role != null && role.isNotEmpty) {
        query = query.eq('role', role);
      }

      if (status.isNotEmpty) {
        query = query.eq('is_active', status == 'Active');
      }

      final response = await query;
      return (response as List)
          .map((json) => ProfileModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load staff: ${e.toString()}');
    }
  }

  Future<ProfileModel> addStaff(Map<String, dynamic> staff) async {
    try {
      final avatarPath = staff['avatar_url'] as String?;
      if (avatarPath != null && avatarPath.isNotEmpty && !avatarPath.startsWith('http')) {
        final url = await _uploadAvatar(avatarPath);
        staff['avatar_url'] = url;
      }

      final response = await _client
          .from('profiles')
          .insert(staff)
          .select()
          .single();

      return ProfileModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add staff: ${e.toString()}');
    }
  }

  Future<ProfileModel> updateStaff(
    String gymId,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final avatarPath = data['avatar_url'] as String?;
      if (avatarPath != null && avatarPath.isNotEmpty && !avatarPath.startsWith('http')) {
        final url = await _uploadAvatar(avatarPath);
        data['avatar_url'] = url;
      }

      final response = await _client
          .from('profiles')
          .update(data)
          .eq('gym_id', gymId)
          .eq('id', id)
          .select()
          .single();

      return ProfileModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update staff: ${e.toString()}');
    }
  }

  Future<void> terminateStaff(String gymId, String id) async {
    try {
      await _client
          .from('profiles')
          .update({'is_active': false})
          .eq('gym_id', gymId)
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to terminate staff: ${e.toString()}');
    }
  }

  Future<String> _uploadAvatar(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      final bytes = await file.readAsBytes();
      final ext = filePath.split('.').last.toLowerCase();
      final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final fileName =
          'staff_avatars/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _client.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );

      return _client.storage.from('avatars').getPublicUrl(fileName);
    } catch (e) {
      throw Exception('Failed to upload avatar: ${e.toString()}');
    }
  }
}
