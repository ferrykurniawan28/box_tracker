import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lockguard/feature/profile/presentation/pages/profile.dart';
import 'presentation/pages/home.dart';
import 'presentation/cubit/home_cubit.dart';
import 'package:lockguard/feature/map/presentation/pages/map.dart';
import 'package:lockguard/feature/map/presentation/pages/history.dart';
import 'package:lockguard/feature/map/presentation/cubit/map/map_cubit.dart';
import 'package:lockguard/feature/map/presentation/cubit/history/history_cubit.dart';
import 'package:lockguard/feature/map/presentation/cubit/routing/routing_cubit.dart';
import 'package:lockguard/feature/map/domain/repositories/map_repository.dart';
import 'package:lockguard/core/services/osrm_services.dart';
import 'package:lockguard/feature/auth/presentation/cubit/auth_cubit.dart';

class HomeModule extends Module {
  @override
  void binds(Injector i) {
    i.addSingleton<HomeCubit>(() => HomeCubit());
    i.addSingleton<OSRMService>(() => OSRMService());
    i.addSingleton<MapCubit>(() =>
        MapCubit(Modular.get<MapRepository>(), Modular.get<OSRMService>()));
    i.addSingleton<HistoryCubit>(
        () => HistoryCubit(Modular.get<MapRepository>()));
    i.addSingleton<RoutingCubit>(
        () => RoutingCubit(Modular.get<OSRMService>()));
  }

  @override
  void routes(RouteManager r) {
    r.child('/',
        child: (context) => BlocProvider.value(
              value: Modular.get<HomeCubit>(),
              child: const HomePage(),
            ),
        children: [
          ChildRoute('/map',
              child: (context) => BlocProvider.value(
                    value: Modular.get<MapCubit>(),
                    child: const MapPage(),
                  )),
          ChildRoute('/history',
              child: (context) => BlocProvider(
                    create: (_) => Modular.get<HistoryCubit>(),
                    child: const HistoryPage(),
                  )),
          ChildRoute('/profile',
              child: (context) => BlocProvider.value(
                    value: Modular.get<AuthCubit>(),
                    child: const ProfilePage(),
                  )),
        ]);
  }
}
