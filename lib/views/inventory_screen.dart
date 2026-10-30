import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/pos_provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _search = '';
  String? _catId;

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final categories = pos.categories;
    final products = pos.products.where((p) {
      final matchCat = _catId == null || p.categoryId == _catId;
      final matchSearch = _search.isEmpty || p.name.toLowerCase().contains(_search.toLowerCase());
      return matchCat && matchSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('คลังสินค้า (Inventory)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Import CSV',
            onPressed: () => _showCsvImportDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export CSV',
            onPressed: () => _showCsvExportSnackbar(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        onPressed: () => _showProductDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มสินค้า'),
      ),
      body: Column(
        children: [
          // Search & Filter
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _search = val),
                  decoration: InputDecoration(
                    hintText: 'ค้นหาสินค้า... (ชื่อสินค้า)',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length + 1,
                    itemBuilder: (ctx, i) {
                      final isAll = i == 0;
                      final isSel = isAll ? _catId == null : _catId == categories[i - 1].id;
                      final title = isAll ? 'ทั้งหมด (${pos.products.length})' : categories[i - 1].name;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(title, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : Colors.black87)),
                          selected: isSel,
                          selectedColor: const Color(0xFF2563EB),
                          onSelected: (_) => setState(() => _catId = isAll ? null : categories[i - 1].id),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: products.isEmpty
                ? const Center(child: Text('ไม่พบรายการสินค้า', style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final p = products[index];
                      final artistName = pos.getArtistName(p.artistId);
                      final canSeeCost = pos.canViewCost(p);
                      final costText = canSeeCost ? '฿${p.cost.toStringAsFixed(0)}' : '-';

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            // Emoji
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(child: Text(p.image, style: const TextStyle(fontSize: 26))),
                            ),
                            const SizedBox(width: 12),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          p.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Artist Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: const Color(0xFFBFDBFE)),
                                        ),
                                        child: Text(
                                          artistName,
                                          style: const TextStyle(fontSize: 10, color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'ราคา ฿${p.price.toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('•  ทุน $costText',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Stock Counter Badge
                            ActionChip(
                              backgroundColor: p.stock <= 5 ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                              label: Text(
                                'เหลือ: ${p.stock}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: p.stock <= 5 ? const Color(0xFFDC2626) : const Color(0xFF334155),
                                ),
                              ),
                              onPressed: () => _showQuickStockDialog(context, p),
                            ),
                            // Popup Actions
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _showProductDialog(context, product: p);
                                } else if (val == 'dup') {
                                  pos.duplicateProduct(p);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('คัดลอก "${p.name}" เรียบร้อย')),
                                  );
                                } else if (val == 'del') {
                                  _confirmDelete(context, p);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('แก้ไข')])),
                                const PopupMenuItem(value: 'dup', child: Row(children: [Icon(Icons.copy, size: 16), SizedBox(width: 8), Text('คัดลอก (Duplicate)')])),
                                const PopupMenuItem(value: 'del', child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: 8), Text('ลบ', style: TextStyle(color: Colors.red))])),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product p) {
    final pos = context.read<PosProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบสินค้า'),
        content: Text('คุณต้องการลบ "${p.name}" ออกจากคลังสินค้าหรือไม่? (ประวัติการขายเดิมจะไม่หายไป)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () {
              pos.deleteProduct(p.id);
              Navigator.pop(ctx);
            },
            child: const Text('ลบสินค้า'),
          ),
        ],
      ),
    );
  }

  void _showQuickStockDialog(BuildContext context, Product product) {
    final pos = context.read<PosProvider>();
    int change = 0;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dCtx, setDState) {
            return AlertDialog(
              title: Text('ปรับสต็อก: ${product.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('สต็อกปัจจุบัน: ${product.stock} ชิ้น'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setDState(() => change -= 1),
                      ),
                      Text(change >= 0 ? '+$change' : '$change',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setDState(() => change += 1),
                      ),
                    ],
                  ),
                  Text('หลังปรับปรุง: ${(product.stock + change).clamp(0, 99999)} ชิ้น',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    pos.adjustStock(product.id, change, 'manual_adjust');
                  },
                  child: const Text('บันทึกสต็อก'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showProductDialog(BuildContext context, {Product? product}) {
    final pos = context.read<PosProvider>();
    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl = TextEditingController(text: product?.price != null ? product!.price.toStringAsFixed(0) : '');
    final costCtrl = TextEditingController(text: product?.cost != null ? product!.cost.toStringAsFixed(0) : '0');
    final stockCtrl = TextEditingController(text: product?.stock != null ? product!.stock.toString() : '10');
    String selectedEmoji = product?.image ?? '🎨';
    String selectedCat = product?.categoryId ?? (pos.categories.isNotEmpty ? pos.categories.first.id : '');
    String selectedArtistId = product?.artistId ?? (pos.artists.isNotEmpty ? pos.artists.first.id : 'default_artist');
    String? validationError;

    final emojis = ['🐱', '🌸', '☕', '✨', '🐕', '🌌', '🎨', '📚', '🧸', '🎀', '🎒', '🧦'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dCtx, setDState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(isEdit ? 'แก้ไขสินค้า' : 'เพิ่มสินค้าใหม่'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (validationError != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                validationError!,
                                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Emoji Picker Row
                    const Text('ไอคอนสินค้า', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: emojis.map((e) {
                        final isSel = selectedEmoji == e;
                        return GestureDetector(
                          onTap: () => setDState(() => selectedEmoji = e),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFEFF6FF) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSel ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
                            ),
                            child: Text(e, style: const TextStyle(fontSize: 20)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'ชื่อสินค้า *', isDense: true),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'ราคาขาย (฿) *', isDense: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: costCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'ราคาทุน (฿)', isDense: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'จำนวนสต็อกเริ่มต้น', isDense: true),
                    ),
                    const SizedBox(height: 10),
                    // Artist selector (Requirement 4.5)
                    DropdownButtonFormField<String>(
                      initialValue: selectedArtistId,
                      decoration: const InputDecoration(labelText: 'ศิลปินเจ้าของสินค้า *', isDense: true),
                      items: pos.artists
                          .map((a) => DropdownMenuItem<String>(value: a.id, child: Text(a.name)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDState(() => selectedArtistId = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    // Category selector (Requirement 4.3)
                    DropdownButtonFormField<String>(
                      initialValue: selectedCat.isNotEmpty ? selectedCat : null,
                      decoration: const InputDecoration(labelText: 'หมวดหมู่ / โฟลเดอร์', isDense: true),
                      items: pos.categories
                          .map((c) => DropdownMenuItem<String>(
                                value: c.id,
                                child: Text(c.parentCategoryId != null ? '  ↳ ${c.name}' : c.name),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDState(() => selectedCat = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
                ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final price = double.tryParse(priceCtrl.text) ?? 0.0;
                    final cost = double.tryParse(costCtrl.text) ?? 0.0;
                    final stock = int.tryParse(stockCtrl.text) ?? 0;

                    // Acceptance criteria 4.2 validation
                    if (name.isEmpty) {
                      setDState(() => validationError = 'กรุณากรอกชื่อสินค้า');
                      return;
                    }
                    if (price <= 0) {
                      setDState(() => validationError = 'กรุณาระบุราคาขายที่มากกว่า 0 บาท');
                      return;
                    }

                    final p = Product(
                      id: product?.id,
                      shopId: pos.shop?.id ?? 'default_shop',
                      artistId: selectedArtistId,
                      name: name,
                      image: selectedEmoji,
                      price: price,
                      cost: cost,
                      categoryId: selectedCat,
                      stock: stock,
                    );
                    pos.saveProduct(p);
                    Navigator.pop(ctx);
                  },
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCsvExportSnackbar(BuildContext context) {
    final pos = context.read<PosProvider>();
    final buffer = StringBuffer();
    buffer.writeln('ID,Name,Artist,Category,Price,Cost,Stock');
    for (var p in pos.products) {
      final aName = pos.getArtistName(p.artistId);
      final cName = pos.categories.cast<Category?>().firstWhere((c) => c?.id == p.categoryId, orElse: () => null)?.name ?? '';
      buffer.writeln('${p.id},"${p.name}","$aName","$cName",${p.price},${p.cost},${p.stock}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('คัดลอกข้อมูลสินค้าในรูปแบบ CSV ลงใน Clipboard แล้ว')),
    );
  }

  void _showCsvImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('นำเข้าสินค้า (Import CSV)'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ฟอร์แมต CSV ที่รองรับ:'),
            SizedBox(height: 8),
            Text('name, price, cost, stock, category, artist', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
            SizedBox(height: 12),
            Text('ระบบจะทำการตรวจสอบข้อมูลว่าง และแจ้งเตือนก่อนบันทึกลงฐานข้อมูล local DB ออฟไลน์', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ปิด')),
        ],
      ),
    );
  }
}
