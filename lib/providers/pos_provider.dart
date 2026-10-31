import 'package:flutter/foundation.dart' hide Category;
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../services/mock_seed_service.dart';

enum BillDiscountType { none, percent, amount }

class PosProvider extends ChangeNotifier {
  final RepositoryRegistry _repo;

  PosProvider({RepositoryRegistry? repo}) : _repo = repo ?? createDefaultRepository();

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

  // Track bill discount intent for dynamic re-allocation
  BillDiscountType _billDiscountType = BillDiscountType.none;
  double _billDiscountValue = 0.0;

  // Getters
  String? get currentShopId => _currentShopId;
  List<Shop> get allShops => _repo.getShops();
  Shop? get shop => _shop;
  List<Member> get members => _members;
  Member? get currentMember => _currentMember;
  bool get isOwner => _currentMember?.role == MemberRole.owner;
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
  Future<void> init([String? testPath]) async {
    await _repo.init(testPath);
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
    _billDiscountType = BillDiscountType.none;
    _billDiscountValue = 0.0;
    refreshData();
  }

  /// Reset or seed data for testing
  Future<void> seedTestData({bool force = true}) async {
    await MockSeedService.seedAllSampleData(_repo, clearExisting: force);
    _currentShopId = 'shop_a';
    refreshData();
  }

  /// Load complete sample seed data for testing & demonstration
  Future<void> loadSampleSeedData() async {
    await MockSeedService.seedAllSampleData(_repo, clearExisting: true);
    _currentShopId = 'shop_a';
    refreshData();
  }

  /// Wipe all database tables to a clean, blank slate for real production use
  Future<void> clearAllData() async {
    await _repo.clearAllData();
    _currentShopId = null;
    _cart.clear();
    _currentFolderId = null;
    _isAllItemsView = false;
    _searchQuery = '';
    _currentMember = null;
    _billDiscountType = BillDiscountType.none;
    _billDiscountValue = 0.0;
    refreshData();
  }

  void refreshData() {
    final shops = _repo.getShops();
    if (shops.isNotEmpty) {
      if (_currentShopId == null || !shops.any((s) => s.id == _currentShopId)) {
        _currentShopId = shops.first.id;
      }
    } else {
      _currentShopId = null;
    }

    _shop = _repo.getShopSync(_currentShopId);
    _members = _repo.getMembers(shopId: _currentShopId);
    _currentMember = _members.isNotEmpty
        ? (_currentMember != null
            ? _members.firstWhere((m) => m.id == _currentMember!.id, orElse: () => _members.first)
            : _members.first)
        : null;
    _invites = _repo.getInvites(shopId: _currentShopId);
    _artists = _repo.getArtists(shopId: _currentShopId);
    _categories = _repo.getCategories(shopId: _currentShopId);
    _products = _repo.getProducts(shopId: _currentShopId);
    _events = _repo.getEvents(shopId: _currentShopId);
    _activeEvent = _repo.getActiveEvent(shopId: _currentShopId);
    if (_activeEvent != null) {
      _activeEventArtistIds = _repo.getEventArtistIds(_activeEvent!.id);
    } else {
      _activeEventArtistIds = [];
    }
    _orders = _repo.getOrders(shopId: _currentShopId);
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
    _recalculateDiscounts();
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cart.removeWhere((item) => item.product.id == productId);
    _recalculateDiscounts();
    notifyListeners();
  }

  void updateCartQty(String productId, int newQty) {
    final index = _cart.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (newQty <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index].qty = newQty;
      }
      _recalculateDiscounts();
      notifyListeners();
    }
  }

  void clearDiscounts() {
    _billDiscountType = BillDiscountType.none;
    _billDiscountValue = 0.0;
    for (var item in _cart) {
      item.discount = 0.0;
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _billDiscountType = BillDiscountType.none;
    _billDiscountValue = 0.0;
    notifyListeners();
  }

  void _recalculateDiscounts() {
    if (_cart.isEmpty) {
      _billDiscountType = BillDiscountType.none;
      _billDiscountValue = 0.0;
      return;
    }

    if (_billDiscountType == BillDiscountType.none || _billDiscountValue <= 0) {
      return;
    }

    final double discountToDistribute;
    if (_billDiscountType == BillDiscountType.percent) {
      discountToDistribute = cartSubtotal * (_billDiscountValue / 100.0);
    } else {
      discountToDistribute = _billDiscountValue > cartSubtotal ? cartSubtotal : _billDiscountValue;
    }

    _distributeProportionalDiscount(discountToDistribute);
  }

  /// Proportional Whole-Bill Discount with exact satang distribution (Hamilton method)
  void applyWholeBillDiscount(double totalDiscount) {
    if (cartSubtotal <= 0 || totalDiscount <= 0) {
      clearDiscounts();
      return;
    }
    _billDiscountType = BillDiscountType.amount;
    _billDiscountValue = totalDiscount;
    final effDiscount = totalDiscount > cartSubtotal ? cartSubtotal : totalDiscount;
    _distributeProportionalDiscount(effDiscount);
    notifyListeners();
  }

  void _distributeProportionalDiscount(double totalDiscount) {
    if (cartSubtotal <= 0 || totalDiscount <= 0) {
      for (var item in _cart) {
        item.discount = 0.0;
      }
      return;
    }

    // Exact satang distribution using largest remainder method
    final totalCents = (totalDiscount * 100).round();
    final artistGrossMap = <String, double>{};
    for (var item in _cart) {
      final gross = item.product.price * item.qty;
      artistGrossMap[item.artistId] = (artistGrossMap[item.artistId] ?? 0.0) + gross;
    }

    final allocations = <String, int>{};
    final remainders = <String, double>{};
    var allocatedCents = 0;

    for (var entry in artistGrossMap.entries) {
      final exactCents = totalCents * (entry.value / cartSubtotal);
      final floorCents = exactCents.floor();
      allocations[entry.key] = floorCents;
      remainders[entry.key] = exactCents - floorCents;
      allocatedCents += floorCents;
    }

    var leftover = totalCents - allocatedCents;
    final sortedKeys = artistGrossMap.keys.toList()
      ..sort((a, b) => (remainders[b] ?? 0).compareTo(remainders[a] ?? 0));

    for (var key in sortedKeys) {
      if (leftover <= 0) break;
      allocations[key] = (allocations[key] ?? 0) + 1;
      leftover--;
    }

    for (var item in _cart) {
      final artistDiscountTotal = (allocations[item.artistId] ?? 0) / 100.0;
      final artistGross = artistGrossMap[item.artistId] ?? 1.0;
      final itemShare = (item.product.price * item.qty) / artistGross;
      final allocated = artistDiscountTotal * itemShare;
      final itemGross = item.product.price * item.qty;
      item.discount = allocated > itemGross ? itemGross : double.parse(allocated.toStringAsFixed(2));
    }
  }

  /// Artist-Specific Discount (Takes precedence over proportional bill re-allocation)
  // Order of evaluation: Artist-specific discount applies only to items of that artist and takes precedence over proportional whole-bill rebalancing.
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
    final orderId = const Uuid().v4();

    // 1. Snapshot OrderItems with Artist ID & Price and matching orderId
    final orderItems = _cart.map((cartItem) {
      return OrderItem(
        orderId: orderId,
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
      id: orderId,
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

    // Atomic Order Placement & Stock Movement Ledger
    await _repo.placeOrder(order);

    clearCart();
    refreshData();
    return order;
  }

  Future<void> voidOrder(String orderId, {String voidReason = 'Customer void'}) async {
    await _repo.voidOrder(
      shopId: _currentShopId ?? 'default_shop',
      orderId: orderId,
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
    await _repo.markAllSynced(shopId: _currentShopId);

    _isSyncing = false;
    refreshData();
  }

  bool canLogout() => unsyncedCount == 0;

  // --- Category Folder Management (Requirement 4.3) ---
  Future<void> saveCategory(Category category) async {
    await _repo.saveCategory(category);
    refreshData();
  }

  Future<void> deleteCategory(String id, {String? targetCategoryId}) async {
    await _repo.deleteCategory(
      _currentShopId ?? 'default_shop',
      id,
      targetCategoryId: targetCategoryId,
    );
    if (_currentFolderId == id) {
      _currentFolderId = null;
    }
    refreshData();
  }

  // --- Product Management ---
  Future<void> saveProduct(Product product) async {
    await _repo.saveProduct(product);
    refreshData();
  }

  Future<void> deleteProduct(String id) async {
    await _repo.deleteProduct(id);
    refreshData();
  }

  Future<void> duplicateProduct(Product product) async {
    final copy = product.copyWith(
      name: '${product.name} (Copy)',
      stock: 0,
    );
    await _repo.saveProduct(copy);
    refreshData();
  }

  Future<void> adjustStock(String productId, int qtyChange, String reason) async {
    await _repo.manualAdjust(
      shopId: _currentShopId ?? 'default_shop',
      productId: productId,
      qtyChange: qtyChange,
      createdBy: _currentMember?.userId ?? 'system',
    );
    refreshData();
  }

  // --- Artist & Commission Management (Requirement 4.6) ---
  Future<void> saveArtist(Artist artist) async {
    await _repo.saveArtist(artist);
    refreshData();
  }

  Future<void> deleteArtist(String id) async {
    await _repo.deleteArtist(id);
    refreshData();
  }

  // --- Member & Invite Management (Requirement 4.7) ---
  Future<Invite> createInvite(String email, {String? artistId}) async {
    final invite = Invite(
      shopId: _shop?.id ?? 'default_shop',
      email: email,
      artistId: artistId,
    );
    await _repo.saveInvite(invite);
    refreshData();
    return invite;
  }

  Future<void> removeMember(String memberId) async {
    await _repo.deleteMember(memberId);
    refreshData();
  }

  Future<void> revokeInvite(String inviteId) async {
    await _repo.deleteInvite(inviteId);
    refreshData();
  }

  // --- Event & Attending Artists Management (Requirement 4.11) ---
  Future<void> setActiveEvent(String eventId) async {
    final event = _events.firstWhere((e) => e.id == eventId);
    await _repo.saveEvent(event.copyWith(isActive: true));

    // Check if cart has products of non-attending artists
    final attending = _repo.getEventArtistIds(eventId);
    if (attending.isNotEmpty) {
      _cart.removeWhere((item) => !attending.contains(item.artistId));
    }

    refreshData();
  }

  Future<void> saveEvent(Event event, List<String> attendingArtistIds) async {
    await _repo.saveEvent(event);
    await _repo.setEventArtistsSync(event.id, attendingArtistIds);
    refreshData();
  }

  Future<void> deleteEvent(String id) async {
    await _repo.deleteEvent(id);
    refreshData();
  }

  // --- Settlement Calculations (Item 11 & Requirement 4.6) ---
  Map<String, Settlement> computeSettlementForEvent(String eventId) {
    final completedOrders = _orders
        .where((o) => o.eventId == eventId && o.status == OrderStatus.completed)
        .toList();
    final savedList = _repo.getSettlements(eventId, shopId: _currentShopId);
    final settlements = <String, Settlement>{};

    for (var artist in _artists) {
      double gross = 0.0;
      double discount = 0.0;
      for (var o in completedOrders) {
        final summary = o.artistTotals[artist.id];
        if (summary != null) {
          gross += summary.gross;
          discount += summary.discount;
        }
      }

      final netSales = gross - discount;
      final rate = artist.commissionRate ?? 0.0;
      final commission = netSales * (rate / 100.0);
      final netPayout = netSales - commission;

      Settlement? existing;
      try {
        existing = savedList.firstWhere((s) => s.artistId == artist.id);
      } catch (_) {}

      settlements[artist.id] = Settlement(
        id: existing?.id,
        shopId: _currentShopId ?? 'default_shop',
        eventId: eventId,
        artistId: artist.id,
        grossSales: netSales,
        commissionAmount: commission,
        netPayout: netPayout,
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
    await _repo.saveSettlement(updated);
    notifyListeners();
  }

  // --- Shop Settings ---
  Future<Shop> createShop({
    required String name,
    required String promptpayId,
    required String promptpayName,
    String ownerUserId = 'owner_user',
  }) async {
    final existingShops = _repo.getShops().where((s) => s.ownerUserId == ownerUserId && s.name == name);
    if (existingShops.isNotEmpty) {
      _currentShopId = existingShops.first.id;
      refreshData();
      return existingShops.first;
    }

    final newShop = Shop(
      name: name,
      promptpayId: promptpayId,
      promptpayName: promptpayName,
      ownerUserId: ownerUserId,
    );
    await _repo.createShop(name: name, ownerUserId: ownerUserId);
    await _repo.updateShop(newShop);

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
    await _repo.updateShop(updated);
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
