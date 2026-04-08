import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Nav',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              _NavButton(
                label: 'Tab',
                onTap: () => ssh.terminal.keyInput(TerminalKey.tab),
              ),
              _NavButton(
                label: '←',
                onTap: () => ssh.terminal.keyInput(TerminalKey.arrowLeft),
              ),
              _NavButton(
                label: '→',
                onTap: () => ssh.terminal.keyInput(TerminalKey.arrowRight),
              ),
              _NavButton(
                label: '↑',
                onTap: () => ssh.terminal.keyInput(TerminalKey.arrowUp),
              ),
              _NavButton(
                label: '↓',
                onTap: () => ssh.terminal.keyInput(TerminalKey.arrowDown),
              ),
              _NavButton(
                label: 'Home',
                onTap: () => ssh.terminal.keyInput(TerminalKey.home),
              ),
              _NavButton(
                label: 'End',
                onTap: () => ssh.terminal.keyInput(TerminalKey.end),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
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
