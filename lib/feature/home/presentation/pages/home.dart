import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:lockguard/feature/auth/presentation/cubit/auth_cubit.dart';
import '../cubit/home_cubit.dart';

class HomePage extends StatefulWidget {
  const HomePage();

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Navigate to the initial route (Map)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Modular.to.navigate('/home/map');
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final currentIndex = state is HomeTabChanged ? state.currentIndex : 0;

        return Scaffold(
          body: RouterOutlet(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) {
              switch (index) {
                case 0:
                  Modular.to.navigate('/home/map');
                  ReadContext(context).read<HomeCubit>().changeTab(0);
                  break;
                case 1:
                  Modular.to.navigate('/home/history');
                  ReadContext(context).read<HomeCubit>().changeTab(1);
                  break;
                case 2:
                  Modular.to.navigate('/home/account');
                  ReadContext(context).read<HomeCubit>().changeTab(2);
                  break;
                // case 3:
                //   Modular.to.navigate('/home/account');
                //   ReadContext(context).read<HomeCubit>().changeTab(3);
                //   break;
              }
            },
            backgroundColor: Colors.black,
            selectedItemColor: Colors.blueAccent,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.history), label: 'History'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.account_circle), label: 'Account'),
            ],
          ),
        );
      },
    );
  }
}

// class _DashboardPage extends StatelessWidget {
//   const _DashboardPage();

//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.dashboard, size: 80, color: Colors.blue),
//             SizedBox(height: 20),
//             Text(
//               'Dashboard',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             Text('Welcome to LockGuard Dashboard!'),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _HistoryPage extends StatelessWidget {
//   const _HistoryPage();

//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.history, size: 80, color: Colors.orange),
//             SizedBox(height: 20),
//             Text(
//               'History',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             Text('Your tracking history will appear here.'),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _AccountPage extends StatelessWidget {
//   const _AccountPage();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.account_circle, size: 80, color: Colors.green),
//             const SizedBox(height: 20),
//             const Text(
//               'Account',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const Text('Your account settings and profile.'),
//             const SizedBox(height: 40),
//             ElevatedButton(
//               onPressed: () {
//                 Modular.get<AuthCubit>().signOut();
//                 Modular.to.navigate('/auth/');
//               },
//               child: const Text('Sign Out'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
