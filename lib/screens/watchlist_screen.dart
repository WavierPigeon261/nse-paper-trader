import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/market_engine.dart';
import '../models/trade_model.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final market = Provider.of<MarketEngine>(context);
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Watchlist', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: market.tickers.length,
        itemBuilder: (context, index) {
          final ticker = market.tickers[index];
          final isPositive = ticker.change >= 0;
          final color = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showOrderSheet(context, ticker),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticker.symbol,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ticker.name,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: CustomPaint(
                        size: const Size(60, 30),
                        painter: SparklinePainter(ticker.priceHistory, color),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormatter.format(ticker.currentPrice),
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${isPositive ? "+" : ""}${ticker.change.toStringAsFixed(2)} (${ticker.percentageChange.toStringAsFixed(2)}%)',
                            style: TextStyle(fontSize: 12, color: color),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showOrderSheet(BuildContext context, Ticker ticker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => OrderSheet(ticker: ticker),
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> prices;
  final Color color;

  SparklinePainter(this.prices, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final priceRange = (maxPrice - minPrice) == 0 ? 1 : (maxPrice - minPrice);

    final path = Path();
    final widthStep = size.width / (prices.length - 1);

    for (int i = 0; i < prices.length; i++) {
      final x = i * widthStep;
      final normalizedPrice = (prices[i] - minPrice) / priceRange;
      final y = size.height - (normalizedPrice * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class OrderSheet extends StatefulWidget {
  final Ticker ticker;
  const OrderSheet({super.key, required this.ticker});

  @override
  State<OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends State<OrderSheet> {
  OrderAction _action = OrderAction.buy;
  OrderType _type = OrderType.market;
  final _quantityController = TextEditingController(text: '1');
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.ticker.currentPrice.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final market = Provider.of<MarketEngine>(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.ticker.symbol} - Trade Order',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _action == OrderAction.buy ? const Color(0xFF10B981) : Colors.grey[800],
                  ),
                  onPressed: () => setState(() => _action = OrderAction.buy),
                  child: const Text('BUY'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _action == OrderAction.sell ? const Color(0xFFEF4444) : Colors.grey[800],
                  ),
                  onPressed: () => setState(() => _action = OrderAction.sell),
                  child: const Text('SELL'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<OrderType>(
            segments: const [
              ButtonSegment(value: OrderType.market, label: Text('MARKET')),
              ButtonSegment(value: OrderType.limit, label: Text('LIMIT')),
            ],
            selected: {_type},
            onSelectionChanged: (set) => setState(() => _type = set.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Quantity',
              border: OutlineInputBorder(),
            ),
          ),
          if (_type == OrderType.limit) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Target Limit Price (₹)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: const Color(0xFF06B6D4),
            ),
            onPressed: () {
              final quantity = int.tryParse(_quantityController.text) ?? 0;
              final limitPrice = double.tryParse(_priceController.text) ?? 0.0;

              if (quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid quantity!')),
                );
                return;
              }

              final error = market.placeOrder(
                symbol: widget.ticker.symbol,
                action: _action,
                type: _type,
                quantity: quantity,
                limitPrice: limitPrice,
              );

              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error), backgroundColor: const Color(0xFFEF4444)),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order Submitted Successfully!'), backgroundColor: Color(0xFF10B981)),
                );
              }
            },
            child: const Text('Confirm Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
