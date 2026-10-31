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

/// Default Implementation leveraging local persistence / offline cache
class LocalRepositoryRegistry
    implements
        AuthRepository,
        ShopRepository,
        MemberRepository,
        CatalogRepository,
        EventRepository,
        OrderRepository,
        StockRepository,
        SettlementRepository {
  final DatabaseService db;
  String? _currentUserId = 'user_rickky_01';

  LocalRepositoryRegistry({required this.db});

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
    final shop = Shop(
      name: name,
      ownerUserId: ownerUserId,
      promptpayId: '',
      promptpayName: '',
    );
    await db.saveShop(shop);
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
    await db.saveOrder(order);

    // WriteBatch equivalent: decrement stock (allow negative) & save movements
    for (var item in order.items) {
      await db.addStockMovement(StockMovement(
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
      await db.addStockMovement(StockMovement(
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
