import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import '../core/utils/error_handler.dart';

const _pageFormat = PdfPageFormat(595.28, 841.89);
const _grey = PdfColor.fromInt(0xFF9CA3AF);
const _green = PdfColor.fromInt(0xFF10B981);
const _red = PdfColor.fromInt(0xFFEF4444);
const _blue = PdfColor.fromInt(0xFF6366F1);

class ImportExportRepository {
  final SupabaseClient _client;

  ImportExportRepository(this._client);

  static const int _maxCsvRows = 5000;

  bool _isValidPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    return clean.length >= 10 && clean.length <= 15;
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
    return regex.hasMatch(email);
  }

  Future<Map<String, dynamic>> importMembersFromCSV({
    required String gymId,
    required String filePath,
    required String adminId,
  }) async {
    ErrorHandler.logStep('ImportExportRepository.importMembersFromCSV', 'called');
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      final fileSize = await file.length();
      if (fileSize > 10485760) {
        throw Exception('File too large. Maximum size is 10MB');
      }

      final lines = await file.readAsLines();
      if (lines.length < 2) {
        throw Exception('CSV file must have a header row and at least one data row');
      }

      final dataRows = lines.length - 1;
      if (dataRows > _maxCsvRows) {
        throw Exception('CSV file has $dataRows data rows. Maximum allowed is $_maxCsvRows.');
      }

      final headers = _parseCsvLine(lines[0]).map((h) => h.trim().toLowerCase()).toList();
      final nameIndex = headers.indexOf('name');
      final phoneIndex = headers.indexOf('phone');
      final emailIndex = headers.indexOf('email');
      final planIndex = headers.contains('plan_name') ? headers.indexOf('plan_name') : headers.indexOf('plan');
      final genderIndex = headers.indexOf('gender');
      final ageIndex = headers.indexOf('age');
      final addressIndex = headers.indexOf('address');
      final joinDateIndex = headers.contains('join_date') ? headers.indexOf('join_date') : headers.indexOf('join date');
      final bloodGroupIndex = headers.contains('blood_group') ? headers.indexOf('blood_group') : headers.indexOf('blood group');
      final emergencyContactIndex = headers.contains('emergency_contact') ? headers.indexOf('emergency_contact') : headers.indexOf('emergency contact');
      final notesIndex = headers.indexOf('notes');
      final statusIndex = headers.indexOf('status');
      final membershipStartIndex = headers.contains('membership_start') ? headers.indexOf('membership_start') : headers.indexOf('membership start');
      final membershipEndIndex = headers.contains('membership_end') ? headers.indexOf('membership_end') : headers.indexOf('membership end');
      final membershipDaysIndex = headers.contains('membership_days') ? headers.indexOf('membership_days') : headers.indexOf('duration_days');

      if (nameIndex == -1 || phoneIndex == -1) {
        throw Exception('CSV must contain at least "name" and "phone" columns');
      }

      int inserted = 0;
      int skipped = 0;
      final List<String> errors = [];

      for (int i = 1; i < lines.length; i++) {
        final row = _parseCsvLine(lines[i]);
        if (row.length < 2) {
          skipped++;
          continue;
        }

        try {
          final name = row[nameIndex];
          final phone = row[phoneIndex];

          if (name.isEmpty || phone.isEmpty) {
            skipped++;
            continue;
          }

          final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
          if (!_isValidPhone(phone)) {
            errors.add('Row ${i + 1}: Invalid phone number "$phone"');
            skipped++;
            continue;
          }

          final existing = await _client
              .from('members')
              .select('id')
              .eq('gym_id', gymId)
              .eq('phone', cleanPhone)
              .maybeSingle();

          if (existing != null) {
            skipped++;
            continue;
          }

          final email = emailIndex != -1 ? row[emailIndex] : null;
          if (email != null && email.isNotEmpty && !_isValidEmail(email)) {
            errors.add('Row ${i + 1}: Invalid email "$email"');
            skipped++;
            continue;
          }

          final ageStr = ageIndex != -1 ? row[ageIndex] : null;
          int? age;
          if (ageStr != null && ageStr.isNotEmpty) {
            age = int.tryParse(ageStr);
            if (age != null && (age < 1 || age > 120)) {
              errors.add('Row ${i + 1}: Age must be between 1 and 120');
              skipped++;
              continue;
            }
          }

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          String joinDate;
          if (joinDateIndex != -1 && row[joinDateIndex].isNotEmpty) {
            try {
              final parsed = DateTime.parse(row[joinDateIndex]);
              joinDate = parsed.toIso8601String().split('T')[0];
            } catch (_) {
              joinDate = today.toIso8601String().split('T')[0];
            }
          } else {
            joinDate = today.toIso8601String().split('T')[0];
          }

          String membershipStart = joinDate;
          if (membershipStartIndex != -1 && row[membershipStartIndex].isNotEmpty) {
            try {
              final parsed = DateTime.parse(row[membershipStartIndex]);
              membershipStart = parsed.toIso8601String().split('T')[0];
            } catch (_) {}
          }

          String? membershipEnd;
          int membershipDays = 30;
          if (membershipDaysIndex != -1 && row[membershipDaysIndex].isNotEmpty) {
            membershipDays = int.tryParse(row[membershipDaysIndex]) ?? 30;
          }
          if (membershipEndIndex != -1 && row[membershipEndIndex].isNotEmpty) {
            try {
              final parsed = DateTime.parse(row[membershipEndIndex]);
              membershipEnd = parsed.toIso8601String().split('T')[0];
            } catch (_) {
              final start = DateTime.parse(membershipStart);
              membershipEnd = start.add(Duration(days: membershipDays)).toIso8601String().split('T')[0];
            }
          } else {
            final start = DateTime.parse(membershipStart);
            membershipEnd = start.add(Duration(days: membershipDays)).toIso8601String().split('T')[0];
          }

          final status = statusIndex != -1 && row[statusIndex].isNotEmpty ? row[statusIndex] : 'Active';

          String? bloodGroup;
          if (bloodGroupIndex != -1 && row[bloodGroupIndex].isNotEmpty) {
            bloodGroup = row[bloodGroupIndex];
          }

          String? emergencyContact;
          if (emergencyContactIndex != -1 && row[emergencyContactIndex].isNotEmpty) {
            emergencyContact = row[emergencyContactIndex];
          }

          String? notes;
          if (notesIndex != -1 && row[notesIndex].isNotEmpty) {
            notes = row[notesIndex];
          }

          final memberData = {
            'gym_id': gymId,
            'name': name,
            'phone': cleanPhone,
            'email': email,
            'gender': genderIndex != -1 ? row[genderIndex] : null,
            'age': age,
            'address': addressIndex != -1 ? row[addressIndex] : null,
            'status': status,
            'plan_name': planIndex != -1 ? row[planIndex] : null,
            'join_date': joinDate,
            'membership_start': membershipStart,
            'membership_end': membershipEnd,
            'blood_group': bloodGroup,
            'emergency_contact': emergencyContact,
            'notes': notes,
          };

          await _client.from('members').insert(memberData);
          inserted++;
        } catch (e, stack) {
          ErrorHandler.logError('ImportExportRepository.importMembersFromCSV.row', e, stack);
          errors.add('Row ${i + 1}: ${e.toString()}');
          skipped++;
        }
      }

      await _client.from('import_logs').insert({
        'gym_id': gymId,
        'admin_id': adminId,
        'type': 'members_csv',
        'total_rows': lines.length - 1,
        'inserted': inserted,
        'skipped': skipped,
        'errors': errors.join('; '),
        'created_at': DateTime.now().toIso8601String(),
      });

      final result = {
        'total': lines.length - 1,
        'inserted': inserted,
        'skipped': skipped,
        'errors': errors,
      };
      ErrorHandler.logStep('ImportExportRepository.importMembersFromCSV', 'returning result');
      return result;
    } catch (e, stack) {
      ErrorHandler.logError('ImportExportRepository.importMembersFromCSV', e, stack);
      throw Exception('Import failed: ${e.toString()}');
    }
  }

  Future<String> exportMembersToCSV(String gymId) async {
    ErrorHandler.logStep('ImportExportRepository.exportMembersToCSV', 'called');
    try {
      final members = await _client
          .from('members')
          .select('name, phone, email, gender, age, address, plan_name, status, membership_start, membership_end, join_date, blood_group, emergency_contact, notes')
          .eq('gym_id', gymId)
          .order('created_at', ascending: false);

      final header = 'Name,Phone,Email,Gender,Age,Address,Plan_Name,Status,Join_Date,Membership_Start,Membership_End,Blood_Group,Emergency_Contact,Notes';
      final rows = <String>[];

      for (final member in members) {
        final row = [
          _escapeCsv(member['name'] as String? ?? ''),
          _escapeCsv(member['phone'] as String? ?? ''),
          _escapeCsv(member['email'] as String? ?? ''),
          _escapeCsv(member['gender'] as String? ?? ''),
          member['age']?.toString() ?? '',
          _escapeCsv(member['address'] as String? ?? ''),
          _escapeCsv(member['plan_name'] as String? ?? ''),
          _escapeCsv(member['status'] as String? ?? ''),
          member['join_date']?.toString().split('T')[0] ?? '',
          member['membership_start']?.toString().split('T')[0] ?? '',
          member['membership_end']?.toString().split('T')[0] ?? '',
          _escapeCsv(member['blood_group'] as String? ?? ''),
          _escapeCsv(member['emergency_contact'] as String? ?? ''),
          _escapeCsv(member['notes'] as String? ?? ''),
        ].join(',');
        rows.add(row);
      }

      final csv = [header, ...rows].join('\n');
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/members_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      return file.path;
    } catch (e, stack) {
      ErrorHandler.logError('ImportExportRepository.exportMembersToCSV', e, stack);
      throw Exception('Export failed: ${e.toString()}');
    }
  }

  Future<Uint8List> generateMemberReportPDF(String gymId, {String? gymName}) async {
    ErrorHandler.logStep('ImportExportRepository.generateMemberReportPDF', 'called');
    try {
      final members = await _client
          .from('members')
          .select('name, phone, email, plan_name, status, membership_end')
          .eq('gym_id', gymId)
          .order('name', ascending: true);

      gymName ??= await _fetchGymName(gymId);
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: _pageFormat,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Text('$gymName - Member Report',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Generated: ${DateTime.now().toLocal()}',
                style: const pw.TextStyle(fontSize: 10, color: _grey)),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headers: ['Name', 'Phone', 'Email', 'Plan', 'Status', 'Membership End'],
              data: members.map((m) => [
                m['name'] as String? ?? '',
                m['phone'] as String? ?? '',
                m['email'] as String? ?? '',
                m['plan_name'] as String? ?? '-',
                m['status'] as String? ?? '',
                m['membership_end']?.toString() ?? '-',
              ]).toList(),
            ),
          ],
        ),
      );

      return await pdf.save();
    } catch (e, stack) {
      ErrorHandler.logError('ImportExportRepository.generateMemberReportPDF', e, stack);
      throw Exception('Failed to generate PDF report: ${e.toString()}');
    }
  }

  Future<String> generateRevenueReportExcel(
    String gymId, {
    int? month,
    int? year,
  }) async {
    ErrorHandler.logStep('ImportExportRepository.generateRevenueReportExcel', 'called');
    try {
      final now = DateTime.now();
      final reportMonth = month ?? now.month;
      final reportYear = year ?? now.year;

      final monthStart = DateTime(reportYear, reportMonth, 1);
      final monthEnd = DateTime(reportYear, reportMonth + 1, 1);

      final payments = await _client
          .from('payments')
          .select('*, members(name, phone), plans(name)')
          .eq('gym_id', gymId)
          .gte('paid_at', monthStart.toIso8601String())
          .lt('paid_at', monthEnd.toIso8601String())
          .order('paid_at', ascending: false);

      final gym = await _client
          .from('gyms')
          .select('name')
          .eq('id', gymId)
          .single();

      final gymName = gym['name'] as String? ?? 'Gym';
      final excel = Excel.createExcel();
      final sheet = excel['Revenue Report'];

      sheet.appendRow([
        TextCellValue('$gymName - Revenue Report'),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
      ]);
      sheet.appendRow([
        TextCellValue('Month: ${monthStart.month}/${monthStart.year}'),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
      ]);
      sheet.appendRow([TextCellValue(''), TextCellValue(''), TextCellValue(''), TextCellValue('')]);
      sheet.appendRow([
        TextCellValue('Member Name'),
        TextCellValue('Phone'),
        TextCellValue('Plan'),
        TextCellValue('Amount'),
      ]);

      num total = 0;
      for (final payment in payments) {
        final memberData = payment['members'] as Map<String, dynamic>?;
        final planData = payment['plans'] as Map<String, dynamic>?;
        final amount = (payment['final_amount'] as num?) ?? 0;
        total += amount;

        sheet.appendRow([
          TextCellValue(memberData?['name'] as String? ?? ''),
          TextCellValue(memberData?['phone'] as String? ?? ''),
          TextCellValue(planData?['name'] as String? ?? ''),
          TextCellValue(amount.toString()),
        ]);
      }

      sheet.appendRow([TextCellValue(''), TextCellValue(''), TextCellValue(''), TextCellValue('')]);
      sheet.appendRow([
        TextCellValue('Total'),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(total.toString()),
      ]);

      final dir = Directory.systemTemp;
      final filePath = '${dir.path}/revenue_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final fileBytes = excel.save();
      if (fileBytes == null) {
        throw Exception('Failed to generate Excel');
      }
      await File(filePath).writeAsBytes(fileBytes);
      return filePath;
    } catch (e, stack) {
      ErrorHandler.logError('ImportExportRepository.generateRevenueReportExcel', e, stack);
      throw Exception('Failed to generate Excel report: ${e.toString()}');
    }
  }

  String _escapeCsv(String value) {
    if (value.isEmpty) return value;
    final trimmed = value.trim();
    final formulaChars = {'=', '+', '-', '@', '%', '|'};
    if (trimmed.isNotEmpty && formulaChars.contains(trimmed[0])) {
      value = "'$value";
    }
    if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    final current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (inQuotes) {
        if (char == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            current.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          current.write(char);
        }
      } else {
        if (char == '"') {
          inQuotes = true;
        } else if (char == ',') {
          result.add(current.toString().trim());
          current.clear();
        } else {
          current.write(char);
        }
      }
    }
    result.add(current.toString().trim());
    return result;
  }

  Future<Uint8List> generateRevenueReportPDF(
    String gymId, {
    required DateTime fromDate,
    required DateTime toDate,
    String? gymName,
  }) async {
    ErrorHandler.logStep('ImportExportRepository.generateRevenueReportPDF', 'called');
    try {
      final from = DateTime(fromDate.year, fromDate.month, fromDate.day);
      final to = DateTime(toDate.year, toDate.month, toDate.day + 1);

      final payments = await _client
          .from('payments')
          .select('*, members(name, phone), plans(name)')
          .eq('gym_id', gymId)
          .gte('paid_at', from.toIso8601String())
          .lt('paid_at', to.toIso8601String())
          .order('paid_at', ascending: false);

      gymName ??= await _fetchGymName(gymId);
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: _pageFormat,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Text('$gymName - Revenue Report',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('${_formatDate(from)} to ${_formatDate(to)}',
                style: const pw.TextStyle(fontSize: 12, color: _grey)),
            pw.SizedBox(height: 8),
            pw.Text('Generated: ${DateTime.now().toLocal()}',
                style: const pw.TextStyle(fontSize: 10, color: _grey)),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headers: ['Member Name', 'Phone', 'Plan', 'Amount'],
              data: payments.map((p) {
                final memberData = p['members'] as Map<String, dynamic>?;
                final planData = p['plans'] as Map<String, dynamic>?;
                final amount = (p['final_amount'] as num?) ?? 0;
                return [
                  memberData?['name'] as String? ?? '',
                  memberData?['phone'] as String? ?? '',
                  planData?['name'] as String? ?? '-',
                  amount.toString(),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Total: ',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                  'Rs${payments.fold<num>(0, (s, p) => s + ((p['final_amount'] as num?) ?? 0)).toStringAsFixed(0)}',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _green),
                ),
              ],
            ),
          ],
        ),
      );

      return await pdf.save();
    } catch (e, stack) {
      ErrorHandler.logError('ImportExportRepository.generateRevenueReportPDF', e, stack);
      throw Exception('Failed to generate revenue PDF: ${e.toString()}');
    }
  }

  Future<Uint8List> generateAttendanceReportPDF(
    String gymId, {
    required DateTime fromDate,
    required DateTime toDate,
    String? gymName,
  }) async {
    ErrorHandler.logStep('ImportExportRepository.generateAttendanceReportPDF', 'called');
    try {
      final from = DateTime(fromDate.year, fromDate.month, fromDate.day);
      final to = DateTime(toDate.year, toDate.month, toDate.day + 1);

      final attendance = await _client
          .from('attendance')
          .select('*, members!inner(name, phone, status)')
          .eq('gym_id', gymId)
          .gte('check_in', from.toIso8601String())
          .lt('check_in', to.toIso8601String())
          .order('check_in', ascending: false);

      gymName ??= await _fetchGymName(gymId);
      final pdf = pw.Document();

      final totalCheckIns = attendance.length;
      final uniqueMembers = <String>{};
      for (final a in attendance) {
        final m = a['members'] as Map<String, dynamic>?;
        if (m != null) uniqueMembers.add(m['name'] as String? ?? 'Unknown');
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: _pageFormat,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Text('$gymName - Attendance Report',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('${_formatDate(from)} to ${_formatDate(to)}',
                style: const pw.TextStyle(fontSize: 12, color: _grey)),
            pw.SizedBox(height: 8),
            pw.Text('Generated: ${DateTime.now().toLocal()}',
                style: const pw.TextStyle(fontSize: 10, color: _grey)),
            pw.SizedBox(height: 12),
            pw.Row(
              children: [
                pw.Text('Total Check-ins: ',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text('$totalCheckIns',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _blue)),
              ],
            ),
            pw.Row(
              children: [
                pw.Text('Unique Members: ',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text('${uniqueMembers.length}',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _blue)),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headers: ['Member Name', 'Phone', 'Check-in', 'Status'],
              data: attendance.map((a) {
                final m = a['members'] as Map<String, dynamic>?;
                final checkIn = a['check_in'] as String? ?? '';
                final memberStatus = m?['status'] as String? ?? 'Active';
                return [
                  m?['name'] as String? ?? 'Unknown',
                  m?['phone'] as String? ?? '',
                  checkIn.length >= 16 ? checkIn.substring(0, 16).replaceAll('T', ' ') : checkIn,
                  memberStatus,
                ];
              }).toList(),
            ),
          ],
        ),
      );

      return await pdf.save();
    } catch (e, stack) {
      ErrorHandler.logError('ImportExportRepository.generateAttendanceReportPDF', e, stack);
      throw Exception('Failed to generate attendance PDF: ${e.toString()}');
    }
  }

  Future<Uint8List> generateExpenseReportPDF(
    String gymId, {
    required DateTime fromDate,
    required DateTime toDate,
    String? gymName,
  }) async {
    ErrorHandler.logStep('ImportExportRepository.generateExpenseReportPDF', 'called');
    try {
      final from = DateTime(fromDate.year, fromDate.month, fromDate.day);
      final to = DateTime(toDate.year, toDate.month, toDate.day + 1);

      final expenses = await _client
          .from('expenses')
          .select()
          .eq('gym_id', gymId)
          .gte('expense_date', from.toIso8601String().split('T')[0])
          .lt('expense_date', to.toIso8601String().split('T')[0])
          .order('expense_date', ascending: false);

      gymName ??= await _fetchGymName(gymId);
      final pdf = pw.Document();

      num total = 0;
      final Map<String, num> categoryTotals = {};
      for (final e in expenses) {
        final amt = (e['amount'] as num?) ?? 0;
        total += amt;
        final cat = e['category'] as String? ?? 'Other';
        categoryTotals[cat] = (categoryTotals[cat] ?? 0) + amt;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: _pageFormat,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Text('$gymName - Expense Report',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('${_formatDate(from)} to ${_formatDate(to)}',
                style: const pw.TextStyle(fontSize: 12, color: _grey)),
            pw.SizedBox(height: 8),
            pw.Text('Generated: ${DateTime.now().toLocal()}',
                style: const pw.TextStyle(fontSize: 10, color: _grey)),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headers: ['Title', 'Category', 'Date', 'Amount'],
              data: expenses.map((e) => [
                e['title'] as String? ?? '',
                e['category'] as String? ?? '',
                (e['expense_date'] as String?)?.substring(0, 10) ?? '',
                ((e['amount'] as num?) ?? 0).toString(),
              ]).toList(),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Category Breakdown',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headers: ['Category', 'Total'],
              data: categoryTotals.entries.map((e) => [e.key, 'Rs${e.value.toStringAsFixed(0)}']).toList(),
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Total Expenses: ',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                  'Rs${total.toStringAsFixed(0)}',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _red),
                ),
              ],
            ),
          ],
        ),
      );

      return await pdf.save();
    } catch (e, stack) {
      ErrorHandler.logError('ImportExportRepository.generateExpenseReportPDF', e, stack);
      throw Exception('Failed to generate expense PDF: ${e.toString()}');
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<String> _fetchGymName(String gymId) async {
    try {
      final gym = await _client
          .from('gyms')
          .select('name')
          .eq('id', gymId)
          .maybeSingle();
      return gym?['name'] as String? ?? 'Gym';
    } catch (e, stack) {
      ErrorHandler.logError('ImportExportRepository._fetchGymName', e, stack);
      return 'Gym';
    }
  }
}
