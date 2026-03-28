import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_developer_assessment/exercises/exercise_3_room_screen_mini.dart';
import 'package:flutter_developer_assessment/exercises/exercise_5_performance_analysis.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Bloc Audit Demo',
      home: RoomScreenMini(roomId: 1),
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}

// ==================== OPTIONAL: MainLayout Demo ====================
class MainLayoutDemo extends StatelessWidget {
  const MainLayoutDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const MainLayout(),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onTap: (_) {},
      ),
    );
  }
}

class FetchUserDataBloc extends Bloc<dynamic, dynamic> {
  FetchUserDataBloc() : super(null);
}

class LayoutBloc extends Bloc<dynamic, dynamic> {
  LayoutBloc() : super(null);
}

class HomeBloc extends Bloc<dynamic, dynamic> {
  HomeBloc() : super(null);
}
