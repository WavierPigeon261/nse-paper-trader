import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trade_model.dart';

class MarketEngine extends ChangeNotifier {
  static const double initialCash = 1000000.0; // ₹10,00,000

  double _cashBalance = initialCash;
  final Map<String, Position> _positions = {};
  final List<TradeOrder> _pendingOrders = [];
  final List<TradeOrder> _orderHistory = [];
  Timer? _tickTimer;
  final Random _random = Random();

  double get cashBalance => _cashBalance;
  List<Position> get positions => _positions.values.toList();
  List<TradeOrder> get pendingOrders => List.unmodifiable(_pendingOrders);
  List<TradeOrder> get orderHistory => List.unmodifiable(_orderHistory);

  final List<Ticker> _tickers = [
    Ticker(symbol: 'NIFTY 50', name: 'Nifty 50 Index', currentPrice: 24000.0, previousClose: 24000.0),
    Ticker(symbol: 'BANKNIFTY', name: 'Nifty Bank Index', currentPrice: 52000.0, previousClose: 52000.0),
    Ticker(symbol: 'RELIANCE', name: 'Reliance Industries', currentPrice: 2500.0, previousClose: 2500.0),
    Ticker(symbol: 'TCS', name: 'Tata Consultancy Services', currentPrice: 4200.0, previousClose: 4200.0),
    Ticker(symbol: 'HDFCBANK', name: 'HDFC Bank Ltd', currentPrice: 1600.0, previousClose: 1600.0),
  ];

  List<Ticker> get tickers => List.unmodifiable(_tickers);

  MarketEngine() {
    _initializeData();
    _startMarketFeed();
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load cash balance
    _cashBalance = prefs.getDouble('cash_balance') ?? initialCash;

    // Load positions
    final positionsJson = prefs.getString('positions');
    if (positionsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(positionsJson);
      decoded.forEach((key, value) {
        _positions[key] = Position.fromJson(value);
      });
    }

    // Load pending orders
    final pendingJson = prefs.getString('pending_orders');
    if (pendingJson != null) {
      final List<dynamic> decoded = jsonDecode(pendingJson);
      _pendingOrders.addAll(decoded.map((e) => TradeOrder.fromJson(e)).toList());
    }

    // Load history
    final historyJson = prefs.getString('order_history');
    if (historyJson != null) {
      final List<dynamic> decoded = jsonDecode(historyJson);
      _orderHistory.addAll(decoded.map((e) => TradeOrder.fromJson(e)).toList());
    }

    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('cash_balance', _cashBalance);
    
    final positionsMap = _positions.map((key, value) => MapEntry(key, value.toJson()));
    await prefs.setString('positions', jsonEncode(positionsMap));

    final pendingList = _pendingOrders.map((e) => e.toJson()).toList();
    await prefs.setString('pending_orders', jsonEncode(pendingList));

    final historyList = _orderHistory.map((e) => e.toJson()).toList();
    await prefs.setString('order_history', jsonEncode(historyList));
  }

  void _startMarketFeed() {
    _tickTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _simulateMarketTick();
    });
  }

  void _simulateMarketTick() {
    for (var ticker in _tickers) {
      // Fluctuate price between -0.2% and +0.2%
      double factor = 1 + (_random.nextDouble() * 0.004 - 0.002);
      ticker.currentPrice = double.parse((ticker.currentPrice * factor).toStringAsFixed(2));
      
      ticker.priceHistory.add(ticker.currentPrice);
      if (ticker.priceHistory.length > 20) {
        ticker.priceHistory.removeAt(0);
      }
    }
    _checkLimitOrders();
    notifyListeners();
  }

  void _checkLimitOrders() {
    final List<TradeOrder> executedOrders = [];

    for (var order in List<TradeOrder>.from(_pendingOrders)) {
      final ticker = _tickers.firstWhere((t) => t.symbol == order.symbol);
      bool execute = false;

      if (order.action == OrderAction.buy && ticker.currentPrice <= order.price) {
        execute = true;
      } else if (order.action == OrderAction.sell && ticker.currentPrice >= order.price) {
        execute = true;
      }

      if (execute) {
        _executeTrade(order, ticker.currentPrice);
        executedOrders.add(order);
      }
    }

    for (var order in executedOrders) {
      _pendingOrders.remove(order);
    }

    if (executedOrders.isNotEmpty) {
      _saveData();
    }
  }

  String? placeOrder({
    required String symbol,
    required OrderAction action,
    required OrderType type,
    required int quantity,
    required double limitPrice,
  }) {
    final ticker = _tickers.firstWhere((t) => t.symbol == symbol);
    final double executionPrice = type == OrderType.market ? ticker.currentPrice : limitPrice;
    final double totalCost = executionPrice * quantity;

    if (action == OrderAction.buy) {
      if (_cashBalance < totalCost) {
        return 'Insufficient Cash Balance! Required: ₹${totalCost.toStringAsFixed(2)}';
      }
    } else {
      final pos = _positions[symbol];
      if (pos == null || pos.quantity < quantity) {
        return 'Insufficient Shares Held! Owned: ${pos?.quantity ?? 0}';
      }
    }

    final order = TradeOrder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      symbol: symbol,
      action: action,
      type: type,
      quantity: quantity,
      price: executionPrice,
      timestamp: DateTime.now(),
      status: type == OrderType.market ? OrderStatus.executed : OrderStatus.pending,
    );

    if (type == OrderType.market) {
      _executeTrade(order, ticker.currentPrice);
    } else {
      _pendingOrders.add(order);
    }

    _saveData();
    notifyListeners();
    return null; // Null means success
  }

  void _executeTrade(TradeOrder order, double executionPrice) {
    order.status = OrderStatus.executed;
    final double totalValue = executionPrice * order.quantity;

    if (order.action == OrderAction.buy) {
      _cashBalance -= totalValue;
      if (_positions.containsKey(order.symbol)) {
        final existing = _positions[order.symbol]!;
        int newQty = existing.quantity + order.quantity;
        double newAvg = ((existing.averageBuyPrice * existing.quantity) + totalValue) / newQty;
        existing.quantity = newQty;
        existing.averageBuyPrice = newAvg;
      } else {
        _positions[order.symbol] = Position(
          symbol: order.symbol,
          quantity: order.quantity,
          averageBuyPrice: executionPrice,
        );
      }
    } else {
      _cashBalance += totalValue;
      if (_positions.containsKey(order.symbol)) {
        final existing = _positions[order.symbol]!;
        existing.quantity -= order.quantity;
        if (existing.quantity <= 0) {
          _positions.remove(order.symbol);
        }
      }
    }

    _orderHistory.insert(0, order);
  }

  void cancelOrder(String id) {
    final order = _pendingOrders.firstWhere((o) => o.id == id);
    order.status = OrderStatus.cancelled;
    _pendingOrders.remove(order);
    _orderHistory.insert(0, order);
    _saveData();
    notifyListeners();
  }

  Future<void> resetDatabase() async {
    _cashBalance = initialCash;
    _positions.clear();
    _pendingOrders.clear();
    _orderHistory.clear();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    notifyListeners();
  }

  // Analytics Engine
  double get totalHoldingsValue {
    double total = 0.0;
    _positions.forEach((symbol, pos) {
      final ticker = _tickers.firstWhere((t) => t.symbol == symbol, orElse: () => Ticker(symbol: '', name: '', currentPrice: 0, previousClose: 0));
      total += pos.quantity * ticker.currentPrice;
    });
    return total;
  }

  double get totalAccountValue => _cashBalance + totalHoldingsValue;
  double get totalPnL => totalAccountValue - initialCash;

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }
}
