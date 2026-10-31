import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:booth_pos_app/models/models.dart';
import 'package:booth_pos_app/repositories/repositories.dart';

void main() {
  group('Phase C - Firestore Security Rules & Query Constraints Contract', () {
    test('Phase C - Item 4: Index configuration exists for member and event compound order queries', () {
      final indexFile = File('firestore.indexes.json');
      expect(indexFile.existsSync(), isTrue);

      final content = jsonDecode(indexFile.readAsStringSync()) as Map<String, dynamic>;
      final indexes = content['indexes'] as List<dynamic>;

      // Must have createdBy + createdAtClient index
      final hasCreatedByIndex = indexes.any((idx) {
        final fields = (idx['fields'] as List<dynamic>).map((f) => f['fieldPath']).toList();
        return idx['collectionGroup'] == 'orders' && fields.contains('createdBy') && fields.contains('createdAtClient');
      });
      expect(hasCreatedByIndex, isTrue);

      // Must have createdBy + eventId + createdAtClient index
      final hasEventCreatedByIndex = indexes.any((idx) {
        final fields = (idx['fields'] as List<dynamic>).map((f) => f['fieldPath']).toList();
        return idx['collectionGroup'] == 'orders' &&
            fields.contains('createdBy') &&
            fields.contains('eventId') &&
            fields.contains('createdAtClient');
      });
      expect(hasEventCreatedByIndex, isTrue);
    });

    test('Phase C - Item 4: Role-based OrderRepository query constraints logic', () async {
      final repo = FakeRepositoryRegistry();
      await repo.createShop(name: 'S1', ownerUserId: 'u_owner');

      // Place 2 orders by member 1, 1 order by member 2
      final o1 = Order(
        shopId: 'S1',
        eventId: 'E1',
        paymentMethod: PaymentMethod.cash,
        total: 100,
        createdBy: 'u_member_1',
        items: [OrderItem(orderId: '', productId: 'p1', artistId: 'a1', nameSnapshot: 'A', priceSnapshot: 100, qty: 1)],
      );
      final o2 = Order(
        shopId: 'S1',
        eventId: 'E1',
        paymentMethod: PaymentMethod.cash,
        total: 200,
        createdBy: 'u_member_1',
        items: [OrderItem(orderId: '', productId: 'p1', artistId: 'a1', nameSnapshot: 'A', priceSnapshot: 200, qty: 1)],
      );
      final o3 = Order(
        shopId: 'S1',
        eventId: 'E1',
        paymentMethod: PaymentMethod.cash,
        total: 300,
        createdBy: 'u_member_2',
        items: [OrderItem(orderId: '', productId: 'p2', artistId: 'a2', nameSnapshot: 'B', priceSnapshot: 300, qty: 1)],
      );

      await repo.placeOrder(o1);
      await repo.placeOrder(o2);
      await repo.placeOrder(o3);

      // Owner watches without filter -> sees all 3 orders
      final ownerOrders = await repo.watchOrders('S1').first;
      expect(ownerOrders.length, 3);

      // Member 1 watches with createdBy filter -> sees only their 2 orders
      final member1Orders = await repo.watchOrders('S1', createdBy: 'u_member_1').first;
      expect(member1Orders.length, 2);
      expect(member1Orders.every((o) => o.createdBy == 'u_member_1'), isTrue);
    });

    test('Phase C - Item 5: firestore.rules.mvp exists with temporary batch creation rules and disclaimer', () {
      final mvpFile = File('firestore.rules.mvp');
      expect(mvpFile.existsSync(), isTrue);

      final content = mvpFile.readAsStringSync();
      expect(content.contains('TEMPORARY: ลบเมื่อ deploy Cloud Functions แล้ว'), isTrue);
      expect(content.contains('request.resource.data.ownerUid == request.auth.uid'), isTrue);
      expect(content.contains("request.resource.data.role == 'owner'"), isTrue);
      expect(content.contains('kCloudFunctionsEnabled'), isFalse); // Kept in Dart
      expect(kCloudFunctionsEnabled, isFalse);
    });

    test('Phase C - Production firestore.rules structural and validator compliance', () {
      final rulesFile = File('firestore.rules');
      expect(rulesFile.existsSync(), isTrue);

      final content = rulesFile.readAsStringSync();

      // 1. Assumed Data Model documentation exists
      expect(content.contains('Assumed Data Model'), isTrue);
      expect(content.contains('Collection: shops/{shopId}'), isTrue);
      expect(content.contains('Collection: shops/{shopId}/products/{productId}'), isTrue);
      expect(content.contains('Collection: shops/{shopId}/orders/{orderId}'), isTrue);

      // 2. Domain Validator Functions exist (Validator Function Pattern)
      expect(content.contains('function isValidShop('), isTrue);
      expect(content.contains('function isValidProduct('), isTrue);
      expect(content.contains('function isValidOrder('), isTrue);
      expect(content.contains('function isValidStockMovement('), isTrue);
      expect(content.contains('function isValidSettlement('), isTrue);
      expect(content.contains('function isValidProductCost('), isTrue);

      // 3. Section 12.1 Acceptance Criteria in rules:
      // - Member cannot change product price, but can decrement stock
      expect(content.contains("onlyChanges(['stock', 'updatedAt', 'updatedBy'])"), isTrue);
      // - Manager cannot read settlements or artistTerms (only isOwner)
      expect(content.contains("match /settlements/{settlementId}"), isTrue);
      expect(content.contains("allow read: if isOwner(shopId);"), isTrue);
      expect(content.contains("match /artistTerms/{artistId}"), isTrue);
      // - OwnerUid immutable on shop update
      expect(content.contains("request.resource.data.ownerUid == resource.data.ownerUid"), isTrue);
      // - Member productCost restricted to linked artist
      expect(content.contains("resource.data.artistId == myArtistId(shopId)"), isTrue);
      // - Stock movements immutable (update, delete forbidden)
      expect(content.contains("match /stockMovements/{movementId}"), isTrue);
      expect(content.contains("allow update, delete: if false;"), isTrue);
      // - Order delete forbidden and double-void prevented
      expect(content.contains("resource.data.status == 'completed'"), isTrue);
      expect(content.contains("request.resource.data.status == 'voided'"), isTrue);
      expect(content.contains("allow delete: if false;"), isTrue);
    });
  });
}

