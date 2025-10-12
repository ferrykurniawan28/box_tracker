import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:lockguard/core/services/osrm_services.dart';
import 'package:meta/meta.dart';

part 'routing_state.dart';

class RoutingCubit extends Cubit<RoutingState> {
  final OSRMService _osrmService;
  Timer? _debounceTimer;

  RoutingCubit(this._osrmService) : super(RoutingInitial());

  Future<void> calculateRoute({
    required LatLng start,
    required LatLng end,
    OSRMProfile profile = OSRMProfile.driving,
    List<LatLng>? waypoints,
    bool debounce = true,
  }) async {
    // Cancel previous debounced call
    if (debounce) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
        await _performRouteCalculation(start, end, profile, waypoints);
      });
    } else {
      await _performRouteCalculation(start, end, profile, waypoints);
    }
  }

  Future<void> _performRouteCalculation(
    LatLng start,
    LatLng end,
    OSRMProfile profile,
    List<LatLng>? waypoints,
  ) async {
    emit(RoutingLoading());

    try {
      final routeResponse = await _osrmService.getRoute(
        start: start,
        end: end,
        profile: profile,
        waypoints: waypoints,
      );

      if (routeResponse.isSuccess) {
        emit(RoutingLoaded(routeResponse: routeResponse));
      } else {
        emit(RoutingError(message: 'No route found: ${routeResponse.code}'));
      }
    } catch (e) {
      emit(RoutingError(message: e.toString()));
    }
  }

  Future<void> calculateMultipleRoutes({
    required LatLng start,
    required List<LatLng> destinations,
    OSRMProfile profile = OSRMProfile.driving,
  }) async {
    emit(RoutingLoading());

    try {
      final routes = await _osrmService.getMultipleRoutes(
        start: start,
        destinations: destinations,
        profile: profile,
      );

      if (routes.isNotEmpty) {
        emit(MultipleRoutesLoaded(routes: routes));
      } else {
        emit(RoutingError(message: 'No routes found to any destination'));
      }
    } catch (e) {
      emit(RoutingError(message: e.toString()));
    }
  }

  void clearRoute() {
    emit(RoutingInitial());
  }

  void selectRoute(OSRMRouteResponse route) {
    if (state is MultipleRoutesLoaded) {
      emit(RoutingLoaded(routeResponse: route));
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _osrmService.dispose();
    return super.close();
  }
}
