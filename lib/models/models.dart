import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// 1. Shop Model
class Shop {
  final String id;
  final String name;
  final String ownerUserId;
  final String promptpayId;
  final String promptpayName;

  Shop({
    String? id,
    required this.name,
    required this.ownerUserId,
    required this.promptpayId,
    required this.promptpayName,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ownerUserId': ownerUserId,
        'promptpayId': promptpayId,
        'promptpayName': promptpayName,
      };

  factory Shop.fromJson(Map<String, dynamic> json) => Shop(
        id: json['id'] as String,
        name: json['name'] as String,
        ownerUserId: json['ownerUserId'] as String,
        promptpayId: json['promptpayId'] as String,
        promptpayName: json['promptpayName'] as String,
      );

  Shop copyWith({
    String? name,
    String? promptpayId,
    String? promptpayName,
  }) {
    return Shop(
      id: id,
      name: name ?? this.name,
      ownerUserId: ownerUserId,
      promptpayId: promptpayId ?? this.promptpayId,
      promptpayName: promptpayName ?? this.promptpayName,
    );
  }
}

/// 2. Member Model (คนในบูธ — Owner หรือ Member)
enum MemberRole { owner, member }

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

/// 3. Invite Model (คำเชิญเข้าร่วมร้าน - อายุ 7 วัน)
enum InviteStatus { pending, accepted, expired, revoked }

class Invite {
  final String id;
  final String shopId;
  final String email;
  final String token;
  final String? artistId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final InviteStatus status;

  Invite({
    String? id,
    required this.shopId,
    required this.email,
    String? token,
    this.artistId,
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
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        status: InviteStatus.values.byName((json['status'] as String?) ?? 'pending'),
      );

  Invite copyWith({InviteStatus? status}) {
    return Invite(
      id: id,
      shopId: shopId,
      email: email,
      token: token,
      artistId: artistId,
      createdAt: createdAt,
      expiresAt: expiresAt,
      status: status ?? this.status,
    );
  }
}

/// 4. Artist Model (Multi-artist with commission rate & member link)
class Artist {
  final String id;
  final String shopId;
  final String name;
  final String? linkedUserId;
  final double? commissionRate; // e.g. 10.0 for 10%, null for 0%

  Artist({
    String? id,
    required this.shopId,
    required this.name,
    this.linkedUserId,
    this.commissionRate,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopId': shopId,
        'name': name,
        'linkedUserId': linkedUserId,
        'commissionRate': commissionRate,
      };

  factory Artist.fromJson(Map<String, dynamic> json) => Artist(
        id: json['id'] as String,
        shopId: json['shopId'] as String,
        name: json['name'] as String,
        linkedUserId: json['linkedUserId'] as String?,
        commissionRate: (json['commissionRate'] as num?)?.toDouble(),
      );

  Artist copyWith({
    String? name,
    String? linkedUserId,
    double? commissionRate,
  }) {
    return Artist(
      id: id,
      shopId: shopId,
      name: name ?? this.name,
      linkedUserId: linkedUserId ?? this.linkedUserId,
      commissionRate: commissionRate ?? this.commissionRate,
    );
  }
}

/// 5. Category Model (Supports hierarchical folders, max 2 levels)
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

/// 6. Product Model
class Product {
  final String id;
  final String shopId;
  final String artistId;
  final String name;
  final String image;
  final double price;
  final double cost;
  final String categoryId;
  final int stock;
  final bool isBestseller;

  Product({
    String? id,
    required this.shopId,
    required this.artistId,
    required this.name,
    this.image = '📦',
    required this.price,
    this.cost = 0.0,
    required this.categoryId,
    required this.stock,
    this.isBestseller = false,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopId': shopId,
        'artistId': artistId,
        'name': name,
        'image': image,
        'price': price,
        'cost': cost,
        'categoryId': categoryId,
        'stock': stock,
        'isBestseller': isBestseller,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        shopId: json['shopId'] as String,
        artistId: json['artistId'] as String,
        name: json['name'] as String,
        image: (json['image'] as String?) ?? '📦',
        price: (json['price'] as num).toDouble(),
        cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
        categoryId: json['categoryId'] as String,
        stock: (json['stock'] as num).toInt(),
        isBestseller: (json['isBestseller'] as bool?) ?? false,
      );

  Product copyWith({
    String? name,
    String? image,
    double? price,
    double? cost,
    String? categoryId,
    int? stock,
    bool? isBestseller,
    String? artistId,
  }) {
    return Product(
      id: id,
      shopId: shopId,
      artistId: artistId ?? this.artistId,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      categoryId: categoryId ?? this.categoryId,
      stock: stock ?? this.stock,
      isBestseller: isBestseller ?? this.isBestseller,
    );
  }
}

/// 7. Event Model & EventArtist (Many-to-Many attending artists)
class Event {
  final String id;
  final String shopId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  Event({
    String? id,
    required this.shopId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopId': shopId,
        'name': name,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'isActive': isActive,
      };

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'] as String,
        shopId: json['shopId'] as String,
        name: json['name'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        isActive: (json['isActive'] as bool?) ?? true,
      );

  Event copyWith({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return Event(
      id: id,
      shopId: shopId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
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

/// 8. Order Model
enum OrderStatus { completed, voided }
enum PaymentMethod { cash, qr }

class Order {
  final String id;
  final String shopId;
  final String eventId;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final double total;
  final double cashReceived;
  final double change;
  final DateTime createdAt;
  final bool synced;
  final bool createdOffline;
  final List<OrderItem> items;

  Order({
    String? id,
    required this.shopId,
    required this.eventId,
    this.status = OrderStatus.completed,
    required this.paymentMethod,
    required this.total,
    this.cashReceived = 0.0,
    this.change = 0.0,
    DateTime? createdAt,
    this.synced = false,
    this.createdOffline = true,
    required this.items,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopId': shopId,
        'eventId': eventId,
        'status': status.name,
        'paymentMethod': paymentMethod.name,
        'total': total,
        'cashReceived': cashReceived,
        'change': change,
        'createdAt': createdAt.toIso8601String(),
        'synced': synced,
        'createdOffline': createdOffline,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        shopId: json['shopId'] as String,
        eventId: json['eventId'] as String,
        status: OrderStatus.values.byName(json['status'] as String),
        paymentMethod: PaymentMethod.values.byName(json['paymentMethod'] as String),
        total: (json['total'] as num).toDouble(),
        cashReceived: (json['cashReceived'] as num?)?.toDouble() ?? 0.0,
        change: (json['change'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        synced: (json['synced'] as bool?) ?? false,
        createdOffline: (json['createdOffline'] as bool?) ?? true,
        items: (json['items'] as List<dynamic>?)
                ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Order copyWith({
    OrderStatus? status,
    bool? synced,
  }) {
    return Order(
      id: id,
      shopId: shopId,
      eventId: eventId,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      total: total,
      cashReceived: cashReceived,
      change: change,
      createdAt: createdAt,
      synced: synced ?? this.synced,
      createdOffline: createdOffline,
      items: items,
    );
  }
}

/// 9. OrderItem Model (Artist & Price Snapshot at sale time)
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

  double get subtotal => (priceSnapshot * qty) - discountAmount;

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
        orderId: json['orderId'] as String,
        productId: json['productId'] as String,
        artistId: json['artistId'] as String,
        nameSnapshot: json['nameSnapshot'] as String,
        priceSnapshot: (json['priceSnapshot'] as num).toDouble(),
        qty: (json['qty'] as num).toInt(),
        discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      );
}

/// 10. StockMovement Ledger Model
enum StockMovementType { sale, voidAction, manualAdjust, importAction }

class StockMovement {
  final String id;
  final String productId;
  final String? orderId;
  final StockMovementType type;
  final int qtyChange;
  final DateTime createdAt;

  StockMovement({
    String? id,
    required this.productId,
    this.orderId,
    required this.type,
    required this.qtyChange,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'orderId': orderId,
        'type': type.name,
        'qtyChange': qtyChange,
        'createdAt': createdAt.toIso8601String(),
      };

  factory StockMovement.fromJson(Map<String, dynamic> json) => StockMovement(
        id: json['id'] as String,
        productId: json['productId'] as String,
        orderId: json['orderId'] as String?,
        type: StockMovementType.values.byName(json['type'] as String),
        qtyChange: (json['qtyChange'] as num).toInt(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// 11. Settlement Model (สรุปจ่ายเงินคืนศิลปินหลังปิดงาน)
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
  }) : id = id ?? _uuid.v4();

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
