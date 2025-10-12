import 'package:flutter_modular/flutter_modular.dart';
import 'package:lockguard/feature/auth/auth_module.dart';
import 'package:lockguard/feature/home/home_module.dart';
import 'package:lockguard/feature/map/map_module.dart';

class AppModule extends Module {
  @override
  void binds(Injector i) {
    super.binds(i);
  }

  @override
  List<Module> get imports => [
        AuthModule(),
        HomeModule(),
        MapModule(),
      ];

  @override
  void routes(RouteManager r) {
    r.module('/auth', module: AuthModule());
    r.module('/home', module: HomeModule());
    r.module('/map', module: MapModule());
    r.redirect('/', to: '/auth/');
  }
}
