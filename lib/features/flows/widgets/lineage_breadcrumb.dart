import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class LineageBreadcrumb extends StatelessWidget {
  const LineageBreadcrumb({
    super.key,
    required this.exec,
    required this.flow,
  });

  final Map<String, dynamic> exec;
  final Map<String, dynamic> flow;

  @override
  Widget build(BuildContext context) {
    final parentExecId = exec['parent_execution_id'] as String?;
    final flowName = flow['name'] as String? ?? '—';
    final execId = exec['id'] as String? ?? '—';

    if (parentExecId == null) return const SizedBox.shrink();

    final parentLabel = parentExecId.length >= 8
        ? parentExecId.substring(0, 8).toUpperCase()
        : parentExecId.toUpperCase();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: AppColors.ctBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('LINAJE',
              style: AppFonts.geist(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
                color: const Color(0xFF475569),
              )),
          _LineageChip(
            kind: 'parent',
            name: parentLabel,
            execId: parentExecId,
            onTap: () => context.go('/executions/$parentExecId'),
          ),
          const _DottedConnector(),
          _LineageChip(
            kind: 'current',
            name: flowName,
            execId: execId,
          ),
        ],
      ),
    );
  }
}

// ── Chips ──────────────────────────────────────────────────────────────────

class _LineageChip extends StatelessWidget {
  const _LineageChip({
    required this.kind,
    required this.name,
    required this.execId,
    this.onTap,
  });

  final String kind; // 'parent' | 'current' | 'child'
  final String name;
  final String execId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, bd, iconData, eyebrow) = switch (kind) {
      'parent' => (
          const Color(0xFFEEF2FF),
          const Color(0xFF4338CA),
          const Color(0xFFC7D2FE),
          Icons.arrow_back_rounded,
          'VINO DE',
        ),
      'current' => (
          AppColors.ctNavy,
          Colors.white,
          AppColors.ctNavy,
          Icons.account_tree_rounded,
          'ESTA EJECUCIÓN',
        ),
      _ => (
          AppColors.ctTealLight,
          const Color(0xFF0F766E),
          const Color(0xFF99F6E4),
          Icons.arrow_forward_rounded,
          'DETONÓ',
        ),
    };

    final isCurrent = kind == 'current';

    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: bd),
        borderRadius: BorderRadius.circular(99),
        boxShadow: isCurrent
            ? [
                const BoxShadow(
                  color: Color(0x4D0B132B),
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: isCurrent
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, size: 10, color: fg),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.06,
                    color: fg.withValues(alpha: 0.65),
                  )),
              Text(name,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  )),
            ],
          ),
          if (!isCurrent) ...[
            const SizedBox(width: 6),
            Text(execId,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 10,
                  color: fg.withValues(alpha: 0.55),
                  letterSpacing: -0.005,
                )),
          ],
        ],
      ),
    );

    if (!isCurrent && onTap != null) {
      chip = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onTap, child: chip),
      );
    }
    return chip;
  }
}


class _DottedConnector extends StatelessWidget {
  const _DottedConnector();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 1.5,
      child: Row(
        children: List.generate(
          6,
          (_) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Container(
              width: 3,
              height: 1.5,
              color: const Color(0xFFD1D5DB),
            ),
          ),
        ),
      ),
    );
  }
}
