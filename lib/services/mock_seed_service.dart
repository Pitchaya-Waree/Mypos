import '../models/models.dart';

/// Service responsible ONLY for generating and seeding mock / test data.
/// Kept completely separate from production database logic so that a fresh
/// install starts with a 100% clean, blank state.
class MockSeedService {
  /// Clears all database tables and seeds complete sample data for Shop A and Shop B
  /// Includes multi-artist setup, categories (with 2-level folders), products,
  /// active events, and sample orders (Cash, QR with proportional discount, artist discount, and voided).
  static Future<void> seedAllSampleData(dynamic db, {bool clearExisting = true}) async {
    if (clearExisting) {
      await db.clearAllData();
    }

    // =========================================================================
    // 1. SHOP A: "Mako Shop (Booth #A14)"
    // =========================================================================
    final shopA = Shop(
      id: 'shop_a',
      name: 'Mako Shop (Booth #A14)',
      ownerUserId: 'user_rickky_01',
      promptpayId: '0812345678',
      promptpayName: 'Rickky PosMaker',
    );
    await db.saveShop(shopA);

    // Members for Shop A
    final ownerA = Member(
      shopId: shopA.id,
      userId: 'user_rickky_01',
      email: 'rickky.pos@gmail.com',
      name: 'Rickky (Owner)',
      role: MemberRole.owner,
    );
    final staffA = Member(
      shopId: shopA.id,
      userId: 'user_somchai_02',
      email: 'somchai@mako.com',
      name: 'Somchai (Staff)',
      role: MemberRole.member,
      invitedArtistId: 'artist_mimi',
    );
    await db.saveMember(ownerA);
    await db.saveMember(staffA);

    // Artists for Shop A
    final artistRickky = Artist(
      id: 'artist_rickky',
      shopId: shopA.id,
      name: 'Rickky Art',
      linkedUserId: ownerA.userId,
      commissionRate: null, // 0% Owner
    );
    final artistMimi = Artist(
      id: 'artist_mimi',
      shopId: shopA.id,
      name: 'Mimi Craft',
      linkedUserId: null,
      commissionRate: 10.0, // 10% commission
    );
    await db.saveArtist(artistRickky);
    await db.saveArtist(artistMimi);

    // Categories for Shop A (Folder Hierarchy)
    final catStickerA = Category(id: 'cat_sticker_a', shopId: shopA.id, name: 'Sticker', sortOrder: 1);
    final catStickerCatA = Category(
      id: 'cat_sticker_cat_a',
      shopId: shopA.id,
      name: 'ลายแมว (Cat)',
      parentCategoryId: catStickerA.id,
      sortOrder: 1,
    );
    final catStickerDogA = Category(
      id: 'cat_sticker_dog_a',
      shopId: shopA.id,
      name: 'ลายหมา (Dog)',
      parentCategoryId: catStickerA.id,
      sortOrder: 2,
    );
    final catPostcardA = Category(id: 'cat_postcard_a', shopId: shopA.id, name: 'Postcard', sortOrder: 2);
    final catKeyringA = Category(id: 'cat_keyring_a', shopId: shopA.id, name: 'Acrylic & Keyring', sortOrder: 3);
    final catMemoA = Category(id: 'cat_memo_a', shopId: shopA.id, name: 'Memo Pad', sortOrder: 4);

    await db.saveCategory(catStickerA);
    await db.saveCategory(catStickerCatA);
    await db.saveCategory(catStickerDogA);
    await db.saveCategory(catPostcardA);
    await db.saveCategory(catKeyringA);
    await db.saveCategory(catMemoA);

    // Event for Shop A
    final eventA = Event(
      id: 'event_a',
      shopId: shopA.id,
      name: 'Comic & Craft Expo 2026',
      startDate: DateTime(2026, 10, 27),
      endDate: DateTime(2026, 10, 29),
      isActive: true,
    );
    await db.saveEvent(eventA);
    await db.setEventArtists(eventA.id, [artistRickky.id, artistMimi.id]);

    // Products for Shop A
    final prodA1 = Product(
      id: 'prod_a1',
      shopId: shopA.id,
      artistId: artistRickky.id,
      name: 'Sticker Cat Day',
      image: '🐱',
      price: 45.0,
      cost: 15.0,
      categoryId: catStickerCatA.id,
      stock: 48, // 50 initial - 2 sold
      isBestseller: true,
    );
    final prodA2 = Product(
      id: 'prod_a2',
      shopId: shopA.id,
      artistId: artistMimi.id,
      name: 'Shiba Inu Sticker',
      image: '🐕',
      price: 45.0,
      cost: 15.0,
      categoryId: catStickerDogA.id,
      stock: 33, // 35 initial - 2 sold
      isBestseller: false,
    );
    final prodA3 = Product(
      id: 'prod_a3',
      shopId: shopA.id,
      artistId: artistMimi.id,
      name: 'Floral Acrylic Stand',
      image: '🌸',
      price: 120.0,
      cost: 45.0,
      categoryId: catKeyringA.id,
      stock: 24, // 25 initial - 1 sold
      isBestseller: true,
    );
    final prodA4 = Product(
      id: 'prod_a4',
      shopId: shopA.id,
      artistId: artistRickky.id,
      name: 'Coffee Boy Postcard',
      image: '☕',
      price: 35.0,
      cost: 10.0,
      categoryId: catPostcardA.id,
      stock: 37, // 40 initial - 3 sold
      isBestseller: false,
    );
    final prodA5 = Product(
      id: 'prod_a5',
      shopId: shopA.id,
      artistId: artistRickky.id,
      name: 'Holo Memo Pad',
      image: '✨',
      price: 80.0,
      cost: 30.0,
      categoryId: catMemoA.id,
      stock: 30, // 30 initial - 1 sold + 1 voided = 30
      isBestseller: false,
    );
    final prodA6 = Product(
      id: 'prod_a6',
      shopId: shopA.id,
      artistId: artistMimi.id,
      name: 'Galaxy Keyring',
      image: '🌌',
      price: 65.0,
      cost: 20.0,
      categoryId: catKeyringA.id,
      stock: 16, // 18 initial - 2 sold
      isBestseller: true,
    );

    final shopAProducts = [prodA1, prodA2, prodA3, prodA4, prodA5, prodA6];
    for (var prod in shopAProducts) {
      await db.saveProduct(prod);
      await db.addStockMovement(StockMovement(
        productId: prod.id,
        type: StockMovementType.importAction,
        qtyChange: prod.stock + (prod.id == 'prod_a1' ? 2 : prod.id == 'prod_a2' ? 2 : prod.id == 'prod_a3' ? 1 : prod.id == 'prod_a4' ? 3 : prod.id == 'prod_a6' ? 2 : 0),
      ));
    }

    // Sample Orders for Shop A
    // Order A1: Cash payment (Completed)
    // Sticker Cat Day x2 (฿90) + Floral Acrylic Stand x1 (฿120) = ฿210
    final orderA1 = Order(
      id: 'order_a1',
      shopId: shopA.id,
      eventId: eventA.id,
      status: OrderStatus.completed,
      paymentMethod: PaymentMethod.cash,
      total: 210.0,
      cashReceived: 300.0,
      change: 90.0,
      createdAt: DateTime(2026, 10, 27, 10, 30),
      synced: true,
      createdOffline: true,
      items: [
        OrderItem(
          orderId: 'order_a1',
          productId: prodA1.id,
          artistId: artistRickky.id,
          nameSnapshot: prodA1.name,
          priceSnapshot: prodA1.price,
          qty: 2,
          discountAmount: 0.0,
        ),
        OrderItem(
          orderId: 'order_a1',
          productId: prodA3.id,
          artistId: artistMimi.id,
          nameSnapshot: prodA3.name,
          priceSnapshot: prodA3.price,
          qty: 1,
          discountAmount: 0.0,
        ),
      ],
    );
    await db.saveOrder(orderA1);
    await db.addStockMovement(StockMovement(productId: prodA1.id, orderId: orderA1.id, type: StockMovementType.sale, qtyChange: -2));
    await db.addStockMovement(StockMovement(productId: prodA3.id, orderId: orderA1.id, type: StockMovementType.sale, qtyChange: -1));

    // Order A2: PromptPay QR (Completed) + Proportional Discount ฿20
    // Coffee Boy Postcard x3 (฿105 gross) + Shiba Inu Sticker x2 (฿90 gross) = ฿195 gross
    // Proportional discount: Rickky (฿105/195 * 20 = 10.77), Mimi (฿90/195 * 20 = 9.23) -> Net ฿175
    final orderA2 = Order(
      id: 'order_a2',
      shopId: shopA.id,
      eventId: eventA.id,
      status: OrderStatus.completed,
      paymentMethod: PaymentMethod.qr,
      total: 175.0,
      cashReceived: 175.0,
      change: 0.0,
      createdAt: DateTime(2026, 10, 27, 12, 15),
      synced: true,
      createdOffline: true,
      items: [
        OrderItem(
          orderId: 'order_a2',
          productId: prodA4.id,
          artistId: artistRickky.id,
          nameSnapshot: prodA4.name,
          priceSnapshot: prodA4.price,
          qty: 3,
          discountAmount: 10.77,
        ),
        OrderItem(
          orderId: 'order_a2',
          productId: prodA2.id,
          artistId: artistMimi.id,
          nameSnapshot: prodA2.name,
          priceSnapshot: prodA2.price,
          qty: 2,
          discountAmount: 9.23,
        ),
      ],
    );
    await db.saveOrder(orderA2);
    await db.addStockMovement(StockMovement(productId: prodA4.id, orderId: orderA2.id, type: StockMovementType.sale, qtyChange: -3));
    await db.addStockMovement(StockMovement(productId: prodA2.id, orderId: orderA2.id, type: StockMovementType.sale, qtyChange: -2));

    // Order A3: Cash payment (Completed) + Artist-Specific Discount ฿10 on Mimi
    // Galaxy Keyring x2 (฿130 gross) - ฿10 discount = ฿120 net
    final orderA3 = Order(
      id: 'order_a3',
      shopId: shopA.id,
      eventId: eventA.id,
      status: OrderStatus.completed,
      paymentMethod: PaymentMethod.cash,
      total: 120.0,
      cashReceived: 150.0,
      change: 30.0,
      createdAt: DateTime(2026, 10, 27, 14, 45),
      synced: true,
      createdOffline: true,
      items: [
        OrderItem(
          orderId: 'order_a3',
          productId: prodA6.id,
          artistId: artistMimi.id,
          nameSnapshot: prodA6.name,
          priceSnapshot: prodA6.price,
          qty: 2,
          discountAmount: 10.0,
        ),
      ],
    );
    await db.saveOrder(orderA3);
    await db.addStockMovement(StockMovement(productId: prodA6.id, orderId: orderA3.id, type: StockMovementType.sale, qtyChange: -2));

    // Order A4: Voided Order (Excluded from sales & settlement, stock returned)
    final orderA4 = Order(
      id: 'order_a4',
      shopId: shopA.id,
      eventId: eventA.id,
      status: OrderStatus.voided,
      paymentMethod: PaymentMethod.cash,
      total: 80.0,
      cashReceived: 100.0,
      change: 20.0,
      createdAt: DateTime(2026, 10, 27, 15, 10),
      synced: true,
      createdOffline: true,
      items: [
        OrderItem(
          orderId: 'order_a4',
          productId: prodA5.id,
          artistId: artistRickky.id,
          nameSnapshot: prodA5.name,
          priceSnapshot: prodA5.price,
          qty: 1,
          discountAmount: 0.0,
        ),
      ],
    );
    await db.saveOrder(orderA4);
    await db.addStockMovement(StockMovement(productId: prodA5.id, orderId: orderA4.id, type: StockMovementType.sale, qtyChange: -1));
    await db.addStockMovement(StockMovement(productId: prodA5.id, orderId: orderA4.id, type: StockMovementType.voidAction, qtyChange: 1));

    // =========================================================================
    // 2. SHOP B: "Crafty Fox Studio (Booth #B08)"
    // =========================================================================
    final shopB = Shop(
      id: 'shop_b',
      name: 'Crafty Fox Studio (Booth #B08)',
      ownerUserId: 'user_kitsune_01',
      promptpayId: '0899998888',
      promptpayName: 'Kitsune Fox Studio',
    );
    await db.saveShop(shopB);

    // Members for Shop B
    final ownerB = Member(
      shopId: shopB.id,
      userId: 'user_kitsune_01',
      email: 'kitsune@craftyfox.com',
      name: 'Kitsune (Owner)',
      role: MemberRole.owner,
    );
    final staffB = Member(
      shopId: shopB.id,
      userId: 'user_tanuki_02',
      email: 'tanuki@craftyfox.com',
      name: 'Tanuki (Staff)',
      role: MemberRole.member,
      invitedArtistId: 'artist_neko',
    );
    await db.saveMember(ownerB);
    await db.saveMember(staffB);

    // Artists for Shop B
    final artistKitsune = Artist(
      id: 'artist_kitsune',
      shopId: shopB.id,
      name: 'Kitsune Studio',
      linkedUserId: ownerB.userId,
      commissionRate: null, // 0% Owner
    );
    final artistNeko = Artist(
      id: 'artist_neko',
      shopId: shopB.id,
      name: 'Neko Pottery',
      linkedUserId: null,
      commissionRate: 15.0, // 15% commission
    );
    await db.saveArtist(artistKitsune);
    await db.saveArtist(artistNeko);

    // Categories for Shop B
    final catCeramicsB = Category(id: 'cat_ceramics_b', shopId: shopB.id, name: 'Ceramics & Pottery', sortOrder: 1);
    final catTextilesB = Category(id: 'cat_textiles_b', shopId: shopB.id, name: 'Linen & Textiles', sortOrder: 2);
    final catStickersB = Category(id: 'cat_stickers_b', shopId: shopB.id, name: 'Stickers & Prints', sortOrder: 3);

    await db.saveCategory(catCeramicsB);
    await db.saveCategory(catTextilesB);
    await db.saveCategory(catStickersB);

    // Event for Shop B
    final eventB = Event(
      id: 'event_b',
      shopId: shopB.id,
      name: 'Craft Fair Winter 2026',
      startDate: DateTime(2026, 10, 27),
      endDate: DateTime(2026, 10, 29),
      isActive: true,
    );
    await db.saveEvent(eventB);
    await db.setEventArtists(eventB.id, [artistKitsune.id, artistNeko.id]);

    // Products for Shop B
    final prodB1 = Product(
      id: 'prod_b1',
      shopId: shopB.id,
      artistId: artistKitsune.id,
      name: 'Fox Ceramic Mug',
      image: '🦊',
      price: 280.0,
      cost: 90.0,
      categoryId: catCeramicsB.id,
      stock: 18, // 20 initial - 2 sold
      isBestseller: true,
    );
    final prodB2 = Product(
      id: 'prod_b2',
      shopId: shopB.id,
      artistId: artistKitsune.id,
      name: 'Linen Tote Bag',
      image: '👜',
      price: 220.0,
      cost: 70.0,
      categoryId: catTextilesB.id,
      stock: 14, // 15 initial - 1 sold
      isBestseller: true,
    );
    final prodB3 = Product(
      id: 'prod_b3',
      shopId: shopB.id,
      artistId: artistNeko.id,
      name: 'Neko Clay Figurine',
      image: '🏺',
      price: 390.0,
      cost: 120.0,
      categoryId: catCeramicsB.id,
      stock: 11, // 12 initial - 1 sold
      isBestseller: true,
    );
    final prodB4 = Product(
      id: 'prod_b4',
      shopId: shopB.id,
      artistId: artistNeko.id,
      name: 'Cat Teacup Set',
      image: '🍵',
      price: 320.0,
      cost: 100.0,
      categoryId: catCeramicsB.id,
      stock: 9, // 10 initial - 1 sold
      isBestseller: false,
    );
    // Note: Same name "Sticker Cat Day" as Shop A to verify shopId separation
    final prodB5 = Product(
      id: 'prod_b5',
      shopId: shopB.id,
      artistId: artistKitsune.id,
      name: 'Sticker Cat Day',
      image: '🐱',
      price: 50.0,
      cost: 18.0,
      categoryId: catStickersB.id,
      stock: 57, // 60 initial - 3 sold
      isBestseller: false,
    );

    final shopBProducts = [prodB1, prodB2, prodB3, prodB4, prodB5];
    for (var prod in shopBProducts) {
      await db.saveProduct(prod);
      await db.addStockMovement(StockMovement(
        productId: prod.id,
        type: StockMovementType.importAction,
        qtyChange: prod.stock + (prod.id == 'prod_b1' ? 2 : prod.id == 'prod_b2' ? 1 : prod.id == 'prod_b3' ? 1 : prod.id == 'prod_b4' ? 1 : prod.id == 'prod_b5' ? 3 : 0),
      ));
    }

    // Sample Orders for Shop B
    // Order B1: PromptPay QR (Completed)
    // Fox Ceramic Mug x1 (฿280) + Linen Tote Bag x1 (฿220) = ฿500
    final orderB1 = Order(
      id: 'order_b1',
      shopId: shopB.id,
      eventId: eventB.id,
      status: OrderStatus.completed,
      paymentMethod: PaymentMethod.qr,
      total: 500.0,
      cashReceived: 500.0,
      change: 0.0,
      createdAt: DateTime(2026, 10, 27, 11, 20),
      synced: true,
      createdOffline: true,
      items: [
        OrderItem(
          orderId: 'order_b1',
          productId: prodB1.id,
          artistId: artistKitsune.id,
          nameSnapshot: prodB1.name,
          priceSnapshot: prodB1.price,
          qty: 1,
          discountAmount: 0.0,
        ),
        OrderItem(
          orderId: 'order_b1',
          productId: prodB2.id,
          artistId: artistKitsune.id,
          nameSnapshot: prodB2.name,
          priceSnapshot: prodB2.price,
          qty: 1,
          discountAmount: 0.0,
        ),
      ],
    );
    await db.saveOrder(orderB1);
    await db.addStockMovement(StockMovement(productId: prodB1.id, orderId: orderB1.id, type: StockMovementType.sale, qtyChange: -1));
    await db.addStockMovement(StockMovement(productId: prodB2.id, orderId: orderB1.id, type: StockMovementType.sale, qtyChange: -1));

    // Order B2: Cash payment (Completed)
    // Sticker Cat Day (Shop B edition) x3 (฿150) + Neko Clay Figurine x1 (฿390) = ฿540
    final orderB2 = Order(
      id: 'order_b2',
      shopId: shopB.id,
      eventId: eventB.id,
      status: OrderStatus.completed,
      paymentMethod: PaymentMethod.cash,
      total: 540.0,
      cashReceived: 1000.0,
      change: 460.0,
      createdAt: DateTime(2026, 10, 27, 13, 40),
      synced: true,
      createdOffline: true,
      items: [
        OrderItem(
          orderId: 'order_b2',
          productId: prodB5.id,
          artistId: artistKitsune.id,
          nameSnapshot: prodB5.name,
          priceSnapshot: prodB5.price,
          qty: 3,
          discountAmount: 0.0,
        ),
        OrderItem(
          orderId: 'order_b2',
          productId: prodB3.id,
          artistId: artistNeko.id,
          nameSnapshot: prodB3.name,
          priceSnapshot: prodB3.price,
          qty: 1,
          discountAmount: 0.0,
        ),
      ],
    );
    await db.saveOrder(orderB2);
    await db.addStockMovement(StockMovement(productId: prodB5.id, orderId: orderB2.id, type: StockMovementType.sale, qtyChange: -3));
    await db.addStockMovement(StockMovement(productId: prodB3.id, orderId: orderB2.id, type: StockMovementType.sale, qtyChange: -1));

    // Order B3: Cash payment (Completed) + Proportional Discount ฿40
    // Cat Teacup Set x1 (฿320 gross) + Fox Ceramic Mug x1 (฿280 gross) = ฿600 gross
    // Proportional discount: Neko (฿320/600 * 40 = 21.33), Kitsune (฿280/600 * 40 = 18.67) -> Net ฿560
    final orderB3 = Order(
      id: 'order_b3',
      shopId: shopB.id,
      eventId: eventB.id,
      status: OrderStatus.completed,
      paymentMethod: PaymentMethod.cash,
      total: 560.0,
      cashReceived: 600.0,
      change: 40.0,
      createdAt: DateTime(2026, 10, 27, 16, 15),
      synced: true,
      createdOffline: true,
      items: [
        OrderItem(
          orderId: 'order_b3',
          productId: prodB4.id,
          artistId: artistNeko.id,
          nameSnapshot: prodB4.name,
          priceSnapshot: prodB4.price,
          qty: 1,
          discountAmount: 21.33,
        ),
        OrderItem(
          orderId: 'order_b3',
          productId: prodB1.id,
          artistId: artistKitsune.id,
          nameSnapshot: prodB1.name,
          priceSnapshot: prodB1.price,
          qty: 1,
          discountAmount: 18.67,
        ),
      ],
    );
    await db.saveOrder(orderB3);
    await db.addStockMovement(StockMovement(productId: prodB4.id, orderId: orderB3.id, type: StockMovementType.sale, qtyChange: -1));
    await db.addStockMovement(StockMovement(productId: prodB1.id, orderId: orderB3.id, type: StockMovementType.sale, qtyChange: -1));
  }
}
