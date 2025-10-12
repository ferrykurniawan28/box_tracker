import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lockguard/feature/auth/domain/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(AuthInitial()) {
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    _authRepository.authStateChanges().listen((user) {
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    emit(AuthLoading());
    try {
      await _authRepository.signInWithEmailAndPassword(email, password);
      // State will be updated via stream listener
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signUp(String email, String password) async {
    emit(AuthLoading());
    try {
      await _authRepository.createUserWithEmailAndPassword(email, password);
      // State will be updated via stream listener
    } catch (e) {
      emit(AuthError(e.toString()));
      // Revert to unauthenticated state after error
      Future.delayed(const Duration(seconds: 2), () {
        emit(AuthUnauthenticated());
      });
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    try {
      await _authRepository.signOut();
      // State will be updated via stream listener
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
