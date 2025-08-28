import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class UserDialog extends StatefulWidget {
  final String? userId;
  final Map<dynamic, dynamic>? userData;

  const UserDialog({super.key, this.userId, this.userData});

  @override
  _UserDialogState createState() => _UserDialogState();
}

class _UserDialogState extends State<UserDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final database = FirebaseDatabase.instance.ref('users');

  @override
  void initState() {
    super.initState();
    if (widget.userData != null) {
      _nameController.text = widget.userData!['name'] ?? '';
      _emailController.text = widget.userData!['email'] ?? '';
      _phoneController.text = widget.userData!['phone'] ?? '';
    }
  }

  Future<void> _saveUser() async {
    final userData = {
      'name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
    };
    if (widget.userId == null) {
      await database.push().set(userData);
    } else {
      await database.child(widget.userId!).update(userData);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.userId == null ? 'Add User' : 'Edit User'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: _saveUser, child: const Text('Save')),
      ],
    );
  }
}