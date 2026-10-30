import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/pos_provider.dart';

class SettlementScreen extends StatefulWidget {
  const SettlementScreen({super.key});

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  String? _selectedEventId;

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final events = pos.events;
    final activeEvent = pos.activeEvent;

    // Default to active event or first event
    if (_selectedEventId == null && events.isNotEmpty) {
      _selectedEventId = activeEvent?.id ?? events.first.id;
    }

    final settlements = _selectedEventId != null
        ? pos.computeSettlementForEvent(_selectedEventId!)
        : <String, Settlement>{};

    final currencyFormat = NumberFormat('#,##0.00', 'th_TH');
    final unsynced = pos.unsyncedCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('สรุปยอด & ปิดก้นถุง (Settlement)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Settlement CSV',
            onPressed: settlements.isEmpty ? null : () => _exportCsv(context, settlements),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Event Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_outlined, color: Color(0xFF2563EB)),
                const SizedBox(width: 12),
                const Text('เลือกอีเวนต์:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedEventId,
                      hint: const Text('เลือกอีเวนต์'),
                      items: events.map((e) {
                        return DropdownMenuItem(
                          value: e.id,
                          child: Text(
                            '${e.name} ${e.isActive ? '(กำลังจัด)' : ''}',
                            style: TextStyle(
                              fontWeight: e.isActive ? FontWeight.bold : FontWeight.normal,
                              color: e.isActive ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedEventId = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Unsynced Orders Warning Banner (Acceptance Criteria 4.6)
          if (unsynced > 0)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'มีออเดอร์ค้างซิงก์ (Unsynced Orders)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                        ),
                        Text(
                          'มี $unsynced รายการขายที่บันทึกออฟไลน์ แนะนำให้กดซิงก์ขึ้นคลาวด์ก่อนปิด Settlement เพื่อความถูกต้องของยอดขาย',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: pos.isSyncing ? null : () => pos.syncNow(),
                    child: const Text('ซิงก์ทันที', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Settlement Summary Cards
          if (settlements.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Text('ไม่มีข้อมูลยอดขายในอีเวนต์นี้', style: TextStyle(color: Color(0xFF94A3B8))),
            )
          else
            ...settlements.entries.map((entry) {
              final artistId = entry.key;
              final settlement = entry.value;
              final artist = pos.artists.cast<Artist?>().firstWhere(
                    (a) => a?.id == artistId,
                    orElse: () => null,
                  );
              final artistName = artist?.name ?? 'ศิลปินไม่ระบุชื่อ';
              final rate = artist?.commissionRate ?? 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: settlement.paid ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                    width: settlement.paid ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Artist Header & Paid Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFFEFF6FF),
                                child: Text(
                                  artistName.isNotEmpty ? artistName[0] : '?',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    artistName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    'หักค่าคอมมิชชัน $rate%',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: settlement.paid ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: settlement.paid ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  settlement.paid ? Icons.check_circle : Icons.pending,
                                  size: 14,
                                  color: settlement.paid ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  settlement.paid ? 'จ่ายเงินแล้ว' : 'รอจ่ายเงิน',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: settlement.paid ? const Color(0xFF15803D) : const Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Metrics Breakdown
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              title: 'ยอดขายรวม (Gross)',
                              amount: '฿${currencyFormat.format(settlement.grossSales)}',
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Expanded(
                            child: _buildMetricTile(
                              title: 'หักค่าคอม ($rate%)',
                              amount: '-฿${currencyFormat.format(settlement.commissionAmount)}',
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                          Expanded(
                            child: _buildMetricTile(
                              title: 'ยอดสุทธิที่ต้องจ่าย (Net)',
                              amount: '฿${currencyFormat.format(settlement.netPayout)}',
                              color: const Color(0xFF2563EB),
                              isHighlight: true,
                            ),
                          ),
                        ],
                      ),

                      // Payment info if paid
                      if (settlement.paid) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'จ่ายเมื่อ: ${settlement.paidAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(settlement.paidAt!) : '-'}${settlement.note.isNotEmpty ? ' • โน้ต: ${settlement.note}' : ''}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Action Button
                      if (!settlement.paid)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.check, size: 18),
                            label: Text(
                              'บันทึกว่าจ่ายแล้ว (฿${currencyFormat.format(settlement.netPayout)})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => _showMarkPaidDialog(context, settlement, artistName),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String amount,
    required Color color,
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: isHighlight ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showMarkPaidDialog(BuildContext context, Settlement settlement, String artistName) {
    final noteController = TextEditingController();
    final pos = context.read<PosProvider>();
    final currencyFormat = NumberFormat('#,##0.00', 'th_TH');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('บันทึกการจ่ายเงิน: $artistName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ยอดสุทธิที่ต้องจ่าย: ฿${currencyFormat.format(settlement.netPayout)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF16A34A)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'บันทึกช่วยจำ (เช่น ช่องทางโอน, เวลาโอน, สลิป)',
                border: OutlineInputBorder(),
              ),
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
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await pos.markSettlementPaid(settlement, noteController.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('บันทึกการจ่ายเงินของ $artistName เรียบร้อยแล้ว')),
                );
              }
            },
            child: const Text('ยืนยันว่าจ่ายแล้ว'),
          ),
        ],
      ),
    );
  }

  void _exportCsv(BuildContext context, Map<String, Settlement> settlements) {
    final pos = context.read<PosProvider>();
    final buffer = StringBuffer();
    buffer.writeln('Artist Name,Gross Sales,Commission Rate (%),Commission Amount,Net Payout,Status,Paid At,Note');

    for (var entry in settlements.entries) {
      final settlement = entry.value;
      final artist = pos.artists.cast<Artist?>().firstWhere((a) => a?.id == entry.key, orElse: () => null);
      final name = artist?.name ?? 'Unknown';
      final rate = artist?.commissionRate ?? 0.0;
      final status = settlement.paid ? 'PAID' : 'PENDING';
      final paidAt = settlement.paidAt?.toIso8601String() ?? '';
      final note = settlement.note.replaceAll(',', ' ');

      buffer.writeln(
        '$name,${settlement.grossSales.toStringAsFixed(2)},$rate,${settlement.commissionAmount.toStringAsFixed(2)},${settlement.netPayout.toStringAsFixed(2)},$status,$paidAt,$note',
      );
    }

    final csvContent = buffer.toString();
    Clipboard.setData(ClipboardData(text: csvContent));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Settlement CSV'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('คัดลอกข้อมูล CSV ลงใน Clipboard แล้ว ท่านสามารถนำไปวางใน Excel หรือ Google Sheets ได้ทันที:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                csvContent,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }
}
