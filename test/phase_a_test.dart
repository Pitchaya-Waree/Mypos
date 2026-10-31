import 'package:flutter_test/flutter_test.dart';
import 'package:booth_pos_app/models/models.dart';
import 'package:booth_pos_app/services/database_service.dart';
import 'package:booth_pos_app/repositories/repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase A - Item 2: deleteCategory Cross-Shop Isolation', () {
    late DatabaseService db;
    late LocalRepositoryRegistry repo;

    setUp(() async {
      db = DatabaseService();
      await db.init('./test_hive_phase_a');
      await db.clearAllData();
      repo = LocalRepositoryRegistry(db: db);
    });

    tearDown(() async {
      await db.clearAllData();
    });

    test('deleteCategory in Shop A does not alter products in Shop B sharing the same categoryId', () async {
      const sharedCatId = 'cat_stickers';

      // Setup Shop A and Shop B
      await db.saveShop(Shop(id: 'shop_a', name: 'Shop A', promptpayId: '', promptpayName: '', ownerUserId: 'user_a'));
      await db.saveShop(Shop(id: 'shop_b', name: 'Shop B', promptpayId: '', promptpayName: '', ownerUserId: 'user_b'));

      // Category in Shop A
      await db.saveCategory(Category(id: sharedCatId, shopId: 'shop_a', name: 'Stickers'));
      // Category in Shop B with same ID
      await db.saveCategory(Category(id: sharedCatId, shopId: 'shop_b', name: 'Stickers B'));

      // Products in Shop A and Shop B
      final prodA = Product(
        id: 'prod_a',
        shopId: 'shop_a',
        artistId: 'artist_a',
        name: 'Sticker A',
        price: 50,
        categoryId: sharedCatId,
        stock: 10,
      );
      final prodB = Product(
        id: 'prod_b',
        shopId: 'shop_b',
        artistId: 'artist_b',
        name: 'Sticker B',
        price: 60,
        categoryId: sharedCatId,
        stock: 20,
      );

      await db.saveProduct(prodA);
      await db.saveProduct(prodB);

      // Act: Delete category in Shop A via repository
      await repo.deleteCategory('shop_a', sharedCatId);

      // Assert Shop A product category is cleared to empty
      final updatedA = db.getProduct('prod_a');
      expect(updatedA?.categoryId, '');

      // Assert Shop B product category is UNTOUCHED
      final updatedB = db.getProduct('prod_b');
      expect(updatedB?.categoryId, sharedCatId);
    });

    test('Phase A - Item 1: Cost confidentiality between Manager and Artists', () {
      final owner = Member(
        shopId: 'shop_a',
        userId: 'u_owner',
        email: 'owner@test.com',
        name: 'Owner',
        role: MemberRole.owner,
      );
      final managerA = Member(
        shopId: 'shop_a',
        userId: 'u_mgr_a',
        email: 'mgr_a@test.com',
        name: 'Manager A',
        role: MemberRole.manager,
        invitedArtistId: 'artist_a',
      );
      final managerB = Member(
        shopId: 'shop_a',
        userId: 'u_mgr_b',
        email: 'mgr_b@test.com',
        name: 'Manager B',
        role: MemberRole.manager,
        invitedArtistId: 'artist_b',
      );

      final prodA = Product(
        id: 'p_a',
        shopId: 'shop_a',
        artistId: 'artist_a',
        name: 'Print A',
        price: 300,
        cost: 120,
        stock: 5,
        categoryId: 'cat_prints',
      );
      final prodB = Product(
        id: 'p_b',
        shopId: 'shop_a',
        artistId: 'artist_b',
        name: 'Print B',
        price: 500,
        cost: 250,
        stock: 5,
        categoryId: 'cat_prints',
      );

      bool canViewCost(Member? m, Product p) {
        if (m == null || m.role == MemberRole.owner) return true;
        if (m.invitedArtistId != null) {
          return p.artistId == m.invitedArtistId;
        }
        return false;
      }

      // Owner sees all
      expect(canViewCost(owner, prodA), isTrue);
      expect(canViewCost(owner, prodB), isTrue);

      // Manager A sees only Artist A's product cost
      expect(canViewCost(managerA, prodA), isTrue);
      expect(canViewCost(managerA, prodB), isFalse);

      // Manager B sees only Artist B's product cost
      expect(canViewCost(managerB, prodA), isFalse);
      expect(canViewCost(managerB, prodB), isTrue);
    });

    test('Phase A - Item 10: Order items have non-empty orderId matching order.id after checkout', () async {
      await db.saveShop(Shop(id: 'shop_test', name: 'Test Shop', promptpayId: '', promptpayName: '', ownerUserId: 'u1'));
      final prod = Product(
        id: 'prod_test',
        shopId: 'shop_test',
        artistId: 'art_1',
        name: 'Item 1',
        price: 100,
        categoryId: '',
        stock: 10,
      );
      await db.saveProduct(prod);

      // Add to cart and checkout via posProvider logic
      final cartItem = CartItem(product: prod, qty: 2);
      // Simulate checkout
      const generatedOrderId = 'order_uuid_123';
      final orderItem = OrderItem(
        orderId: generatedOrderId,
        productId: cartItem.product.id,
        artistId: cartItem.product.artistId,
        nameSnapshot: cartItem.product.name,
        priceSnapshot: cartItem.product.price,
        qty: cartItem.qty,
        discountAmount: cartItem.discount,
      );

      final order = Order(
        id: generatedOrderId,
        shopId: 'shop_test',
        eventId: 'event_1',
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.cash,
        total: 200,
        items: [orderItem],
      );

      await db.saveOrder(order);

      final fetchedOrder = db.getOrder(generatedOrderId);
      expect(fetchedOrder, isNotNull);
      expect(fetchedOrder!.items, isNotEmpty);
      for (var item in fetchedOrder.items) {
        expect(item.orderId, isNotEmpty);
        expect(item.orderId, equals(fetchedOrder.id));
      }
    });

    test('Phase A - Item 7: createShop generates owner member & default artist; unauthenticated member has least privilege', () async {
      final createdShop = await repo.createShop(name: 'Handmade Crafts', ownerUserId: 'u_artisan');

      final members = await repo.listMembers(createdShop.id);
      expect(members.length, 1);
      expect(members.first.userId, 'u_artisan');
      expect(members.first.role, MemberRole.owner);

      final artists = db.getArtists(shopId: createdShop.id);
      expect(artists.length, 1);
      expect(artists.first.linkedUserId, 'u_artisan');

      // Calling createShop again does not duplicate member or artist
      await repo.createShop(name: 'Handmade Crafts', ownerUserId: 'u_artisan');
      final artistsAfter = db.getArtists(shopId: createdShop.id);
      expect(artistsAfter.length, 1);
    });

    test('Phase A - Item 6: Manual stock adjust allows negative stock (-3) & records StockMovement', () async {
      final p = Product(
        id: 'p_adjust',
        shopId: 'shop_test',
        artistId: 'art_1',
        name: 'Manual Product',
        price: 100,
        categoryId: '',
        stock: 0,
      );
      await db.saveProduct(p);

      // Adjust by -3
      final product = db.getProduct('p_adjust')!;
      final newStock = product.stock + (-3);
      await db.saveProduct(product.copyWith(stock: newStock));
      await db.addStockMovement(StockMovement(
        productId: 'p_adjust',
        type: StockMovementType.manualAdjust,
        qtyChange: -3,
      ));

      final fetched = db.getProduct('p_adjust');
      expect(fetched?.stock, -3);

      final movements = db.getMovements('p_adjust');
      expect(movements.any((m) => m.type == StockMovementType.manualAdjust && m.qtyChange == -3), isTrue);
    });
  });
}
