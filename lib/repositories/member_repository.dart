import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/member_model.dart';

class MemberRepository {
  final SupabaseClient _supabase;

  MemberRepository(this._supabase);

  Future<List<MemberModel>> getMembers(
    String gymId, {
    String? status,
    String? search,
    int? page,
    int limit = 20,
  }) async {
    try {
      dynamic query = _supabase
          .from('members')
          .select('*, plans(name)');
      query = query.eq('gym_id', gymId);
      query = query.order('created_at', ascending: false);

      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }

      if (search != null && search.isNotEmpty) {
        query = query.or(
          'name.ilike.%$search%,phone.ilike.%$search%',
        );
      }

      if (page != null) {
        final from = page * limit;
        final to = from + limit - 1;
        query = query.range(from, to);
      }

      final response = await query;

      return (response as List).map((json) {
        final planData = json['plans'] as Map<String, dynamic>?;
        if (planData != null) {
          json['plan_name'] = planData['name'];
        }
        return MemberModel.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load members: ${e.toString()}');
    }
  }

  Future<MemberModel> getMemberById(String gymId, String id) async {
    try {
      final response = await _supabase
          .from('members')
          .select('*, plans(name)')
          .eq('gym_id', gymId)
          .eq('id', id)
          .single();

      final planData = response['plans'] as Map<String, dynamic>?;
      if (planData != null) {
        response['plan_name'] = planData['name'];
      }

      return MemberModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load member: ${e.toString()}');
    }
  }

  Future<MemberModel> addMember(Map<String, dynamic> member) async {
    try {
      final picPath = member['profile_pic'] as String?;
      if (picPath != null && picPath.isNotEmpty && !picPath.startsWith('http')) {
        final url = await _uploadProfilePic(picPath);
        member['profile_pic'] = url;
      }

      final response = await _supabase
          .from('members')
          .insert(member)
          .select()
          .single();

      return MemberModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add member: ${e.toString()}');
    }
  }

  Future<MemberModel> updateMember(
    String gymId,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final picPath = data['profile_pic'] as String?;
      if (picPath != null && picPath.isNotEmpty && !picPath.startsWith('http')) {
        final url = await _uploadProfilePic(picPath);
        data['profile_pic'] = url;
      }

      final response = await _supabase
          .from('members')
          .update(data)
          .eq('gym_id', gymId)
          .eq('id', id)
          .select()
          .single();

      return MemberModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update member: ${e.toString()}');
    }
  }

  Future<void> softDeleteMember(String gymId, String id) async {
    try {
      await _supabase
          .from('members')
          .update({'status': 'Deleted'})
          .eq('gym_id', gymId)
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete member: ${e.toString()}');
    }
  }

  Future<Map<String, int>> getMemberStats(String gymId) async {
    try {
      final total = await _supabase
          .from('members')
          .select('id')
          .eq('gym_id', gymId);

      final active = await _supabase
          .from('members')
          .select('id')
          .eq('gym_id', gymId)
          .eq('status', 'Active');

      final expired = await _supabase
          .from('members')
          .select('id')
          .eq('gym_id', gymId)
          .eq('status', 'Expired');

      final paused = await _supabase
          .from('members')
          .select('id')
          .eq('gym_id', gymId)
          .eq('status', 'Paused');

      return {
        'total': (total as List).length,
        'active': (active as List).length,
        'expired': (expired as List).length,
        'paused': (paused as List).length,
      };
    } catch (e) {
      throw Exception('Failed to load member stats: ${e.toString()}');
    }
  }

  Future<String> _uploadProfilePic(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      final bytes = await file.readAsBytes();
      final ext = filePath.split('.').last.toLowerCase();
      final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final fileName =
          'avatars/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _supabase.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );

      return _supabase.storage.from('avatars').getPublicUrl(fileName);
    } catch (e) {
      throw Exception('Failed to upload profile picture: ${e.toString()}');
    }
  }
}
