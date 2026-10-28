import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

/// Offline-First Database Service using Hive
/// Operates 100% locally on the device (iPad, Android, Desktop, Web).
/// Starts with a completely clean/blank database in production.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String boxShops = 'shops';
  static const String boxMembers = 'members';
  static const String boxInvites = 'invites';
  static const String boxArtists = 'artists';
  static const String boxCategories = 'categories';
  static const String boxProducts = 'products';
  static const String boxEvents = 'events';
  static const String boxEventArtists = 'event_artists';
  static const String boxOrders = 'orders';
  static const String boxStockMovements = 'stock_movements';
  static const String boxSettlements = 'settlements';

  late Box _shopsBox;
  late Box _membersBox;
  late Box _invitesBox;
  late Box _artistsBox;
  late Box _categoriesBox;
  late Box _productsBox;
  late Box _eventsBox;
  late Box _eventArtistsBox;
  late Box _ordersBox;
  late Box _stockMovementsBox;
  late Box _settlementsBox;

  /// Initializes local Hive storage boxes.
  /// Note: Keeps database clean and blank for real production use.
  Future<void> init() async {
    await Hive.initFlutter();

    _shopsBox = await Hive.openBox(boxShops);
    _membersBox = await Hive.openBox(boxMembers);
    _invitesBox = await Hive.openBox(boxInvites);
    _artistsBox = await Hive.openBox(boxArtists);
    _categoriesBox = await Hive.openBox(boxCategories);
    _productsBox = await Hive.openBox(boxProducts);
    _eventsBox = await Hive.openBox(boxEvents);
    _eventArtistsBox = await Hive.openBox(boxEventArtists);
    _ordersBox = await Hive.openBox(boxOrders);
    _stockMovementsBox = await Hive.openBox(boxStockMovements);
    _settlementsBox = await Hive.openBox(boxSettlements);
  }

  /// Wipes all local database tables clean (Fresh Slate)
  Future<void> clearAllData() async {
    await _shopsBox.clear();
    await _membersBox.clear();
    await _invitesBox.clear();
    await _artistsBox.clear();
    await _categoriesBox.clear();
    await _productsBox.clear();
    await _eventsBox.clear();
    await _eventArtistsBox.clear();
    await _ordersBox.clear();
    await _stockMovementsBox.clear();
    await _settlementsBox.clear();
  }

  // --- Shop Operations ---
  List<Shop> getShops() {
    return _shopsBox.values
        .map((e) => Shop.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Shop? getShop([String? shopId]) {
    if (_shopsBox.isEmpty) return null;
    if (shopId != null) {
      final data = _shopsBox.get(shopId);
      if (data != null) {
        return Shop.fromJson(Map<String, dynamic>.from(data as Map));
      }
    }
    final map = Map<String, dynamic>.from(_shopsBox.values.first as Map);
    return Shop.fromJson(map);
  }

  Future<void> saveShop(Shop shop) async {
    await _shopsBox.put(shop.id, shop.toJson());
  }

  Future<void> deleteShop(String shopId) async {
    await _shopsBox.delete(shopId);
  }

  // --- Member Operations ---
  List<Member> getMembers({String? shopId}) {
    var list = _membersBox.values
        .map((e) => Member.fromJson(Map<String, dynamic>.from(e as Map)));
    if (shopId != null) {
      list = list.where((m) => m.shopId == shopId);
    }
    return list.toList();
  }

  Future<void> saveMember(Member member) async {
    await _membersBox.put(member.id, member.toJson());
  }

  Future<void> deleteMember(String id) async {
    await _membersBox.delete(id);
  }

  // --- Invite Operations ---
  List<Invite> getInvites({String? shopId}) {
    var list = _invitesBox.values
        .map((e) => Invite.fromJson(Map<String, dynamic>.from(e as Map)));
    if (shopId != null) {
      list = list.where((i) => i.shopId == shopId);
    }
    return list.toList();
  }

  Future<void> saveInvite(Invite invite) async {
    await _invitesBox.put(invite.id, invite.toJson());
  }

  Future<void> deleteInvite(String id) async {
    await _invitesBox.delete(id);
  }

  // --- Artist Operations ---
  List<Artist> getArtists({String? shopId}) {
    var list = _artistsBox.values
        .map((e) => Artist.fromJson(Map<String, dynamic>.from(e as Map)));
    if (shopId != null) {
      list = list.where((a) => a.shopId == shopId);
    }
    return list.toList();
  }

  Artist? getArtist(String id) {
    final data = _artistsBox.get(id);
    if (data == null) return null;
    return Artist.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> saveArtist(Artist artist) async {
    await _artistsBox.put(artist.id, artist.toJson());
  }

  Future<void> deleteArtist(String id) async {
    await _artistsBox.delete(id);
  }

  // --- Category Operations (Folders) ---
  List<Category> getCategories({String? shopId}) {
    var list = _categoriesBox.values
        .map((e) => Category.fromJson(Map<String, dynamic>.from(e as Map)));
    if (shopId != null) {
      list = list.where((c) => c.shopId == shopId);
    }
    final res = list.toList();
    res.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return res;
  }

  Future<void> saveCategory(Category category) async {
    await _categoriesBox.put(category.id, category.toJson());
  }

  Future<void> deleteCategory(String id, {String? targetCategoryId, String? shopId}) async {
    // Requirement 4.3: Move products to target category or uncategorized (empty) instead of deleting products!
    final products = getProducts(shopId: shopId);
    for (var prod in products) {
      if (prod.categoryId == id) {
        await saveProduct(prod.copyWith(categoryId: targetCategoryId ?? ''));
      }
    }
    // Also move children categories if any
    final children = getCategories(shopId: shopId).where((c) => c.parentCategoryId == id);
    for (var child in children) {
      await saveCategory(child.copyWith(parentCategoryId: null));
    }
    await _categoriesBox.delete(id);
  }

  // --- Product Operations ---
  List<Product> getProducts({String? shopId}) {
    var list = _productsBox.values
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)));
    if (shopId != null) {
      list = list.where((p) => p.shopId == shopId);
    }
    return list.toList();
  }

  Product? getProduct(String id) {
    final data = _productsBox.get(id);
    if (data == null) return null;
    return Product.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> saveProduct(Product product) async {
    await _productsBox.put(product.id, product.toJson());
  }

  Future<void> deleteProduct(String id) async {
    await _productsBox.delete(id);
  }

  // --- Event & EventArtist Operations ---
  List<Event> getEvents({String? shopId}) {
    var list = _eventsBox.values
        .map((e) => Event.fromJson(Map<String, dynamic>.from(e as Map)));
    if (shopId != null) {
      list = list.where((e) => e.shopId == shopId);
    }
    return list.toList();
  }

  Event? getActiveEvent({String? shopId}) {
    final events = getEvents(shopId: shopId);
    try {
      return events.firstWhere((e) => e.isActive);
    } catch (_) {
      return events.isNotEmpty ? events.first : null;
    }
  }

  Future<void> saveEvent(Event event) async {
    if (event.isActive) {
      for (var e in getEvents(shopId: event.shopId)) {
        if (e.id != event.id && e.isActive) {
          await _eventsBox.put(e.id, e.copyWith(isActive: false).toJson());
        }
      }
    }
    await _eventsBox.put(event.id, event.toJson());
  }

  Future<void> deleteEvent(String id) async {
    await _eventsBox.delete(id);
    // Delete event artists mappings
    final toDelete = _eventArtistsBox.values
        .map((e) => EventArtist.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((ea) => ea.eventId == id)
        .map((ea) => ea.id)
        .toList();
    for (var eaId in toDelete) {
      await _eventArtistsBox.delete(eaId);
    }
  }

  List<String> getEventArtistIds(String eventId) {
    return _eventArtistsBox.values
        .map((e) => EventArtist.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((ea) => ea.eventId == eventId)
        .map((ea) => ea.artistId)
        .toList();
  }

  Future<void> setEventArtists(String eventId, List<String> artistIds) async {
    // Clear existing for this event
    final existing = _eventArtistsBox.values
        .map((e) => EventArtist.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((ea) => ea.eventId == eventId)
        .map((ea) => ea.id)
        .toList();
    for (var id in existing) {
      await _eventArtistsBox.delete(id);
    }
    // Add new
    for (var aId in artistIds) {
      final ea = EventArtist(eventId: eventId, artistId: aId);
      await _eventArtistsBox.put(ea.id, ea.toJson());
    }
  }

  // --- Settlement Operations ---
  List<Settlement> getSettlements(String eventId, {String? shopId}) {
    var list = _settlementsBox.values
        .map((e) => Settlement.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((s) => s.eventId == eventId);
    if (shopId != null) {
      list = list.where((s) => s.shopId == shopId);
    }
    return list.toList();
  }

  Future<void> saveSettlement(Settlement s) async {
    await _settlementsBox.put(s.id, s.toJson());
  }

  // --- Order Operations ---
  List<Order> getOrders({String? shopId}) {
    var list = _ordersBox.values
        .map((e) => Order.fromJson(Map<String, dynamic>.from(e as Map)));
    if (shopId != null) {
      list = list.where((o) => o.shopId == shopId);
    }
    final res = list.toList();
    res.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return res;
  }

  int getUnsyncedOrdersCount({String? shopId}) {
    return getOrders(shopId: shopId).where((o) => !o.synced).length;
  }

  Future<void> saveOrder(Order order) async {
    await _ordersBox.put(order.id, order.toJson());
  }

  Future<void> voidOrder(String orderId) async {
    final orderData = _ordersBox.get(orderId);
    if (orderData == null) return;
    final order = Order.fromJson(Map<String, dynamic>.from(orderData as Map));
    if (order.status == OrderStatus.voided) return;

    final updatedOrder = order.copyWith(status: OrderStatus.voided, synced: false);
    await _ordersBox.put(orderId, updatedOrder.toJson());

    // Restore stock for all products across all artists in the order
    for (var item in order.items) {
      final product = getProduct(item.productId);
      if (product != null) {
        await addStockMovement(StockMovement(
          productId: item.productId,
          orderId: order.id,
          type: StockMovementType.voidAction,
          qtyChange: item.qty,
        ));

        await saveProduct(product.copyWith(stock: product.stock + item.qty));
      }
    }
  }

  // --- Stock Movement Ledger Operations ---
  List<StockMovement> getStockMovements() {
    return _stockMovementsBox.values
        .map((e) => StockMovement.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> addStockMovement(StockMovement movement) async {
    await _stockMovementsBox.put(movement.id, movement.toJson());
  }

  Future<void> markAllSynced({String? shopId}) async {
    for (var order in getOrders(shopId: shopId)) {
      if (!order.synced) {
        await _ordersBox.put(order.id, order.copyWith(synced: true).toJson());
      }
    }
  }
}
