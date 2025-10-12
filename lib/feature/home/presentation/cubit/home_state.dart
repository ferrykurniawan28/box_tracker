part of 'home_cubit.dart';

abstract class HomeState {
  const HomeState();
}

class HomeInitial extends HomeState {}

class HomeTabChanged extends HomeState {
  final int currentIndex;
  const HomeTabChanged(this.currentIndex);
}
