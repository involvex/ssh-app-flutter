import 'package:flutter/material.dart';
import 'package:opencode_api/opencode_api.dart' show MessageWithParts;
import 'package:provider/provider.dart';

import '../models/ssh_profile.dart';
import '../models/agent_connection.dart';
import '../providers/agent_provider.dart';
import '../providers/ssh_provider.dart';
import '../widgets/agent_permission_dialog.dart';

class AgentsTab extends StatefulWidget {
  const AgentsTab({super.key});

  @override
  State<AgentsTab> createState() => _AgentsTabState();
}

class _AgentsTabState extends State<AgentsTab> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _manualUrlController = TextEditingController();
  final TextEditingController _manualPasswordController =
      TextEditingController();
  bool _isConnecting = false;
  bool _permissionDialogVisible = false;

  @override
  void dispose() {
    _promptController.dispose();
    _manualUrlController.dispose();
    _manualPasswordController.dispose();
    super.dispose();
  }

  Future<void> _connectProfile(SSHProfile profile) async {
    setState(() => _isConnecting = true);
    try {
      await Provider.of<AgentProvider>(context, listen: false)
          .connectFromProfile(profile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connect failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _connectManualUrl() async {
    final url = _manualUrlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isConnecting = true);
    try {
      await Provider.of<AgentProvider>(context, listen: false).connectFromUrl(
        url: url.startsWith('http') ? url : 'http://$url',
        password: _manualPasswordController.text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connect failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AgentProvider, SSHProvider>(
      builder: (context, agents, ssh, child) {
        if (agents.pendingPermission != null && !_permissionDialogVisible) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showPermissionDialog(context, agents);
          });
        }

        if (agents.connections.isEmpty) {
          return _buildDisconnectedView(ssh.profiles);
        }

        final active = agents.activeConnection;
        if (active == null) {
          return const Center(child: Text('No active agent connection'));
        }

        final showingChat = active.activeSessionId != null;

        return PopScope(
          canPop: !showingChat,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && showingChat) {
              agents.clearActiveSession(active.id);
            }
          },
          child: Column(
            children: [
              _buildConnectionBar(agents),
              Expanded(
                child: showingChat
                    ? _buildChatPane(agents, active)
                    : _buildSessionList(agents, active.id),
              ),
              if (showingChat) _buildPromptInput(agents, active),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDisconnectedView(List<SSHProfile> profiles) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Connect to OpenCode Agent',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Attach to a running opencode web/serve instance using saved profiles.',
        ),
        const SizedBox(height: 16),
        if (_isConnecting) const LinearProgressIndicator(),
        if (profiles.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('No profiles saved'),
              subtitle: Text('Add a profile with host and agent port first'),
            ),
          )
        else
          ...profiles.map(
            (profile) => Card(
              child: ListTile(
                leading: const Icon(Icons.smart_toy, color: Colors.purple),
                title: Text(profile.name),
                subtitle: Text(
                  'SSH ${profile.host}:${profile.port} · Agent ${profile.agentBaseUrl}',
                ),
                trailing: const Icon(Icons.link),
                onTap: _isConnecting ? null : () => _connectProfile(profile),
              ),
            ),
          ),
        const Divider(height: 32),
        const Text(
          'Manual URL',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _manualUrlController,
          decoration: const InputDecoration(
            labelText: 'OpenCode URL',
            hintText: 'http://involvex.myfritz.link:5000',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _manualPasswordController,
          decoration: const InputDecoration(
            labelText: 'Password (optional)',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _isConnecting ? null : _connectManualUrl,
          icon: const Icon(Icons.link),
          label: const Text('Connect'),
        ),
      ],
    );
  }

  Widget _buildConnectionBar(AgentProvider agents) {
    final chips = agents.connections.map((connection) {
      final isActive = agents.activeConnectionId == connection.id;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InputChip(
          selected: isActive,
          avatar: CircleAvatar(
            radius: 4,
            backgroundColor:
                connection.isConnected ? Colors.green : Colors.red,
          ),
          label: Text(connection.profile.name),
          onPressed: () => agents.switchActiveConnection(connection.id),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () => agents.disconnect(connection.id),
        ),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips),
      ),
    );
  }

  Widget _buildSessionList(AgentProvider agents, String connectionId) {
    final connection = agents.activeConnection;
    if (connection == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Sessions',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'New session',
                onPressed: () => agents.createSession(connectionId),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: () => agents.refreshSessions(connectionId),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: connection.sessions.length,
            itemBuilder: (context, index) {
              final session = connection.sessions[index];
              final isActive = connection.activeSessionId == session.id;
              return ListTile(
                dense: true,
                selected: isActive,
                title: Text(
                  session.title ?? session.id ?? 'Untitled',
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: session.id != null
                    ? Text(
                        session.id!,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      )
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: session.id == null
                      ? null
                      : () => agents.deleteSession(connectionId, session.id!),
                ),
                onTap: session.id == null
                    ? null
                    : () => agents.selectSession(connectionId, session.id!),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatPane(AgentProvider agents, AgentConnection active) {
    final sessionId = active.activeSessionId!;
    String title = sessionId;
    for (final session in active.sessions) {
      if (session.id == sessionId) {
        title = session.title ?? sessionId;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          elevation: 1,
          child: ListTile(
            dense: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to sessions',
              onPressed: () => agents.clearActiveSession(active.id),
            ),
            title: Text(
              title,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Expanded(child: _buildChatView(agents, active)),
      ],
    );
  }

  Widget _buildChatView(AgentProvider agents, AgentConnection active) {
    if (active.isLoadingMessages) {
      return const Center(child: CircularProgressIndicator());
    }

    if (active.messages.isEmpty) {
      return const Center(child: Text('No messages yet. Send a prompt below.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: active.messages.length,
      itemBuilder: (context, index) {
        final message = active.messages[index];
        return _MessageBubble(message: message);
      },
    );
  }

  Widget _buildPromptInput(AgentProvider agents, AgentConnection active) {
    final canSend = active.activeSessionId != null && !active.isSending;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                hintText: 'Send a prompt to the agent...',
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 4,
              enabled: canSend,
              onSubmitted: canSend ? (_) => _sendPrompt(agents, active.id) : null,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: canSend ? () => _sendPrompt(agents, active.id) : null,
            child: active.isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPrompt(AgentProvider agents, String connectionId) async {
    final text = _promptController.text;
    _promptController.clear();
    await agents.sendPrompt(connectionId, text);
  }

  Future<void> _showPermissionDialog(
    BuildContext context,
    AgentProvider agents,
  ) async {
    final pending = agents.pendingPermission;
    if (pending == null || _permissionDialogVisible) return;

    _permissionDialogVisible = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AgentPermissionDialog(
        request: pending,
        onRespond: (response, remember) async {
          await agents.respondToPermission(
            response: response,
            remember: remember,
          );
        },
        onDismiss: agents.dismissPermission,
      ),
    );
    _permissionDialogVisible = false;
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final MessageWithParts message;

  @override
  Widget build(BuildContext context) {
    final role = message.info?.role ?? 'unknown';
    final isUser = role == 'user';
    final parts = message.parts ?? [];

    final textParts = parts
        .where((p) => p.type == 'text' || p.text != null)
        .map((p) => p.text ?? p.content ?? '')
        .where((t) => t.isNotEmpty)
        .join('\n');

    final toolParts = parts.where((p) => p.type != 'text' && p.text == null);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            if (textParts.isNotEmpty) ...[
              const SizedBox(height: 4),
              SelectableText(textParts),
            ],
            for (final part in toolParts)
              ExpansionTile(
                title: Text('[${part.type ?? 'tool'}]'),
                children: [
                  SelectableText(part.content ?? part.text ?? ''),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
