part of 'routing_cubit.dart';

@immutable
sealed class RoutingState {}

final class RoutingInitial extends RoutingState {}

final class RoutingLoading extends RoutingState {}

final class RoutingLoaded extends RoutingState {
  final OSRMRouteResponse routeResponse;

  RoutingLoaded({required this.routeResponse});
}

final class RoutingError extends RoutingState {
  final String message;

  RoutingError({required this.message});
}

final class RoutingNoRoute extends RoutingState {}

final class MultipleRoutesLoaded extends RoutingState {
  final List<OSRMRouteResponse> routes;

  MultipleRoutesLoaded({required this.routes});
}
