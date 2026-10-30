import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/models.dart';
import '../providers/pos_provider.dart';
import '../services/promptpay_service.dart';

class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context),
      body: isTablet ? _buildTabletLayout(context) : _buildMobileLayout(context),
      bottomNavigationBar: isTablet ? null : _buildMobileBottomBar(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final shop = pos.shop;
    final activeEvent = pos.activeEvent;

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Text('🐙', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PopupMenuButton<String>(
              tooltip: 'สลับร้าน (Switch Shop)',
              onSelected: (shopId) => pos.switchShop(shopId),
              itemBuilder: (context) {
                if (pos.allShops.isEmpty) {
                  return [
                    const PopupMenuItem<String>(
                      enabled: false,
                      value: '',
                      child: Text('ยังไม่มีร้านค้าในระบบ', style: TextStyle(color: Colors.grey)),
                    ),
                  ];
                }
                return pos.allShops.map((s) {
                  final isSelected = s.id == pos.currentShopId;
                  return PopupMenuItem<String>(
                    value: s.id,
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle : Icons.storefront_outlined,
                          size: 18,
                          color: isSelected ? const Color(0xFF2563EB) : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF2563EB) : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          shop?.name ?? 'ยังไม่มีร้านค้า',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 18, color: Colors.blueGrey),
                    ],
                  ),
                  if (activeEvent != null)
                    Text(
                      '🎪 ${activeEvent.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Offline Sync Status Badge
        GestureDetector(
          onTap: pos.isSyncing ? null : () => pos.syncNow(),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: pos.unsyncedCount > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: pos.unsyncedCount > 0 ? const Color(0xFFFDE68A) : const Color(0xFF86EFAC),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pos.isSyncing)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD97706)),
                  )
                else
                  Icon(
                    pos.unsyncedCount > 0 ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined,
                    size: 14,
                    color: pos.unsyncedCount > 0 ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                  ),
                const SizedBox(width: 4),
                Text(
                  pos.unsyncedCount > 0 ? '${pos.unsyncedCount} รอซิงก์' : 'ออฟไลน์พร้อม',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: pos.unsyncedCount > 0 ? const Color(0xFF92400E) : const Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Tablet Dual-Pane Layout (Catalog Left, Cart Right)
  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        // Left Column: Catalog & Categories (7 cols ratio)
        Expanded(
          flex: 7,
          child: Column(
            children: [
              _buildSearchBar(context),
              _buildFolderBreadcrumbsAndControls(context),
              Expanded(child: _buildCatalogContent(context, crossAxisCount: 3)),
            ],
          ),
        ),
        // Divider
        const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
        // Right Column: Cart Drawer (5 cols ratio)
        const Expanded(
          flex: 5,
          child: ColoredBox(
            color: Colors.white,
            child: CartDrawer(),
          ),
        ),
      ],
    );
  }

  /// Mobile Layout
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(context),
        _buildFolderBreadcrumbsAndControls(context),
        Expanded(child: _buildCatalogContent(context, crossAxisCount: 2)),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final pos = context.watch<PosProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: TextField(
        onChanged: (val) => pos.setSearchQuery(val),
        decoration: InputDecoration(
          hintText: 'ค้นหาสินค้าทุกโฟลเดอร์... (ชื่อสินค้า)',
          prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      ),
    );
  }

  /// Folder Navigation Breadcrumbs and "ดูทั้งหมด" button (Requirement 4.3)
  Widget _buildFolderBreadcrumbsAndControls(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final breadcrumbs = pos.folderBreadcrumbs;
    final isSearching = pos.searchQuery.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Breadcrumbs Bar
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => pos.openFolder(null),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.folder_outlined, size: 16, color: Color(0xFF2563EB)),
                          const SizedBox(width: 4),
                          Text(
                            'คลังสินค้า',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: (pos.currentFolderId == null && !pos.isAllItemsView) ? FontWeight.bold : FontWeight.normal,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  for (int i = 0; i < breadcrumbs.length; i++) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => pos.openFolder(breadcrumbs[i].id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          breadcrumbs[i].name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: (i == breadcrumbs.length - 1 && !pos.isAllItemsView) ? FontWeight.bold : FontWeight.normal,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // "ดูทั้งหมด" (All Items) Flat List Chip
          ChoiceChip(
            label: const Text('ดูทั้งหมด'),
            selected: pos.isAllItemsView && !isSearching,
            onSelected: (_) => pos.showAllItems(),
            selectedColor: const Color(0xFF2563EB),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: (pos.isAllItemsView && !isSearching) ? Colors.white : const Color(0xFF475569),
            ),
            side: BorderSide(
              color: (pos.isAllItemsView && !isSearching) ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ],
      ),
    );
  }

  /// Catalog Content: Displays Folder Cards or Product Grid based on hierarchy state
  Widget _buildCatalogContent(BuildContext context, {required int crossAxisCount}) {
    final pos = context.watch<PosProvider>();
    final shop = pos.shop;
    final isSearching = pos.searchQuery.isNotEmpty;
    final isAllView = pos.isAllItemsView;

    // 1. If Searching or "All Items" view: Show full flat product list
    if (isSearching || isAllView) {
      final products = pos.filteredProducts;
      if (products.isEmpty) {
        return Center(
          child: Text(
            isSearching ? 'ไม่พบสินค้าที่ตรงกับ "${pos.searchQuery}"' : 'ไม่มีสินค้าในคลัง',
            style: const TextStyle(color: Color(0xFF94A3B8)),
          ),
        );
      }
      return _buildProductsGridView(context, products, crossAxisCount);
    }

    // 2. If at Root Level: Show Root Folder Cards + Uncategorized Products
    if (pos.currentFolderId == null) {
      final rootFolders = pos.categories.where((c) => c.parentCategoryId == null).toList();
      final uncategorized = pos.filteredProducts;

      if (rootFolders.isEmpty && uncategorized.isEmpty) {
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFDBEAFE), width: 2),
                    ),
                    child: const Icon(Icons.storefront_outlined, size: 36, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    shop != null ? 'ร้าน "${shop.name}" ยังไม่มีสินค้า' : 'ยินดีต้อนรับสู่ MyPOS',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    shop != null
                        ? 'คุณสามารถเพิ่มสินค้าจริงได้ในหน้า "คลังสินค้า" หรือกดปุ่มด้านล่างเพื่อโหลดข้อมูลตัวอย่างสำหรับทดสอบ'
                        : 'ระบบพร้อมสำหรับการเริ่มใช้งานจริง (สถานะหน้าว่าง 100%)\nคุณสามารถเริ่มสร้างร้านค้าและเพิ่มสินค้า หรือโหลดข้อมูลจำลองเพื่อทดลองใช้งาน',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _showQuickSetupShopDialog(context, pos),
                        icon: const Icon(Icons.add_business_outlined, size: 18),
                        label: Text(shop != null ? 'แก้ไขข้อมูลร้าน' : 'สร้างร้านค้าของคุณ'),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0D9488),
                          side: const BorderSide(color: Color(0xFF0D9488)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          await pos.loadSampleSeedData();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('โหลดข้อมูลตัวอย่างเรียบร้อยแล้ว')),
                            );
                          }
                        },
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('โหลดข้อมูลตัวอย่าง (Demo Data)'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (rootFolders.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('หมวดหมู่โฟลเดอร์', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1.4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: rootFolders.length,
              itemBuilder: (ctx, i) {
                final folder = rootFolders[i];
                final subCount = pos.categories.where((c) => c.parentCategoryId == folder.id).length;
                final prodCount = pos.products.where((p) => p.categoryId == folder.id).length;

                return _buildFolderCard(
                  title: folder.name,
                  subtitle: subCount > 0 ? '$subCount โฟลเดอร์ย่อย' : '$prodCount รายการ',
                  onTap: () => pos.openFolder(folder.id),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
          if (uncategorized.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('สินค้าทั่วไป (ไม่มีหมวดหมู่)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))),
            ),
            _buildProductsGridView(context, uncategorized, crossAxisCount, isSliver: false),
          ],
        ],
      );
    }

    // 3. Inside a Folder: Show Subfolders + Products in this category
    final subfolders = pos.currentSubfolders;
    final products = pos.filteredProducts;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (subfolders.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('โฟลเดอร์ย่อย', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1.4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: subfolders.length,
            itemBuilder: (ctx, i) {
              final sub = subfolders[i];
              final prodCount = pos.products.where((p) => p.categoryId == sub.id).length;
              return _buildFolderCard(
                title: sub.name,
                subtitle: '$prodCount รายการ',
                onTap: () => pos.openFolder(sub.id),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
        if (products.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('สินค้าในโฟลเดอร์นี้ (${products.length} รายการ)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))),
          ),
          _buildProductsGridView(context, products, crossAxisCount, isSliver: false),
        ] else if (subfolders.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('ไม่มีสินค้าในโฟลเดอร์นี้', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
          ),
      ],
    );
  }

  Widget _buildFolderCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.folder, color: Color(0xFF2563EB), size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsGridView(
    BuildContext context,
    List<Product> products,
    int crossAxisCount, {
    bool isSliver = true,
  }) {
    final pos = context.watch<PosProvider>();

    final grid = GridView.builder(
      shrinkWrap: !isSliver,
      physics: isSliver ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
      padding: isSliver ? const EdgeInsets.all(12) : EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.82,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final isOutOfStock = product.stock <= 0;
        final artistName = pos.getArtistName(product.artistId);

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.04),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              pos.addToCart(product);
              if (product.stock <= 0) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('⚠️ เตือน: ${product.name} สต็อกเหลือ ${product.stock - 1} (ติดลบ) กรุณาปรับสต็อกภายหลัง'),
                    backgroundColor: const Color(0xFFDC2626),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Emoji Icon / Image Box
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          product.image,
                          style: const TextStyle(fontSize: 34),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Artist Name Tag (Multi-Artist Requirement 4.5)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      artistName,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Title
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Price and Stock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '฿${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOutOfStock
                              ? const Color(0xFFFEE2E2)
                              : product.stock <= 10
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isOutOfStock ? 'หมด' : 'เหลือ ${product.stock}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isOutOfStock
                                ? const Color(0xFFDC2626)
                                : product.stock <= 10
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return grid;
  }

  /// Mobile Bottom Bar to view Cart
  Widget _buildMobileBottomBar(BuildContext context) {
    final pos = context.watch<PosProvider>();
    if (pos.cart.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (ctx) => const SizedBox(
                height: 580,
                child: CartDrawer(),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text('${pos.totalCartQty} ชิ้น'),
                ],
              ),
              Text(
                'รวม ฿${pos.cartTotal.toStringAsFixed(0)} • ชำระเงิน',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickSetupShopDialog(BuildContext context, PosProvider pos) {
    final shop = pos.shop;
    final nameCtrl = TextEditingController(text: shop?.name ?? '');
    final ppIdCtrl = TextEditingController(text: shop?.promptpayId ?? '');
    final ppNameCtrl = TextEditingController(text: shop?.promptpayName ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(shop != null ? 'ข้อมูลร้านค้า & พร้อมเพย์' : 'สร้างร้านค้าของคุณ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'ชื่อร้านค้า / หมายเลขบูธ'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ppIdCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'PromptPay ID (เบอร์โทร หรือ เลขประจำตัว)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ppNameCtrl,
                decoration: const InputDecoration(labelText: 'ชื่อบัญชีพร้อมเพย์ (แสดงให้ลูกค้าตรวจสอบ)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  await pos.updateShop(
                    name: name,
                    promptpayId: ppIdCtrl.text.trim(),
                    promptpayName: ppNameCtrl.text.trim(),
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }
}

/// Cart Drawer Widget for iPad & Mobile Bottom Sheet
class CartDrawer extends StatelessWidget {
  const CartDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'รายการสั่งซื้อ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${pos.totalCartQty}',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (pos.cart.isNotEmpty)
                TextButton(
                  onPressed: () => pos.clearCart(),
                  child: const Text('ล้างตะกร้า', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Cart Items List
        Expanded(
          child: pos.cart.isEmpty
              ? const Center(
                  child: Text(
                    'แตะสินค้าด้านซ้ายเพื่อเพิ่มลงตะกร้า',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: pos.cart.length,
                  separatorBuilder: (context, index) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final item = pos.cart[index];
                    final artistName = pos.getArtistName(item.artistId);
                    final itemGross = item.product.price * item.qty;

                    return Row(
                      children: [
                        // Item Title, Artist Tag & Unit Price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      artistName,
                                      style: const TextStyle(fontSize: 9, color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    '฿${item.unitPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                  ),
                                  if (item.discount > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFFCA5A5), width: 0.8),
                                      ),
                                      child: Text(
                                        'ลด -฿${item.discount.toStringAsFixed(0)}',
                                        style: const TextStyle(color: Color(0xFFDC2626), fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Qty Adjusters
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 20, color: Color(0xFF64748B)),
                              onPressed: () => pos.updateCartQty(item.product.id, item.qty - 1),
                            ),
                            Text('${item.qty}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF2563EB)),
                              onPressed: () => pos.updateCartQty(item.product.id, item.qty + 1),
                            ),
                          ],
                        ),
                        // Line Total
                        SizedBox(
                          width: 65,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (item.discount > 0)
                                Text(
                                  '฿${itemGross.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    decoration: TextDecoration.lineThrough,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              Text(
                                '฿${item.totalPrice.toStringAsFixed(0)}',
                                textAlign: TextAlign.end,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),

        // Bottom Summary & Tender Actions
        if (pos.cart.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                // Detailed Itemized Discount Breakdown if discount exists
                if (pos.cartDiscount > 0) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.discount_outlined, size: 14, color: Color(0xFFDC2626)),
                                const SizedBox(width: 4),
                                Text(
                                  'รายละเอียดส่วนลด (${pos.cart.where((i) => i.discount > 0).length} รายการ):',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFB91C1C)),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () => pos.clearDiscounts(),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.close, size: 14, color: Color(0xFFDC2626)),
                                    SizedBox(width: 2),
                                    Text('ล้างส่วนลด', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        for (var dItem in pos.cart.where((i) => i.discount > 0))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '• ${dItem.product.name} (${pos.getArtistName(dItem.artistId)}) x${dItem.qty}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF7F1D1D)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  'ลด -฿${dItem.discount.toStringAsFixed(0)} (เหลือ ฿${dItem.totalPrice.toStringAsFixed(0)})',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                // Discount Button & Summary Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        side: const BorderSide(color: Color(0xFF93C5FD)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showDiscountDialog(context),
                      icon: const Icon(Icons.percent, size: 14, color: Color(0xFF2563EB)),
                      label: Text(
                        pos.cartDiscount > 0 ? 'ส่วนลด -฿${pos.cartDiscount.toStringAsFixed(0)}' : 'ใส่ส่วนลด',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (pos.cartDiscount > 0)
                          Text(
                            'จาก ฿${pos.cartSubtotal.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: Color(0xFF94A3B8)),
                          ),
                        Text(
                          '฿${pos.cartTotal.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Payment Action Buttons
                Row(
                  children: [
                    // Cash Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showCashTenderDialog(context),
                        icon: const Icon(Icons.payments_outlined, size: 18),
                        label: const Text('เงินสด', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // PromptPay QR Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showPromptPayDialog(context),
                        icon: const Icon(Icons.qr_code_2, size: 18),
                        label: const Text('พร้อมเพย์ QR', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Multi-Artist Proportional Discount Dialog (Requirement 4.5)
  void _showDiscountDialog(BuildContext context) {
    final pos = context.read<PosProvider>();
    final amountController = TextEditingController();
    int selectedTab = 0; // 0 = Whole-bill proportional, 1 = Artist-specific
    String? selectedArtistId;

    // Get artists present in cart
    final cartArtistIds = pos.cart.map((i) => i.artistId).toSet().toList();
    if (cartArtistIds.isNotEmpty) {
      selectedArtistId = cartArtistIds.first;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setState) {
          final enteredVal = double.tryParse(amountController.text) ?? 0.0;

          return AlertDialog(
            title: const Text('กำหนดส่วนลด (Discounts)'),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show currently active discounts if any
                  if (pos.cartDiscount > 0) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ส่วนลดที่กำลังใช้อยู่ในบิล:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFDC2626))),
                          const SizedBox(height: 4),
                          for (var item in pos.cart.where((i) => i.discount > 0))
                            Text(
                              '• ${item.product.name} (${pos.getArtistName(item.artistId)}): ลด -฿${item.discount.toStringAsFixed(0)} (เหลือ ฿${item.totalPrice.toStringAsFixed(0)})',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B)),
                            ),
                        ],
                      ),
                    ),
                  ],

                  // Tab Switcher
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('ทั้งบิล (เฉลี่ยสัดส่วน)'),
                          selected: selectedTab == 0,
                          onSelected: (_) => setState(() => selectedTab = 0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('เฉพาะศิลปิน'),
                          selected: selectedTab == 1,
                          onSelected: (_) => setState(() => selectedTab = 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (selectedTab == 0) ...[
                    const Text(
                      'ส่วนลดทั้งบิลจะถูกเฉลี่ยแบ่งตามสัดส่วนมูลค่าสินค้าของแต่ละศิลปินในตะกร้าโดยอัตโนมัติ',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'จำนวนเงินส่วนลดทั้งบิล (฿)',
                        border: OutlineInputBorder(),
                        prefixText: '฿ ',
                      ),
                    ),
                    if (enteredVal > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ตัวอย่างการเฉลี่ยส่วนลด:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            for (var aId in cartArtistIds) ...[
                              Builder(builder: (context) {
                                final aGross = pos.cart
                                    .where((i) => i.artistId == aId)
                                    .fold(0.0, (s, i) => s + (i.product.price * i.qty));
                                final aShare = pos.cartSubtotal > 0 ? (aGross / pos.cartSubtotal) : 0.0;
                                final aDisc = enteredVal * aShare;
                                return Text(
                                  '• ${pos.getArtistName(aId)}: ลด ฿${aDisc.toStringAsFixed(1)} (ยอด ฿${aGross.toStringAsFixed(0)})',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF1D4ED8)),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    const Text(
                      'เลือกลดเฉพาะสินค้าของศิลปินท่านนี้ในบิล สินค้าของศิลปินอื่นจะไม่ถูกหัก',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedArtistId,
                      decoration: const InputDecoration(labelText: 'เลือกศิลปิน', border: OutlineInputBorder()),
                      items: cartArtistIds.map((aId) {
                        return DropdownMenuItem(value: aId, child: Text(pos.getArtistName(aId)));
                      }).toList(),
                      onChanged: (val) => setState(() => selectedArtistId = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'จำนวนเงินส่วนลดของศิลปินนี้ (฿)',
                        border: OutlineInputBorder(),
                        prefixText: '฿ ',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  pos.clearDiscounts();
                  Navigator.pop(ctx);
                },
                child: const Text('ล้างส่วนลด', style: TextStyle(color: Color(0xFFEF4444))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                onPressed: () {
                  final disc = double.tryParse(amountController.text) ?? 0.0;
                  if (disc > 0) {
                    if (selectedTab == 0) {
                      pos.applyWholeBillDiscount(disc);
                    } else if (selectedArtistId != null) {
                      pos.applyArtistDiscount(selectedArtistId!, disc);
                    }
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('ใช้ส่วนลด'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Cash Tender Dialog with Quick Action Chips and Full Touch Numpad
  void _showCashTenderDialog(BuildContext context) {
    final pos = context.read<PosProvider>();
    final total = pos.cartTotal;
    String cashInput = total.toStringAsFixed(0);
    bool isFirstInput = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            final cashReceived = double.tryParse(cashInput) ?? 0.0;
            final isSufficient = cashReceived >= total;
            final change = isSufficient ? cashReceived - total : 0.0;
            final shortfall = isSufficient ? 0.0 : total - cashReceived;

            void onDigit(String d) {
              setState(() {
                if (isFirstInput || cashInput == '0') {
                  cashInput = d;
                  isFirstInput = false;
                } else if (cashInput.length < 7) {
                  cashInput += d;
                }
              });
            }

            void onBackspace() {
              setState(() {
                isFirstInput = false;
                if (cashInput.length > 1) {
                  cashInput = cashInput.substring(0, cashInput.length - 1);
                } else {
                  cashInput = '0';
                }
              });
            }

            void onClear() {
              setState(() {
                isFirstInput = false;
                cashInput = '0';
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header & Total Due
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ชำระด้วยเงินสด', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Bill Total & Received Display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('ยอดที่ต้องชำระ', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                Text(
                                  '฿${total.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            const Divider(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('รับเงินมา', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                Text(
                                  '฿$cashInput',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Change or Shortfall Banner
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isSufficient ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSufficient ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isSufficient ? 'เงินทอน' : 'ยังขาดอีก',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isSufficient ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                              ),
                            ),
                            Text(
                              isSufficient ? '฿${change.toStringAsFixed(0)}' : '฿${shortfall.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isSufficient ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Quick Cash Preset Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildQuickChip('พอดี', () {
                              setState(() {
                                cashInput = total.toStringAsFixed(0);
                                isFirstInput = false;
                              });
                            }),
                            const SizedBox(width: 6),
                            _buildQuickChip('+20', () {
                              setState(() {
                                cashInput = (cashReceived + 20).toStringAsFixed(0);
                                isFirstInput = false;
                              });
                            }),
                            const SizedBox(width: 6),
                            _buildQuickChip('+50', () {
                              setState(() {
                                cashInput = (cashReceived + 50).toStringAsFixed(0);
                                isFirstInput = false;
                              });
                            }),
                            const SizedBox(width: 6),
                            _buildQuickChip('+100', () {
                              setState(() {
                                cashInput = (cashReceived + 100).toStringAsFixed(0);
                                isFirstInput = false;
                              });
                            }),
                            const SizedBox(width: 6),
                            _buildQuickChip('500', () {
                              setState(() {
                                cashInput = '500';
                                isFirstInput = false;
                              });
                            }),
                            const SizedBox(width: 6),
                            _buildQuickChip('1000', () {
                              setState(() {
                                cashInput = '1000';
                                isFirstInput = false;
                              });
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 3x4 Touch Numpad Grid
                      Table(
                        children: [
                          TableRow(
                            children: [
                              _buildNumpadButton('1', () => onDigit('1')),
                              _buildNumpadButton('2', () => onDigit('2')),
                              _buildNumpadButton('3', () => onDigit('3')),
                            ],
                          ),
                          TableRow(
                            children: [
                              _buildNumpadButton('4', () => onDigit('4')),
                              _buildNumpadButton('5', () => onDigit('5')),
                              _buildNumpadButton('6', () => onDigit('6')),
                            ],
                          ),
                          TableRow(
                            children: [
                              _buildNumpadButton('7', () => onDigit('7')),
                              _buildNumpadButton('8', () => onDigit('8')),
                              _buildNumpadButton('9', () => onDigit('9')),
                            ],
                          ),
                          TableRow(
                            children: [
                              _buildNumpadButton('C', onClear, color: const Color(0xFFEF4444)),
                              _buildNumpadButton('0', () => onDigit('0')),
                              _buildNumpadIcon(Icons.backspace_outlined, onBackspace),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Confirm Payment Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSufficient ? const Color(0xFF16A34A) : Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: isSufficient ? 2 : 0,
                          ),
                          onPressed: isSufficient
                              ? () async {
                                  Navigator.pop(ctx);
                                  final order = await pos.checkoutCash(cashReceived: cashReceived);
                                  if (context.mounted) {
                                    _showSuccessDialog(context, order);
                                  }
                                }
                              : null,
                          child: Text(
                            isSufficient
                                ? 'ยืนยันรับเงิน ฿${cashReceived.toStringAsFixed(0)} (ทอน ฿${change.toStringAsFixed(0)})'
                                : 'ยอดเงินไม่เพียงพอ',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildQuickChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      backgroundColor: const Color(0xFFEFF6FF),
      labelStyle: const TextStyle(color: Color(0xFF2563EB)),
      side: const BorderSide(color: Color(0xFFBFDBFE)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
    );
  }

  static Widget _buildNumpadButton(String label, VoidCallback onTap, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            height: 44,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color ?? const Color(0xFF1E293B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildNumpadIcon(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            height: 44,
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  /// PromptPay QR Tender Dialog
  void _showPromptPayDialog(BuildContext context) {
    final pos = context.read<PosProvider>();
    final shop = pos.shop;
    final total = pos.cartTotal;
    final promptpayId = shop?.promptpayId ?? '0812345678';
    final payload = PromptPayService.generatePayload(promptpayId: promptpayId, amount: total);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.qr_code_2, color: Color(0xFF2563EB), size: 22),
            ),
            const SizedBox(width: 8),
            const Text('สแกน QR พร้อมเพย์', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(shop?.promptpayName ?? 'ร้านค้า', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text('พร้อมเพย์: $promptpayId', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: QrImageView(
                data: payload,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'ยอดชำระ ฿${total.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final order = await pos.checkoutPromptPay();
              if (context.mounted) {
                _showSuccessDialog(context, order);
              }
            },
            child: const Text('ยืนยันลูกค้าชำระแล้ว'),
          ),
        ],
      ),
    );
  }

  /// Success Checkout Dialog
  void _showSuccessDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFFDCFCE7),
              child: Icon(Icons.check, color: Color(0xFF16A34A), size: 36),
            ),
            const SizedBox(height: 14),
            const Text('บันทึกการขายสำเร็จ!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text('ออเดอร์ #${order.id.substring(0, 8)}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ยอดรวม'),
                      Text('฿${order.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (order.paymentMethod == PaymentMethod.cash) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('รับเงินสดมา'),
                        Text('฿${order.cashReceived.toStringAsFixed(0)}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('เงินทอน'),
                        Text('฿${order.change.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('บิลถัดไป'),
          ),
        ],
      ),
    );
  }
}
