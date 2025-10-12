import 'package:bloc/bloc.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeTabChanged(0)); // Start with Map tab

  void changeTab(int index) {
    emit(HomeTabChanged(index));
  }
}
