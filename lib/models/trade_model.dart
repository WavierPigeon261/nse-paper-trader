enum OrderType { market, limit }
enum OrderAction { buy, sell }
enum OrderStatus { pending, executed, cancelled }

class Ticker {
  final String symbol;
  final String name;
  double currentPrice;
  double previousClose;
  List<double> priceHistory;

  Ticker({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.previousClose,
    List<double>? priceHistory,
  }) : priceHistory = priceHistory ?? [currentPrice];

  double get change => currentPrice - previousClose;
  double get percentageChange => (change / previousClose) * 100;
}

class Position {
  final String symbol;
  int quantity;
  double averageBuyPrice;

  Position({
    required this.symbol,
    required this.quantity,
    required this.averageBuyPrice,
  });

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'quantity': quantity,
    'averageBuyPrice': averageBuyPrice,
  };

  factory Position.fromJson(Map<String, dynamic> json) => Position(
    symbol: json['symbol'],
    quantity: json['quantity'],
    averageBuyPrice: (json['averageBuyPrice'] as num).toDouble(),
  );
}

class TradeOrder {
  final String id;
  final String symbol;
  final OrderAction action;
  final OrderType type;
  final int quantity;
  final double price; // Executed price for market, target price for limit
  final DateTime timestamp;
  OrderStatus status;

  TradeOrder({
    required this.id,
    required this.symbol,
    required this.action,
    required this.type,
    required this.quantity,
    required this.price,
    required this.timestamp,
    this.status = OrderStatus.pending,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'symbol': symbol,
    'action': action.index,
    'type': type.index,
    'quantity': quantity,
    'price': price,
    'timestamp': timestamp.toIso8601String(),
    'status': status.index,
  };

  factory TradeOrder.fromJson(Map<String, dynamic> json) => TradeOrder(
    id: json['id'],
    symbol: json['symbol'],
    action: OrderAction.values[json['action']],
    type: OrderType.values[json['type']],
    quantity: json['quantity'],
    price: (json['price'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp']),
    status: OrderStatus.values[json['status']],
  );
}