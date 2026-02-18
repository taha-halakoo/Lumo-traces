import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../data/trace_repository.dart';

// State
class MapState {
  final LatLng center;
  final LatLngBounds? bounds;
  final String searchQuery;
  final List<String> activeFilters;
  final List<dynamic> traces;
  final bool isLoading;
  final bool isScanning;

  MapState({
    required this.center,
    this.bounds,
    this.searchQuery = '',
    this.activeFilters = const [],
    this.traces = const [],
    this.isLoading = false,
    this.isScanning = false,
  });

  MapState copyWith({
    LatLng? center,
    LatLngBounds? bounds,
    String? searchQuery,
    List<String>? activeFilters,
    List<dynamic>? traces,
    bool? isLoading,
    bool? isScanning,
  }) {
    return MapState(
      center: center ?? this.center,
      bounds: bounds ?? this.bounds,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilters: activeFilters ?? this.activeFilters,
      traces: traces ?? this.traces,
      isLoading: isLoading ?? this.isLoading,
      isScanning: isScanning ?? this.isScanning,
    );
  }
}

// ViewModel
class MapViewModel extends StateNotifier<MapState> {
  final TraceRepository _repo;

  MapViewModel(this._repo) : super(MapState(center: const LatLng(0, 0)));

  void updateBounds(LatLngBounds bounds) {
    // Only update if bounds changed significantly to avoid spam
    if (state.bounds != bounds) {
       state = state.copyWith(bounds: bounds);
       // Debounce here or just call fetch? Let's just call fetch for now.
       // In production, we'd debounce.
       _fetchTraces();
    }
  }

  void updateCenter(LatLng center) {
    state = state.copyWith(center: center);
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
    if (query.isNotEmpty) {
      _performSearch();
    } else {
      _fetchTraces();
    }
  }

  void toggleFilter(String filter) {
    final current = List<String>.from(state.activeFilters);
    if (current.contains(filter)) {
      current.remove(filter);
    } else {
      current.add(filter);
    }
    state = state.copyWith(activeFilters: current);
    // Locally filter logic could go here, but for now we just store state.
    // The View will filter the displayed list based on this state.
  }

  Future<void> _fetchTraces() async {
    if (state.bounds == null) return;
    if (state.searchQuery.isNotEmpty) return; // Search mode overrides bounds mode

    state = state.copyWith(isLoading: true);
    try {
      final traces = await _repo.getInBounds(
        state.bounds!.south,
        state.bounds!.north,
        state.bounds!.west,
        state.bounds!.east,
      );
      state = state.copyWith(traces: traces, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _performSearch() async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await _repo.search(state.searchQuery, state.center.latitude, state.center.longitude);
      state = state.copyWith(traces: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
  
  Future<void> scanArea() async {
      state = state.copyWith(isScanning: true);
      await Future.delayed(const Duration(seconds: 1)); // UX delay for "Scanning" feel
      if (state.searchQuery.isNotEmpty) {
          await _performSearch();
      } else {
          await _fetchTraces();
      }
      state = state.copyWith(isScanning: false);
  }
}

final mapViewModelProvider = StateNotifierProvider<MapViewModel, MapState>((ref) {
  return MapViewModel(ref.read(traceRepositoryProvider));
});
