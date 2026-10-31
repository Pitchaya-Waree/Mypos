import '../models/models.dart';
import '../services/database_service.dart';

/// 1. Auth Repository Interface
abstract class AuthRepository {
  Stream<String?> get authState;
  String? get currentUserId;
  Future<void> signInWithGoogle();
  Future<bool> signOut({bool checkPendingWrites = true});
}

/// 2. Shop Repository Interface
abstract class ShopRepository {
  Future<List<UserMembership>> listMyShops(String userId);
  Future<Shop?> getShop(String shopId);
  Future<void> updateShop(Shop shop);
  Future<Shop> createShop({required String name, required String ownerUserId});
}

/// 3. Member Repository Interface
abstract class MemberRepository {
  Future<List<Member>> listMembers(String shopId);
  Future<Invite> createInvite({
    required String shopId,
    required String email,
    required MemberRole role,
    String? artistId,
    required String createdBy,
  });
  Future<void> revokeInvite(String shopId, String inviteId);
  Future<void> acceptInvite(String shopId, String inviteId, String token, String userId, String email);
  Future<void> changeMemberRole(String shopId, String memberUid, MemberRole role, {String? artistId});
  Future<void> removeMember(String shopId, String memberUid);
}

/// 4. Catalog Repository Interface
abstract class CatalogRepository {
  Stream<List<Product>> watchProducts(String shopId);
  Stream<List<Category>> watchCategories(String shopId);
  Future<void> upsertProduct(Product product);
  Future<void> setProductActive(String shopId, String productId, bool active);
  Future<void> upsertCategory(Category category);
  Future<void> deleteCategory(String shopId, String categoryId, {String? targetCategoryId});
}

/// 5. Event Repository Interface
abstract class EventRepository {
  Stream<List<Event>> watchEvents(String shopId);
  Future<void> upsertEvent(Event event);
  Future<void> setEventArtists(String shopId, String eventId, List<String> artistIds);
  Future<void> setEventProducts(String shopId, String eventId, List<String> productIds);
  Future<Event> cloneFromEvent({
    required String shopId,
    required String sourceEventId,
    required String newEventName,
    required DateTime startDate,
    required DateTime endDate,
  });
}

/// 6. Order Repository Interface
abstract class OrderRepository {
  Future<Order> placeOrder(Order order);
  Future<void> voidOrder({
    required String shopId,
    required String orderId,
    required String voidedBy,
    required String voidReason,
  });
  Stream<List<Order>> watchOrders(String shopId, {String? eventId, String? createdBy});
  int get pendingCount;
}

/// 7. Stock Repository Interface
abstract class StockRepository {
  Future<void> manualAdjust({
    required String shopId,
    required String productId,
    required int qtyChange,
    required String createdBy,
  });
  Stream<List<StockMovement>> watchMovements(String shopId, String productId);
}

/// 8. Settlement Repository Interface
abstract class SettlementRepository {
  Future<List<Settlement>> computeForEvent({
    required String shopId,
    required String eventId,
    required List<Artist> artists,
  });
  Future<void> markPaid(String settlementId, {required String note});
  String exportCsv(List<Settlement> settlements, {required List<Artist> artists});
}

/// Unified Registry Interface for Repository Layer
abstract class RepositoryRegistry
    implements
        AuthRepository,
        ShopRepository,
        MemberRepository,
        CatalogRepository,
        EventRepository,
        OrderRepository,
        StockRepository,
        SettlementRepository {
  Future<void> init([String? testPath]);
  Future<void> clearAllData();
  List<Shop> getShops();
  Shop? getShopSync(String? shopId);
  List<Member> getMembers({String? shopId});
  Future<void> saveMember(Member member);
  Future<void> deleteMember(String id);
  List<Invite> getInvites({String? shopId});
  Future<void> saveInvite(Invite invite);
  Future<void> deleteInvite(String id);
  List<Artist> getArtists({String? shopId});
  Future<void> saveArtist(Artist artist);
  Future<void> deleteArtist(String id);
  List<Category> getCategories({String? shopId});
  Future<void> saveCategory(Category category);
  List<Product> getProducts({String? shopId});
  Product? getProduct(String id);
  Future<void> saveProduct(Product product);
  Future<void> deleteProduct(String id);
  List<Event> getEvents({String? shopId});
  Event? getActiveEvent({String? shopId});
  Future<void> saveEvent(Event event);
  Future<void> deleteEvent(String id);
  List<String> getEventArtistIds(String eventId);
  Future<void> setEventArtistsSync(String eventId, List<String> artistIds);
  List<Order> getOrders({String? shopId});
  Order? getOrder(String id);
  List<StockMovement> getMovements(String productId);
  List<Settlement> getSettlements(String eventId, {String? shopId});
  Future<void> saveSettlement(Settlement settlement);
  Future<void> markAllSynced({String? shopId});
  int getUnsyncedOrdersCount({String? shopId});
}

/// Factory helper providing the default repository registry
RepositoryRegistry createDefaultRepository() => LocalRepositoryRegistry(db: DatabaseService());
class LocalRepositoryRegistry implements RepositoryRegistry {
  final DatabaseService db;
  String? _currentUserId = 'user_rickky_01';

  LocalRepositoryRegistry({required this.db});

  @override
  Future<void> init([String? testPath]) => db.init(testPath);

  @override
  Future<void> clearAllData() => db.clearAllData();

  @override
  List<Shop> getShops() => db.getShops();

  @override
  Shop? getShopSync(String? shopId) => db.getShop(shopId);

  @override
  List<Member> getMembers({String? shopId}) => db.getMembers(shopId: shopId);

  @override
  Future<void> saveMember(Member member) => db.saveMember(member);

  @override
  Future<void> deleteMember(String id) => db.deleteMember(id);

  @override
  List<Invite> getInvites({String? shopId}) => db.getInvites(shopId: shopId);

  @override
  Future<void> saveInvite(Invite invite) => db.saveInvite(invite);

  @override
  Future<void> deleteInvite(String id) => db.deleteInvite(id);

  @override
  List<Artist> getArtists({String? shopId}) => db.getArtists(shopId: shopId);

  @override
  Future<void> saveArtist(Artist artist) => db.saveArtist(artist);

  @override
  Future<void> deleteArtist(String id) => db.deleteArtist(id);

  @override
  List<Category> getCategories({String? shopId}) => db.getCategories(shopId: shopId);

  @override
  Future<void> saveCategory(Category category) => db.saveCategory(category);

  @override
  List<Product> getProducts({String? shopId}) => db.getProducts(shopId: shopId);

  @override
  Product? getProduct(String id) => db.getProduct(id);

  @override
  Future<void> saveProduct(Product product) => db.saveProduct(product);

  @override
  Future<void> deleteProduct(String id) => db.deleteProduct(id);

  @override
  List<Event> getEvents({String? shopId}) => db.getEvents(shopId: shopId);

  @override
  Event? getActiveEvent({String? shopId}) => db.getActiveEvent(shopId: shopId);

  @override
  Future<void> saveEvent(Event event) => db.saveEvent(event);

  @override
  Future<void> deleteEvent(String id) => db.deleteEvent(id);

  @override
  List<String> getEventArtistIds(String eventId) => db.getEventArtistIds(eventId);

  @override
  Future<void> setEventArtistsSync(String eventId, List<String> artistIds) =>
      db.setEventArtists(eventId, artistIds);

  @override
  List<Order> getOrders({String? shopId}) => db.getOrders(shopId: shopId);

  @override
  Order? getOrder(String id) => db.getOrder(id);

  @override
  List<StockMovement> getMovements(String productId) => db.getMovements(productId);

  @override
  List<Settlement> getSettlements(String eventId, {String? shopId}) =>
      db.getSettlements(eventId, shopId: shopId);

  @override
  Future<void> saveSettlement(Settlement settlement) => db.saveSettlement(settlement);

  @override
  Future<void> markAllSynced({String? shopId}) => db.markAllSynced(shopId: shopId);

  @override
  int getUnsyncedOrdersCount({String? shopId}) => db.getUnsyncedOrdersCount(shopId: shopId);

  // AuthRepository
  @override
  Stream<String?> get authState => Stream.value(_currentUserId);

  @override
  String? get currentUserId => _currentUserId;

  @override
  Future<void> signInWithGoogle() async {
    _currentUserId = 'user_google_auth';
  }

  @override
  Future<bool> signOut({bool checkPendingWrites = true}) async {
    if (checkPendingWrites && pendingCount > 0) {
      return false; // Block logout when pending writes exist (v1.7 rule)
    }
    _currentUserId = null;
    return true;
  }

  // ShopRepository
  @override
  Future<List<UserMembership>> listMyShops(String userId) async {
    final shops = db.getShops();
    return shops
        .map((s) => UserMembership(
              shopId: s.id,
              shopName: s.name,
              role: s.ownerUserId == userId ? MemberRole.owner : MemberRole.member,
            ))
        .toList();
  }

  @override
  Future<Shop?> getShop(String shopId) async => db.getShop(shopId);

  @override
  Future<void> updateShop(Shop shop) async => db.saveShop(shop);

  @override
  Future<Shop> createShop({required String name, required String ownerUserId}) async {
    final existingShops = db.getShops().where((s) => s.ownerUserId == ownerUserId && s.name == name);
    if (existingShops.isNotEmpty) {
      return existingShops.first;
    }

    final shop = Shop(
      name: name,
      ownerUserId: ownerUserId,
      promptpayId: '',
      promptpayName: '',
    );
    await db.saveShop(shop);

    final members = db.getMembers(shopId: shop.id);
    if (!members.any((m) => m.userId == ownerUserId)) {
      await db.saveMember(Member(
        shopId: shop.id,
        userId: ownerUserId,
        email: '',
        name: 'Owner',
        role: MemberRole.owner,
      ));
    }

    final artists = db.getArtists(shopId: shop.id);
    if (!artists.any((a) => a.linkedUserId == ownerUserId)) {
      await db.saveArtist(Artist(
        shopId: shop.id,
        name: 'Main Artist',
        linkedUserId: ownerUserId,
      ));
    }

    return shop;
  }

  // MemberRepository
  @override
  Future<List<Member>> listMembers(String shopId) async => db.getMembers(shopId: shopId);

  @override
  Future<Invite> createInvite({
    required String shopId,
    required String email,
    required MemberRole role,
    String? artistId,
    required String createdBy,
  }) async {
    final invite = Invite(
      shopId: shopId,
      email: email,
      role: role,
      artistId: artistId,
    );
    await db.saveInvite(invite);
    return invite;
  }

  @override
  Future<void> revokeInvite(String shopId, String inviteId) async {
    final invites = db.getInvites(shopId: shopId);
    final invite = invites.firstWhere((i) => i.id == inviteId);
    await db.saveInvite(invite.copyWith(status: InviteStatus.revoked));
  }

  @override
  Future<void> acceptInvite(String shopId, String inviteId, String token, String userId, String email) async {
    final invites = db.getInvites(shopId: shopId);
    final invite = invites.firstWhere((i) => i.id == inviteId && i.token == token);
    if (invite.isExpired || invite.status != InviteStatus.pending) {
      throw Exception('Invite is invalid or expired');
    }
    await db.saveInvite(invite.copyWith(status: InviteStatus.accepted));
    final member = Member(
      shopId: shopId,
      userId: userId,
      email: email,
      name: email.split('@').first,
      role: invite.role,
      invitedArtistId: invite.artistId,
    );
    await db.saveMember(member);
  }

  @override
  Future<void> changeMemberRole(String shopId, String memberUid, MemberRole role, {String? artistId}) async {
    final members = db.getMembers(shopId: shopId);
    final member = members.firstWhere((m) => m.userId == memberUid);
    await db.saveMember(member.copyWith(role: role, invitedArtistId: artistId));
  }

  @override
  Future<void> removeMember(String shopId, String memberUid) async {
    final members = db.getMembers(shopId: shopId);
    final member = members.firstWhere((m) => m.userId == memberUid);
    if (member.role == MemberRole.owner) {
      throw Exception('Cannot remove owner');
    }
    await db.deleteMember(member.id);
  }

  // CatalogRepository
  @override
  Stream<List<Product>> watchProducts(String shopId) =>
      Stream.value(db.getProducts(shopId: shopId));

  @override
  Stream<List<Category>> watchCategories(String shopId) =>
      Stream.value(db.getCategories(shopId: shopId));

  @override
  Future<void> upsertProduct(Product product) async => db.saveProduct(product);

  @override
  Future<void> setProductActive(String shopId, String productId, bool active) async {
    final product = db.getProduct(productId);
    if (product != null) {
      await db.saveProduct(product.copyWith(active: active));
    }
  }

  @override
  Future<void> upsertCategory(Category category) async => db.saveCategory(category);

  @override
  Future<void> deleteCategory(String shopId, String categoryId, {String? targetCategoryId}) async =>
      db.deleteCategory(categoryId, shopId: shopId, targetCategoryId: targetCategoryId);

  // EventRepository
  @override
  Stream<List<Event>> watchEvents(String shopId) =>
      Stream.value(db.getEvents(shopId: shopId));

  @override
  Future<void> upsertEvent(Event event) async => db.saveEvent(event);

  @override
  Future<void> setEventArtists(String shopId, String eventId, List<String> artistIds) async =>
      db.setEventArtists(eventId, artistIds);

  @override
  Future<void> setEventProducts(String shopId, String eventId, List<String> productIds) async {
    final event = db.getEvent(eventId);
    if (event != null) {
      await db.saveEvent(event.copyWith(eventProductIds: productIds));
    }
  }

  @override
  Future<Event> cloneFromEvent({
    required String shopId,
    required String sourceEventId,
    required String newEventName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final sourceEvent = db.getEvent(sourceEventId);
    final sourceArtists = db.getEventArtistIds(sourceEventId);

    final newEvent = Event(
      shopId: shopId,
      name: newEventName,
      startDate: startDate,
      endDate: endDate,
      eventArtistIds: sourceArtists,
      eventProductIds: sourceEvent?.eventProductIds ?? [],
    );
    await db.saveEvent(newEvent);
    await db.setEventArtists(newEvent.id, sourceArtists);
    return newEvent;
  }

  // OrderRepository
  @override
  Future<Order> placeOrder(Order order) async {
    final existing = db.getOrder(order.id);
    if (existing != null) {
      return existing; // Idempotent: don't deduct stock twice
    }

    await db.saveOrder(order);

    // Delta decrement from fresh stock & save deterministic movement
    for (var item in order.items) {
      final movementId = 'sale_${order.id}_${item.productId}';
      await db.addStockMovement(StockMovement(
        id: movementId,
        productId: item.productId,
        orderId: order.id,
        type: StockMovementType.sale,
        qtyChange: -item.qty,
        createdBy: order.createdBy,
      ));

      final product = db.getProduct(item.productId);
      if (product != null) {
        // v1.7: Stock can go negative!
        await db.saveProduct(product.copyWith(
          stock: product.stock - item.qty,
          updatedAt: DateTime.now(),
          updatedBy: order.createdBy,
        ));
      }
    }
    return order;
  }

  @override
  Future<void> voidOrder({
    required String shopId,
    required String orderId,
    required String voidedBy,
    required String voidReason,
  }) async {
    final Order? order = db.getOrder(orderId);
    if (order == null || order.status == OrderStatus.voided) {
      throw Exception('Order already voided or not found');
    }

    final updated = order.copyWith(
      status: OrderStatus.voided,
      voidedAt: DateTime.now(),
      voidedBy: voidedBy,
      voidReason: voidReason,
    );
    await db.saveOrder(updated);

    for (OrderItem item in order.items) {
      final movementId = 'void_${order.id}_${item.productId}';
      await db.addStockMovement(StockMovement(
        id: movementId,
        productId: item.productId,
        orderId: order.id,
        type: StockMovementType.voidAction,
        qtyChange: item.qty,
        createdBy: voidedBy,
      ));

      final product = db.getProduct(item.productId);
      if (product != null) {
        await db.saveProduct(product.copyWith(
          stock: product.stock + item.qty,
          updatedAt: DateTime.now(),
          updatedBy: voidedBy,
        ));
      }
    }
  }

  @override
  Stream<List<Order>> watchOrders(String shopId, {String? eventId, String? createdBy}) {
    var orders = db.getOrders(shopId: shopId);
    if (eventId != null) {
      orders = orders.where((o) => o.eventId == eventId).toList();
    }
    if (createdBy != null) {
      orders = orders.where((o) => o.createdBy == createdBy).toList();
    }
    return Stream.value(orders);
  }

  @override
  int get pendingCount => db.getOrders().where((o) => !o.synced).length;

  // StockRepository
  @override
  Future<void> manualAdjust({
    required String shopId,
    required String productId,
    required int qtyChange,
    required String createdBy,
  }) async {
    final product = db.getProduct(productId);
    if (product != null) {
      await db.saveProduct(product.copyWith(
        stock: product.stock + qtyChange,
        updatedAt: DateTime.now(),
        updatedBy: createdBy,
      ));
      await db.addStockMovement(StockMovement(
        productId: productId,
        type: StockMovementType.manualAdjust,
        qtyChange: qtyChange,
        createdBy: createdBy,
      ));
    }
  }

  @override
  Stream<List<StockMovement>> watchMovements(String shopId, String productId) {
    final movements = db.getMovements(productId);
    return Stream.value(movements);
  }

  // SettlementRepository
  @override
  Future<List<Settlement>> computeForEvent({
    required String shopId,
    required String eventId,
    required List<Artist> artists,
  }) async {
    final completedOrders = db
        .getOrders(shopId: shopId)
        .where((o) => o.eventId == eventId && o.status == OrderStatus.completed)
        .toList();

    final results = <Settlement>[];
    for (var artist in artists) {
      // v1.7: Aggregation directly from artistTotals inside Order
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
      final commissionAmount = netSales * (rate / 100.0);
      final netPayout = netSales - commissionAmount;

      results.add(Settlement(
        shopId: shopId,
        eventId: eventId,
        artistId: artist.id,
        grossSales: netSales,
        commissionAmount: commissionAmount,
        netPayout: netPayout,
      ));
    }
    return results;
  }

  @override
  Future<void> markPaid(String settlementId, {required String note}) async {
    final existing = db.getSettlement(settlementId);
    if (existing != null) {
      await db.saveSettlement(existing.copyWith(
        paid: true,
        paidAt: DateTime.now(),
        note: note,
      ));
    }
  }

  @override
  String exportCsv(List<Settlement> settlements, {required List<Artist> artists}) {
    final buffer = StringBuffer();
    buffer.writeln('Artist,Net Sales,Commission Rate,Commission Amount,Net Payout,Status,Paid At,Note');
    for (var s in settlements) {
      final artistName = artists
          .firstWhere((a) => a.id == s.artistId, orElse: () => Artist(shopId: '', name: s.artistId))
          .name;
      buffer.writeln(
        '"$artistName",${s.grossSales.toStringAsFixed(2)},,${s.commissionAmount.toStringAsFixed(2)},${s.netPayout.toStringAsFixed(2)},${s.paid ? "PAID" : "UNPAID"},${s.paidAt?.toIso8601String() ?? ""},"${s.note}"',
      );
    }
    return buffer.toString();
  }
}

/// In-memory Fake implementation of RepositoryRegistry for pure unit testing without Hive/I/O
class FakeRepositoryRegistry implements RepositoryRegistry {
  final Map<String, Shop> _shops = {};
  final Map<String, Member> _members = {};
  final Map<String, Invite> _invites = {};
  final Map<String, Artist> _artists = {};
  final Map<String, Category> _categories = {};
  final Map<String, Product> _products = {};
  final Map<String, Event> _events = {};
  final Map<String, List<String>> _eventArtists = {};
  final Map<String, Order> _orders = {};
  final List<StockMovement> _movements = [];
  final Map<String, Settlement> _settlements = {};

  String? _currentUserId = 'fake_user_1';

  @override
  Future<void> init([String? testPath]) async {}

  @override
  Future<void> clearAllData() async {
    _shops.clear();
    _members.clear();
    _invites.clear();
    _artists.clear();
    _categories.clear();
    _products.clear();
    _events.clear();
    _eventArtists.clear();
    _orders.clear();
    _movements.clear();
    _settlements.clear();
  }

  // Auth
  @override
  Stream<String?> get authState => Stream.value(_currentUserId);
  @override
  String? get currentUserId => _currentUserId;
  @override
  Future<void> signInWithGoogle() async {
    _currentUserId = 'fake_google_user';
  }
  @override
  Future<bool> signOut({bool checkPendingWrites = true}) async {
    if (checkPendingWrites && pendingCount > 0) return false;
    _currentUserId = null;
    return true;
  }

  // Shop
  @override
  List<Shop> getShops() => _shops.values.toList();
  @override
  Shop? getShopSync(String? shopId) => shopId != null ? _shops[shopId] : (_shops.isNotEmpty ? _shops.values.first : null);
  @override
  Future<Shop?> getShop(String shopId) async => _shops[shopId];
  @override
  Future<void> updateShop(Shop shop) async {
    _shops[shop.id] = shop;
  }
  @override
  Future<List<UserMembership>> listMyShops(String userId) async {
    return _shops.values
        .map((s) => UserMembership(
              shopId: s.id,
              shopName: s.name,
              role: s.ownerUserId == userId ? MemberRole.owner : MemberRole.member,
            ))
        .toList();
  }
  @override
  Future<Shop> createShop({required String name, required String ownerUserId}) async {
    final existing = _shops.values.where((s) => s.ownerUserId == ownerUserId && s.name == name);
    if (existing.isNotEmpty) return existing.first;

    final shop = Shop(name: name, ownerUserId: ownerUserId, promptpayId: '', promptpayName: '');
    _shops[shop.id] = shop;

    if (!_members.values.any((m) => m.shopId == shop.id && m.userId == ownerUserId)) {
      final ownerMember = Member(
        shopId: shop.id,
        userId: ownerUserId,
        email: '',
        name: 'Owner',
        role: MemberRole.owner,
      );
      _members[ownerMember.id] = ownerMember;
    }

    if (!_artists.values.any((a) => a.shopId == shop.id && a.linkedUserId == ownerUserId)) {
      final mainArtist = Artist(
        shopId: shop.id,
        name: 'Main Artist',
        linkedUserId: ownerUserId,
      );
      _artists[mainArtist.id] = mainArtist;
    }

    return shop;
  }

  // Members
  @override
  List<Member> getMembers({String? shopId}) =>
      _members.values.where((m) => shopId == null || m.shopId == shopId).toList();
  @override
  Future<List<Member>> listMembers(String shopId) async => getMembers(shopId: shopId);
  @override
  Future<void> saveMember(Member member) async {
    _members[member.id] = member;
  }
  @override
  Future<void> deleteMember(String id) async {
    _members.remove(id);
  }
  @override
  Future<Invite> createInvite({
    required String shopId,
    required String email,
    required MemberRole role,
    String? artistId,
    required String createdBy,
  }) async {
    final invite = Invite(shopId: shopId, email: email, artistId: artistId);
    _invites[invite.id] = invite;
    return invite;
  }
  @override
  Future<void> revokeInvite(String shopId, String inviteId) async {
    _invites.remove(inviteId);
  }
  @override
  Future<void> acceptInvite(String shopId, String inviteId, String token, String userId, String email) async {
    final invite = _invites[inviteId];
    if (invite != null) {
      _invites.remove(inviteId);
      final member = Member(
        shopId: shopId,
        userId: userId,
        email: email,
        name: email.split('@').first,
        role: MemberRole.member,
        invitedArtistId: invite.artistId,
      );
      _members[member.id] = member;
    }
  }
  @override
  Future<void> changeMemberRole(String shopId, String memberUid, MemberRole role, {String? artistId}) async {
    final member = _members.values.firstWhere((m) => m.shopId == shopId && m.userId == memberUid);
    _members[member.id] = member.copyWith(role: role, invitedArtistId: artistId);
  }
  @override
  Future<void> removeMember(String shopId, String memberUid) async {
    _members.removeWhere((id, m) => m.shopId == shopId && m.userId == memberUid);
  }

  // Invites
  @override
  List<Invite> getInvites({String? shopId}) =>
      _invites.values.where((i) => shopId == null || i.shopId == shopId).toList();
  @override
  Future<void> saveInvite(Invite invite) async {
    _invites[invite.id] = invite;
  }
  @override
  Future<void> deleteInvite(String id) async {
    _invites.remove(id);
  }

  // Artists
  @override
  List<Artist> getArtists({String? shopId}) =>
      _artists.values.where((a) => shopId == null || a.shopId == shopId).toList();
  @override
  Future<void> saveArtist(Artist artist) async {
    _artists[artist.id] = artist;
  }
  @override
  Future<void> deleteArtist(String id) async {
    _artists.remove(id);
  }

  // Catalog
  @override
  List<Category> getCategories({String? shopId}) =>
      _categories.values.where((c) => shopId == null || c.shopId == shopId).toList();
  @override
  Stream<List<Category>> watchCategories(String shopId) => Stream.value(getCategories(shopId: shopId));
  @override
  Future<void> saveCategory(Category category) async {
    _categories[category.id] = category;
  }
  @override
  Future<void> upsertCategory(Category category) => saveCategory(category);
  @override
  Future<void> deleteCategory(String shopId, String categoryId, {String? targetCategoryId}) async {
    for (var prod in getProducts(shopId: shopId)) {
      if (prod.categoryId == categoryId) {
        _products[prod.id] = prod.copyWith(categoryId: targetCategoryId ?? '');
      }
    }
    for (var child in getCategories(shopId: shopId).where((c) => c.parentCategoryId == categoryId)) {
      _categories[child.id] = child.copyWith(parentCategoryId: null);
    }
    _categories.remove(categoryId);
  }

  @override
  List<Product> getProducts({String? shopId}) =>
      _products.values.where((p) => shopId == null || p.shopId == shopId).toList();
  @override
  Product? getProduct(String id) => _products[id];
  @override
  Stream<List<Product>> watchProducts(String shopId) => Stream.value(getProducts(shopId: shopId));
  @override
  Future<void> saveProduct(Product product) async {
    _products[product.id] = product;
  }
  @override
  Future<void> upsertProduct(Product product) => saveProduct(product);
  @override
  Future<void> deleteProduct(String id) async {
    _products.remove(id);
  }
  @override
  Future<void> setProductActive(String shopId, String productId, bool active) async {
    final p = _products[productId];
    if (p != null) _products[productId] = p.copyWith(active: active);
  }

  // Events
  @override
  List<Event> getEvents({String? shopId}) =>
      _events.values.where((e) => shopId == null || e.shopId == shopId).toList();
  @override
  Event? getActiveEvent({String? shopId}) {
    final list = getEvents(shopId: shopId);
    return list.cast<Event?>().firstWhere((e) => e?.isActive == true, orElse: () => list.isNotEmpty ? list.first : null);
  }
  @override
  Stream<List<Event>> watchEvents(String shopId) => Stream.value(getEvents(shopId: shopId));
  @override
  Future<void> saveEvent(Event event) async {
    if (event.isActive) {
      for (var e in getEvents(shopId: event.shopId)) {
        if (e.id != event.id && e.isActive) {
          _events[e.id] = e.copyWith(isActive: false);
        }
      }
    }
    _events[event.id] = event;
  }
  @override
  Future<void> upsertEvent(Event event) => saveEvent(event);
  @override
  Future<void> deleteEvent(String id) async {
    _events.remove(id);
  }
  @override
  List<String> getEventArtistIds(String eventId) => _eventArtists[eventId] ?? [];
  @override
  Future<void> setEventArtistsSync(String eventId, List<String> artistIds) async {
    _eventArtists[eventId] = List.from(artistIds);
  }
  @override
  Future<void> setEventArtists(String shopId, String eventId, List<String> artistIds) =>
      setEventArtistsSync(eventId, artistIds);
  @override
  Future<void> setEventProducts(String shopId, String eventId, List<String> productIds) async {
    final e = _events[eventId];
    if (e != null) _events[eventId] = e.copyWith(eventProductIds: productIds);
  }
  @override
  Future<Event> cloneFromEvent({
    required String shopId,
    required String sourceEventId,
    required String newEventName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final srcEvent = _events[sourceEventId];
    final srcArtists = _eventArtists[sourceEventId] ?? [];
    final cloned = Event(
      shopId: shopId,
      name: newEventName,
      startDate: startDate,
      endDate: endDate,
      eventArtistIds: srcArtists,
      eventProductIds: srcEvent?.eventProductIds ?? [],
    );
    await saveEvent(cloned);
    await setEventArtistsSync(cloned.id, srcArtists);
    return cloned;
  }

  // Orders & Stock
  @override
  List<Order> getOrders({String? shopId}) =>
      _orders.values.where((o) => shopId == null || o.shopId == shopId).toList();
  @override
  Order? getOrder(String id) => _orders[id];
  @override
  Stream<List<Order>> watchOrders(String shopId, {String? eventId, String? createdBy}) {
    var list = getOrders(shopId: shopId);
    if (eventId != null) list = list.where((o) => o.eventId == eventId).toList();
    if (createdBy != null) list = list.where((o) => o.createdBy == createdBy).toList();
    return Stream.value(list);
  }
  @override
  int get pendingCount => _orders.values.where((o) => !o.synced).length;

  @override
  Future<Order> placeOrder(Order order) async {
    if (_orders.containsKey(order.id)) {
      return _orders[order.id]!; // Idempotent
    }
    _orders[order.id] = order;

    for (var item in order.items) {
      final movementId = 'sale_${order.id}_${item.productId}';
      _movements.add(StockMovement(
        id: movementId,
        productId: item.productId,
        orderId: order.id,
        type: StockMovementType.sale,
        qtyChange: -item.qty,
        createdBy: order.createdBy,
      ));

      final product = _products[item.productId];
      if (product != null) {
        _products[item.productId] = product.copyWith(
          stock: product.stock - item.qty,
          updatedAt: DateTime.now(),
          updatedBy: order.createdBy,
        );
      }
    }
    return order;
  }

  @override
  Future<void> voidOrder({
    required String shopId,
    required String orderId,
    required String voidedBy,
    required String voidReason,
  }) async {
    final order = _orders[orderId];
    if (order == null || order.status == OrderStatus.voided) {
      throw Exception('Order already voided or not found');
    }

    _orders[orderId] = order.copyWith(
      status: OrderStatus.voided,
      voidedAt: DateTime.now(),
      voidedBy: voidedBy,
      voidReason: voidReason,
    );

    for (var item in order.items) {
      final movementId = 'void_${order.id}_${item.productId}';
      _movements.add(StockMovement(
        id: movementId,
        productId: item.productId,
        orderId: order.id,
        type: StockMovementType.voidAction,
        qtyChange: item.qty,
        createdBy: voidedBy,
      ));

      final product = _products[item.productId];
      if (product != null) {
        _products[item.productId] = product.copyWith(
          stock: product.stock + item.qty,
          updatedAt: DateTime.now(),
          updatedBy: voidedBy,
        );
      }
    }
  }

  @override
  Future<void> manualAdjust({
    required String shopId,
    required String productId,
    required int qtyChange,
    required String createdBy,
  }) async {
    final product = _products[productId];
    if (product != null) {
      _products[productId] = product.copyWith(
        stock: product.stock + qtyChange,
        updatedAt: DateTime.now(),
        updatedBy: createdBy,
      );
      _movements.add(StockMovement(
        productId: productId,
        type: StockMovementType.manualAdjust,
        qtyChange: qtyChange,
        createdBy: createdBy,
      ));
    }
  }

  @override
  List<StockMovement> getMovements(String productId) =>
      _movements.where((m) => m.productId == productId).toList();
  @override
  Stream<List<StockMovement>> watchMovements(String shopId, String productId) =>
      Stream.value(getMovements(productId));

  // Settlement
  @override
  List<Settlement> getSettlements(String eventId, {String? shopId}) =>
      _settlements.values.where((s) => s.eventId == eventId && (shopId == null || s.shopId == shopId)).toList();

  @override
  Future<void> saveSettlement(Settlement settlement) async {
    _settlements[settlement.id] = settlement;
  }

  @override
  Future<List<Settlement>> computeForEvent({
    required String shopId,
    required String eventId,
    required List<Artist> artists,
  }) async {
    final completedOrders = _orders.values
        .where((o) => o.shopId == shopId && o.eventId == eventId && o.status == OrderStatus.completed)
        .toList();

    final savedList = getSettlements(eventId, shopId: shopId);
    final results = <Settlement>[];

    for (var artist in artists) {
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
      final commissionAmount = netSales * (rate / 100.0);
      final netPayout = netSales - commissionAmount;

      Settlement? existing;
      try {
        existing = savedList.firstWhere((s) => s.artistId == artist.id);
      } catch (_) {}

      results.add(Settlement(
        id: existing?.id,
        shopId: shopId,
        eventId: eventId,
        artistId: artist.id,
        grossSales: netSales,
        commissionAmount: commissionAmount,
        netPayout: netPayout,
        paid: existing?.paid ?? false,
        paidAt: existing?.paidAt,
        note: existing?.note ?? '',
      ));
    }
    return results;
  }

  @override
  Future<void> markPaid(String settlementId, {required String note}) async {
    final s = _settlements[settlementId];
    if (s != null) {
      _settlements[settlementId] = s.copyWith(paid: true, paidAt: DateTime.now(), note: note);
    }
  }

  @override
  String exportCsv(List<Settlement> settlements, {required List<Artist> artists}) {
    final buffer = StringBuffer();
    buffer.writeln('Artist,Net Sales,Commission Rate,Commission Amount,Net Payout,Status,Paid At,Note');
    for (var s in settlements) {
      final artistName = artists
          .firstWhere((a) => a.id == s.artistId, orElse: () => Artist(shopId: '', name: s.artistId))
          .name;
      buffer.writeln(
        '"$artistName",${s.grossSales.toStringAsFixed(2)},,${s.commissionAmount.toStringAsFixed(2)},${s.netPayout.toStringAsFixed(2)},${s.paid ? "PAID" : "UNPAID"},${s.paidAt?.toIso8601String() ?? ""},"${s.note}"',
      );
    }
    return buffer.toString();
  }

  @override
  Future<void> markAllSynced({String? shopId}) async {
    for (var entry in _orders.entries) {
      if (shopId == null || entry.value.shopId == shopId) {
        _orders[entry.key] = entry.value.copyWith(synced: true);
      }
    }
  }

  @override
  int getUnsyncedOrdersCount({String? shopId}) =>
      _orders.values.where((o) => (shopId == null || o.shopId == shopId) && !o.synced).length;
}
