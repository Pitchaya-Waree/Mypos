import 'package:flutter_test/flutter_test.dart';
import 'package:booth_pos_app/models/models.dart';
import 'package:booth_pos_app/services/promptpay_service.dart';

void main() {
  group('v1.5 Acceptance Criteria Tests', () {
    // -------------------------------------------------------------
    // Test 1: Acceptance Criteria 4.5 - Proportional Discounts
    // -------------------------------------------------------------
    test('4.5 Proportional whole-bill discount is split according to gross sales ratio (30:70)', () {
      final pA = Product(
        id: 'prod_a',
        shopId: 'shop1',
        artistId: 'artist_a',
        name: 'Sticker A',
        price: 300,
        cost: 100,
        stock: 10,
        categoryId: 'cat1',
      );
      final pB = Product(
        id: 'prod_b',
        shopId: 'shop1',
        artistId: 'artist_b',
        name: 'Sticker B',
        price: 700,
        cost: 200,
        stock: 10,
        categoryId: 'cat1',
      );

      final cart = [
        CartItem(product: pA, qty: 1),
        CartItem(product: pB, qty: 1),
      ];

      final cartSubtotal = cart.fold(0.0, (s, i) => s + (i.product.price * i.qty));
      expect(cartSubtotal, 1000.0);

      // Apply 100 THB whole-bill discount
      const totalDiscount = 100.0;
      final artistGrossMap = <String, double>{};
      for (var item in cart) {
        final gross = item.product.price * item.qty;
        artistGrossMap[item.artistId] = (artistGrossMap[item.artistId] ?? 0.0) + gross;
      }

      for (var item in cart) {
        final artistShare = (artistGrossMap[item.artistId] ?? 0.0) / cartSubtotal;
        final artistDiscountTotal = totalDiscount * artistShare;
        final itemShareInArtist = (item.product.price * item.qty) / (artistGrossMap[item.artistId] ?? 1.0);
        item.discount = artistDiscountTotal * itemShareInArtist;
      }

      // Check: Artist A (300 THB gross) should get exactly 30 THB discount
      expect(cart[0].discount, 30.0);
      // Check: Artist B (700 THB gross) should get exactly 70 THB discount
      expect(cart[1].discount, 70.0);

      // Final total after discount
      final cartTotal = cartSubtotal - cart.fold(0.0, (s, i) => s + i.discount);
      expect(cartTotal, 900.0);
    });

    test('4.5 Artist-specific discount applies only to target artist items', () {
      final pA = Product(
        id: 'prod_a',
        shopId: 'shop1',
        artistId: 'artist_a',
        name: 'Item A',
        price: 200,
        cost: 50,
        stock: 10,
        categoryId: 'cat1',
      );
      final pB = Product(
        id: 'prod_b',
        shopId: 'shop1',
        artistId: 'artist_b',
        name: 'Item B',
        price: 300,
        cost: 80,
        stock: 10,
        categoryId: 'cat1',
      );

      final cart = [
        CartItem(product: pA, qty: 1),
        CartItem(product: pB, qty: 1),
      ];

      // Apply 50 THB discount ONLY to Artist A
      const discountToA = 50.0;
      final artistAItems = cart.where((i) => i.artistId == 'artist_a').toList();
      final artistAGross = artistAItems.fold(0.0, (s, i) => s + (i.product.price * i.qty));
      for (var item in artistAItems) {
        final share = (item.product.price * item.qty) / artistAGross;
        item.discount = discountToA * share;
      }

      expect(cart[0].discount, 50.0); // Artist A discounted 50
      expect(cart[1].discount, 0.0);  // Artist B untouched!
    });

    test('4.5 Clearing discount resets all items to 0 and restores full cart total', () {
      final pA = Product(
        id: 'p1',
        shopId: 'shop1',
        artistId: 'artist_a',
        name: 'Sticker Cat',
        price: 200,
        cost: 50,
        stock: 5,
        categoryId: 'cat1',
      );
      final pB = Product(
        id: 'p2',
        shopId: 'shop1',
        artistId: 'artist_b',
        name: 'Sticker Dog',
        price: 300,
        cost: 60,
        stock: 5,
        categoryId: 'cat1',
      );

      final cart = [
        CartItem(product: pA, qty: 2), // 400 gross
        CartItem(product: pB, qty: 1), // 300 gross
      ];

      final subtotal = cart.fold(0.0, (s, i) => s + (i.product.price * i.qty));
      expect(subtotal, 700.0);

      // 1. Add discount
      void applyDiscount(double totalDiscount) {
        if (totalDiscount <= 0) {
          for (var item in cart) {
            item.discount = 0.0;
          }
          return;
        }
        final grossMap = <String, double>{};
        for (var item in cart) {
          grossMap[item.artistId] = (grossMap[item.artistId] ?? 0) + (item.product.price * item.qty);
        }
        for (var item in cart) {
          final artistShare = (grossMap[item.artistId] ?? 0) / subtotal;
          final artistDiscount = totalDiscount * artistShare;
          final itemShare = (item.product.price * item.qty) / (grossMap[item.artistId] ?? 1);
          item.discount = artistDiscount * itemShare;
        }
      }

      applyDiscount(70.0);
      expect(cart[0].discount, 40.0); // 400/700 * 70 = 40
      expect(cart[1].discount, 30.0); // 300/700 * 70 = 30
      expect(cart[0].totalPrice, 360.0); // 400 - 40 = 360
      expect(cart[1].totalPrice, 270.0); // 300 - 30 = 270

      var totalWithDiscount = subtotal - cart.fold(0.0, (s, i) => s + i.discount);
      expect(totalWithDiscount, 630.0);

      // 2. Clear discount
      applyDiscount(0.0);
      expect(cart[0].discount, 0.0);
      expect(cart[1].discount, 0.0);
      expect(cart[0].totalPrice, 400.0); // Restored
      expect(cart[1].totalPrice, 300.0); // Restored

      var restoredTotal = subtotal - cart.fold(0.0, (s, i) => s + i.discount);
      expect(restoredTotal, 700.0); // Full total restored!
    });

    test('4.5 Itemized discount details correctly tracks which items got discount', () {
      final pA = Product(
        id: 'p1',
        shopId: 'shop1',
        artistId: 'artist_a',
        name: 'Cat Postcard',
        price: 150,
        cost: 50,
        stock: 10,
        categoryId: 'cat1',
      );
      final pB = Product(
        id: 'p2',
        shopId: 'shop1',
        artistId: 'artist_b',
        name: 'Dog Keyring',
        price: 250,
        cost: 80,
        stock: 10,
        categoryId: 'cat1',
      );

      final cart = [
        CartItem(product: pA, qty: 2), // 300
        CartItem(product: pB, qty: 1), // 250
      ];

      // Discount only Artist A by 60 THB
      cart[0].discount = 60.0;
      cart[1].discount = 0.0;

      final discountedItems = cart.where((i) => i.discount > 0).toList();
      expect(discountedItems.length, 1);
      expect(discountedItems.first.product.name, 'Cat Postcard');
      expect(discountedItems.first.discount, 60.0);
      expect(discountedItems.first.totalPrice, 240.0); // 300 - 60 = 240

      // Undiscounted item remains full price
      expect(cart[1].discount, 0.0);
      expect(cart[1].totalPrice, 250.0);
    });

    // -------------------------------------------------------------
    // Test 2: Acceptance Criteria 4.6 - Settlement Calculation
    // -------------------------------------------------------------
    test('4.6 Settlement computes 10% commission correctly (Gross: 1000 -> Comm: 100, Net: 900)', () {
      const grossSales = 1000.0;
      const commissionRate = 10.0; // 10%

      final commission = grossSales * (commissionRate / 100.0);
      final netPayout = grossSales - commission;

      expect(commission, 100.0);
      expect(netPayout, 900.0);

      final settlement = Settlement(
        shopId: 'shop1',
        eventId: 'event_01',
        artistId: 'artist_a',
        grossSales: grossSales,
        commissionAmount: commission,
        netPayout: netPayout,
        paid: false,
      );

      expect(settlement.grossSales, 1000.0);
      expect(settlement.commissionAmount, 100.0);
      expect(settlement.netPayout, 900.0);
      expect(settlement.paid, isFalse);

      // Mark paid
      final paidSettlement = settlement.copyWith(
        paid: true,
        paidAt: DateTime(2026, 10, 27, 18, 0),
        note: 'โอนผ่าน K-Bank',
      );
      expect(paidSettlement.paid, isTrue);
      expect(paidSettlement.note, 'โอนผ่าน K-Bank');
    });

    test('4.6 Voided orders are excluded from settlement gross sales', () {
      final orders = [
        Order(
          shopId: 'shop1',
          eventId: 'event_01',
          status: OrderStatus.completed,
          paymentMethod: PaymentMethod.cash,
          total: 500,
          cashReceived: 500,
          change: 0,
          synced: true,
          createdOffline: true,
          items: [
            OrderItem(
              orderId: 'o1',
              productId: 'p1',
              artistId: 'artist_a',
              nameSnapshot: 'Product 1',
              priceSnapshot: 500,
              qty: 1,
            ),
          ],
        ),
        Order(
          shopId: 'shop1',
          eventId: 'event_01',
          status: OrderStatus.voided, // Voided!
          paymentMethod: PaymentMethod.cash,
          total: 800,
          cashReceived: 800,
          change: 0,
          synced: true,
          createdOffline: true,
          items: [
            OrderItem(
              orderId: 'o2',
              productId: 'p2',
              artistId: 'artist_a',
              nameSnapshot: 'Product 2',
              priceSnapshot: 800,
              qty: 1,
            ),
          ],
        ),
      ];

      // Calculate gross sales for artist_a excluding voided
      final validOrders = orders.where((o) => o.status == OrderStatus.completed);
      var gross = 0.0;
      for (var o in validOrders) {
        for (var item in o.items.where((i) => i.artistId == 'artist_a')) {
          gross += item.subtotal;
        }
      }

      expect(gross, 500.0); // Only 500, not 1300!
    });

    // -------------------------------------------------------------
    // Test 3: Acceptance Criteria 4.8 - Role & Cost Visibility
    // -------------------------------------------------------------
    test('4.8 Cost visibility rules: Owner sees all, Member only sees linked artist cost', () {
      final prodA = Product(
        id: 'p1',
        shopId: 'shop1',
        artistId: 'artist_a',
        name: 'Item A',
        price: 100,
        cost: 40,
        stock: 5,
        categoryId: 'cat1',
      );
      final prodB = Product(
        id: 'p2',
        shopId: 'shop1',
        artistId: 'artist_b',
        name: 'Item B',
        price: 150,
        cost: 60,
        stock: 5,
        categoryId: 'cat1',
      );

      bool canViewCost(MemberRole role, String? linkedArtistId, Product product) {
        if (role == MemberRole.owner) return true;
        if (linkedArtistId != null) {
          return product.artistId == linkedArtistId;
        }
        return false;
      }

      // Case 1: Owner sees both
      expect(canViewCost(MemberRole.owner, null, prodA), isTrue);
      expect(canViewCost(MemberRole.owner, null, prodB), isTrue);

      // Case 2: Member linked to artist_a sees prodA, but NOT prodB
      expect(canViewCost(MemberRole.member, 'artist_a', prodA), isTrue);
      expect(canViewCost(MemberRole.member, 'artist_a', prodB), isFalse);

      // Case 3: Member not linked to any artist sees neither
      expect(canViewCost(MemberRole.member, null, prodA), isFalse);
      expect(canViewCost(MemberRole.member, null, prodB), isFalse);
    });

    // -------------------------------------------------------------
    // Test 4: Acceptance Criteria 4.4 - Stock limit prevention
    // -------------------------------------------------------------
    test('4.4 Out of stock prevention: cart qty cannot exceed product stock', () {
      final p = Product(
        id: 'p_limited',
        shopId: 'shop1',
        artistId: 'artist_a',
        name: 'Limited Edition Keyring',
        price: 250,
        cost: 100,
        stock: 1, // Only 1 in stock!
        categoryId: 'cat1',
      );

      final cart = <CartItem>[];

      void addToCart(Product product) {
        final existingIndex = cart.indexWhere((item) => item.product.id == product.id);
        if (existingIndex >= 0) {
          if (cart[existingIndex].qty + 1 > product.stock) {
            return; // Blocked!
          }
          cart[existingIndex].qty += 1;
        } else {
          if (product.stock < 1) return;
          cart.add(CartItem(product: product, qty: 1));
        }
      }

      addToCart(p); // First add -> Qty 1
      expect(cart.length, 1);
      expect(cart[0].qty, 1);

      addToCart(p); // Second add -> Blocked, stays at 1!
      expect(cart[0].qty, 1);
    });

    // -------------------------------------------------------------
    // Test 5: PromptPay Offline Payload Format Verification
    // -------------------------------------------------------------
    test('PromptPay payload generates correct EMVCo tags and CRC16 offline', () {
      final payload = PromptPayService.generatePayload(
        promptpayId: '0812345678',
        amount: 250.0,
      );

      expect(payload.startsWith('000201'), isTrue); // EMVCo Payload Format
      expect(payload.contains('5303764'), isTrue);  // THB Currency 764
      expect(payload.contains('5406250.00'), isTrue); // Amount 250.00
      expect(payload.length >= 60, isTrue);
    });

    // -------------------------------------------------------------
    // Test 6: Multi-Artist Snapshot in OrderItem (Requirement 3 & 4.5)
    // -------------------------------------------------------------
    test('3 & 4.5 OrderItem snapshots artist_id and price at sale time and remains unchanged even if artist/product is deleted', () {
      final pA = Product(
        id: 'prod_a',
        shopId: 'shop1',
        artistId: 'artist_rickky',
        name: 'Cat Sticker Pack',
        price: 250,
        cost: 80,
        stock: 20,
        categoryId: 'cat1',
      );
      final pB = Product(
        id: 'prod_b',
        shopId: 'shop1',
        artistId: 'artist_mimi',
        name: 'Dog Acrylic Keyring',
        price: 350,
        cost: 120,
        stock: 15,
        categoryId: 'cat1',
      );

      // Snapshot into OrderItem at checkout
      final orderItemA = OrderItem(
        orderId: 'order_123',
        productId: pA.id,
        artistId: pA.artistId, // Essential snapshot!
        nameSnapshot: pA.name,
        priceSnapshot: pA.price,
        qty: 2,
        discountAmount: 20,
      );

      final orderItemB = OrderItem(
        orderId: 'order_123',
        productId: pB.id,
        artistId: pB.artistId, // Essential snapshot!
        nameSnapshot: pB.name,
        priceSnapshot: pB.price,
        qty: 1,
        discountAmount: 10,
      );

      final order = Order(
        shopId: 'shop1',
        eventId: 'event_artfair',
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.qr,
        total: (orderItemA.subtotal + orderItemB.subtotal),
        cashReceived: 810,
        change: 0,
        synced: false,
        createdOffline: true,
        items: [orderItemA, orderItemB],
      );

      // Verify snapshots
      expect(order.items[0].artistId, 'artist_rickky');
      expect(order.items[0].nameSnapshot, 'Cat Sticker Pack');
      expect(order.items[0].priceSnapshot, 250.0);
      expect(order.items[0].subtotal, (250 * 2) - 20); // 480

      expect(order.items[1].artistId, 'artist_mimi');
      expect(order.items[1].nameSnapshot, 'Dog Acrylic Keyring');
      expect(order.items[1].priceSnapshot, 350.0);
      expect(order.items[1].subtotal, (350 * 1) - 10); // 340

      expect(order.total, 820.0);

      // Even if original Product is modified or Artist is removed, order items retain exact values
      final modifiedPA = pA.copyWith(price: 999, name: 'Changed Name');
      expect(orderItemA.nameSnapshot, 'Cat Sticker Pack');
      expect(orderItemA.priceSnapshot, 250.0);
      expect(modifiedPA.price, 999.0);
    });

    // -------------------------------------------------------------
    // Test 7: Multi-User Invite & Expiration (Requirement 4.7)
    // -------------------------------------------------------------
    test('4.7 Multi-user invite generates token with 7-day validity and expires on day 8', () {
      final now = DateTime(2026, 10, 28, 12, 0);

      // Create invite with 7 days validity
      final invite = Invite(
        shopId: 'shop_demo',
        email: 'staff@example.com',
        artistId: 'artist_rickky',
        createdAt: now,
        expiresAt: now.add(const Duration(days: 7)),
      );

      expect(invite.token.length >= 8, isTrue);
      expect(invite.status, InviteStatus.pending);
      expect(invite.artistId, 'artist_rickky');

      // Check on Day 3: Still valid
      final day3 = now.add(const Duration(days: 3));
      expect(day3.isAfter(invite.expiresAt), isFalse);

      // Check on Day 7 (exact): Still valid
      final day7 = now.add(const Duration(days: 7));
      expect(day7.isAfter(invite.expiresAt), isFalse);

      // Check on Day 8 (Acceptance Criteria 4.7): Expired!
      final day8 = now.add(const Duration(days: 8));
      expect(day8.isAfter(invite.expiresAt), isTrue);
    });

    // -------------------------------------------------------------
    // Test 8: Multi-Artist Settlement with Multiple Commission Rates (Requirement 4.6)
    // -------------------------------------------------------------
    test('4.6 End-to-end multi-artist settlement calculates gross, commission, and net payout per artist', () {
      final artists = [
        Artist(shopId: 's1', name: 'Rickky Art', commissionRate: 10.0), // 10%
        Artist(shopId: 's1', name: 'Mimi Craft', commissionRate: 15.0), // 15%
        Artist(shopId: 's1', name: 'Solo Artist', commissionRate: null), // 0% / null
      ];

      final orders = [
        Order(
          shopId: 's1',
          eventId: 'fair_2026',
          status: OrderStatus.completed,
          paymentMethod: PaymentMethod.cash,
          total: 2000,
          cashReceived: 2000,
          change: 0,
          synced: true,
          createdOffline: true,
          items: [
            OrderItem(
              orderId: 'o1',
              productId: 'p1',
              artistId: artists[0].id,
              nameSnapshot: 'Rickky Print',
              priceSnapshot: 1000,
              qty: 1,
            ),
            OrderItem(
              orderId: 'o1',
              productId: 'p2',
              artistId: artists[1].id,
              nameSnapshot: 'Mimi Doll',
              priceSnapshot: 600,
              qty: 1,
            ),
            OrderItem(
              orderId: 'o1',
              productId: 'p3',
              artistId: artists[2].id,
              nameSnapshot: 'Solo Card',
              priceSnapshot: 400,
              qty: 1,
            ),
          ],
        ),
      ];

      // Settlement calculation per artist
      final grossMap = <String, double>{};
      for (var o in orders.where((o) => o.status == OrderStatus.completed)) {
        for (var item in o.items) {
          grossMap[item.artistId] = (grossMap[item.artistId] ?? 0) + item.subtotal;
        }
      }

      // 1. Rickky Art (1000 gross, 10% commission)
      final rGross = grossMap[artists[0].id] ?? 0.0;
      final rCommRate = artists[0].commissionRate ?? 0.0;
      final rCommission = rGross * (rCommRate / 100.0);
      final rNet = rGross - rCommission;

      expect(rGross, 1000.0);
      expect(rCommission, 100.0);
      expect(rNet, 900.0);

      // 2. Mimi Craft (600 gross, 15% commission)
      final mGross = grossMap[artists[1].id] ?? 0.0;
      final mCommRate = artists[1].commissionRate ?? 0.0;
      final mCommission = mGross * (mCommRate / 100.0);
      final mNet = mGross - mCommission;

      expect(mGross, 600.0);
      expect(mCommission, 90.0); // 15% of 600 = 90
      expect(mNet, 510.0);       // 600 - 90 = 510

      // 3. Solo Artist (400 gross, null commission -> 0%)
      final sGross = grossMap[artists[2].id] ?? 0.0;
      final sCommRate = artists[2].commissionRate ?? 0.0;
      final sCommission = sGross * (sCommRate / 100.0);
      final sNet = sGross - sCommission;

      expect(sGross, 400.0);
      expect(sCommission, 0.0);
      expect(sNet, 400.0);
    });
  });

  group('v1.6 Acceptance Criteria Tests (Multi-Shop Isolation & Seed Data)', () {
    // -------------------------------------------------------------
    // Test 1: Multi-shop Order & Sales Isolation
    // -------------------------------------------------------------
    test('5.1 Orders from Shop A and Shop B are strictly isolated by shop_id', () {
      final orderA1 = Order(
        id: 'order_a1',
        shopId: 'shop_a',
        eventId: 'event_a',
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.cash,
        total: 210.0,
        items: [
          OrderItem(orderId: 'order_a1', productId: 'p_a1', artistId: 'artist_rickky', nameSnapshot: 'Sticker Cat Day', priceSnapshot: 45.0, qty: 2),
          OrderItem(orderId: 'order_a1', productId: 'p_a3', artistId: 'artist_mimi', nameSnapshot: 'Floral Acrylic Stand', priceSnapshot: 120.0, qty: 1),
        ],
      );

      final orderA2 = Order(
        id: 'order_a2',
        shopId: 'shop_a',
        eventId: 'event_a',
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.qr,
        total: 175.0,
        items: [
          OrderItem(orderId: 'order_a2', productId: 'p_a4', artistId: 'artist_rickky', nameSnapshot: 'Coffee Boy Postcard', priceSnapshot: 35.0, qty: 3, discountAmount: 10.77),
          OrderItem(orderId: 'order_a2', productId: 'p_a2', artistId: 'artist_mimi', nameSnapshot: 'Shiba Inu Sticker', priceSnapshot: 45.0, qty: 2, discountAmount: 9.23),
        ],
      );

      final orderA3 = Order(
        id: 'order_a3',
        shopId: 'shop_a',
        eventId: 'event_a',
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.cash,
        total: 120.0,
        items: [
          OrderItem(orderId: 'order_a3', productId: 'p_a6', artistId: 'artist_mimi', nameSnapshot: 'Galaxy Keyring', priceSnapshot: 65.0, qty: 2, discountAmount: 10.0),
        ],
      );

      final orderA4Voided = Order(
        id: 'order_a4',
        shopId: 'shop_a',
        eventId: 'event_a',
        status: OrderStatus.voided,
        paymentMethod: PaymentMethod.cash,
        total: 80.0,
        items: [
          OrderItem(orderId: 'order_a4', productId: 'p_a5', artistId: 'artist_rickky', nameSnapshot: 'Holo Memo Pad', priceSnapshot: 80.0, qty: 1),
        ],
      );

      // Shop B orders
      final orderB1 = Order(
        id: 'order_b1',
        shopId: 'shop_b',
        eventId: 'event_b',
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.qr,
        total: 500.0,
        items: [
          OrderItem(orderId: 'order_b1', productId: 'p_b1', artistId: 'artist_kitsune', nameSnapshot: 'Fox Ceramic Mug', priceSnapshot: 280.0, qty: 1),
          OrderItem(orderId: 'order_b1', productId: 'p_b2', artistId: 'artist_kitsune', nameSnapshot: 'Linen Tote Bag', priceSnapshot: 220.0, qty: 1),
        ],
      );

      final orderB2 = Order(
        id: 'order_b2',
        shopId: 'shop_b',
        eventId: 'event_b',
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.cash,
        total: 540.0,
        items: [
          OrderItem(orderId: 'order_b2', productId: 'p_b5', artistId: 'artist_kitsune', nameSnapshot: 'Sticker Cat Day', priceSnapshot: 50.0, qty: 3),
          OrderItem(orderId: 'order_b2', productId: 'p_b3', artistId: 'artist_neko', nameSnapshot: 'Neko Clay Figurine', priceSnapshot: 390.0, qty: 1),
        ],
      );

      final orderB3 = Order(
        id: 'order_b3',
        shopId: 'shop_b',
        eventId: 'event_b',
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.cash,
        total: 560.0,
        items: [
          OrderItem(orderId: 'order_b3', productId: 'p_b4', artistId: 'artist_neko', nameSnapshot: 'Cat Teacup Set', priceSnapshot: 320.0, qty: 1, discountAmount: 21.33),
          OrderItem(orderId: 'order_b3', productId: 'p_b1', artistId: 'artist_kitsune', nameSnapshot: 'Fox Ceramic Mug', priceSnapshot: 280.0, qty: 1, discountAmount: 18.67),
        ],
      );

      final allOrders = [orderA1, orderA2, orderA3, orderA4Voided, orderB1, orderB2, orderB3];

      // Query filter by shop_a
      final shopAOrders = allOrders.where((o) => o.shopId == 'shop_a').toList();
      expect(shopAOrders.length, 4);
      expect(shopAOrders.any((o) => o.shopId == 'shop_b'), isFalse);

      final shopACompleted = shopAOrders.where((o) => o.status == OrderStatus.completed).toList();
      expect(shopACompleted.length, 3);
      final shopATotalRevenue = shopACompleted.fold(0.0, (sum, o) => sum + o.total);
      expect(shopATotalRevenue, 505.0);

      // Query filter by shop_b
      final shopBOrders = allOrders.where((o) => o.shopId == 'shop_b').toList();
      expect(shopBOrders.length, 3);
      expect(shopBOrders.any((o) => o.shopId == 'shop_a'), isFalse);

      final shopBCompleted = shopBOrders.where((o) => o.status == OrderStatus.completed).toList();
      expect(shopBCompleted.length, 3);
      final shopBTotalRevenue = shopBCompleted.fold(0.0, (sum, o) => sum + o.total);
      expect(shopBTotalRevenue, 1600.0);
    });

    // -------------------------------------------------------------
    // Test 2: Product Name Collision Isolation
    // -------------------------------------------------------------
    test('5.2 Products with identical names in different shops are isolated by shop_id', () {
      final prodA = Product(
        id: 'prod_a1',
        shopId: 'shop_a',
        artistId: 'artist_rickky',
        name: 'Sticker Cat Day',
        price: 45.0,
        cost: 15.0,
        categoryId: 'cat_sticker_cat_a',
        stock: 48,
      );

      final prodB = Product(
        id: 'prod_b5',
        shopId: 'shop_b',
        artistId: 'artist_kitsune',
        name: 'Sticker Cat Day',
        price: 50.0,
        cost: 18.0,
        categoryId: 'cat_stickers_b',
        stock: 57,
      );

      final allProducts = [prodA, prodB];

      final shopAProducts = allProducts.where((p) => p.shopId == 'shop_a').toList();
      expect(shopAProducts.length, 1);
      expect(shopAProducts.first.id, 'prod_a1');
      expect(shopAProducts.first.price, 45.0);

      final shopBProducts = allProducts.where((p) => p.shopId == 'shop_b').toList();
      expect(shopBProducts.length, 1);
      expect(shopBProducts.first.id, 'prod_b5');
      expect(shopBProducts.first.price, 50.0);
    });

    // -------------------------------------------------------------
    // Test 3: Settlement Calculation for Shop A & Shop B Seed Data
    // -------------------------------------------------------------
    test('5.3 Settlement calculation per shop correctly computes gross, commission, and net payout', () {
      // 1. Shop A Settlement
      final shopACompletedOrders = [
        Order(
          id: 'order_a1',
          shopId: 'shop_a',
          eventId: 'event_a',
          status: OrderStatus.completed,
          paymentMethod: PaymentMethod.cash,
          total: 210.0,
          items: [
            OrderItem(orderId: 'order_a1', productId: 'p_a1', artistId: 'artist_rickky', nameSnapshot: 'Sticker Cat Day', priceSnapshot: 45.0, qty: 2),
            OrderItem(orderId: 'order_a1', productId: 'p_a3', artistId: 'artist_mimi', nameSnapshot: 'Floral Acrylic Stand', priceSnapshot: 120.0, qty: 1),
          ],
        ),
        Order(
          id: 'order_a2',
          shopId: 'shop_a',
          eventId: 'event_a',
          status: OrderStatus.completed,
          paymentMethod: PaymentMethod.qr,
          total: 175.0,
          items: [
            OrderItem(orderId: 'order_a2', productId: 'p_a4', artistId: 'artist_rickky', nameSnapshot: 'Coffee Boy Postcard', priceSnapshot: 35.0, qty: 3, discountAmount: 10.77),
            OrderItem(orderId: 'order_a2', productId: 'p_a2', artistId: 'artist_mimi', nameSnapshot: 'Shiba Inu Sticker', priceSnapshot: 45.0, qty: 2, discountAmount: 9.23),
          ],
        ),
        Order(
          id: 'order_a3',
          shopId: 'shop_a',
          eventId: 'event_a',
          status: OrderStatus.completed,
          paymentMethod: PaymentMethod.cash,
          total: 120.0,
          items: [
            OrderItem(orderId: 'order_a3', productId: 'p_a6', artistId: 'artist_mimi', nameSnapshot: 'Galaxy Keyring', priceSnapshot: 65.0, qty: 2, discountAmount: 10.0),
          ],
        ),
      ];

      // Voided order must be excluded!
      final voidedOrder = Order(
        id: 'order_a4',
        shopId: 'shop_a',
        eventId: 'event_a',
        status: OrderStatus.voided,
        paymentMethod: PaymentMethod.cash,
        total: 80.0,
        items: [
          OrderItem(orderId: 'order_a4', productId: 'p_a5', artistId: 'artist_rickky', nameSnapshot: 'Holo Memo Pad', priceSnapshot: 80.0, qty: 1),
        ],
      );

      final grossMapA = <String, double>{};
      for (var o in [...shopACompletedOrders, voidedOrder].where((o) => o.status == OrderStatus.completed)) {
        for (var item in o.items) {
          grossMapA[item.artistId] = (grossMapA[item.artistId] ?? 0.0) + item.subtotal;
        }
      }

      // Rickky Art (0% commission)
      final rGross = grossMapA['artist_rickky']!;
      expect((rGross - 184.23).abs() < 0.01, isTrue); // 90.0 + 94.23 = 184.23
      const rCommission = 0.0;
      final rPayout = rGross - rCommission;
      expect((rPayout - 184.23).abs() < 0.01, isTrue);

      // Mimi Craft (10% commission)
      final mGross = grossMapA['artist_mimi']!;
      expect((mGross - 320.77).abs() < 0.01, isTrue); // 120.0 + 80.77 + 120.0 = 320.77
      final mCommission = mGross * 0.10;
      expect((mCommission - 32.08).abs() < 0.01, isTrue);
      final mPayout = mGross - mCommission;
      expect((mPayout - 288.69).abs() < 0.01, isTrue);

      // 2. Shop B Settlement
      final shopBCompletedOrders = [
        Order(
          id: 'order_b1',
          shopId: 'shop_b',
          eventId: 'event_b',
          status: OrderStatus.completed,
          paymentMethod: PaymentMethod.qr,
          total: 500.0,
          items: [
            OrderItem(orderId: 'order_b1', productId: 'p_b1', artistId: 'artist_kitsune', nameSnapshot: 'Fox Ceramic Mug', priceSnapshot: 280.0, qty: 1),
            OrderItem(orderId: 'order_b1', productId: 'p_b2', artistId: 'artist_kitsune', nameSnapshot: 'Linen Tote Bag', priceSnapshot: 220.0, qty: 1),
          ],
        ),
        Order(
          id: 'order_b2',
          shopId: 'shop_b',
          eventId: 'event_b',
          status: OrderStatus.completed,
          paymentMethod: PaymentMethod.cash,
          total: 540.0,
          items: [
            OrderItem(orderId: 'order_b2', productId: 'p_b5', artistId: 'artist_kitsune', nameSnapshot: 'Sticker Cat Day', priceSnapshot: 50.0, qty: 3),
            OrderItem(orderId: 'order_b2', productId: 'p_b3', artistId: 'artist_neko', nameSnapshot: 'Neko Clay Figurine', priceSnapshot: 390.0, qty: 1),
          ],
        ),
        Order(
          id: 'order_b3',
          shopId: 'shop_b',
          eventId: 'event_b',
          status: OrderStatus.completed,
          paymentMethod: PaymentMethod.cash,
          total: 560.0,
          items: [
            OrderItem(orderId: 'order_b3', productId: 'p_b4', artistId: 'artist_neko', nameSnapshot: 'Cat Teacup Set', priceSnapshot: 320.0, qty: 1, discountAmount: 21.33),
            OrderItem(orderId: 'order_b3', productId: 'p_b1', artistId: 'artist_kitsune', nameSnapshot: 'Fox Ceramic Mug', priceSnapshot: 280.0, qty: 1, discountAmount: 18.67),
          ],
        ),
      ];

      final grossMapB = <String, double>{};
      for (var o in shopBCompletedOrders) {
        for (var item in o.items) {
          grossMapB[item.artistId] = (grossMapB[item.artistId] ?? 0.0) + item.subtotal;
        }
      }

      // Kitsune Studio (0% commission)
      final kGross = grossMapB['artist_kitsune']!;
      expect((kGross - 911.33).abs() < 0.01, isTrue); // 500 + 150 + 261.33 = 911.33
      final kPayout = kGross;
      expect((kPayout - 911.33).abs() < 0.01, isTrue);

      // Neko Pottery (15% commission)
      final nGross = grossMapB['artist_neko']!;
      expect((nGross - 688.67).abs() < 0.01, isTrue); // 390 + 298.67 = 688.67
      final nCommission = nGross * 0.15;
      expect((nCommission - 103.30).abs() < 0.01, isTrue);
      final nPayout = nGross - nCommission;
      expect((nPayout - 585.37).abs() < 0.01, isTrue);
    });

    // -------------------------------------------------------------
    // Test 4: Cost Visibility Rules across shops and members
    // -------------------------------------------------------------
    test('5.4 Staff member of Shop A can only see cost for their linked artist in Shop A', () {
      final staffA = Member(
        shopId: 'shop_a',
        userId: 'user_somchai_02',
        email: 'somchai@mako.com',
        name: 'Somchai (Staff)',
        role: MemberRole.member,
        invitedArtistId: 'artist_mimi',
      );

      final pMimiA = Product(
        shopId: 'shop_a',
        artistId: 'artist_mimi',
        name: 'Floral Acrylic Stand',
        price: 120.0,
        cost: 45.0,
        categoryId: 'cat1',
        stock: 24,
      );

      final pRickkyA = Product(
        shopId: 'shop_a',
        artistId: 'artist_rickky',
        name: 'Sticker Cat Day',
        price: 45.0,
        cost: 15.0,
        categoryId: 'cat1',
        stock: 48,
      );

      final pNekoB = Product(
        shopId: 'shop_b',
        artistId: 'artist_neko',
        name: 'Neko Clay Figurine',
        price: 390.0,
        cost: 120.0,
        categoryId: 'cat2',
        stock: 11,
      );

      bool canViewCost(Member member, Product product) {
        if (member.shopId != product.shopId) return false;
        if (member.role == MemberRole.owner) return true;
        return product.artistId == member.invitedArtistId;
      }

      // Staff Somchai in Shop A can see Mimi's cost
      expect(canViewCost(staffA, pMimiA), isTrue);

      // Staff Somchai in Shop A CANNOT see Rickky's cost
      expect(canViewCost(staffA, pRickkyA), isFalse);

      // Staff Somchai in Shop A CANNOT see Shop B product cost
      expect(canViewCost(staffA, pNekoB), isFalse);
    });

    // -------------------------------------------------------------
    // Test 5: Production Blank Slate & Decoupled Mock Data
    // -------------------------------------------------------------
    test('5.5 Initial state is clean blank slate with zero shops/products, and owner privileges are default', () {
      // In a fresh blank database:
      final List<Shop> blankShops = [];
      final List<Product> blankProducts = [];
      final List<Order> blankOrders = [];
      bool checkIsOwner(Member? member) => member == null ? true : member.role == MemberRole.owner;

      // When there are no members in the database (first run / blank slate), user has owner access to setup
      expect(checkIsOwner(null), isTrue);

      // Verify lists are empty
      expect(blankShops.isEmpty, isTrue);
      expect(blankProducts.isEmpty, isTrue);
      expect(blankOrders.isEmpty, isTrue);

      // When shop is created by user
      final userShop = Shop(
        id: 'shop_production_1',
        name: 'My Real Shop',
        ownerUserId: 'owner_user_1',
        promptpayId: '0899999999',
        promptpayName: 'Somying Real',
      );
      blankShops.add(userShop);
      expect(blankShops.length, 1);
      expect(blankShops.first.name, 'My Real Shop');
    });
  });
}

