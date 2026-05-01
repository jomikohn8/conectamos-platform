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
    final parentRaw = exec['parent'];
    final parent = parentRaw is Map
        ? Map<String, dynamic>.from(parentRaw)
        : null;
    final rawChildren = exec['children'] as List? ?? [];
    final children = rawChildren
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final flowName = flow['name'] as String? ?? '—';
    final execId = exec['id'] as String? ?? '—';

    if (parent == null && children.isEmpty) return const SizedBox.shrink();

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
          if (parent != null) ...[
            _LineageChip(
              kind: 'parent',
              name: parent['name'] as String? ?? '—',
              execId: parent['execId'] as String? ?? parent['exec_id'] as String? ?? '',
              onTap: () {
                final id = parent['execId'] as String? ??
                    parent['exec_id'] as String?;
                if (id != null) context.go('/flows/runs/$id');
              },
            ),
            const _DottedConnector(),
          ],
          _LineageChip(
            kind: 'current',
            name: flowName,
            execId: execId,
          ),
          if (children.isNotEmpty) ...[
            const _DottedConnector(),
            ...children.take(4).map((c) {
              final cId = c['execId'] as String? ?? c['exec_id'] as String? ?? '';
              final cStatus = c['status'] as String? ?? 'completed';
              return _LineageChip(
                kind: 'child',
                name: c['name'] as String? ?? '—',
                execId: cId,
                status: cStatus,
                onTap: () {
                  if (cId.isNotEmpty) context.go('/flows/runs/$cId');
                },
              );
            }),
            if (children.length > 4)
              _MoreChildrenChip(count: children.length - 4),
          ],
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
    this.status,
    this.onTap,
  });

  final String kind; // 'parent' | 'current' | 'child'
  final String name;
  final String execId;
  final String? status;
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
          if (status != null && status != 'completed') ...[
            const SizedBox(width: 4),
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: status == 'in-progress'
                    ? AppColors.ctInfo
                    : AppColors.ctDanger,
                shape: BoxShape.circle,
              ),
            ),
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

class _MoreChildrenChip extends StatelessWidget {
  const _MoreChildrenChip({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.ctSurface2,
        border: Border.all(color: AppColors.ctBorder),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text('+ $count más',
          style: AppFonts.geist(
              fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ctText2)),
    );
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
