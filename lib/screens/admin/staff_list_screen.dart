import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../core/constants/app_colors.dart';

class StaffListScreen extends ConsumerStatefulWidget {
  const StaffListScreen({super.key});

  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen> {
  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(allStaffProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
      ),
      body: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (staff) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: staff.length,
            itemBuilder: (context, index) {
              final user = staff[index];
              final isSuperadmin = user.role == 'superadmin';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        (isSuperadmin ? AppColors.primary : Colors.grey)
                            .withValues(alpha: 0.1),
                    child: Text(
                      user.name[0].toUpperCase(),
                      style: TextStyle(
                        color: isSuperadmin
                            ? AppColors.primary
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${user.email}\nRole: ${user.role}'),
                  trailing: isSuperadmin
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'SUPERADMIN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title:
                                      const Text('Confirm Delete?'),
                                  content: const Text(
                                      'Delete this staff member?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child:
                                          const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: const Text('Delete',
                                          style: TextStyle(
                                              color: AppColors.danger)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await Supabase.instance.client
                                    .from('profiles')
                                    .delete()
                                    .eq('id', user.id);
                                ref.invalidate(allStaffProvider);
                              }
                            } else if (value == 'make_admin') {
                              await Supabase.instance.client
                                  .from('profiles')
                                  .update({'role': 'admin'})
                                  .eq('id', user.id);
                              ref.invalidate(allStaffProvider);
                            } else if (value == 'make_trainer') {
                              await Supabase.instance.client
                                  .from('profiles')
                                  .update({'role': 'trainer'})
                                  .eq('id', user.id);
                              ref.invalidate(allStaffProvider);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'make_admin',
                              child: Text('Set as Admin'),
                            ),
                            const PopupMenuItem(
                              value: 'make_trainer',
                              child: Text('Set as Trainer'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      color: AppColors.danger, size: 18),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style:
                                          TextStyle(color: AppColors.danger)),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStaffDialog(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _showAddStaffDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRole = 'staff';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Staff'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: nameController,
                  label: 'Name',
                  hintText: 'Enter name',
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: emailController,
                  label: 'Email',
                  hintText: 'Enter email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: ['admin', 'trainer', 'staff']
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r[0].toUpperCase() + r.substring(1)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedRole = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.isEmpty ||
                          emailController.text.isEmpty) { return; }
                      setDialogState(() => isLoading = true);
                      try {
                        await Supabase.instance.client.from('profiles').insert({
                          'name': nameController.text.trim(),
                          'email': emailController.text.trim(),
                          'role': selectedRole,
                        });
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        ref.invalidate(allStaffProvider);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
