import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ssh_provider.dart';

class SSHClientForm extends StatefulWidget {
  const SSHClientForm({super.key});

  @override
  State<SSHClientForm> createState() => _SSHClientFormState();
}

class _SSHClientFormState extends State<SSHClientForm> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController(text: 'localhost');
  final _portController = TextEditingController(text: '2222');
  final _usernameController = TextEditingController(text: 'user');
  final _passwordController = TextEditingController(text: 'password');
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final ssh = Provider.of<SSHProvider>(context, listen: false);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('SSH Client Connection', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _hostController,
              decoration: const InputDecoration(labelText: 'Host', border: OutlineInputBorder()),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _portController,
              decoration: const InputDecoration(labelText: 'Port', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              obscureText: true,
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                if (_formKey.currentState!.validate()) {
                  setState(() => _isLoading = true);
                  try {
                    await ssh.connectClient(
                      host: _hostController.text,
                      port: int.parse(_portController.text),
                      username: _usernameController.text,
                      password: _passwordController.text,
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                      );
                    }
                  }
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text('Connect'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}