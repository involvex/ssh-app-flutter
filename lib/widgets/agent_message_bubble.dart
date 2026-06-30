import 'package:flutter/material.dart';
import 'package:opencode_api/opencode_api.dart';

import 'agent_message_part_tile.dart';

class AgentMessageBubble extends StatelessWidget {
  const AgentMessageBubble({
    required this.message,
    this.collapseToolParts = true,
    super.key,
  });

  final MessageWithParts message;
  final bool collapseToolParts;

  @override
  Widget build(BuildContext context) {
    final role = message.info?.role ?? 'unknown';
    final isUser = role == 'user';
    final parts = message.parts ?? <MessagePart>[];

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
            const SizedBox(height: 4),
            for (final part in parts)
              AgentMessagePartTile(
                part: part,
                forceCollapsed: collapseToolParts,
              ),
          ],
        ),
      ),
    );
  }
}
