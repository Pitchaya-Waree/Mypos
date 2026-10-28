import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/pos_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final shop = pos.shop;
    final activeEvent = pos.activeEvent;
    final unsynced = pos.unsyncedCount;
    final isOwner = pos.isOwner;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('ตั้งค่าระบบ (Settings)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Role Banner if Member
          if (!isOwner)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Color(0xFFD97706), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'คุณกำลังใช้งานในฐานะ Member การแก้ไขข้อมูลร้านและเชิญทีมงานจะถูกจำกัดเฉพาะ Owner เท่านั้น (สลับบทบาทได้ในหน้า "ทีมงาน & บทบาท")',
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),

          // Offline & Sync Engine Card (Requirement 4.12)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: unsynced > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: unsynced > 0 ? const Color(0xFFFDE68A) : const Color(0xFF86EFAC),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          unsynced > 0 ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined,
                          color: unsynced > 0 ? const Color(0xFF92400E) : const Color(0xFF15803D),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ระบบซิงก์ข้อมูลออฟไลน์ (Offline-First)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: unsynced > 0 ? const Color(0xFF92400E) : const Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                    if (pos.isSyncing)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  unsynced > 0
                      ? 'มีรายการขาย $unsynced รายการที่บันทึกในเครื่องและรอเชื่อมต่อเน็ตเพื่อส่งขึ้นคลาวด์'
                      : 'ข้อมูลทั้งหมดซิงก์ขึ้นคลาวด์เรียบร้อยแล้ว หรือพร้อมทำงานออฟไลน์ได้ 100%',
                  style: TextStyle(
                    fontSize: 12,
                    color: unsynced > 0 ? const Color(0xFF92400E) : const Color(0xFF166534),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F172A),
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: pos.isSyncing ? null : () => pos.syncNow(),
                    icon: const Icon(Icons.sync, size: 18),
                    label: const Text('ซิงก์ขึ้นคลาวด์เดี๋ยวนี้ (Sync Now)'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Active Event Section (Requirement 4.11)
          _buildSectionHeader('อีเวนต์ & ศิลปินที่เข้าร่วม (Event & Attending Artists)'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.festival_outlined, color: Color(0xFFD97706)),
                  title: Text(activeEvent?.name ?? 'ไม่ได้เลือกอีเวนต์ (แสดงสินค้าทั้งหมด)'),
                  subtitle: Text(
                    activeEvent != null
                        ? 'ศิลปินร่วมงาน: ${pos.activeEventArtistIds.map((id) => pos.getArtistName(id)).join(", ")}'
                        : 'แตะเพื่อเลือกอีเวนต์ที่กำลังจัด หรือสร้างอีเวนต์ใหม่',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.swap_horiz),
                  onTap: () => _showEventSelectorDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Category Folders Management (Requirement 4.3)
          _buildSectionHeader('หมวดหมู่สินค้าแบบโฟลเดอร์ (Category Folders)'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_special_outlined, color: Color(0xFF2563EB)),
                  title: const Text('จัดการโฟลเดอร์หมวดหมู่'),
                  subtitle: Text('ทั้งหมด ${pos.categories.length} โฟลเดอร์ (จำกัดความลึกไม่เกิน 2 ชั้น)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showCategoryManagementDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Artists & Commission Section (Requirement 4.6)
          _buildSectionHeader('ศิลปิน & ค่าคอมมิชชัน (Artists & Commission)'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined, color: Color(0xFF8B5CF6)),
                  title: const Text('จัดการศิลปิน & ค่าคอมมิชชัน'),
                  subtitle: Text('${pos.artists.length} ศิลปินในบูธ • กำหนด % ส่วนแบ่งยอดขาย'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showArtistManagementDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Shop Settings Section
          _buildSectionHeader('ข้อมูลร้านค้า & พร้อมเพย์ (PromptPay)'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.swap_horiz, color: Color(0xFF2563EB)),
                  title: const Text('สลับร้านค้า (Multi-Shop Isolation)'),
                  subtitle: Text('กำลังเลือกร้าน: ${shop?.name ?? 'ยังไม่มีร้านค้า'}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showSwitchShopDialog(context, pos),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storefront_outlined, color: Color(0xFF2563EB)),
                  title: Text(shop != null ? 'ชื่อร้านค้า / บูธ' : 'สร้างร้านค้าใหม่'),
                  subtitle: Text(shop?.name ?? 'ยังไม่มีร้านค้า (แตะเพื่อสร้างร้าน)'),
                  trailing: isOwner ? const Icon(Icons.edit_outlined, size: 18) : null,
                  onTap: isOwner ? () => _showEditShopDialog(context) : null,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.qr_code_2, color: Color(0xFF2563EB)),
                  title: const Text('เบอร์โทร / เลขประจำตัว PromptPay'),
                  subtitle: Text('${shop?.promptpayId ?? '-'} (${shop?.promptpayName ?? '-'})'),
                  trailing: isOwner ? const Icon(Icons.edit_outlined, size: 18) : null,
                  onTap: isOwner ? () => _showEditShopDialog(context) : null,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.auto_awesome, color: Color(0xFF0D9488)),
                  title: const Text('โหลดข้อมูลตัวอย่างสำหรับทดสอบ (Demo Seed Data)'),
                  subtitle: const Text('จำลองข้อมูลร้าน A, ร้าน B และยอดขายตัวอย่างทั้งหมด'),
                  trailing: const Icon(Icons.play_arrow_outlined),
                  onTap: () async {
                    await pos.loadSampleSeedData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('โหลดข้อมูลตัวอย่างและยอดขายเรียบร้อยแล้ว')),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFDC2626)),
                  title: const Text('ล้างข้อมูลทั้งหมด (เริ่มต้นใช้งานจริงแบบหน้าว่าง)'),
                  subtitle: const Text('ลบข้อมูลจำลองทั้งหมดเพื่อให้เป็นหน้าโล่ง 100% พร้อมใช้งานจริง'),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFFDC2626)),
                  onTap: () => _showConfirmClearAllDialog(context, pos),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Logout Action (Safeguarded against unsynced data loss)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFEE2E2)),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFDC2626)),
              title: const Text(
                'ออกจากระบบ (Google Account)',
                style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('มีระบบบล็อกการออกจากระบบหากยังมีข้อมูลค้างซิงก์'),
              onTap: () => _handleLogoutAttempt(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)),
      ),
    );
  }

  void _showEditShopDialog(BuildContext context) {
    final pos = context.read<PosProvider>();
    final shop = pos.shop;
    final nameCtrl = TextEditingController(text: shop?.name ?? '');
    final ppIdCtrl = TextEditingController(text: shop?.promptpayId ?? '');
    final ppNameCtrl = TextEditingController(text: shop?.promptpayName ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('แก้ไขข้อมูลร้านค้า & พร้อมเพย์'),
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
                decoration: const InputDecoration(labelText: 'PromptPay ID (เบอร์มือถือ หรือ บัตร ปชช.)'),
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
              onPressed: () {
                pos.updateShop(
                  name: nameCtrl.text.trim(),
                  promptpayId: ppIdCtrl.text.trim(),
                  promptpayName: ppNameCtrl.text.trim(),
                );
                Navigator.pop(ctx);
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }

  // --- Category Management Dialog (Requirement 4.3) ---
  void _showCategoryManagementDialog(BuildContext context) {
    final pos = context.read<PosProvider>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final rootCats = pos.categories.where((c) => c.parentCategoryId == null).toList();

          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('จัดการโฟลเดอร์หมวดหมู่'),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF2563EB)),
                  tooltip: 'เพิ่มโฟลเดอร์',
                  onPressed: () => _showAddCategoryDialog(dialogCtx),
                ),
              ],
            ),
            content: SizedBox(
              width: 450,
              height: 400,
              child: ListView(
                children: [
                  for (var root in rootCats) ...[
                    ListTile(
                      leading: const Icon(Icons.folder, color: Color(0xFF2563EB)),
                      title: Text(root.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('โฟลเดอร์หลัก (ชั้นที่ 1)', style: TextStyle(fontSize: 11)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                        onPressed: () => _confirmDeleteCategory(dialogCtx, root),
                      ),
                    ),
                    // Subfolders (Level 2)
                    for (var sub in pos.categories.where((c) => c.parentCategoryId == root.id))
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: ListTile(
                          leading: const Icon(Icons.subdirectory_arrow_right, color: Color(0xFF64748B), size: 18),
                          title: Text(sub.name),
                          subtitle: const Text('โฟลเดอร์ย่อย (ชั้นที่ 2)', style: TextStyle(fontSize: 11)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                            onPressed: () => _confirmDeleteCategory(dialogCtx, sub),
                          ),
                        ),
                      ),
                    const Divider(height: 1),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ปิด')),
            ],
          );
        },
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext parentContext) {
    final pos = parentContext.read<PosProvider>();
    final nameCtrl = TextEditingController();
    String? selectedParentId; // null = root folder

    showDialog(
      context: parentContext,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setState) => AlertDialog(
          title: const Text('เพิ่มโฟลเดอร์หมวดหมู่ใหม่'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'ชื่อโฟลเดอร์ *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              // Parent Category Selector (Limit to 2 levels)
              DropdownButtonFormField<String?>(
                initialValue: selectedParentId,
                decoration: const InputDecoration(
                  labelText: 'ตำแหน่งโฟลเดอร์ (ระดับ)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('📁 โฟลเดอร์หลัก (ชั้นที่ 1)')),
                  // Only show root folders as potential parents to strictly enforce max 2 levels!
                  ...pos.categories.where((c) => c.parentCategoryId == null).map((c) {
                    return DropdownMenuItem(
                      value: c.id,
                      child: Text('  ↳ โฟลเดอร์ย่อยใน "${c.name}" (ชั้นที่ 2)'),
                    );
                  }),
                ],
                onChanged: (val) => setState(() => selectedParentId = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                await pos.saveCategory(Category(
                  shopId: pos.shop?.id ?? 'default_shop',
                  name: name,
                  parentCategoryId: selectedParentId,
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, Category cat) {
    final pos = context.read<PosProvider>();
    final count = pos.products.where((p) => p.categoryId == cat.id).length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ยืนยันการลบ "${cat.name}"'),
        content: Text(
          count > 0
              ? 'โฟลเดอร์นี้มีสินค้าอยู่ $count ชิ้น หากลบโฟลเดอร์ สินค้าทั้งหมดจะถูกย้ายไปที่ "ไม่มีหมวดหมู่" โดยอัตโนมัติ (ไม่ลบสินค้าทิ้ง)'
              : 'คุณต้องการลบโฟลเดอร์ "${cat.name}" หรือไม่?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () async {
              await pos.deleteCategory(cat.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('ยืนยันลบ'),
          ),
        ],
      ),
    );
  }

  // --- Artist Management Dialog (Requirement 4.6) ---
  void _showArtistManagementDialog(BuildContext context) {
    final pos = context.read<PosProvider>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('จัดการศิลปิน & ค่าคอมมิชชัน'),
              IconButton(
                icon: const Icon(Icons.person_add, color: Color(0xFF2563EB)),
                tooltip: 'เพิ่มศิลปิน',
                onPressed: () => _showAddArtistDialog(dialogCtx),
              ),
            ],
          ),
          content: SizedBox(
            width: 450,
            height: 350,
            child: ListView.separated(
              itemCount: pos.artists.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final artist = pos.artists[index];
                final count = pos.products.where((p) => p.artistId == artist.id).length;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(artist.name.isNotEmpty ? artist.name[0] : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                  ),
                  title: Text(artist.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('หักคอมมิชชัน ${artist.commissionRate ?? 0}% • สินค้า $count ชิ้น'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => _showEditArtistRateDialog(dialogCtx, artist),
                      ),
                      if (pos.artists.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                          onPressed: () => pos.deleteArtist(artist.id),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ปิด')),
          ],
        ),
      ),
    );
  }

  void _showAddArtistDialog(BuildContext parentContext) {
    final pos = parentContext.read<PosProvider>();
    final nameCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: '10');

    showDialog(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        title: const Text('เพิ่มศิลปินใหม่'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ชื่อศิลปิน / สตูดิโอ *')),
            const SizedBox(height: 10),
            TextField(
              controller: rateCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'อัตราค่าคอมมิชชัน (%)', suffixText: '%'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final rate = double.tryParse(rateCtrl.text) ?? 0.0;
              if (name.isEmpty) return;
              await pos.saveArtist(Artist(
                shopId: pos.shop?.id ?? 'default_shop',
                name: name,
                commissionRate: rate,
              ));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );
  }

  void _showEditArtistRateDialog(BuildContext parentContext, Artist artist) {
    final pos = parentContext.read<PosProvider>();
    final rateCtrl = TextEditingController(text: (artist.commissionRate ?? 0).toStringAsFixed(0));

    showDialog(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        title: Text('ตั้งค่าคอมมิชชัน: ${artist.name}'),
        content: TextField(
          controller: rateCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'อัตราค่าคอมมิชชัน (%)', suffixText: '%'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              final rate = double.tryParse(rateCtrl.text) ?? 0.0;
              await pos.saveArtist(artist.copyWith(commissionRate: rate));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  // --- Event & Attending Artists Dialog (Requirement 4.11) ---
  void _showEventSelectorDialog(BuildContext context) {
    final pos = context.read<PosProvider>();
    final events = pos.events;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('เลือกอีเวนต์ที่กำลังจัด'),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2563EB)),
                tooltip: 'สร้างอีเวนต์ใหม่',
                onPressed: () => _showAddEventDialog(ctx),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: ListView(
              shrinkWrap: true,
              children: [
                // "No active event" option (Shows all products!)
                ListTile(
                  leading: const Icon(Icons.all_inclusive, color: Color(0xFF64748B)),
                  title: const Text('ไม่ใช้งานอีเวนต์ (แสดงสินค้าทั้งหมด)'),
                  trailing: pos.activeEvent == null ? const Icon(Icons.check_circle, color: Color(0xFF16A34A)) : null,
                  onTap: () {
                    for (var e in pos.events) {
                      pos.saveEvent(e.copyWith(isActive: false), pos.activeEventArtistIds);
                    }
                    pos.refreshData();
                    Navigator.pop(ctx);
                  },
                ),
                const Divider(height: 1),
                for (var ev in events) ...[
                  ListTile(
                    leading: const Icon(Icons.festival_outlined, color: Color(0xFFD97706)),
                    title: Text(ev.name, style: TextStyle(fontWeight: ev.isActive ? FontWeight.bold : FontWeight.normal)),
                    trailing: ev.isActive ? const Icon(Icons.check_circle, color: Color(0xFF2563EB)) : null,
                    onTap: () {
                      pos.setActiveEvent(ev.id);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ปิด')),
          ],
        );
      },
    );
  }

  void _showAddEventDialog(BuildContext parentContext) {
    final pos = parentContext.read<PosProvider>();
    final nameCtrl = TextEditingController();
    final attendingArtistIds = <String>{...pos.artists.map((a) => a.id)}; // default all attend

    showDialog(
      context: parentContext,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setState) => AlertDialog(
          title: const Text('สร้างอีเวนต์ใหม่'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'ชื่องานอีเวนต์ *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ศิลปินที่เข้าร่วมงานนี้ (สินค้าของศิลปินที่ไม่ได้ติ๊กจะถูกซ่อนจากหน้าขาย):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                for (var artist in pos.artists)
                  CheckboxListTile(
                    dense: true,
                    title: Text(artist.name),
                    value: attendingArtistIds.contains(artist.id),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          attendingArtistIds.add(artist.id);
                        } else {
                          attendingArtistIds.remove(artist.id);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                final newEvent = Event(
                  shopId: pos.shop?.id ?? 'default_shop',
                  name: name,
                  startDate: DateTime.now(),
                  endDate: DateTime.now().add(const Duration(days: 2)),
                  isActive: true,
                );
                await pos.saveEvent(newEvent, attendingArtistIds.toList());
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('สร้างอีเวนต์'),
            ),
          ],
        ),
      ),
    );
  }

  /// Critical Requirement 4.7: Block logout if unsynced items exist!
  void _handleLogoutAttempt(BuildContext context) {
    final pos = context.read<PosProvider>();

    if (!pos.canLogout()) {
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
                SizedBox(width: 8),
                Text('ไม่สามารถออกจากระบบได้', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Text(
              'ตรวจพบรายการขาย ${pos.unsyncedCount} รายการที่ยังไม่ได้ซิงก์ขึ้นคลาวด์!\n\n'
              'เพื่อป้องกันข้อมูลสูญหาย กรุณากดปุ่ม "ซิงก์ขึ้นคลาวด์เดี๋ยวนี้" ให้เสร็จสิ้นก่อนออกจากระบบ',
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('เข้าใจแล้ว')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  pos.syncNow();
                },
                icon: const Icon(Icons.sync, size: 16),
                label: const Text('ซิงก์เดี๋ยวนี้'),
              ),
            ],
          );
        },
      );
      return;
    }

    // If safe, allow logout
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('ยืนยันออกจากระบบ?'),
          content: const Text('ข้อมูลทั้งหมดซิงก์ปลอดภัยแล้ว คุณสามารถออกจากระบบได้'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ออกจากระบบเรียบร้อย')),
                );
              },
              child: const Text('ออกจากระบบ'),
            ),
          ],
        );
      },
    );
  }

  void _showSwitchShopDialog(BuildContext context, PosProvider pos) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.swap_horiz, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text('สลับร้านค้า (Switch Shop)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: pos.allShops.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('ยังไม่มีร้านค้าในระบบ คุณสามารถสร้างร้านค้าใหม่ได้จากหน้าการตั้งค่านี้',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: pos.allShops.map((s) {
                    final isCurrent = s.id == pos.currentShopId;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isCurrent ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrent ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                          width: isCurrent ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          isCurrent ? Icons.check_circle : Icons.storefront_outlined,
                          color: isCurrent ? const Color(0xFF2563EB) : Colors.grey,
                        ),
                        title: Text(s.name, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                        subtitle: Text('ID: ${s.id}'),
                        onTap: () {
                          Navigator.pop(ctx);
                          pos.switchShop(s.id);
                        },
                      ),
                    );
                  }).toList(),
                ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ปิด')),
          ],
        );
      },
    );
  }

  void _showConfirmClearAllDialog(BuildContext context, PosProvider pos) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
              SizedBox(width: 8),
              Text('ยืนยันล้างข้อมูลทั้งหมด?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: const Text(
            'การดำเนินการนี้จะล้างข้อมูลร้านค้า, สินค้า, ประวัติการขาย และข้อมูลจำลองทั้งหมด\n'
            'เพื่อให้ระบบกลับสู่สถานะหน้าว่างเปล่า (Blank Slate 100%) พร้อมสำหรับการเปิดใช้งานจริง\n\n'
            'คุณต้องการดำเนินการต่อหรือไม่?',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await pos.clearAllData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ล้างข้อมูลเรียบร้อยแล้ว ระบบอยู่ในสถานะหน้าว่าง 100%')),
                  );
                }
              },
              child: const Text('ล้างข้อมูลให้เป็นหน้าว่าง'),
            ),
          ],
        );
      },
    );
  }
}
