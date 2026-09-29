import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/market_engine.dart';
import 'screens/dashboard_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => MarketEngine(),
      child: const PaperTradingApp(),
    ),
  );
}

class PaperTradingApp extends StatelessWidget {
  const PaperTradingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NSE Paper Trader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        cardColor: const Color(0xFF1E293B),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF06B6D4),
          surface: Color(0xFF1E293B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B0F19),
          elevation: 0,
        ),
      ),
      home: const DashboardShell(),
    );
  }
}
