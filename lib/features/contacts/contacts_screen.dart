import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/contact_model.dart';
import '../sos/sos_engine.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trusted Contacts"),
      ),
      body: contacts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    "No trusted contacts added yet.",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddContactSheet(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text("Add Trusted Contact"),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: contact.isPrimary ? AppTheme.emergencyRed : Colors.grey.shade300,
                      foregroundColor: contact.isPrimary ? Colors.white : Colors.black87,
                      child: Text(contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?'),
                    ),
                    title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${contact.relationship} • ${contact.phoneNumber}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (contact.isPrimary)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.emergencyRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text("Primary", style: TextStyle(color: AppTheme.emergencyRed, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.grey),
                          onPressed: () {
                            ref.read(contactsProvider.notifier).deleteContact(contact.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: contacts.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.emergencyRed,
              foregroundColor: Colors.white,
              onPressed: () => _showAddContactSheet(context, ref),
              icon: const Icon(Icons.add),
              label: const Text("Add Contact"),
            )
          : null,
    );
  }

  void _showAddContactSheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationshipController = TextEditingController();
    int priority = 1;
    bool isPrimary = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Add Trusted Contact",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Contact Name",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Phone Number",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: relationshipController,
                  decoration: InputDecoration(
                    labelText: "Relationship (e.g. Mother, Friend)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text("Primary Contact (Call First)"),
                  value: isPrimary,
                  onChanged: (val) => setModalState(() => isPrimary = val),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
                      return;
                    }
                    final newContact = ContactModel(
                      id: const Uuid().v4(),
                      name: nameController.text.trim(),
                      phoneNumber: phoneController.text.trim(),
                      relationship: relationshipController.text.trim().isEmpty ? 'Family' : relationshipController.text.trim(),
                      priority: priority,
                      isPrimary: isPrimary,
                    );
                    ref.read(contactsProvider.notifier).addContact(newContact);
                    Navigator.of(sheetContext).pop();
                  },
                  child: const Text("Save Contact"),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
