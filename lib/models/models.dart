import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Feature flag: Indicates if Cloud Functions are deployed (required for remote invite/role modification on live Firebase)
const bool kCloudFunctionsEnabled = false;

/// 1. Shop Model
class Shop {
  final String id;
  final String name;
  final String ownerUserId;
  final String promptpayId;
  final String promptpayName;
  final String currency;
  final DateTime createdAt;

  Shop({
    String? id,
    required this.name,
    required this.ownerUserId,
    required this.promptpayId,
    required this.promptpayName,
    this.currency = 'THB',
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ownerUserId': ownerUserId,
        'promptpayId': promptpayId,
        'promptpayName': promptpayName,
        'currency': currency,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Shop.fromJson(Map<String, dynamic> json) => Shop(
        id: json['id'] as String,
        name: json['name'] as String,
        ownerUserId: json['ownerUserId'] as String,
        promptpayId: json['promptpayId'] as String,
        promptpayName: json['promptpayName'] as String,
        currency: (json['currency'] as String?) ?? 'THB',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );

  Shop copyWith({
    String? name,
    String? promptpayId,
    String? promptpayName,
    String? currency,
  }) {
    return Shop(
      id: id,
      name: name ?? this.name,
      ownerUserId: ownerUserId,
      promptpayId: promptpayId ?? this.promptpayId,
      promptpayName: promptpayName ?? this.promptpayName,
      currency: currency ?? this.currency,
      createdAt: createdAt,
    );
  }
}

/// 2. User Membership Index (v1.7: 1 Google account can be part of multiple shops)
class UserMembership {
  final String shopId;
  final String shopName;
  final MemberRole role;
  final DateTime joinedAt;

  UserMembership({
    required this.shopId,
    required this.shopName,
    required this.role,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'shopId': shopId,
        'shopName': shopName,
        'role': role.name,
        'joinedAt': joinedAt.toIso8601String(),
      };

  factory UserMembership.fromJson(Map<String, dynamic> json) => UserMembership(
        shopId: json['shopId'] as String,
        shopName: (json['shopName'] as String?) ?? 'Shop',
        role: MemberRole.values.byName((json['role'] as String?) ?? 'member'),
        joinedAt: json['joinedAt'] != null
            ? DateTime.parse(json['joinedAt'] as String)
            : DateTime.now(),
      );
}

/// 3. Member Model (Owner, Manager, or Member)
enum MemberRole { owner, manager, member }

class Member {
  final String id;
  final String shopId;
  final String userId;
  final String email;
  final String name;
  final MemberRole role;
  final String? invitedArtistId;
  final DateTime joinedAt;

  Member({
    String? id,
    required this.shopId,
    required this.userId,
    required this.email,
    required this.name,
    this.role = MemberRole.member,
    this.invitedArtistId,
    DateTime? joinedAt,
  })  : id = id ?? _uuid.v4(),
        joinedAt = joinedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopId': shopId,
        'userId': userId,
        'email': email,
        'name': name,
        'role': role.name,
        'invitedArtistId': invitedArtistId,
        'joinedAt': joinedAt.toIso8601String(),
      };

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        id: json['id'] as String,
        shopId: json['shopId'] as String,
        userId: json['userId'] as String,
        email: (json['email'] as String?) ?? '',
        name: (json['name'] as String?) ?? 'Staff',
        role: MemberRole.values.byName((json['role'] as String?) ?? 'member'),
        invitedArtistId: json['invitedArtistId'] as String?,
        joinedAt: json['joinedAt'] != null
            ? DateTime.parse(json['joinedAt'] as String)
            : DateTime.now(),
      );

  Member copyWith({
    String? name,
    MemberRole? role,
    String? invitedArtistId,
  }) {
    return Member(
      id: id,
      shopId: shopId,
      userId: userId,
      email: email,
      name: name ?? this.name,
      role: role ?? this.role,
      invitedArtistId: invitedArtistId ?? this.invitedArtistId,
      joinedAt: joinedAt,
    );
  }
}

/// 4. Invite Model (คำเชิญเข้าร่วมร้าน - อายุ 7 วัน)
enum InviteStatus { pending, accepted, expired, revoked }

class Invite {
  final String id;
  final String shopId;
  final String email;
  final String token;
  final String? artistId;
  final MemberRole role;
  final DateTime createdAt;
  final DateTime expiresAt;
  final InviteStatus status;

  Invite({
    String? id,
    required this.shopId,
    required this.email,
    String? token,
    this.artistId,
    this.role = MemberRole.member,
    DateTime? createdAt,
    DateTime? expiresAt,
    this.status = InviteStatus.pending,
  })  : id = id ?? _uuid.v4(),
        token = token ?? _uuid.v4().substring(0, 8),
        createdAt = createdAt ?? DateTime.now(),
        expiresAt = expiresAt ?? DateTime.now().add(const Duration(days: 7));

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopId': shopId,
        'email': email,
        'token': token,
        'artistId': artistId,
        'role': role.name,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'status': status.name,
      };

  factory Invite.fromJson(Map<String, dynamic> json) => Invite(
        id: json['id'] as String,
        shopId: json['shopId'] as String,
        email: json['email'] as String,
        token: json['token'] as String,
        artistId: json['artistId'] as String?,
        role: MemberRole.values.byName((json['role'] as String?) ?? 'member'),
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        status: InviteStatus.values.byName((json['status'] as String?) ?? 'pending'),
      );

  Invite copyWith({InviteStatus? status, MemberRole? role}) {
    return Invite(
      id: id,
      shopId: shopId,
      email: email,
      token: token,
      artistId: artistId,
      role: role ?? this.role,
      createdAt: createdAt,
      expiresAt: expiresAt,
      status: status ?? this.status,
    );
  }
}

/// 5. Artist Model
class Artist {
  final String id;
  final String shopId;
  final String name;
  final String? linkedUserId;
  final double? commissionRate; // Cached/optional for convenience
  final bool active;

  Artist({
    String? id,
    required this.shopId,
    required this.name,
    this.linkedUserId,
    this.commissionRate,
    this.active = true,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopId': shopId,
        'name': name,
        'linkedUserId': linkedUserId,
        'commissionRate': commissionRate,
        'active': active,
      };

  factory Artist.fromJson(Map<String, dynamic> json) => Artist(
        id: json['id'] as String,
        shopId: json['shopId'] as String,
        name: json['name'] as String,
        linkedUserId: json['linkedUserId'] as String?,
        commissionRate: (json['commissionRate'] as num?)?.toDouble(),
        active: (json['active'] as bool?) ?? true,
      );

  Artist copyWith({
    String? name,
    String? linkedUserId,
    double? commissionRate,
    bool? active,
  }) {
    return Artist(
      id: id,
      shopId: shopId,
      name: name ?? this.name,
      linkedUserId: linkedUserId ?? this.linkedUserId,
      commissionRate: commissionRate ?? this.commissionRate,
      active: active ?? this.active,
    );
  }
}

/// 6. ArtistTerms Model (Owner-only financial agreement)
class ArtistTerm {
  final String artistId;
  final double commissionRate; // percentage
  final String note;

  ArtistTerm({
    required this.artistId,
    required this.commissionRate,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'artistId': artistId,
        'commissionRate': commissionRate,
        'note': note,
      };

  factory ArtistTerm.fromJson(Map<String, dynamic> json) => ArtistTerm(
        artistId: json['artistId'] as String,
        commissionRate: (json['commissionRate'] as num).toDouble(),
        note: (json['note'] as String?) ?? '',
      );
}

/// 7. ProductCost Model (Separated document for fine-grained security rules)
class ProductCost {
  final String productId;
  final String artistId;
  final double cost;

  ProductCost({
    required this.productId,
    required this.artistId,
    required this.cost,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'artistId': artistId,
        'cost': cost,
      };

  factory ProductCost.fromJson(Map<String, dynamic> json) => ProductCost(
        productId: json['productId'] as String,
        artistId: json['artistId'] as String,
        cost: (json['cost'] as num).toDouble(),
      );
}

/// 8. Category Model (Supports hierarchical folders, max 2 levels)
class Category {
  final String id;
  final String shopId;
  final String name;
  final String? parentCategoryId;
  final int sortOrder;

  Category({
    String? id,
    required this.shopId,
    required this.name,
    this.parentCategoryId,
    this.sortOrder = 0,
  }) : id = id ?? _uuid.v4();

  bool get isRoot => parentCategoryId == null || parentCategoryId!.isEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopId': shopId,
        'name': name,
        'parentCategoryId': parentCategoryId,
        'sortOrder': sortOrder,
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        shopId: json['shopId'] as String,
        name: json['name'] as String,
        parentCategoryId: json['parentCategoryId'] as String?,
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      );

  Category copyWith({
    String? name,
    String? parentCategoryId,
    int? sortOrder,
  }) {
    return Category(
      id: id,
      shopId: shopId,
      name: name ?? this.name,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

/// 9. Product Model (Central Catalog - stock can be negative!)
class Product {
  final String id;
  final String shopId;
  final String artistId;
  final String name;
  final String image;
  final String? imagePath;
  final String? imageUrl;
  final double price;
  final double cost;
  final String categoryId;
  final int stock; // Can go negative in v1.7!
  final bool isBestseller;
  final bool active; // Soft delete flag
  final DateTime? updatedAt;
  final String? updatedBy;

  Product({
    String? id,
    required this.shopId,
    required this.artistId,
    required this.name,
    this.image = '📦',
    this.imagePath,
    this.imageUrl,
    required this.price,
    this.cost = 0.0,
    required this.categoryId,
    required this.stock,
    this.isBestseller = false,
    this.active = true,
    this.updatedAt,
    this.updatedBy,
  }) : id = id ?? _uuid.v4();

  bool get isOutOfStock => stock <= 0;
  bool get isNegativeStock => stock < 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopId': shopId,
        'artistId': artistId,
        'name': name,
        'image': image,
        'imagePath': imagePath,
        'imageUrl': imageUrl,
        'price': price,
        'cost': cost,
        'categoryId': categoryId,
        'stock': stock,
        'isBestseller': isBestseller,
        'active': active,
        'updatedAt': updatedAt?.toIso8601String(),
        'updatedBy': updatedBy,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        shopId: json['shopId'] as String,
        artistId: json['artistId'] as String,
        name: json['name'] as String,
        image: (json['image'] as String?) ?? '📦',
        imagePath: json['imagePath'] as String?,
        imageUrl: json['imageUrl'] as String?,
        price: (json['price'] as num).toDouble(),
        cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
        categoryId: json['categoryId'] as String,
        stock: (json['stock'] as num).toInt(),
        isBestseller: (json['isBestseller'] as bool?) ?? false,
        active: (json['active'] as bool?) ?? true,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        updatedBy: json['updatedBy'] as String?,
      );

  Product copyWith({
    String? name,
    String? image,
    String? imagePath,
    String? imageUrl,
    double? price,
    double? cost,
    String? categoryId,
    int? stock,
    bool? isBestseller,
    bool? active,
    String? artistId,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return Product(
      id: id,
      shopId: shopId,
      artistId: artistId ?? this.artistId,
      name: name ?? this.name,
      image: image ?? this.image,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      categoryId: categoryId ?? this.categoryId,
      stock: stock ?? this.stock,
      isBestseller: isBestseller ?? this.isBestseller,
      active: active ?? this.active,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

/// 10. Event Model & Event Product / Artist selections
enum EventStatus { planned, active, closed }

class Event {
  final String id;
  final String shopId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final EventStatus status;
  final List<String> eventArtistIds;
  final List<String> eventProductIds;

  Event({
    String? id,
    required this.shopId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.status = EventStatus.active,
    List<String>? eventArtistIds,
    List<String>? eventProductIds,
  })  : id = id ?? _uuid.v4(),
        eventArtistIds = eventArtistIds ?? [],
        eventProductIds = eventProductIds ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopId': shopId,
        'name': name,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'isActive': isActive,
        'status': status.name,
        'eventArtistIds': eventArtistIds,
        'eventProductIds': eventProductIds,
      };

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'] as String,
        shopId: json['shopId'] as String,
        name: json['name'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        isActive: (json['isActive'] as bool?) ?? true,
        status: EventStatus.values.byName((json['status'] as String?) ?? 'active'),
        eventArtistIds: (json['eventArtistIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        eventProductIds: (json['eventProductIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

  Event copyWith({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    EventStatus? status,
    List<String>? eventArtistIds,
    List<String>? eventProductIds,
  }) {
    return Event(
      id: id,
      shopId: shopId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      eventArtistIds: eventArtistIds ?? this.eventArtistIds,
      eventProductIds: eventProductIds ?? this.eventProductIds,
    );
  }
}

class EventArtist {
  final String id;
  final String eventId;
  final String artistId;

  EventArtist({
    String? id,
    required this.eventId,
    required this.artistId,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventId': eventId,
        'artistId': artistId,
      };

  factory EventArtist.fromJson(Map<String, dynamic> json) => EventArtist(
        id: json['id'] as String,
        eventId: json['eventId'] as String,
        artistId: json['artistId'] as String,
      );
}

/// 11. Artist Order Summary (for aggregated artist totals embedded in Order)
class ArtistOrderSummary {
  final double gross;
  final double discount;
  final double net;
  final int qty;

  ArtistOrderSummary({
    required this.gross,
    required this.discount,
    required this.net,
    required this.qty,
  });

  Map<String, dynamic> toJson() => {
        'gross': gross,
        'discount': discount,
        'net': net,
        'qty': qty,
      };

  factory ArtistOrderSummary.fromJson(Map<String, dynamic> json) =>
      ArtistOrderSummary(
        gross: (json['gross'] as num).toDouble(),
        discount: (json['discount'] as num).toDouble(),
        net: (json['net'] as num).toDouble(),
        qty: (json['qty'] as num).toInt(),
      );
}

/// 12. Order Model (Atomic array items + artistTotals aggregation)
enum OrderStatus { completed, voided }
enum PaymentMethod { cash, qr }

class Order {
  final String id;
  final String shopId;
  final String eventId;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final double subtotal;
  final double discountTotal;
  final double total;
  final double cashReceived;
  final double change;
  final DateTime createdAt;
  final DateTime createdAtClient;
  final bool synced;
  final bool createdOffline;
  final String? createdBy;
  final String? deviceId;
  final DateTime? voidedAt;
  final String? voidedBy;
  final String? voidReason;
  final List<OrderItem> items;
  final Map<String, ArtistOrderSummary> artistTotals;

  factory Order({
    String? id,
    required String shopId,
    required String eventId,
    OrderStatus status = OrderStatus.completed,
    required PaymentMethod paymentMethod,
    double? subtotal,
    double? discountTotal,
    required double total,
    double cashReceived = 0.0,
    double change = 0.0,
    DateTime? createdAt,
    DateTime? createdAtClient,
    bool synced = false,
    bool createdOffline = true,
    String? createdBy,
    String? deviceId,
    DateTime? voidedAt,
    String? voidedBy,
    String? voidReason,
    required List<OrderItem> items,
    Map<String, ArtistOrderSummary>? artistTotals,
  }) {
    final effectiveId = id ?? _uuid.v4();
    final fixedItems = items.map((i) => i.orderId.isEmpty ? i.copyWith(orderId: effectiveId) : i).toList();
    return Order._(
      id: effectiveId,
      shopId: shopId,
      eventId: eventId,
      status: status,
      paymentMethod: paymentMethod,
      subtotal: subtotal,
      discountTotal: discountTotal,
      total: total,
      cashReceived: cashReceived,
      change: change,
      createdAt: createdAt,
      createdAtClient: createdAtClient,
      synced: synced,
      createdOffline: createdOffline,
      createdBy: createdBy,
      deviceId: deviceId,
      voidedAt: voidedAt,
      voidedBy: voidedBy,
      voidReason: voidReason,
      items: fixedItems,
      artistTotals: artistTotals,
    );
  }

  Order._({
    required this.id,
    required this.shopId,
    required this.eventId,
    this.status = OrderStatus.completed,
    required this.paymentMethod,
    double? subtotal,
    double? discountTotal,
    required this.total,
    this.cashReceived = 0.0,
    this.change = 0.0,
    DateTime? createdAt,
    DateTime? createdAtClient,
    this.synced = false,
    this.createdOffline = true,
    this.createdBy,
    this.deviceId,
    this.voidedAt,
    this.voidedBy,
    this.voidReason,
    required this.items,
    Map<String, ArtistOrderSummary>? artistTotals,
  })  : subtotal = subtotal ?? items.fold(0.0, (sum, i) => sum + (i.priceSnapshot * i.qty)),
        discountTotal = discountTotal ?? items.fold(0.0, (sum, i) => sum + i.discountAmount),
        createdAt = createdAt ?? DateTime.now(),
        createdAtClient = createdAtClient ?? (createdAt ?? DateTime.now()),
        artistTotals = artistTotals ?? _calculateArtistTotals(items);

  static Map<String, ArtistOrderSummary> _calculateArtistTotals(List<OrderItem> items) {
    final map = <String, Map<String, num>>{};
    for (var item in items) {
      final aId = item.artistId;
      final gross = item.priceSnapshot * item.qty;
      final discount = item.discountAmount;
      final net = gross - discount;
      final qty = item.qty;

      map[aId] = {
        'gross': (map[aId]?['gross'] ?? 0.0) + gross,
        'discount': (map[aId]?['discount'] ?? 0.0) + discount,
        'net': (map[aId]?['net'] ?? 0.0) + net,
        'qty': (map[aId]?['qty'] ?? 0) + qty,
      };
    }

    return map.map((key, val) => MapEntry(
          key,
          ArtistOrderSummary(
            gross: val['gross']!.toDouble(),
            discount: val['discount']!.toDouble(),
            net: val['net']!.toDouble(),
            qty: val['qty']!.toInt(),
          ),
        ));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopId': shopId,
        'eventId': eventId,
        'status': status.name,
        'paymentMethod': paymentMethod.name,
        'subtotal': subtotal,
        'discountTotal': discountTotal,
        'total': total,
        'cashReceived': cashReceived,
        'change': change,
        'createdAt': createdAt.toIso8601String(),
        'createdAtClient': createdAtClient.toIso8601String(),
        'synced': synced,
        'createdOffline': createdOffline,
        'createdBy': createdBy,
        'deviceId': deviceId,
        'voidedAt': voidedAt?.toIso8601String(),
        'voidedBy': voidedBy,
        'voidReason': voidReason,
        'items': items.map((i) => i.toJson()).toList(),
        'artistTotals':
            artistTotals.map((key, val) => MapEntry(key, val.toJson())),
      };

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?)
            ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    Map<String, ArtistOrderSummary> parsedTotals = {};
    if (json['artistTotals'] != null) {
      final rawMap = json['artistTotals'] as Map<String, dynamic>;
      parsedTotals = rawMap.map((key, value) =>
          MapEntry(key, ArtistOrderSummary.fromJson(value as Map<String, dynamic>)));
    } else {
      parsedTotals = Order._calculateArtistTotals(rawItems);
    }

    return Order(
      id: json['id'] as String,
      shopId: json['shopId'] as String,
      eventId: json['eventId'] as String,
      status: OrderStatus.values.byName(json['status'] as String),
      paymentMethod: PaymentMethod.values.byName(json['paymentMethod'] as String),
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      discountTotal: (json['discountTotal'] as num?)?.toDouble(),
      total: (json['total'] as num).toDouble(),
      cashReceived: (json['cashReceived'] as num?)?.toDouble() ?? 0.0,
      change: (json['change'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdAtClient: json['createdAtClient'] != null
          ? DateTime.parse(json['createdAtClient'] as String)
          : DateTime.parse(json['createdAt'] as String),
      synced: (json['synced'] as bool?) ?? false,
      createdOffline: (json['createdOffline'] as bool?) ?? true,
      createdBy: json['createdBy'] as String?,
      deviceId: json['deviceId'] as String?,
      voidedAt: json['voidedAt'] != null
          ? DateTime.parse(json['voidedAt'] as String)
          : null,
      voidedBy: json['voidedBy'] as String?,
      voidReason: json['voidReason'] as String?,
      items: rawItems,
      artistTotals: parsedTotals,
    );
  }

  Order copyWith({
    OrderStatus? status,
    bool? synced,
    DateTime? voidedAt,
    String? voidedBy,
    String? voidReason,
  }) {
    return Order(
      id: id,
      shopId: shopId,
      eventId: eventId,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      subtotal: subtotal,
      discountTotal: discountTotal,
      total: total,
      cashReceived: cashReceived,
      change: change,
      createdAt: createdAt,
      createdAtClient: createdAtClient,
      synced: synced ?? this.synced,
      createdOffline: createdOffline,
      createdBy: createdBy,
      deviceId: deviceId,
      voidedAt: voidedAt ?? this.voidedAt,
      voidedBy: voidedBy ?? this.voidedBy,
      voidReason: voidReason ?? this.voidReason,
      items: items,
      artistTotals: artistTotals,
    );
  }
}

/// 13. OrderItem Model (Artist & Price Snapshot at sale time)
class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String artistId;
  final String nameSnapshot;
  final double priceSnapshot;
  final int qty;
  final double discountAmount;

  OrderItem({
    String? id,
    required this.orderId,
    required this.productId,
    required this.artistId,
    required this.nameSnapshot,
    required this.priceSnapshot,
    required this.qty,
    this.discountAmount = 0.0,
  }) : id = id ?? _uuid.v4();

  OrderItem copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? artistId,
    String? nameSnapshot,
    double? priceSnapshot,
    int? qty,
    double? discountAmount,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      artistId: artistId ?? this.artistId,
      nameSnapshot: nameSnapshot ?? this.nameSnapshot,
      priceSnapshot: priceSnapshot ?? this.priceSnapshot,
      qty: qty ?? this.qty,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }

  double get subtotal => (priceSnapshot * qty) - discountAmount;
  double get lineTotal => subtotal;

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'productId': productId,
        'artistId': artistId,
        'nameSnapshot': nameSnapshot,
        'priceSnapshot': priceSnapshot,
        'qty': qty,
        'discountAmount': discountAmount,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'] as String,
        orderId: (json['orderId'] as String?) ?? '',
        productId: json['productId'] as String,
        artistId: json['artistId'] as String,
        nameSnapshot: (json['nameSnapshot'] as String?) ?? (json['name'] as String? ?? ''),
        priceSnapshot: ((json['priceSnapshot'] ?? json['price']) as num).toDouble(),
        qty: (json['qty'] as num).toInt(),
        discountAmount: ((json['discountAmount'] ?? json['discount']) as num?)?.toDouble() ?? 0.0,
      );
}

/// 14. StockMovement Ledger Model
enum StockMovementType { sale, voidAction, manualAdjust, importAction }

class StockMovement {
  final String id;
  final String productId;
  final String? orderId;
  final StockMovementType type;
  final int qtyChange;
  final DateTime createdAt;
  final String? createdBy;

  StockMovement({
    String? id,
    required this.productId,
    this.orderId,
    required this.type,
    required this.qtyChange,
    DateTime? createdAt,
    this.createdBy,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'orderId': orderId,
        'type': type.name,
        'qtyChange': qtyChange,
        'createdAt': createdAt.toIso8601String(),
        'createdBy': createdBy,
      };

  factory StockMovement.fromJson(Map<String, dynamic> json) => StockMovement(
        id: json['id'] as String,
        productId: json['productId'] as String,
        orderId: json['orderId'] as String?,
        type: StockMovementType.values.byName(json['type'] as String),
        qtyChange: (json['qtyChange'] as num).toInt(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        createdBy: json['createdBy'] as String?,
      );
}

/// 15. Settlement Model (สรุปจ่ายเงินคืนศิลปินหลังปิดงาน)
class Settlement {
  final String id;
  final String shopId;
  final String eventId;
  final String artistId;
  final double grossSales;
  final double commissionAmount;
  final double netPayout;
  final bool paid;
  final DateTime? paidAt;
  final String note;
  final DateTime calculatedAt;

  Settlement({
    String? id,
    required this.shopId,
    required this.eventId,
    required this.artistId,
    required this.grossSales,
    required this.commissionAmount,
    required this.netPayout,
    this.paid = false,
    this.paidAt,
    this.note = '',
    DateTime? calculatedAt,
  })  : id = id ?? '${eventId}_$artistId',
        calculatedAt = calculatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopId': shopId,
        'eventId': eventId,
        'artistId': artistId,
        'grossSales': grossSales,
        'commissionAmount': commissionAmount,
        'netPayout': netPayout,
        'paid': paid,
        'paidAt': paidAt?.toIso8601String(),
        'note': note,
        'calculatedAt': calculatedAt.toIso8601String(),
      };

  factory Settlement.fromJson(Map<String, dynamic> json) => Settlement(
        id: json['id'] as String,
        shopId: json['shopId'] as String,
        eventId: json['eventId'] as String,
        artistId: json['artistId'] as String,
        grossSales: (json['grossSales'] as num).toDouble(),
        commissionAmount: (json['commissionAmount'] as num).toDouble(),
        netPayout: (json['netPayout'] as num).toDouble(),
        paid: (json['paid'] as bool?) ?? false,
        paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt'] as String) : null,
        note: (json['note'] as String?) ?? '',
        calculatedAt: json['calculatedAt'] != null
            ? DateTime.parse(json['calculatedAt'] as String)
            : DateTime.now(),
      );

  Settlement copyWith({
    bool? paid,
    DateTime? paidAt,
    String? note,
  }) {
    return Settlement(
      id: id,
      shopId: shopId,
      eventId: eventId,
      artistId: artistId,
      grossSales: grossSales,
      commissionAmount: commissionAmount,
      netPayout: netPayout,
      paid: paid ?? this.paid,
      paidAt: paidAt ?? this.paidAt,
      note: note ?? this.note,
      calculatedAt: calculatedAt,
    );
  }
}

/// Cart Item for POS in-memory checkout flow
class CartItem {
  final Product product;
  int qty;
  double discount; // discount amount in THB for this item

  CartItem({
    required this.product,
    this.qty = 1,
    this.discount = 0.0,
  });

  String get artistId => product.artistId;
  double get unitPrice => product.price;
  double get totalPrice => (unitPrice * qty) - discount;
}
