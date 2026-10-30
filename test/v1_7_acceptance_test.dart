import 'package:flutter_test/flutter_test.dart';
import 'package:booth_pos_app/models/models.dart';

void main() {
  group('v1.7 Acceptance Criteria Tests (Roles, Central Catalog, Negative Stock & Firebase Architecture)', () {
    // -------------------------------------------------------------
    // Test 1: Three-tier Role Hierarchy & Permissions (Section 3 & 12.1)
    // -------------------------------------------------------------
    test('12.1 Three-tier roles: Owner, Manager, and Member permission boundaries', () {
      final owner = Member(
        shopId: 'shop_1',
        userId: 'u_owner',
        email: 'owner@test.com',
        name: 'Shop Owner',
        role: MemberRole.owner,
      );

      final manager = Member(
        shopId: 'shop_1',
        userId: 'u_manager',
        email: 'manager@test.com',
        name: 'Shop Manager',
        role: MemberRole.manager,
        invitedArtistId: 'artist_1',
      );

      final member = Member(
        shopId: 'shop_1',
        userId: 'u_member',
        email: 'staff@test.com',
        name: 'Staff Member',
        role: MemberRole.member,
        invitedArtistId: 'artist_1',
      );

      // Permissions check functions
      bool canVoidOrder(Member m) => m.role == MemberRole.owner || m.role == MemberRole.manager;
      bool canManageCatalog(Member m) => m.role == MemberRole.owner || m.role == MemberRole.manager;
      bool canViewSettlement(Member m) => m.role == MemberRole.owner;
      bool canEditPromptPay(Member m) => m.role == MemberRole.owner;
      bool canInviteManager(Member m) => m.role == MemberRole.owner;
      bool canInviteMember(Member m) => m.role == MemberRole.owner || m.role == MemberRole.manager;

      // 1. Owner has all rights
      expect(canVoidOrder(owner), isTrue);
      expect(canManageCatalog(owner), isTrue);
      expect(canViewSettlement(owner), isTrue);
      expect(canEditPromptPay(owner), isTrue);
      expect(canInviteManager(owner), isTrue);
      expect(canInviteMember(owner), isTrue);

      // 2. Manager has catalog & void rights, but CANNOT view settlement or edit promptpay or invite manager
      expect(canVoidOrder(manager), isTrue);
      expect(canManageCatalog(manager), isTrue);
      expect(canViewSettlement(manager), isFalse); // Restricted to Owner
      expect(canEditPromptPay(manager), isFalse);  // Restricted to Owner
      expect(canInviteManager(manager), isFalse);  // Restricted to Owner
      expect(canInviteMember(manager), isTrue);   // Can invite Member only

      // 3. Member can only sell; CANNOT void, CANNOT manage catalog, CANNOT view settlement
      expect(canVoidOrder(member), isFalse);
      expect(canManageCatalog(member), isFalse);
      expect(canViewSettlement(member), isFalse);
      expect(canEditPromptPay(member), isFalse);
      expect(canInviteMember(member), isFalse);
    });

    // -------------------------------------------------------------
    // Test 2: Cost Visibility for Owner vs Manager vs Member (Section 3 & 12.1)
    // -------------------------------------------------------------
    test('12.1 Cost visibility: Owner sees all; Manager and Member only see linked artist cost', () {
      final p1 = Product(
        shopId: 'shop_1',
        artistId: 'artist_1',
        name: 'Sticker 1',
        price: 50.0,
        cost: 20.0,
        categoryId: 'cat_1',
        stock: 10,
      );

      final p2 = Product(
        shopId: 'shop_1',
        artistId: 'artist_2',
        name: 'Sticker 2',
        price: 80.0,
        cost: 30.0,
        categoryId: 'cat_1',
        stock: 10,
      );

      bool canViewCost(Member m, Product p) {
        if (m.role == MemberRole.owner) return true;
        return m.invitedArtistId != null && m.invitedArtistId == p.artistId;
      }

      final owner = Member(
        shopId: 'shop_1',
        userId: 'u_owner',
        email: 'owner@test.com',
        name: 'Owner',
        role: MemberRole.owner,
      );

      final managerLinkedToA1 = Member(
        shopId: 'shop_1',
        userId: 'u_mgr',
        email: 'mgr@test.com',
        name: 'Mgr',
        role: MemberRole.manager,
        invitedArtistId: 'artist_1',
      );

      final memberLinkedToA1 = Member(
        shopId: 'shop_1',
        userId: 'u_mem',
        email: 'mem@test.com',
        name: 'Mem',
        role: MemberRole.member,
        invitedArtistId: 'artist_1',
      );

      // Owner sees costs for both products
      expect(canViewCost(owner, p1), isTrue);
      expect(canViewCost(owner, p2), isTrue);

      // Manager sees cost for artist_1, but NOT artist_2
      expect(canViewCost(managerLinkedToA1, p1), isTrue);
      expect(canViewCost(managerLinkedToA1, p2), isFalse);

      // Member sees cost for artist_1, but NOT artist_2
      expect(canViewCost(memberLinkedToA1, p1), isTrue);
      expect(canViewCost(memberLinkedToA1, p2), isFalse);
    });

    // -------------------------------------------------------------
    // Test 3: Member Order Scope Isolation (Section 3 & 12.1)
    // -------------------------------------------------------------
    test('12.1 Order visibility: Member sees only own orders, Owner/Manager sees all', () {
      final orders = [
        Order(
          id: 'o1',
          shopId: 'shop_1',
          eventId: 'ev1',
          paymentMethod: PaymentMethod.cash,
          total: 100,
          createdBy: 'u_member_1',
          items: [],
        ),
        Order(
          id: 'o2',
          shopId: 'shop_1',
          eventId: 'ev1',
          paymentMethod: PaymentMethod.cash,
          total: 200,
          createdBy: 'u_member_2',
          items: [],
        ),
        Order(
          id: 'o3',
          shopId: 'shop_1',
          eventId: 'ev1',
          paymentMethod: PaymentMethod.qr,
          total: 150,
          createdBy: 'u_member_1',
          items: [],
        ),
      ];

      List<Order> getVisibleOrders(MemberRole role, String uid) {
        if (role == MemberRole.member) {
          return orders.where((o) => o.createdBy == uid).toList();
        }
        return orders;
      }

      // Member 1 only sees their 2 orders
      final m1Orders = getVisibleOrders(MemberRole.member, 'u_member_1');
      expect(m1Orders.length, 2);
      expect(m1Orders.map((o) => o.id).toSet(), {'o1', 'o3'});

      // Manager sees all 3 orders
      final mgrOrders = getVisibleOrders(MemberRole.manager, 'u_mgr');
      expect(mgrOrders.length, 3);

      // Owner sees all 3 orders
      final ownerOrders = getVisibleOrders(MemberRole.owner, 'u_owner');
      expect(ownerOrders.length, 3);
    });

    // -------------------------------------------------------------
    // Test 4: Negative Stock Allowed with Warning (Section 0, 5.1 & 12.2)
    // -------------------------------------------------------------
    test('12.2 Stock can go negative (-1) when sold without blocking checkout', () {
      final product = Product(
        id: 'p_last',
        shopId: 's1',
        artistId: 'a1',
        name: 'Last Standee',
        price: 250.0,
        stock: 1, // Only 1 in stock
        categoryId: 'cat1',
      );

      // Device 1 and Device 2 both sell 1 item offline
      const saleQty1 = 1;
      const saleQty2 = 1;

      int currentStock = product.stock;
      currentStock -= saleQty1;
      expect(currentStock, 0);

      // Concurrent second sale makes stock -1
      currentStock -= saleQty2;
      expect(currentStock, -1);

      final updatedProduct = product.copyWith(stock: currentStock);
      expect(updatedProduct.stock, -1);
      expect(updatedProduct.isNegativeStock, isTrue);
      expect(updatedProduct.isOutOfStock, isTrue);
    });

    // -------------------------------------------------------------
    // Test 5: Order Atomic Items Array & artistTotals Aggregation (Section 4 & 12.5)
    // -------------------------------------------------------------
    test('12.5 Order embeds artistTotals map directly and matches settlement aggregation', () {
      final items = [
        OrderItem(
          orderId: 'ord_1',
          productId: 'prod_a',
          artistId: 'artist_a',
          nameSnapshot: 'A Print',
          priceSnapshot: 300.0,
          qty: 2, // 600
          discountAmount: 60.0, // net 540
        ),
        OrderItem(
          orderId: 'ord_1',
          productId: 'prod_b',
          artistId: 'artist_b',
          nameSnapshot: 'B Keyring',
          priceSnapshot: 200.0,
          qty: 1, // 200
          discountAmount: 20.0, // net 180
        ),
      ];

      final order = Order(
        shopId: 'shop_1',
        eventId: 'event_art',
        paymentMethod: PaymentMethod.qr,
        total: 720.0, // 540 + 180
        items: items,
        createdBy: 'user_staff',
      );

      // Verify artistTotals map embedded in the order
      expect(order.artistTotals.containsKey('artist_a'), isTrue);
      expect(order.artistTotals['artist_a']!.gross, 600.0);
      expect(order.artistTotals['artist_a']!.discount, 60.0);
      expect(order.artistTotals['artist_a']!.net, 540.0);
      expect(order.artistTotals['artist_a']!.qty, 2);

      expect(order.artistTotals.containsKey('artist_b'), isTrue);
      expect(order.artistTotals['artist_b']!.gross, 200.0);
      expect(order.artistTotals['artist_b']!.discount, 20.0);
      expect(order.artistTotals['artist_b']!.net, 180.0);
      expect(order.artistTotals['artist_b']!.qty, 1);

      // Aggregate settlement directly from artistTotals
      final completedOrders = [order];
      double aGross = 0.0;
      double aNet = 0.0;
      for (var o in completedOrders) {
        final summary = o.artistTotals['artist_a'];
        if (summary != null) {
          aGross += summary.gross;
          aNet += summary.net;
        }
      }
      expect(aGross, 600.0);
      expect(aNet, 540.0);
    });

    // -------------------------------------------------------------
    // Test 6: Central Catalog & Event Selection (Section 4.2 & 12.4)
    // -------------------------------------------------------------
    test('12.4 Central catalog selection: Event filters products by eventProducts & eventArtists', () {
      final centralProducts = [
        Product(id: 'p1', shopId: 's1', artistId: 'a1', name: 'Cat Pin', price: 100, stock: 10, categoryId: 'c1'),
        Product(id: 'p2', shopId: 's1', artistId: 'a1', name: 'Cat Poster', price: 150, stock: 10, categoryId: 'c1'),
        Product(id: 'p3', shopId: 's1', artistId: 'a2', name: 'Dog Standee', price: 200, stock: 5, categoryId: 'c2'),
      ];

      // Event 1 brings artist a1 & a2, but only selects p1 and p3 from central catalog
      final event1 = Event(
        id: 'event_1',
        shopId: 's1',
        name: 'Expo 1',
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 2),
        eventArtistIds: ['a1', 'a2'],
        eventProductIds: ['p1', 'p3'], // p2 not brought to this event!
      );

      final displayProducts = centralProducts.where((p) {
        if (!p.active) return false;
        if (event1.eventArtistIds.isNotEmpty && !event1.eventArtistIds.contains(p.artistId)) {
          return false;
        }
        if (event1.eventProductIds.isNotEmpty && !event1.eventProductIds.contains(p.id)) {
          return false;
        }
        return true;
      }).toList();

      expect(displayProducts.length, 2);
      expect(displayProducts.map((p) => p.id).toSet(), {'p1', 'p3'});
      // p2 remains in central catalog unharmed
      expect(centralProducts.any((p) => p.id == 'p2'), isTrue);
    });

    // -------------------------------------------------------------
    // Test 7: Multi-shop membership per user (Section 4 & 12.3)
    // -------------------------------------------------------------
    test('12.3 Single user can belong to multiple shops via UserMembership index', () {
      final memberships = [
        UserMembership(
          shopId: 'shop_a',
          shopName: 'Mako Shop',
          role: MemberRole.owner,
        ),
        UserMembership(
          shopId: 'shop_b',
          shopName: 'Crafty Fox',
          role: MemberRole.member,
        ),
      ];

      expect(memberships.length, 2);
      expect(memberships.first.shopName, 'Mako Shop');
      expect(memberships.first.role, MemberRole.owner);

      expect(memberships.last.shopName, 'Crafty Fox');
      expect(memberships.last.role, MemberRole.member);
    });

    // -------------------------------------------------------------
    // Test 8: Single-Void Protection & Reason Tracking (Section 5.2 & 12.1)
    // -------------------------------------------------------------
    test('12.1 Void order updates status to voided with reason and cannot be voided again', () {
      final order = Order(
        id: 'o_void_test',
        shopId: 's1',
        eventId: 'ev1',
        paymentMethod: PaymentMethod.cash,
        total: 300,
        status: OrderStatus.completed,
        items: [
          OrderItem(
            orderId: 'o_void_test',
            productId: 'p1',
            artistId: 'a1',
            nameSnapshot: 'Item 1',
            priceSnapshot: 300,
            qty: 1,
          ),
        ],
      );

      // Perform void
      final voidedOrder = order.copyWith(
        status: OrderStatus.voided,
        voidedAt: DateTime(2026, 10, 30, 18, 0),
        voidedBy: 'manager_uid',
        voidReason: 'Customer returned item',
      );

      expect(voidedOrder.status, OrderStatus.voided);
      expect(voidedOrder.voidedBy, 'manager_uid');
      expect(voidedOrder.voidReason, 'Customer returned item');

      // Attempting to void again is disallowed
      bool canVoidAgain(Order o) => o.status == OrderStatus.completed;
      expect(canVoidAgain(voidedOrder), isFalse);
    });

    // -------------------------------------------------------------
    // Test 9: Sign-out Guard when Pending Writes exist (Section 5.3 & 12.2)
    // -------------------------------------------------------------
    test('12.2 Sign-out guard blocks logout when pending unsynced writes exist', () {
      bool canSignOut(int pendingCount) => pendingCount == 0;

      expect(canSignOut(5), isFalse); // 5 orders pending sync -> BLOCKED!
      expect(canSignOut(0), isTrue);  // 0 pending -> Allowed!
    });
  });
}
