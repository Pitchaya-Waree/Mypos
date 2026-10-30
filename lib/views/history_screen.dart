import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/pos_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final orders = pos.orders;
    final dateFormat = DateFormat('dd MMM, HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('ประวัติการขาย (Orders)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: orders.isEmpty
          ? const Center(
              child: Text('ยังไม่มีรายการขาย', style: TextStyle(color: Color(0xFF94A3B8))),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final order = orders[index];
                final isVoided = order.status == OrderStatus.voided;

                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 1,
                  shadowColor: Colors.black.withValues(alpha: 0.04),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showOrderDetailSheet(context, order),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          // Status Icon Badge
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isVoided ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isVoided ? Icons.cancel_outlined : Icons.check_circle_outline,
                              color: isVoided ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Order Meta
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '#${order.id.substring(0, 8).toUpperCase()}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        decoration: isVoided ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        order.paymentMethod == PaymentMethod.cash ? 'เงินสด' : 'PromptPay QR',
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${order.items.length} รายการ • ${dateFormat.format(order.createdAt)}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          // Total & Status
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '฿${order.total.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isVoided ? const Color(0xFF94A3B8) : const Color(0xFF2563EB),
                                  decoration: isVoided ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              Text(
                                isVoided ? 'ยกเลิกแล้ว (Void)' : 'สำเร็จ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isVoided ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
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
            ),
    );
  }

  void _showOrderDetailSheet(BuildContext context, Order order) {
    final isVoided = order.status == OrderStatus.voided;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('บิล #${order.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(isVoided ? 'ยกเลิกแล้ว' : 'ชำระเรียบร้อย',
                        style: TextStyle(
                            color: isVoided ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                // Items
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item.nameSnapshot} × ${item.qty}'),
                        Text('฿${item.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ยอดรวมทั้งสิ้น', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('฿${order.total.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                  ],
                ),
                const SizedBox(height: 16),
                // Void Order Button
                if (!isVoided)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFDC2626)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmVoidOrder(context, order);
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                      label: const Text('Void รายการขายนี้ (คืนสต็อกอัตโนมัติ)'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmVoidOrder(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('ยืนยันการ Void บิล?'),
          content: const Text(
            'การ Void จะคืนสินค้าทั้งหมดในบิลกลับเข้าสู่คลังสต็อกโดยอัตโนมัติผ่าน StockMovement\n\nการกระทำนี้ไม่สามารถย้อนกลับได้',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
              onPressed: () {
                final pos = context.read<PosProvider>();
                pos.voidOrder(order.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Void บิลเรียบร้อย และคืนสต็อกสำเร็จ!')),
                );
              },
              child: const Text('ยืนยัน Void'),
            ),
          ],
        );
      },
    );
  }
}
