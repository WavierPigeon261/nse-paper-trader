import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/market_engine.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final market = Provider.of<MarketEngine>(context);
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final isPnLPositive = market.totalPnL >= 0;
    final pnlColor = isPnLPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio & P&L', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Executive Summary Banner
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: pnlColor..withValues(alpha: 0.3), width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Account Value', style: TextStyle(color: Color(0xFF94A3B8))),
                    Text(
                      currencyFormatter.format(market.totalAccountValue),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFF334155)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Available Cash', style: TextStyle(color: Color(0xFF94A3B8))),
                    Text(
                      currencyFormatter.format(market.cashBalance),
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Net Realized + Unrealized P&L', style: TextStyle(color: Color(0xFF94A3B8))),
                    Text(
                      '${isPnLPositive ? "+" : ""}${currencyFormatter.format(market.totalPnL)}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: pnlColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Active Holdings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          Expanded(
            child: market.positions.isEmpty
                ? const Center(child: Text('No active positions held.', style: TextStyle(color: Color(0xFF94A3B8))))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: market.positions.length,
                    itemBuilder: (context, index) {
                      final position = market.positions[index];
                      final ticker = market.tickers.firstWhere((t) => t.symbol == position.symbol);
                      final currentValue = position.quantity * ticker.currentPrice;
                      final investedValue = position.quantity * position.averageBuyPrice;
                      final pnl = currentValue - investedValue;
                      final posPnLColor = pnl >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(position.symbol, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                  Text(
                                    '${pnl >= 0 ? "+" : ""}${currencyFormatter.format(pnl)}',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: posPnLColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Qty: ${position.quantity}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                                  Text('Avg: ${currencyFormatter.format(position.averageBuyPrice)}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                                  Text('LTP: ${currencyFormatter.format(ticker.currentPrice)}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
