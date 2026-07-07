import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/member_model.dart';
import '../core/utils/error_handler.dart';

class MemberRepository {
  final SupabaseClient _supabase;

  MemberRepository(this._supabase);

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
    return regex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    return clean.length >= 10 && clean.length <= 15;
  }

  bool _isValidAge(int? age) {
    if (age == null) return true;
    return age >= 1 && age <= 120;
  }

  Future<List<MemberModel>> getMembers(
    String gymId, {
    String? status,
    String? search,
    int? page,
    int limit = 20,
  }) async {
    ErrorHandler.logStep('MemberRepository.getMembers', 'called');
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

      final result = (response as List).map((json) {
        final planData = json['plans'] as Map<String, dynamic>?;
        if (planData != null) {
          json['plan_name'] = planData['name'];
        }
        return MemberModel.fromJson(json);
      }).toList();
      ErrorHandler.logStep('MemberRepository.getMembers', 'returning result');
      return result;
    } catch (e, stack) {
      ErrorHandler.logError('MemberRepository.getMembers', e, stack);
      throw Exception('Failed to load members: ${e.toString()}');
    }
  }

  Future<MemberModel> getMemberById(String gymId, String id) async {
    ErrorHandler.logStep('MemberRepository.getMemberById', 'called');
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
    } catch (e, stack) {
      ErrorHandler.logError('MemberRepository.getMemberById', e, stack);
      throw Exception('Failed to load member: ${e.toString()}');
    }
  }

  Future<MemberModel> addMember(Map<String, dynamic> member) async {
    ErrorHandler.logStep('MemberRepository.addMember', 'called');
    try {
      const allowedFields = {'gym_id', 'name', 'phone', 'email', 'gender', 'age', 'address', 'status', 'plan_id', 'plan_name', 'profile_pic', 'join_date', 'membership_start', 'membership_end', 'emergency_contact', 'notes'};
      final filtered = Map<String, dynamic>.fromEntries(
        member.entries.where((e) => allowedFields.contains(e.key)),
      );

      final phone = filtered['phone'] as String?;
      if (phone != null && phone.isNotEmpty && !_isValidPhone(phone)) {
        throw Exception('Invalid phone number');
      }

      final email = filtered['email'] as String?;
      if (email != null && email.isNotEmpty && !_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }

      final age = filtered['age'] as int?;
      if (!_isValidAge(age)) {
        throw Exception('Age must be between 1 and 120');
      }

      if (filtered['membership_start'] != null && filtered['membership_end'] != null) {
        final start = DateTime.tryParse(filtered['membership_start'] as String);
        final end = DateTime.tryParse(filtered['membership_end'] as String);
        if (start != null && end != null && !end.isAfter(start)) {
          throw Exception('Membership end must be after start date');
        }
      }

      final picPath = filtered['profile_pic'] as String?;
      if (picPath != null && picPath.isNotEmpty && !picPath.startsWith('http')) {
        final url = await _uploadProfilePic(picPath);
        filtered['profile_pic'] = url;
      }

      final response = await _supabase
          .from('members')
          .insert(filtered)
          .select()
          .single();

      return MemberModel.fromJson(response);
    } catch (e, stack) {
      ErrorHandler.logError('MemberRepository.addMember', e, stack);
      throw Exception('Failed to add member: ${e.toString()}');
    }
  }

  Future<MemberModel> updateMember(
    String gymId,
    String id,
    Map<String, dynamic> data,
  ) async {
    ErrorHandler.logStep('MemberRepository.updateMember', 'called');
    try {
      const allowedFields = {'name', 'phone', 'email', 'gender', 'age', 'address', 'status', 'plan_id', 'plan_name', 'profile_pic', 'join_date', 'membership_start', 'membership_end', 'emergency_contact', 'notes'};
      final filtered = Map<String, dynamic>.fromEntries(
        data.entries.where((e) => allowedFields.contains(e.key)),
      );

      final phone = filtered['phone'] as String?;
      if (phone != null && phone.isNotEmpty && !_isValidPhone(phone)) {
        throw Exception('Invalid phone number');
      }

      final email = filtered['email'] as String?;
      if (email != null && email.isNotEmpty && !_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }

      final age = filtered['age'] as int?;
      if (!_isValidAge(age)) {
        throw Exception('Age must be between 1 and 120');
      }

      if (filtered['membership_start'] != null && filtered['membership_end'] != null) {
        final start = DateTime.tryParse(filtered['membership_start'] as String);
        final end = DateTime.tryParse(filtered['membership_end'] as String);
        if (start != null && end != null && !end.isAfter(start)) {
          throw Exception('Membership end must be after start date');
        }
      }

      final picPath = filtered['profile_pic'] as String?;
      if (picPath != null && picPath.isNotEmpty && !picPath.startsWith('http')) {
        final url = await _uploadProfilePic(picPath);
        filtered['profile_pic'] = url;
      }

      final response = await _supabase
          .from('members')
          .update(filtered)
          .eq('gym_id', gymId)
          .eq('id', id)
          .select()
          .single();

      return MemberModel.fromJson(response);
    } catch (e, stack) {
      ErrorHandler.logError('MemberRepository.updateMember', e, stack);
      throw Exception('Failed to update member: ${e.toString()}');
    }
  }

  Future<void> hardDeleteMember(String gymId, String id) async {
    ErrorHandler.logStep('MemberRepository.hardDeleteMember', 'called');
    try {
      await _supabase
          .from('members')
          .delete()
          .eq('gym_id', gymId)
          .eq('id', id);
    } catch (e, stack) {
      ErrorHandler.logError('MemberRepository.hardDeleteMember', e, stack);
      throw Exception('Failed to delete member: ${e.toString()}');
    }
  }

  Future<Map<String, int>> getMemberStats(String gymId) async {
    ErrorHandler.logStep('MemberRepository.getMemberStats', 'called');
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

      final result = {
        'total': (total as List).length,
        'active': (active as List).length,
        'expired': (expired as List).length,
        'paused': (paused as List).length,
      };
      ErrorHandler.logStep('MemberRepository.getMemberStats', 'returning result');
      return result;
    } catch (e, stack) {
      ErrorHandler.logError('MemberRepository.getMemberStats', e, stack);
      throw Exception('Failed to load member stats: ${e.toString()}');
    }
  }

  Future<void> markExpiredMembers(String gymId) async {
    ErrorHandler.logStep('MemberRepository.markExpiredMembers', 'called');
    try {
      await _supabase
          .from('members')
          .update({'status': 'Expired'})
          .eq('gym_id', gymId)
          .eq('status', 'Active')
          .lt('membership_end', DateTime.now().toIso8601String());
    } catch (e, stack) {
      ErrorHandler.logError('MemberRepository.markExpiredMembers', e, stack);
      throw Exception('Failed to mark expired members: ${e.toString()}');
    }
  }

  Future<String> _uploadProfilePic(String filePath) async {
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
          'avatars/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _supabase.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );

      return _supabase.storage.from('avatars').getPublicUrl(fileName);
    } catch (e, stack) {
      ErrorHandler.logError('MemberRepository._uploadProfilePic', e, stack);
      throw Exception('Failed to upload profile picture: ${e.toString()}');
    }
  }
}
