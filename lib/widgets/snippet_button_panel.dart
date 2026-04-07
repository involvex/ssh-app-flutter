import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ssh_provider.dart';
import '../providers/snippet_provider.dart';

class SnippetButtonPanel extends StatelessWidget {
  const SnippetButtonPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SSHProvider, SnippetProvider>(
      builder: (context, ssh, snippets, child) {
        if (!ssh.isClientConnected || !snippets.isLoaded) {
          return const SizedBox.shrink();
        }

        final displaySnippets = snippets.snippets.take(6).toList();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade700),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Snippets',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              ...displaySnippets.map((s) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  onTap: () => ssh.terminal.write('${s.content}\n'),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      s.name.length > 8 ? '${s.name.substring(0, 8)}...' : s.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              )),
              if (snippets.snippets.length > 6)
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 16),
                  onPressed: () => _showSnippetManager(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showSnippetManager(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _SnippetListSheet(),
    );
  }
}

class _SnippetListSheet extends StatelessWidget {
  const _SnippetListSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: <Widget>[
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Snippet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Consumer2<SSHProvider, SnippetProvider>(
                  builder: (context, ssh, snippets, child) {
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: snippets.snippets.length,
                      itemBuilder: (context, index) {
                        final snippet = snippets.snippets[index];
                        return ListTile(
                          leading: const Icon(Icons.code, color: Colors.blue),
                          title: Text(snippet.name),
                          subtitle: Text(snippet.content),
                          onTap: () {
                            ssh.terminal.write('${snippet.content}\n');
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}