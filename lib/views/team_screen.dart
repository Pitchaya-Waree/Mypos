import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/pos_provider.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final isOwner = pos.isOwner;
    final currentMember = pos.currentMember;
    final members = pos.members;
    final invites = pos.invites;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('ทีมงาน & บทบาท (Team & Roles)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              onPressed: () => _showInviteDialog(context),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('เชิญทีมงาน'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current User Profile & Role Test Switcher
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isOwner ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                          child: Icon(
                            isOwner ? Icons.admin_panel_settings : Icons.person,
                            color: isOwner ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentMember != null ? 'ผู้ใช้ปัจจุบัน (${currentMember.userId})' : 'เจ้าของร้าน',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isOwner ? const Color(0xFFDBEAFE) : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isOwner ? '👑 เจ้าของร้าน (Owner)' : '👤 สมาชิกทีมงาน (Member)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isOwner ? const Color(0xFF1D4ED8) : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Test Role Toggle Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFF93C5FD)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => pos.toggleRoleForTesting(),
                      icon: const Icon(Icons.swap_horiz, size: 16),
                      label: const Text('สลับบทบาททดสอบ', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isOwner ? const Color(0xFFF0FDF4) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isOwner ? Icons.check_circle_outline : Icons.visibility_off_outlined,
                        size: 16,
                        color: isOwner ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isOwner
                              ? 'สิทธิ์ Owner: มองเห็นราคาทุนสินค้าทุกชิ้น, จัดการทีมงาน, ปรับแต่งร้านค้าได้สมบูรณ์'
                              : 'สิทธิ์ Member: ซ่อนราคาทุนสินค้าผู้อื่น (-), ขายของและดูรายงานรวมได้, ป้องกันการแก้ไขร้าน',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOwner ? const Color(0xFF15803D) : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section Header: Active Members
          _buildSectionHeader('สมาชิกในบูธ (${members.length} คน)'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: members.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('ยังไม่มีสมาชิกในร้าน', style: TextStyle(color: Color(0xFF94A3B8))),
                    ),
                  )
                : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final m = members[index];
                final isSelf = m.id == currentMember?.id;
                final artistName = m.invitedArtistId != null ? pos.getArtistName(m.invitedArtistId!) : null;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: m.role == MemberRole.owner ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9),
                    child: Text(
                      m.userId.isNotEmpty ? m.userId[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: m.role == MemberRole.owner ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(m.userId, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (isSelf)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('คุณ', style: TextStyle(fontSize: 10, color: Color(0xFF15803D))),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    '${m.role == MemberRole.owner ? "เจ้าของร้าน" : "ทีมงาน"}${artistName != null ? " • ผูกกับ $artistName" : ""} • เข้าร่วม: ${DateFormat("dd/MM/yyyy").format(m.joinedAt)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  trailing: (isOwner && !isSelf && m.role != MemberRole.owner)
                      ? IconButton(
                          icon: const Icon(Icons.person_remove_outlined, color: Color(0xFFEF4444)),
                          tooltip: 'นำออกจากทีม',
                          onPressed: () => _confirmRemoveMember(context, m),
                        )
                      : null,
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Section Header: Pending Invites
          _buildSectionHeader('คำเชิญที่รอเข้าร่วม (${invites.length} รายการ)'),
          if (invites.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text('ไม่มีคำเชิญที่ค้างอยู่', style: TextStyle(color: Color(0xFF94A3B8))),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: invites.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final inv = invites[index];
                  final isExpired = DateTime.now().isAfter(inv.expiresAt);
                  final artistName = inv.artistId != null ? pos.getArtistName(inv.artistId!) : null;

                  return ListTile(
                    leading: Icon(
                      isExpired ? Icons.timer_off_outlined : Icons.mail_outline,
                      color: isExpired ? const Color(0xFF94A3B8) : const Color(0xFF2563EB),
                    ),
                    title: Text(inv.email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${artistName != null ? "ผูกกับ: $artistName • " : ""}${isExpired ? "หมดอายุแล้ว" : "หมดอายุใน ${inv.expiresAt.difference(DateTime.now()).inDays} วัน"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isExpired ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Token: ${inv.token}',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          tooltip: 'คัดลอกลิงก์คำเชิญ',
                          onPressed: () {
                            final link = 'https://makergo-pos.app/join?token=${inv.token}';
                            Clipboard.setData(ClipboardData(text: link));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('คัดลอกลิงก์คำเชิญเรียบร้อยแล้ว')),
                            );
                          },
                        ),
                        if (isOwner)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                            tooltip: 'ยกเลิกคำเชิญ',
                            onPressed: () => pos.revokeInvite(inv.id),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    final emailController = TextEditingController();
    final pos = context.read<PosProvider>();
    String? selectedArtistId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setState) => AlertDialog(
          title: const Text('เชิญทีมงานใหม่'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ระบบจะสร้างลิงก์เชิญที่มีอายุ 7 วัน สามารถส่งให้ทีมงานเปิดผ่านเบราว์เซอร์เพื่อเข้าช่วยขายได้ทันที',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'อีเมล Gmail ของทีมงาน',
                  hintText: 'staff@gmail.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: selectedArtistId,
                decoration: const InputDecoration(
                  labelText: 'ผูกกับศิลปิน (ไม่บังคับ)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.palette_outlined),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('ไม่ผูก (ซ่อนราคาทุนทุกชิ้น)')),
                  ...pos.artists.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
                ],
                onChanged: (val) => setState(() => selectedArtistId = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) return;

                final invite = await pos.createInvite(email, artistId: selectedArtistId);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  _showInviteCreatedSuccessDialog(context, invite);
                }
              },
              child: const Text('สร้างคำเชิญ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteCreatedSuccessDialog(BuildContext context, Invite invite) {
    final link = 'https://makergo-pos.app/join?token=${invite.token}';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF16A34A)),
            SizedBox(width: 8),
            Text('สร้างคำเชิญสำเร็จ'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ส่งลิงก์ด้านล่างนี้ให้ ${invite.email}:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                link,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB)),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• ลิงก์มีอายุ 7 วัน\n• ใช้ล็อกอินได้ 1 ครั้ง\n• เข้าได้เฉพาะบัญชี Gmail ที่ตรงกับคำเชิญ',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('คัดลอกลิงก์เรียบร้อยแล้ว')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('คัดลอกลิงก์'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('เสร็จสิ้น'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(BuildContext context, Member member) {
    final pos = context.read<PosProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการนำออกจากทีม'),
        content: Text('คุณต้องการนำ ${member.userId} ออกจากทีมหรือไม่? สมาชิกคนนี้จะไม่สามารถเข้าถึงร้านค้าได้อีกต่อไป'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () async {
              await pos.removeMember(member.id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('นำ ${member.userId} ออกเรียบร้อยแล้ว')),
                );
              }
            },
            child: const Text('นำออก'),
          ),
        ],
      ),
    );
  }
}
