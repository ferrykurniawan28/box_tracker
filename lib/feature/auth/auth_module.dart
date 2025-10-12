import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'presentation/cubit/auth_cubit.dart';
import 'presentation/widgets/auth_checker.dart';
import 'presentation/pages/login.dart';
import 'presentation/pages/register.dart';

class AuthModule extends Module {
  @override
  void binds(Injector i) {
    i.addSingleton<FirebaseAuth>(() => FirebaseAuth.instance);
    i.addSingleton<AuthRepository>(
        () => AuthRepositoryImpl(i.get<FirebaseAuth>()));
    i.addSingleton<AuthCubit>(() => AuthCubit(i.get<AuthRepository>()));
  }

  @override
  void routes(RouteManager r) {
    r.child('/',
        child: (context) => BlocProvider.value(
              value: Modular.get<AuthCubit>(),
              child: const AuthChecker(),
            ));
    r.child('/login',
        child: (context) => BlocProvider.value(
              value: Modular.get<AuthCubit>(),
              child: const LoginPage(),
            ));
    r.child('/register',
        child: (context) => BlocProvider.value(
              value: Modular.get<AuthCubit>(),
              child: const RegisterPage(),
            ));
  }
}
