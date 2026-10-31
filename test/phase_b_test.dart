import 'package:flutter_test/flutter_test.dart';
import 'package:booth_pos_app/models/models.dart';
import 'package:booth_pos_app/repositories/repositories.dart';
import 'package:booth_pos_app/providers/pos_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase B - Repositories, Delta Stock, Dynamic Discount & Settlement', () {
    late FakeRepositoryRegistry fakeRepo;
    late PosProvider pos;

    setUp(() async {
      fakeRepo = FakeRepositoryRegistry();
      await fakeRepo.init();
      pos = PosProvider(repo: fakeRepo);
      await pos.init();
    });

    test('Phase B - Item 3: Checkout uses fresh stock delta (10 in cart, adjust to 20, buy 2 -> 18 not 8)', () async {
      // 1. Create shop and product with stock 10
      await pos.createShop(name: 'Test Shop', promptpayId: '', promptpayName: '');
      final product = Product(
        id: 'p_delta_test',
        shopId: pos.currentShopId!,
        artistId: 'artist_1',
        name: 'Delta Sticker',
        price: 50,
        categoryId: '',
        stock: 10,
      );
      await pos.saveProduct(product);

      // 2. Add product to cart (cart has snapshot stock = 10)
      pos.addToCart(product);
      pos.updateCartQty('p_delta_test', 2);

      // 3. Concurrently adjust stock in DB to 20
      await pos.adjustStock('p_delta_test', 10, 'Restock');
      expect(fakeRepo.getProduct('p_delta_test')?.stock, 20);

      // 4. Checkout 2 items from cart
      await pos.checkoutCash(cashReceived: 100);

      // 5. Assert stock is 18 (20 - 2), NOT 8 (10 - 2)
      final finalProd = fakeRepo.getProduct('p_delta_test');
      expect(finalProd?.stock, 18);
    });

    test('Phase B - Item 3: Idempotent placeOrder prevents duplicate stock deduction on same orderId', () async {
      await pos.createShop(name: 'Test Shop', promptpayId: '', promptpayName: '');
      final product = Product(
        id: 'p_idem',
        shopId: pos.currentShopId!,
        artistId: 'art_1',
        name: 'Idempotent Mug',
        price: 100,
        categoryId: '',
        stock: 10,
      );
      await pos.saveProduct(product);

      final orderItem = OrderItem(
        orderId: 'order_idem_1',
        productId: 'p_idem',
        artistId: 'art_1',
        nameSnapshot: 'Idempotent Mug',
        priceSnapshot: 100,
        qty: 3,
      );
      final order = Order(
        id: 'order_idem_1',
        shopId: pos.currentShopId!,
        eventId: 'event_1',
        paymentMethod: PaymentMethod.cash,
        total: 300,
        items: [orderItem],
      );

      // Place first time -> stock drops to 7
      await fakeRepo.placeOrder(order);
      expect(fakeRepo.getProduct('p_idem')?.stock, 7);

      // Place second time with exact same orderId -> stock stays 7
      await fakeRepo.placeOrder(order);
      expect(fakeRepo.getProduct('p_idem')?.stock, 7);
    });

    test('Phase B - Item 8: Dynamic whole-bill discount re-evaluates when cart items are updated or removed', () {
      final pA = Product(
        id: 'p_a',
        shopId: 'shop1',
        artistId: 'artist_a',
        name: 'Product A',
        price: 300,
        categoryId: '',
        stock: 10,
      );
      final pB = Product(
        id: 'p_b',
        shopId: 'shop1',
        artistId: 'artist_b',
        name: 'Product B',
        price: 700,
        categoryId: '',
        stock: 10,
      );

      pos.addToCart(pA); // Gross: 300
      pos.addToCart(pB); // Gross: 700 -> Subtotal: 1000

      // Apply 100 THB whole-bill discount -> 30 to A, 70 to B
      pos.applyWholeBillDiscount(100);
      expect(pos.cart[0].discount, 30.0);
      expect(pos.cart[1].discount, 70.0);
      expect(pos.cartTotal, 900.0);

      // Remove product B -> Discount re-evaluates dynamically for remaining cart
      pos.removeFromCart('p_b');
      expect(pos.cart.length, 1);
      // Since subtotal is now 300, amount discount of 100 is allocated fully to A
      expect(pos.cart[0].discount, 100.0);
      expect(pos.cartTotal, 200.0);
    });

    test('Phase B - Item 8: Whole-bill discount divides odd cents without losing satang (100 THB across 3 artists)', () {
      final p1 = Product(id: 'p1', shopId: 's', artistId: 'a1', name: '1', price: 100, categoryId: '', stock: 5);
      final p2 = Product(id: 'p2', shopId: 's', artistId: 'a2', name: '2', price: 100, categoryId: '', stock: 5);
      final p3 = Product(id: 'p3', shopId: 's', artistId: 'a3', name: '3', price: 100, categoryId: '', stock: 5);

      pos.addToCart(p1);
      pos.addToCart(p2);
      pos.addToCart(p3);
      expect(pos.cartSubtotal, 300.0);

      // 100 THB divided across 3 equal items = 33.34 + 33.33 + 33.33 = 100.00
      pos.applyWholeBillDiscount(100);

      final totalItemDiscounts = pos.cart.fold(0.0, (sum, i) => sum + i.discount);
      expect(double.parse(totalItemDiscounts.toStringAsFixed(2)), 100.00);
      expect(pos.cartTotal, 200.00);
    });

    test('Phase B - Item 11: Settlement computes 10% commission on artist totals and excludes voided orders', () async {
      await pos.createShop(name: 'Art Shop', promptpayId: '', promptpayName: '');
      final shopId = pos.currentShopId!;
      final eventId = 'comic_con_01';

      final artist = Artist(id: 'art_solo', shopId: shopId, name: 'Solo Artist', commissionRate: 10.0);
      await pos.saveArtist(artist);

      final product = Product(
        id: 'p_solo',
        shopId: shopId,
        artistId: 'art_solo',
        name: 'Artbook',
        price: 1000,
        categoryId: '',
        stock: 5,
      );
      await pos.saveProduct(product);

      // Completed order: 1000 THB
      final orderItem = OrderItem(
        orderId: 'ord_1',
        productId: 'p_solo',
        artistId: 'art_solo',
        nameSnapshot: 'Artbook',
        priceSnapshot: 1000,
        qty: 1,
      );
      final order1 = Order(
        id: 'ord_1',
        shopId: shopId,
        eventId: eventId,
        paymentMethod: PaymentMethod.cash,
        total: 1000,
        items: [orderItem],
      );
      await fakeRepo.placeOrder(order1);

      // Voided order: 500 THB
      final voidedItem = OrderItem(
        orderId: 'ord_void',
        productId: 'p_solo',
        artistId: 'art_solo',
        nameSnapshot: 'Artbook',
        priceSnapshot: 500,
        qty: 1,
      );
      final orderVoided = Order(
        id: 'ord_void',
        shopId: shopId,
        eventId: eventId,
        paymentMethod: PaymentMethod.cash,
        total: 500,
        status: OrderStatus.voided,
        items: [voidedItem],
      );
      await fakeRepo.placeOrder(orderVoided);

      // Compute settlement via repository
      final settlements = await fakeRepo.computeForEvent(
        shopId: shopId,
        eventId: eventId,
        artists: [artist],
      );

      expect(settlements.length, 1);
      final s = settlements.first;
      expect(s.grossSales, 1000.0);
      expect(s.commissionAmount, 100.0); // 10% of 1000
      expect(s.netPayout, 900.0);
    });
  });
}

