import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/ai_workers_api.dart';
import '../../core/theme/app_theme.dart';
import 'channels_screen.dart';
import 'workflows_screen.dart';

class WorkerDetailScreen extends ConsumerStatefulWidget {
  const WorkerDetailScreen({required this.workerId, super.key});
  final String workerId;

  @override
  ConsumerState<WorkerDetailScreen> createState() =>
      _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends ConsumerState<WorkerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, dynamic>? _worker;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final workers = await AiWorkersApi.listWorkers();
      final worker = workers.firstWhere(
        (w) => (w['id'] as String?) == widget.workerId,
        orElse: () => <String, dynamic>{},
      );
      if (!mounted) return;
      setState(() {
        _worker = worker.isNotEmpty ? worker : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String get _workerName =>
      _worker?['display_name'] as String? ??
      _worker?['catalog_name'] as String? ??
      'Worker';

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.ctSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.ctText),
        onPressed: () => context.go('/workers'),
      ),
      title: _loading
          ? const SizedBox(
              width: 120,
              height: 12,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.ctBorder,
                color: AppColors.ctTeal,
              ),
            )
          : Text(
              _workerName,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.ctText,
              ),
            ),
      bottom: TabBar(
        controller: _tabCtrl,
        labelColor: AppColors.ctTeal,
        unselectedLabelColor: AppColors.ctText2,
        indicatorColor: AppColors.ctTeal,
        labelStyle: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 12,
        ),
        tabs: const [
          Tab(text: 'FLUJOS'),
          Tab(text: 'CANALES'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.ctBg,
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.ctDanger),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  color: AppColors.ctText2,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: _load, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.ctBg,
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          WorkflowsScreen(tenantWorkerId: widget.workerId),
          ChannelsScreen(tenantWorkerId: widget.workerId),
        ],
      ),
    );
  }
}
