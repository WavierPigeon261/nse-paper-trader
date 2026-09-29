import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/market_engine.dart';
import '../models/trade_model.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFormatter = DateFormat('dd MMM, HH:mm:ss');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Orders & Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            indicatorColor: Color(0xFF06B6D4),
            tabs: [
              Tab(text: 'PENDING LIMIT ORDERS'),
              Tab(text: 'EXECUTION HISTORY'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Pending Orders Tab
            Consumer<MarketEngine>(
              builder: (context, market, child) {
                if (market.pendingOrders.isEmpty) {
                  return const Center(child: Text('No pending limit orders.', style: TextStyle(color: Color(0xFF94A3B8))));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: market.pendingOrders.length,
                  itemBuilder: (context, index) {
                    final order = market.pendingOrders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text('${order.action.name.toUpperCase()} ${order.symbol} x ${order.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text('Target: ${currencyFormatter.format(order.price)}\n${dateFormatter.format(order.timestamp)}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        trailing: TextButton(
                          onPressed: () => market.cancelOrder(order.id),
                          child: const Text('CANCEL', style: TextStyle(color: Color(0xFFEF4444))),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            // Order History Tab
            Consumer<MarketEngine>(
              builder: (context, market, child) {
                if (market.orderHistory.isEmpty) {
                  return const Center(child: Text('No historical trades.', style: TextStyle(color: Color(0xFF94A3B8))));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: market.orderHistory.length,
                  itemBuilder: (context, index) {
                    final order = market.orderHistory[index];
                    final isBuy = order.action == OrderAction.buy;
                    final statusColor = order.status == OrderStatus.executed
                        ? (isBuy ? const Color(0xFF10B981) : const Color(0xFF06B6D4))
                        : const Color(0xFFEF4444);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.2),
                          child: Text(
                            order.action.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text('${order.symbol} (${order.type.name.toUpperCase()})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text('${dateFormatter.format(order.timestamp)}\nQty: ${order.quantity} @ ${currencyFormatter.format(order.price)}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        trailing: Text(
                          order.status.name.toUpperCase(),
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
