import 'package:flutter/material.dart';

import '../../core/api/channels_api.dart';
import '../../core/theme/colors.dart';

class ChannelDetailScreen extends StatefulWidget {
  const ChannelDetailScreen({super.key, required this.channelId});

  final String channelId;

  @override
  State<ChannelDetailScreen> createState() => _ChannelDetailScreenState();
}

class _ChannelDetailScreenState extends State<ChannelDetailScreen> {
  Map<String, dynamic>? _channel;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ChannelsApi.getChannel(channelId: widget.channelId);
      if (mounted) setState(() { _channel = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _channel?['display_name'] as String? ?? widget.channelId;

    return Scaffold(
      backgroundColor: AppColors.ctBg,
      appBar: AppBar(
        backgroundColor: AppColors.ctSurface,
        elevation: 0,
        leading: BackButton(color: AppColors.ctText),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.ctText,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.ctBorder),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    'Error al cargar canal: $_error',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.ctDanger,
                    ),
                  ),
                )
              : const Center(
                  child: Text(
                    'En construcción',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.ctText2,
                    ),
                  ),
                ),
    );
  }
}
