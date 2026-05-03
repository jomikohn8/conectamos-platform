import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class MessagesThread extends StatelessWidget {
  const MessagesThread({super.key, required this.messages});
  final List<Map<String, dynamic>> messages;

  static const _shortMonths = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
  ];

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.ctSurface2,
          border: Border.all(color: AppColors.ctBorder, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, size: 24, color: Color(0xFF94A3B8)),
            const SizedBox(height: 8),
            Text('Esta ejecución no tuvo conversación asociada.',
                style: AppFonts.geist(fontSize: 13, color: const Color(0xFF94A3B8))),
          ],
        ),
      );
    }

    // Build date label from first message
    final now = DateTime.now();
    final dateLabel =
        '${now.day.toString().padLeft(2, '0')} ${_shortMonths[now.month - 1]} ${now.year}';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 520),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE7E1D5),
            border: Border.all(color: AppColors.ctBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date pill
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      color: Colors.white.withValues(alpha: 0.7),
                      child: Text(dateLabel,
                          style: AppFonts.geist(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF475569))),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                ...messages.map((m) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _MessageBubble(message: m),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final Map<String, dynamic> message;

  @override
  Widget build(BuildContext context) {
    final isWorker = message['from'] == 'worker';
    final text = message['text'] as String? ?? '';
    final at = message['at'] as String? ?? '';
    final author = message['author'] as String?;
    final attachments = message['attachments'] as List?;

    return Align(
      alignment: isWorker ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Column(
          crossAxisAlignment:
              isWorker ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isWorker && author != null)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text(author,
                    style: AppFonts.geist(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ctInfo)),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 6),
              decoration: BoxDecoration(
                color: isWorker ? const Color(0xFFD9FDD3) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(8),
                  topRight: const Radius.circular(8),
                  bottomLeft: Radius.circular(isWorker ? 8 : 2),
                  bottomRight: Radius.circular(isWorker ? 2 : 8),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    offset: Offset(0, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isWorker)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded,
                              size: 11, color: AppColors.ctTeal),
                          const SizedBox(width: 5),
                          Text('AI WORKER · MARCO V1',
                              style: AppFonts.geist(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ctTeal,
                                letterSpacing: 0.04,
                              )),
                        ],
                      ),
                    ),
                  if (attachments != null && attachments.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: text.isNotEmpty ? 6 : 0),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: attachments.map<Widget>((a) {
                          if (a is String && a.startsWith('http')) {
                            return MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (_) => Dialog.fullscreen(
                                    backgroundColor: const Color(0xD90B132B),
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: Image.network(
                                            a,
                                            fit: BoxFit.contain,
                                            errorBuilder: (ctx2, err, stack) =>
                                                const Icon(Icons.broken_image_rounded,
                                                    size: 48, color: Colors.white54),
                                          ),
                                        ),
                                        Positioned(
                                          top: 18,
                                          right: 18,
                                          child: GestureDetector(
                                            onTap: () => Navigator.of(context).pop(),
                                            child: Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.15),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.close_rounded,
                                                  color: Colors.white, size: 20),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(a,
                                      width: 90, height: 68, fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) => Container(
                                          width: 90, height: 68,
                                          color: AppColors.ctSurface2)),
                                ),
                              ),
                            );
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.ctSurface2,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(a.toString(),
                                style: AppFonts.geist(
                                    fontSize: 11, color: const Color(0xFF475569))),
                          );
                        }).toList(),
                      ),
                    ),
                  if (text.isNotEmpty)
                    Text(text,
                        style: AppFonts.geist(
                            fontSize: 13, height: 1.4, color: AppColors.ctText)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(at,
                          style: AppFonts.geist(
                              fontSize: 10, color: const Color(0xFF94A3B8))),
                      if (isWorker) ...[
                        const SizedBox(width: 3),
                        const Icon(Icons.done_all_rounded,
                            size: 10, color: AppColors.ctInfo),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
