import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/market_engine.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final market = Provider.of<MarketEngine>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control Panel', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Database & Local Data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF06B6D4)),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.restore, color: Color(0xFFEF4444)),
                title: const Text('Reset Simulation Database', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Wipes out all history, positions, and restores cash balance back to ₹10,00,000.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                onTap: () => _confirmReset(context, market),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, MarketEngine market) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Confirm Database Wipe', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to reset your local wallet? All active orders and position logs will be permanently deleted.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              await market.resetDatabase();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Database reset to ₹10,00,000 initial balance!')),
                );
              }
            },
            child: const Text('RESET', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
