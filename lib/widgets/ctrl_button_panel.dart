import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';

import '../providers/ssh_provider.dart';

class CtrlButtonPanel extends StatelessWidget {
  const CtrlButtonPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SSHProvider>(
      builder: (context, ssh, child) {
        final active = ssh.activeSession;
        if (active == null || !active.isConnected) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade700),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _NavButton(
                  label: 'Tab',
                  onTap: () => active.terminal.keyInput(TerminalKey.tab),
                ),
                _NavButton(
                  label: '←',
                  onTap: () => active.terminal.keyInput(TerminalKey.arrowLeft),
                ),
                _NavButton(
                  label: '→',
                  onTap: () => active.terminal.keyInput(TerminalKey.arrowRight),
                ),
                _NavButton(
                  label: '↑',
                  onTap: () => active.terminal.keyInput(TerminalKey.arrowUp),
                ),
                _NavButton(
                  label: '↓',
                  onTap: () => active.terminal.keyInput(TerminalKey.arrowDown),
                ),
                _NavButton(
                  label: 'Home',
                  onTap: () => active.terminal.keyInput(TerminalKey.home),
                ),
                _NavButton(
                  label: 'End',
                  onTap: () => active.terminal.keyInput(TerminalKey.end),
                ),
                _NavButton(
                  label: 'Ctrl+C',
                  onTap: () => ssh.sendControlCharacter(3),
                ),
                _NavButton(
                  label: 'Ctrl+V',
                  onTap: () => _pasteFromClipboard(context, ssh),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pasteFromClipboard(
    BuildContext context,
    SSHProvider ssh,
  ) async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard is empty')),
        );
      }
      return;
    }
    ssh.sendString(text);
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
