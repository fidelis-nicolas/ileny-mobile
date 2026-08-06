import 'package:flutter/material.dart';

import '../network/api_exception.dart';
import '../network/page_response.dart';
import '../theme/app_colors.dart';

/// Shared infinite-scroll + pull-to-refresh list for every paginated
/// backend endpoint (directory, attendance history, notifications,
/// announcements) — same page/size contract, same loading/empty/error
/// states, so it's built once instead of four times over.
class PaginatedListView<T> extends StatefulWidget {
  const PaginatedListView({
    super.key,
    required this.fetchPage,
    required this.itemBuilder,
    this.emptyMessage = 'Nothing to show yet.',
    this.pageSize = 20,
  });

  final Future<PageResponse<T>> Function(int page, int size) fetchPage;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyMessage;
  final int pageSize;

  @override
  State<PaginatedListView<T>> createState() => PaginatedListViewState<T>();
}

class PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();
  int _nextPage = 0;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPage(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loading) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadPage();
    }
  }

  Future<void> refresh() => _loadPage(reset: true);

  Future<void> _loadPage({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      if (reset) _error = null;
    });
    try {
      final page = reset ? 0 : _nextPage;
      final result = await widget.fetchPage(page, widget.pageSize);
      setState(() {
        if (reset) _items.clear();
        _items.addAll(result.content);
        _nextPage = page + 1;
        _hasMore = !result.last;
        _error = null;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items.isEmpty) {
      return _MessageView(message: _error!, onRetry: refresh);
    }
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return _MessageView(message: widget.emptyMessage, onRetry: refresh);
    }
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return widget.itemBuilder(context, _items[index]);
        },
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: onRetry,
          child: ListView(
            children: [
              SizedBox(
                height: constraints.maxHeight,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
