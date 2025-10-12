part of 'map_cubit.dart';

abstract class MapState {
  const MapState();
}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

class MapDataLoaded extends MapState {
  final MapData mapData;
  const MapDataLoaded({required this.mapData});

  MapDataLoaded copyWith({MapData? mapData}) {
    return MapDataLoaded(mapData: mapData ?? this.mapData);
  }
}

class MapError extends MapState {
  final String message;
  const MapError(this.message);
}
