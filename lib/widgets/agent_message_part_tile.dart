import 'package:flutter/material.dart';
import 'package:opencode_api/opencode_api.dart';

String _normalizePartType(MessagePart part) {
  final raw = (part.type ?? '').toLowerCase();
  if (raw.isEmpty && part.text != null) return 'text';
  return raw;
}

String _partSummary(MessagePart part) {
  final body = part.text ?? part.content ?? '';
  final firstLine = body.split('\n').firstWhere(
        (line) => line.trim().isNotEmpty,
        orElse: () => '',
      );
  if (firstLine.length > 80) {
    return '${firstLine.substring(0, 80)}…';
  }
  return firstLine;
}

bool _isCollapsibleType(String type) {
  return type == 'thinking' ||
      type == 'reasoning' ||
      type == 'tool' ||
      type == 'tool_call' ||
      type == 'tool_result' ||
      (type.isNotEmpty && type != 'text');
}

/// Renders a single agent message part with collapsible non-text sections.
class AgentMessagePartTile extends StatefulWidget {
  const AgentMessagePartTile({
    required this.part,
    this.forceCollapsed = true,
    super.key,
  });

  final MessagePart part;
  final bool forceCollapsed;

  @override
  State<AgentMessagePartTile> createState() => _AgentMessagePartTileState();
}

class _AgentMessagePartTileState extends State<AgentMessagePartTile> {
  bool? _expanded;

  bool get _collapsed => !(_expanded ?? !widget.forceCollapsed);

  @override
  Widget build(BuildContext context) {
    final type = _normalizePartType(widget.part);
    final body = widget.part.text ?? widget.part.content ?? '';

    if (type == 'text' || (!_isCollapsibleType(type) && body.isEmpty)) {
      if (body.isEmpty) return const SizedBox.shrink();
      return SelectableText(body);
    }

    if (!_isCollapsibleType(type)) {
      return _CollapsiblePartShell(
        icon: Icons.help_outline,
        title: '[${widget.part.type ?? 'part'}]',
        summary: _partSummary(widget.part),
        collapsed: _collapsed,
        onToggle: () => setState(() => _expanded = _collapsed),
        child: SelectableText(
          body.isEmpty ? '(empty)' : body,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
        ),
      );
    }

    final icon = type == 'thinking' || type == 'reasoning'
        ? Icons.psychology_outlined
        : Icons.build_outlined;
    final label = type == 'thinking' || type == 'reasoning'
        ? 'Thinking'
        : type.replaceAll('_', ' ');

    return _CollapsiblePartShell(
      icon: icon,
      title: label,
      summary: _partSummary(widget.part),
      collapsed: _collapsed,
      onToggle: () => setState(() => _expanded = _collapsed),
      child: SelectableText(
        body.isEmpty ? '(no content)' : body,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
      ),
    );
  }
}

class _CollapsiblePartShell extends StatelessWidget {
  const _CollapsiblePartShell({
    required this.icon,
    required this.title,
    required this.summary,
    required this.collapsed,
    required this.onToggle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String summary;
  final bool collapsed;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    Icon(
                      collapsed
                          ? Icons.expand_more
                          : Icons.expand_less,
                      size: 18,
                    ),
                  ],
                ),
                if (collapsed && summary.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 22, top: 2),
                    child: Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: child,
                  ),
                  crossFadeState: collapsed
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 150),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
