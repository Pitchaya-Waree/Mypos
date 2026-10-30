import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/pos_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final todayRevenue = pos.todayRevenue;
    final todayCount = pos.todayOrdersCount;
    final totalRevenue = pos.totalRevenue;
    final topProducts = pos.topProductsSalesCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = topProducts.take(5).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('รายงานการขาย (Reports)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Excel/CSV',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ส่งออกรายงานยอดขายสำเร็จ (Excel/CSV Exported)'),
                  backgroundColor: Color(0xFF16A34A),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'ยอดขายวันนี้',
                    value: '฿${todayRevenue.toStringAsFixed(0)}',
                    subtext: '$todayCount บิลสำเร็จ',
                    color: const Color(0xFF2563EB),
                    icon: Icons.today,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'ยอดขายรวมทั้งงาน',
                    value: '฿${totalRevenue.toStringAsFixed(0)}',
                    subtext: '${pos.orders.where((o) => o.status == OrderStatus.completed).length} บิลทั้งหมด',
                    color: const Color(0xFF16A34A),
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Top 5 Bestsellers Section
            const Text(
              '🏆 5 อันดับสินค้าขายดี (Top 5 Bestsellers)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: top5.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('ยังไม่มีข้อมูลการขายสินค้า', style: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                    )
                  : Column(
                      children: top5.map((entry) {
                        final maxVal = top5.first.value > 0 ? top5.first.value : 1;
                        final ratio = (entry.value / maxVal).clamp(0.05, 1.0);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('${entry.value} ชิ้น',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 8,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  valueColor: const AlwaysStoppedAnimation(Color(0xFF3B82F6)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 20),

            // Payment Methods Breakdown
            const Text(
              '💳 สัดส่วนช่องทางชำระเงิน',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildPaymentMethodStat(
                      title: 'เงินสด (Cash)',
                      count: pos.orders.where((o) => o.status == OrderStatus.completed && o.paymentMethod == PaymentMethod.cash).length,
                      total: pos.orders.where((o) => o.status == OrderStatus.completed && o.paymentMethod == PaymentMethod.cash).fold(0.0, (s, o) => s + o.total),
                      icon: Icons.payments_outlined,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                  const VerticalDivider(width: 24, thickness: 1),
                  Expanded(
                    child: _buildPaymentMethodStat(
                      title: 'พร้อมเพย์ QR',
                      count: pos.orders.where((o) => o.status == OrderStatus.completed && o.paymentMethod == PaymentMethod.qr).length,
                      total: pos.orders.where((o) => o.status == OrderStatus.completed && o.paymentMethod == PaymentMethod.qr).fold(0.0, (s, o) => s + o.total),
                      icon: Icons.qr_code_2,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtext,
    required Color color,
    required IconData icon,
  }) {
    return Container(
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
              Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(subtext, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodStat({
    required String title,
    required int count,
    required double total,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        Text('฿${total.toStringAsFixed(0)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text('$count บิล', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }
}
