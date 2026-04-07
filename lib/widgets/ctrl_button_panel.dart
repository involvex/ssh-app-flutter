import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ssh_provider.dart';

class CtrlButtonPanel extends StatelessWidget {
  const CtrlButtonPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SSHProvider>(
      builder: (context, ssh, child) {
        if (!ssh.isClientConnected) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade700),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Ctrl',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(width: 8),
              _CtrlButton(label: 'C', charCode: 3),
              _CtrlButton(label: 'D', charCode: 4),
              _CtrlButton(label: 'Z', charCode: 26),
              _CtrlButton(label: 'L', charCode: 12),
              _CtrlButton(label: 'A', charCode: 1),
              _CtrlButton(label: 'P', charCode: 16),
            ],
          ),
        );
      },
    );
  }
}

class _CtrlButton extends StatelessWidget {
  final String label;
  final int charCode;

  const _CtrlButton({
    required this.label,
    required this.charCode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () {
          final ssh = Provider.of<SSHProvider>(context, listen: false);
          ssh.sendControlCharacter(charCode);
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
