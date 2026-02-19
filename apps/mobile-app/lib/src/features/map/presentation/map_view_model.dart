import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../data/trace_repository.dart';
import '../data/geocoding_repository.dart';

// State
class MapState {
  final LatLng center;
  final LatLngBounds? bounds;
  final String searchQuery;
  final List<String> activeFilters;
  final List<dynamic> traces;
  final List<PlaceResult> placeSuggestions;
  final PlaceResult? selectedPlace;
  final bool isLoading;
  final bool isScanning;

  MapState({
    required this.center,
    this.bounds,
    this.searchQuery = '',
    this.activeFilters = const [],
    this.traces = const [],
    this.placeSuggestions = const [],
    this.selectedPlace,
    this.isLoading = false,
    this.isScanning = false,
  });

  MapState copyWith({
    LatLng? center,
    LatLngBounds? bounds,
    String? searchQuery,
    List<String>? activeFilters,
    List<dynamic>? traces,
    List<PlaceResult>? placeSuggestions,
    PlaceResult? selectedPlace,
    bool? isLoading,
    bool? isScanning,
  }) {
    return MapState(
      center: center ?? this.center,
      bounds: bounds ?? this.bounds,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilters: activeFilters ?? this.activeFilters,
      traces: traces ?? this.traces,
      placeSuggestions: placeSuggestions ?? this.placeSuggestions,
      selectedPlace: selectedPlace ?? this.selectedPlace,
      isLoading: isLoading ?? this.isLoading,
      isScanning: isScanning ?? this.isScanning,
    );
  }
}

// ViewModel
class MapViewModel extends StateNotifier<MapState> {
  final TraceRepository _repo;
  final GeocodingRepository _geoRepo;

  MapViewModel(this._repo, this._geoRepo) : super(MapState(center: const LatLng(0, 0)));

  void updateBounds(LatLngBounds bounds) {
    if (state.bounds != bounds) {
       state = state.copyWith(bounds: bounds);
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
      state = state.copyWith(placeSuggestions: [], selectedPlace: null);
      _fetchTraces();
    }
  }
  
  void selectPlace(PlaceResult place) {
    state = state.copyWith(
      selectedPlace: place,
      center: place.location,
      placeSuggestions: [], // Clear suggestions on selection
      searchQuery: place.displayName.split(',')[0], // Shorten for display
    );
    // When a place is selected, we should also fetch traces around IT
    _fetchTracesAround(place.location);
  }
  
  void clearSelection() {
    state = state.copyWith(selectedPlace: null, searchQuery: '');
    _fetchTraces(); // Revert to bounds-based fetching
  }

  void toggleFilter(String filter) {
    final current = List<String>.from(state.activeFilters);
    if (current.contains(filter)) {
      current.remove(filter);
    } else {
      current.add(filter);
    }
    state = state.copyWith(activeFilters: current);
  }

  Future<void> _fetchTraces() async {
    if (state.bounds == null) return;
    if (state.selectedPlace != null) return; // Don't overwrite if looking at a specific place result

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
  
  Future<void> _fetchTracesAround(LatLng location) async {
    state = state.copyWith(isLoading: true);
    try {
        final traces = await _repo.getNearby(location.latitude, location.longitude, radius: 2000);
        state = state.copyWith(traces: traces, isLoading: false);
    } catch(e) {
        state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _performSearch() async {
    // Hybrid Search: Traces (AI) + Places (Geocoding)
    state = state.copyWith(isLoading: true);
    
    try {
      // 1. Search Places (Geocoding) - Parallel
      final placeFuture = _geoRepo.searchPlaces(state.searchQuery);
      
      // 2. Search Traces (Contextual/Vector) - Parallel
      // We use a wider radius for global search suggestions
      final traceFuture = _repo.search(state.searchQuery, state.center.latitude, state.center.longitude);

      final results = await Future.wait([placeFuture, traceFuture]);
      final places = results[0] as List<PlaceResult>;
      final traces = results[1] as List<dynamic>;

      // Map Traces to PlaceResults for the suggestion list
      final traceSuggestions = traces.take(5).map((t) {
        return PlaceResult(
          displayName: "Trace: ${t['content']?['text'] ?? 'Memory'} near you", 
          location: LatLng((t['lat'] as num).toDouble(), (t['long'] as num).toDouble()),
          type: 'trace'
        );
      }).toList();

      // Combine: Traces first (high relevance local), then Places (global)
      final combined = [...traceSuggestions, ...places];
      
      state = state.copyWith(
        traces: traces, // Still update the map markers
        placeSuggestions: combined,
        isLoading: false
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
  
  Future<void> scanArea() async {
      state = state.copyWith(isScanning: true);
      await Future.delayed(const Duration(seconds: 1)); // UX delay
      if (state.selectedPlace != null) {
          await _fetchTracesAround(state.selectedPlace!.location);
      } else {
          await _fetchTraces();
      }
      state = state.copyWith(isScanning: false);
  }
}

final mapViewModelProvider = StateNotifierProvider<MapViewModel, MapState>((ref) {
  return MapViewModel(ref.read(traceRepositoryProvider), ref.read(geocodingRepositoryProvider));
});
