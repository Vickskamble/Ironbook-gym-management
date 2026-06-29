import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';

class ImportExportRepository {
  final SupabaseClient _client;

  ImportExportRepository(this._client);

  Future<Map<String, dynamic>> importMembersFromCSV({
    required String gymId,
    required String filePath,
    required String adminId,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      final lines = await file.readAsLines();
      if (lines.length < 2) {
        throw Exception('CSV file must have a header row and at least one data row');
      }

      final headers = lines[0].split(',').map((h) => h.trim().toLowerCase()).toList();
      final nameIndex = headers.indexOf('name');
      final phoneIndex = headers.indexOf('phone');
      final emailIndex = headers.indexOf('email');
      final planIndex = headers.indexOf('plan');
      final genderIndex = headers.indexOf('gender');
      final ageIndex = headers.indexOf('age');
      final addressIndex = headers.indexOf('address');

      if (nameIndex == -1 || phoneIndex == -1) {
        throw Exception('CSV must contain at least "name" and "phone" columns');
      }

      int inserted = 0;
      int skipped = 0;
      final List<String> errors = [];

      for (int i = 1; i < lines.length; i++) {
        final row = lines[i].split(',').map((c) => c.trim()).toList();
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

          final existing = await _client
              .from('members')
              .select('id')
              .eq('gym_id', gymId)
              .eq('phone', phone)
              .maybeSingle();

          if (existing != null) {
            skipped++;
            continue;
          }

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final memberData = {
            'gym_id': gymId,
            'name': name,
            'phone': phone,
            'email': emailIndex != -1 ? row[emailIndex] : null,
            'gender': genderIndex != -1 ? row[genderIndex] : null,
            'age': ageIndex != -1 ? int.tryParse(row[ageIndex]) : null,
            'address': addressIndex != -1 ? row[addressIndex] : null,
            'status': 'Active',
            'plan_name': planIndex != -1 ? row[planIndex] : null,
            'join_date': today.toIso8601String().split('T')[0],
            'membership_start': today.toIso8601String().split('T')[0],
            'membership_end': today.add(const Duration(days: 30)).toIso8601String().split('T')[0],
          };

          await _client.from('members').insert(memberData);
          inserted++;
        } catch (e) {
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

      return {
        'total': lines.length - 1,
        'inserted': inserted,
        'skipped': skipped,
        'errors': errors,
      };
    } catch (e) {
      throw Exception('Import failed: ${e.toString()}');
    }
  }

  Future<String> exportMembersToCSV(String gymId) async {
    try {
      final members = await _client
          .from('members')
          .select('name, phone, email, gender, age, address, plan_name, status, membership_start, membership_end, join_date')
          .eq('gym_id', gymId)
          .order('created_at', ascending: false);

      final header = 'Name,Phone,Email,Gender,Age,Address,Plan,Status,Membership Start,Membership End,Join Date';
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
          member['membership_start']?.toString() ?? '',
          member['membership_end']?.toString() ?? '',
          member['join_date']?.toString() ?? '',
        ].join(',');
        rows.add(row);
      }

      final csv = [header, ...rows].join('\n');
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/members_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      return file.path;
    } catch (e) {
      throw Exception('Export failed: ${e.toString()}');
    }
  }

  Future<String> generateMemberReportPDF(String gymId) async {
    try {
      final members = await _client
          .from('members')
          .select('name, phone, email, plan_name, status, membership_end')
          .eq('gym_id', gymId)
          .order('name', ascending: true);

      final gym = await _client
          .from('gyms')
          .select('name')
          .eq('id', gymId)
          .single();

      final gymName = gym['name'] as String? ?? 'Gym';
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text('$gymName - Member Report',
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Generated: ${DateTime.now().toLocal()}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
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

      final dir = Directory.systemTemp;
      final filePath = '${dir.path}/member_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      return filePath;
    } catch (e) {
      throw Exception('Failed to generate PDF report: ${e.toString()}');
    }
  }

  Future<String> generateRevenueReportExcel(
    String gymId, {
    int? month,
    int? year,
  }) async {
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
    } catch (e) {
      throw Exception('Failed to generate Excel report: ${e.toString()}');
    }
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
