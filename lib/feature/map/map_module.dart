import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lockguard/feature/map/presentation/pages/map.dart';
import 'package:lockguard/feature/map/presentation/pages/history.dart';
import 'package:lockguard/core/services/osrm_services.dart';
import 'data/repositories/map_repository_impl.dart';
import 'domain/repositories/map_repository.dart';
import 'presentation/cubit/map/map_cubit.dart';
import 'presentation/cubit/history/history_cubit.dart';
import 'presentation/cubit/routing/routing_cubit.dart';

class MapModule extends Module {
  @override
  void binds(Injector i) {
    i.add<MapRepository>(() => MapRepositoryImpl());
    i.add<OSRMService>(() => OSRMService());
    i.add<MapCubit>(
        () => MapCubit(i.get<MapRepository>(), i.get<OSRMService>()));
    i.add<HistoryCubit>(() => HistoryCubit(i.get<MapRepository>()));
    i.add<RoutingCubit>(() => RoutingCubit(i.get<OSRMService>()));
  }

  @override
  void routes(RouteManager r) {
    r.child('/',
        child: (context) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: Modular.get<MapCubit>()),
                BlocProvider.value(value: Modular.get<RoutingCubit>()),
              ],
              child: const MapPage(),
            ));
    r.child('/history',
        child: (context) => BlocProvider.value(
              value: Modular.get<HistoryCubit>(),
              child: const HistoryPage(),
            ));
  }
}
