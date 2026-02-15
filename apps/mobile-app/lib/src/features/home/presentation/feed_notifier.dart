import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

final newTraceEventProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

final feedFilterProvider = StateProvider<String>((ref) => 'All');

final feedProvider = StateNotifierProvider.autoDispose<FeedNotifier, AsyncValue<List<dynamic>>>((ref) {
  final filter = ref.watch(feedFilterProvider);
  return FeedNotifier(ref.read(apiClientProvider), ref, filter);
});

class FeedNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final Dio _dio;
  final Ref _ref;
  final String filter;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  FeedNotifier(this._dio, this._ref, this.filter) : super(const AsyncValue.loading()) {
    loadInitial();
    _setupRealtime();
  }

  void _setupRealtime() {
    Supabase.instance.client
        .channel('public:traces')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'traces',
          callback: (payload) {
            final newTrace = payload.newRecord;
            // Only insert if matches filter
            if (filter == 'All' || (newTrace['type'] as String?)?.toUpperCase() == filter.toUpperCase()) {
               _fetchAndInsertNew(newTrace['id']);
            }
          },
        )
        .subscribe();
  }

  Future<void> _fetchAndInsertNew(String id) async {
    try {
      final response = await _dio.get('/traces/$id');
      final fullTrace = response.data;
      if (state.hasValue) {
        state = AsyncValue.data([fullTrace, ...state.value!]);
        // Trigger Dynamic Island via global state
        _ref.read(newTraceEventProvider.notifier).state = fullTrace;
      }
    } catch (_) {}
  }

  Future<void> loadInitial() async {
    _page = 1;
    _hasMore = true;
    try {
      final Map<String, dynamic> query = {'page': _page, 'limit': 15};
      if (filter != 'All') query['type'] = filter;
      
      final response = await _dio.get('/traces/feed', queryParameters: query);
      final List data = response.data;
      state = AsyncValue.data(data);
      if (data.length < 15) _hasMore = false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    _page++;
    
    try {
      final Map<String, dynamic> query = {'page': _page, 'limit': 15};
      if (filter != 'All') query['type'] = filter;
      
      final response = await _dio.get('/traces/feed', queryParameters: query);
      final List newData = response.data;
      
      if (newData.isEmpty) {
        _hasMore = false;
      } else {
        state = AsyncValue.data([...state.value!, ...newData]);
        if (newData.length < 15) _hasMore = false;
      }
    } catch (_) {
      _page--;
    } finally {
      _isLoadingMore = false;
    }
  }
}
