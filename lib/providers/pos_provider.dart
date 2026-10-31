import 'package:flutter/foundation.dart' hide Category;
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/mock_seed_service.dart';

class PosProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  String? _currentShopId;
  Shop? _shop;
  List<Member> _members = [];
  Member? _currentMember;
  List<Invite> _invites = [];
  List<Artist> _artists = [];
  List<Category> _categories = [];
  List<Product> _products = [];
  List<Event> _events = [];
  Event? _activeEvent;
  List<String> _activeEventArtistIds = [];
  List<Order> _orders = [];

  // Folder navigation state (max 2 levels)
  String? _currentFolderId;
  bool _isAllItemsView = false;

  // Cart & POS state
  final List<CartItem> _cart = [];
  String _searchQuery = '';
  bool _isSyncing = false;

  // Getters
  String? get currentShopId => _currentShopId;
  List<Shop> get allShops => _db.getShops();
  Shop? get shop => _shop;
  List<Member> get members => _members;
  Member? get currentMember => _currentMember;
  bool get isOwner => _currentMember == null ? true : _currentMember?.role == MemberRole.owner;
  bool get isManager => _currentMember?.role == MemberRole.manager;
  bool get isManagerUp => isOwner || isManager;
  bool get isMember => _currentMember?.role == MemberRole.member;

  bool get canVoid => isManagerUp;
  bool get canManageCatalog => isManagerUp;
  bool get canViewSettlement => isOwner;
  bool get canViewSettings => isOwner;

  List<Invite> get invites => _invites;
  List<Artist> get artists => _artists;
  List<Category> get categories => _categories;
  List<Product> get products => _products;
  List<Event> get events => _events;
  Event? get activeEvent => _activeEvent;
  List<String> get activeEventArtistIds => _activeEventArtistIds;

  // v1.7: Member sees only orders created by themselves; Owner/Manager see all shop orders
  List<Order> get orders {
    if (isMember && _currentMember != null) {
      return _orders.where((o) => o.createdBy == _currentMember!.userId).toList();
    }
    return _orders;
  }
  List<Order> get allShopOrders => _orders;

  List<CartItem> get cart => List.unmodifiable(_cart);
  String? get currentFolderId => _currentFolderId;
  bool get isAllItemsView => _isAllItemsView;
  String get searchQuery => _searchQuery;
  bool get isSyncing => _isSyncing;

  int get unsyncedCount => _orders.where((o) => !o.synced).length;

  // Initialize Provider
  Future<void> init() async {
    await _db.init();
    refreshData();
  }

  /// Switch the active shop context (e.g. Shop A vs Shop B)
  void switchShop(String shopId) {
    _currentShopId = shopId;
    _cart.clear();
    _currentFolderId = null;
    _isAllItemsView = false;
    _searchQuery = '';
    _currentMember = null;
    refreshData();
  }

  /// Reset or seed data for testing
  Future<void> seedTestData({bool force = true}) async {
    await MockSeedService.seedAllSampleData(_db, clearExisting: force);
    _currentShopId = 'shop_a';
    refreshData();
  }

  /// Load complete sample seed data for testing & demonstration
  Future<void> loadSampleSeedData() async {
    await MockSeedService.seedAllSampleData(_db, clearExisting: true);
    _currentShopId = 'shop_a';
    refreshData();
  }

  /// Wipe all database tables to a clean, blank slate for real production use
  Future<void> clearAllData() async {
    await _db.clearAllData();
    _currentShopId = null;
    _cart.clear();
    _currentFolderId = null;
    _isAllItemsView = false;
    _searchQuery = '';
    _currentMember = null;
    refreshData();
  }

  void refreshData() {
    final shops = _db.getShops();
    if (shops.isNotEmpty) {
      if (_currentShopId == null || !shops.any((s) => s.id == _currentShopId)) {
        _currentShopId = shops.first.id;
      }
    } else {
      _currentShopId = null;
    }

    _shop = _db.getShop(_currentShopId);
    _members = _db.getMembers(shopId: _currentShopId);
    _currentMember = _members.isNotEmpty
        ? (_currentMember != null
            ? _members.firstWhere((m) => m.id == _currentMember!.id, orElse: () => _members.first)
            : _members.first)
        : null;
    _invites = _db.getInvites(shopId: _currentShopId);
    _artists = _db.getArtists(shopId: _currentShopId);
    _categories = _db.getCategories(shopId: _currentShopId);
    _products = _db.getProducts(shopId: _currentShopId);
    _events = _db.getEvents(shopId: _currentShopId);
    _activeEvent = _db.getActiveEvent(shopId: _currentShopId);
    if (_activeEvent != null) {
      _activeEventArtistIds = _db.getEventArtistIds(_activeEvent!.id);
    } else {
      _activeEventArtistIds = [];
    }
    _orders = _db.getOrders(shopId: _currentShopId);
    notifyListeners();
  }

  // --- Role & Permissions (Requirement 4.7 & 4.8) ---
  void setCurrentMember(Member member) {
    _currentMember = member;
    notifyListeners();
  }

  void toggleRoleForTesting() {
    if (_currentMember == null) return;
    MemberRole newRole;
    switch (_currentMember!.role) {
      case MemberRole.owner:
        newRole = MemberRole.manager;
        break;
      case MemberRole.manager:
        newRole = MemberRole.member;
        break;
      case MemberRole.member:
        newRole = MemberRole.owner;
        break;
    }
    _currentMember = _currentMember!.copyWith(role: newRole);
    notifyListeners();
  }

  /// Visibility rule for product cost (v1.7: Owner sees all; Manager and Member only see linked artist)
  bool canViewCost(Product product) {
    if (isOwner) return true;
    if (_currentMember?.invitedArtistId != null) {
      return product.artistId == _currentMember!.invitedArtistId;
    }
    return false;
  }

  // --- Folder & Category Hierarchy (Requirement 4.3) ---
  Category? get currentFolder {
    if (_currentFolderId == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == _currentFolderId);
    } catch (_) {
      return null;
    }
  }

  /// List of breadcrumbs from root to current folder
  List<Category> get folderBreadcrumbs {
    final list = <Category>[];
    String? cursor = _currentFolderId;
    while (cursor != null) {
      final found = _categories.cast<Category?>().firstWhere(
            (c) => c?.id == cursor,
            orElse: () => null,
          );
      if (found != null) {
        list.insert(0, found);
        cursor = found.parentCategoryId;
      } else {
        break;
      }
    }
    return list;
  }

  List<Category> get currentSubfolders {
    if (_isAllItemsView) return [];
    return _categories
        .where((c) => c.parentCategoryId == _currentFolderId)
        .toList();
  }

  void openFolder(String? folderId) {
    _currentFolderId = folderId;
    _isAllItemsView = false;
    notifyListeners();
  }

  void showAllItems() {
    _isAllItemsView = true;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Filtered Products for POS Touch Grid (considering central catalog active flag, eventProducts, eventArtists, folders, and search)
  List<Product> get filteredProducts {
    return _products.where((p) {
      // 0. Soft delete check (v1.7)
      if (!p.active) return false;

      // 1. Event Artist and Event Product Filtering (v1.7)
      if (_activeEvent != null) {
        if (_activeEventArtistIds.isNotEmpty && !_activeEventArtistIds.contains(p.artistId)) {
          return false; // Hide products of artists not attending this event
        }
        if (_activeEvent!.eventProductIds.isNotEmpty && !_activeEvent!.eventProductIds.contains(p.id)) {
          return false; // Hide products not selected for this event
        }
      }

      // 2. Global Search: if searching, ignore current folder and search across all folders!
      if (_searchQuery.isNotEmpty) {
        return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }

      // 3. Flat "All Items" view
      if (_isAllItemsView) {
        return true;
      }

      // 4. Folder Navigation view
      if (_currentFolderId == null) {
        // At root level: show uncategorized products or products directly at root
        return p.categoryId.isEmpty;
      } else {
        // Inside a folder: show products belonging to this category
        return p.categoryId == _currentFolderId;
      }
    }).toList();
  }

  // Helper to get Artist Name
  String getArtistName(String artistId) {
    try {
      return _artists.firstWhere((a) => a.id == artistId).name;
    } catch (_) {
      return 'Unknown Artist';
    }
  }

  // --- Cart Calculations & Multi-Artist Discounts (Requirement 4.5) ---
  int get totalCartQty => _cart.fold(0, (sum, item) => sum + item.qty);

  double get cartSubtotal =>
      _cart.fold(0.0, (sum, item) => sum + (item.product.price * item.qty));

  double get cartDiscount =>
      _cart.fold(0.0, (sum, item) => sum + item.discount);

  double get cartTotal {
    final t = cartSubtotal - cartDiscount;
    return t > 0 ? t : 0.0;
  }

  void addToCart(Product product) {
    final existingIndex =
        _cart.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      _cart[existingIndex].qty += 1;
    } else {
      _cart.add(CartItem(product: product, qty: 1));
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cart.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateCartQty(String productId, int newQty) {
    final index = _cart.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (newQty <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index].qty = newQty;
        if (_cart[index].discount > _cart[index].product.price * _cart[index].qty) {
          _cart[index].discount = _cart[index].product.price * _cart[index].qty;
        }
      }
      notifyListeners();
    }
  }

  void clearDiscounts() {
    for (var item in _cart) {
      item.discount = 0.0;
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  /// Proportional Whole-Bill Discount (Acceptance Criteria 4.5)
  /// Divides discount across artists proportionally to their gross value in the cart!
  void applyWholeBillDiscount(double totalDiscount) {
    if (cartSubtotal <= 0 || totalDiscount <= 0) {
      clearDiscounts();
      return;
    }

    // Group gross totals by artist
    final artistGrossMap = <String, double>{};
    for (var item in _cart) {
      final gross = item.product.price * item.qty;
      artistGrossMap[item.artistId] = (artistGrossMap[item.artistId] ?? 0.0) + gross;
    }

    // Allocate discount per artist based on share
    for (var item in _cart) {
      final artistShare = (artistGrossMap[item.artistId] ?? 0.0) / cartSubtotal;
      final artistDiscountTotal = totalDiscount * artistShare;
      final itemShareInArtist = (item.product.price * item.qty) / (artistGrossMap[item.artistId] ?? 1.0);
      final allocated = artistDiscountTotal * itemShareInArtist;
      final itemGross = item.product.price * item.qty;
      item.discount = allocated > itemGross ? itemGross : allocated;
    }
    notifyListeners();
  }

  /// Artist-Specific Discount: applies discount ONLY to items belonging to this artist!
  void applyArtistDiscount(String artistId, double discountAmount) {
    if (discountAmount <= 0) {
      for (var item in _cart.where((i) => i.artistId == artistId)) {
        item.discount = 0.0;
      }
      notifyListeners();
      return;
    }

    final artistItems = _cart.where((i) => i.artistId == artistId).toList();
    final artistGross = artistItems.fold(0.0, (s, i) => s + (i.product.price * i.qty));
    if (artistGross <= 0) return;

    for (var item in artistItems) {
      final share = (item.product.price * item.qty) / artistGross;
      final allocated = discountAmount * share;
      final itemGross = item.product.price * item.qty;
      item.discount = allocated > itemGross ? itemGross : allocated;
    }
    notifyListeners();
  }

  // --- Checkout Operations ---
  Future<Order> checkoutCash({required double cashReceived}) async {
    final change = cashReceived >= cartTotal ? cashReceived - cartTotal : 0.0;
    return await _processOrder(
      paymentMethod: PaymentMethod.cash,
      cashReceived: cashReceived,
      change: change,
    );
  }

  Future<Order> checkoutPromptPay() async {
    return await _processOrder(
      paymentMethod: PaymentMethod.qr,
      cashReceived: cartTotal,
      change: 0.0,
    );
  }

  Future<Order> _processOrder({
    required PaymentMethod paymentMethod,
    required double cashReceived,
    required double change,
  }) async {
    final shopId = _shop?.id ?? 'default_shop';
    final eventId = _activeEvent?.id ?? 'default_event';

    // 1. Snapshot OrderItems with Artist ID & Price
    final orderItems = _cart.map((cartItem) {
      return OrderItem(
        orderId: '',
        productId: cartItem.product.id,
        artistId: cartItem.product.artistId, // Essential for settlement!
        nameSnapshot: cartItem.product.name,
        priceSnapshot: cartItem.product.price,
        qty: cartItem.qty,
        discountAmount: cartItem.discount,
      );
    }).toList();

    // 2. Create Order (v1.7: with createdBy, createdAtClient, and artistTotals aggregation)
    final order = Order(
      shopId: shopId,
      eventId: eventId,
      status: OrderStatus.completed,
      paymentMethod: paymentMethod,
      total: cartTotal,
      cashReceived: cashReceived,
      change: change,
      synced: false,
      createdOffline: true,
      createdBy: _currentMember?.userId ?? 'anonymous',
      createdAtClient: DateTime.now(),
      items: orderItems,
    );

    await _db.saveOrder(order);

    // 3. Record StockMovement & deduct stock locally (v1.7: stock can be negative!)
    for (var cartItem in _cart) {
      await _db.addStockMovement(StockMovement(
        productId: cartItem.product.id,
        orderId: order.id,
        type: StockMovementType.sale,
        qtyChange: -cartItem.qty,
        createdBy: order.createdBy,
      ));

      final updatedStock = cartItem.product.stock - cartItem.qty;
      await _db.saveProduct(cartItem.product.copyWith(
        stock: updatedStock,
        updatedAt: DateTime.now(),
        updatedBy: order.createdBy,
      ));
    }

    clearCart();
    refreshData();
    return order;
  }

  Future<void> voidOrder(String orderId, {String voidReason = 'Customer void'}) async {
    await _db.voidOrder(
      orderId,
      voidedBy: _currentMember?.userId ?? 'system',
      voidReason: voidReason,
    );
    refreshData();
  }

  Future<void> syncNow() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1000));
    await _db.markAllSynced(shopId: _currentShopId);

    _isSyncing = false;
    refreshData();
  }

  bool canLogout() => unsyncedCount == 0;

  // --- Category Folder Management (Requirement 4.3) ---
  Future<void> saveCategory(Category category) async {
    await _db.saveCategory(category);
    refreshData();
  }

  Future<void> deleteCategory(String id, {String? targetCategoryId}) async {
    await _db.deleteCategory(
      id,
      shopId: _currentShopId ?? 'default_shop',
      targetCategoryId: targetCategoryId,
    );
    if (_currentFolderId == id) {
      _currentFolderId = null;
    }
    refreshData();
  }

  // --- Product Management ---
  Future<void> saveProduct(Product product) async {
    await _db.saveProduct(product);
    refreshData();
  }

  Future<void> deleteProduct(String id) async {
    await _db.deleteProduct(id);
    refreshData();
  }

  Future<void> duplicateProduct(Product product) async {
    final copy = product.copyWith(
      name: '${product.name} (Copy)',
      stock: 0,
    );
    await _db.saveProduct(copy);
    refreshData();
  }

  Future<void> adjustStock(String productId, int qtyChange, String reason) async {
    final product = _db.getProduct(productId);
    if (product == null) return;

    await _db.addStockMovement(StockMovement(
      productId: productId,
      type: StockMovementType.manualAdjust,
      qtyChange: qtyChange,
    ));

    final newStock = product.stock + qtyChange;
    await _db.saveProduct(product.copyWith(
      stock: newStock > 0 ? newStock : 0,
    ));
    refreshData();
  }

  // --- Artist & Commission Management (Requirement 4.6) ---
  Future<void> saveArtist(Artist artist) async {
    await _db.saveArtist(artist);
    refreshData();
  }

  Future<void> deleteArtist(String id) async {
    await _db.deleteArtist(id);
    refreshData();
  }

  // --- Member & Invite Management (Requirement 4.7) ---
  Future<Invite> createInvite(String email, {String? artistId}) async {
    final invite = Invite(
      shopId: _shop?.id ?? 'default_shop',
      email: email,
      artistId: artistId,
    );
    await _db.saveInvite(invite);
    refreshData();
    return invite;
  }

  Future<void> removeMember(String memberId) async {
    await _db.deleteMember(memberId);
    refreshData();
  }

  Future<void> revokeInvite(String inviteId) async {
    await _db.deleteInvite(inviteId);
    refreshData();
  }

  // --- Event & Attending Artists Management (Requirement 4.11) ---
  Future<void> setActiveEvent(String eventId) async {
    final event = _events.firstWhere((e) => e.id == eventId);
    await _db.saveEvent(event.copyWith(isActive: true));

    // Check if cart has products of non-attending artists
    final attending = _db.getEventArtistIds(eventId);
    if (attending.isNotEmpty) {
      _cart.removeWhere((item) => !attending.contains(item.artistId));
    }

    refreshData();
  }

  Future<void> saveEvent(Event event, List<String> attendingArtistIds) async {
    await _db.saveEvent(event);
    await _db.setEventArtists(event.id, attendingArtistIds);
    refreshData();
  }

  Future<void> deleteEvent(String id) async {
    await _db.deleteEvent(id);
    refreshData();
  }

  // --- Settlement Calculations (Requirement 4.6) ---
  Map<String, Settlement> computeSettlementForEvent(String eventId) {
    final settlements = <String, Settlement>{};
    final savedList = _db.getSettlements(eventId);

    // Sum gross sales from completed, non-voided order items
    final eventOrders = _orders.where(
      (o) => o.eventId == eventId && o.status == OrderStatus.completed,
    );

    final grossMap = <String, double>{};
    for (var o in eventOrders) {
      for (var item in o.items) {
        grossMap[item.artistId] = (grossMap[item.artistId] ?? 0.0) + item.subtotal;
      }
    }

    // Build settlement per artist
    for (var artist in _artists) {
      final gross = grossMap[artist.id] ?? 0.0;
      final rate = artist.commissionRate ?? 0.0;
      final commission = gross * (rate / 100.0);
      final net = gross - commission;

      // Check if already paid in DB
      Settlement? existing;
      try {
        existing = savedList.firstWhere((s) => s.artistId == artist.id);
      } catch (_) {}

      settlements[artist.id] = Settlement(
        id: existing?.id,
        shopId: _shop?.id ?? 'default_shop',
        eventId: eventId,
        artistId: artist.id,
        grossSales: gross,
        commissionAmount: commission,
        netPayout: net,
        paid: existing?.paid ?? false,
        paidAt: existing?.paidAt,
        note: existing?.note ?? '',
      );
    }
    return settlements;
  }

  Future<void> markSettlementPaid(Settlement settlement, String note) async {
    final updated = settlement.copyWith(
      paid: true,
      paidAt: DateTime.now(),
      note: note,
    );
    await _db.saveSettlement(updated);
    notifyListeners();
  }

  // --- Shop Settings ---
  Future<Shop> createShop({
    required String name,
    required String promptpayId,
    required String promptpayName,
  }) async {
    final newShop = Shop(
      name: name,
      promptpayId: promptpayId,
      promptpayName: promptpayName,
      ownerUserId: 'owner_user',
    );
    await _db.saveShop(newShop);
    _currentShopId = newShop.id;
    refreshData();
    return newShop;
  }

  Future<void> updateShop({
    required String name,
    required String promptpayId,
    required String promptpayName,
  }) async {
    final updated = _shop != null
        ? _shop!.copyWith(
            name: name,
            promptpayId: promptpayId,
            promptpayName: promptpayName,
          )
        : Shop(
            name: name,
            promptpayId: promptpayId,
            promptpayName: promptpayName,
            ownerUserId: 'owner_user',
          );
    await _db.saveShop(updated);
    _currentShopId = updated.id;
    refreshData();
  }

  // --- Reports & Stats ---
  double get todayRevenue {
    final now = DateTime.now();
    return _orders
        .where((o) =>
            o.status == OrderStatus.completed &&
            o.createdAt.year == now.year &&
            o.createdAt.month == now.month &&
            o.createdAt.day == now.day)
        .fold(0.0, (sum, o) => sum + o.total);
  }

  int get todayOrdersCount {
    final now = DateTime.now();
    return _orders
        .where((o) =>
            o.status == OrderStatus.completed &&
            o.createdAt.year == now.year &&
            o.createdAt.month == now.month &&
            o.createdAt.day == now.day)
        .length;
  }

  double get totalRevenue {
    return _orders
        .where((o) => o.status == OrderStatus.completed)
        .fold(0.0, (sum, o) => sum + o.total);
  }

  Map<String, int> get topProductsSalesCount {
    final map = <String, int>{};
    for (var o in _orders.where((o) => o.status == OrderStatus.completed)) {
      for (var item in o.items) {
        map[item.nameSnapshot] = (map[item.nameSnapshot] ?? 0) + item.qty;
      }
    }
    return map;
  }
}
