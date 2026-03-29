import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/ingreso.dart';
import '../../models/pago_semanal.dart';
import '../../providers/caja_ahorro_provider.dart';

class GraficosScreen extends StatelessWidget {
  const GraficosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final caja = context.watch<CajaAhorroProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gráficos',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text('Visualización financiera',
              style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),

          // ── Pagos por semana (últimas 6) ──────────────────────────────
          _ChartCard(
            title: 'Pagos por Semana',
            subtitle: 'Últimas 6 semanas',
            icon: Icons.bar_chart,
            child: _PagosPorSemanaChart(caja: caja),
          ),
          const SizedBox(height: 16),

          // ── Ingresos por mes ─────────────────────────────────────────
          _ChartCard(
            title: 'Ingresos por Mes',
            subtitle: 'Últimos 6 meses',
            icon: Icons.show_chart,
            child: _IngresosPorMesChart(caja: caja),
          ),
          const SizedBox(height: 16),

          // ── Estado de pagos semana actual ────────────────────────────
          _ChartCard(
            title: 'Estado Semana Actual',
            subtitle: 'Semana ${caja.semanaActual}',
            icon: Icons.pie_chart,
            child: _EstadoPagosPieChart(caja: caja),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _PagosPorSemanaChart extends StatelessWidget {
  final CajaAhorroProvider caja;
  const _PagosPorSemanaChart({required this.caja});

  @override
  Widget build(BuildContext context) {
    final semanaBase = caja.semanaActual;
    final anio = DateTime.now().year;
    final colorScheme = Theme.of(context).colorScheme;

    // Últimas 6 semanas
    final semanas = List.generate(6, (i) => semanaBase - 5 + i);
    final valores = semanas.map((s) {
      final pagos = caja.getPagosDeSemana(s, anio);
      return pagos.fold(0.0, (sum, p) => sum + p.montoPagado);
    }).toList();

    if (valores.every((v) => v == 0)) {
      return const _NoDataPlaceholder();
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: List.generate(6, (i) {
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: valores[i],
                color: colorScheme.primary,
                width: 20,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6)),
              ),
            ]);
          }),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('S${semanas[value.toInt()]}',
                      style: const TextStyle(fontSize: 10)),
                ),
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  getTitlesWidget: (value, meta) => Text(
                      '\$${value.toInt()}',
                      style: const TextStyle(fontSize: 9))),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: true),
        ),
      ),
    );
  }
}

class _IngresosPorMesChart extends StatelessWidget {
  final CajaAhorroProvider caja;
  const _IngresosPorMesChart({required this.caja});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final colorScheme = Theme.of(context).colorScheme;
    final meses = <String>[];
    final valores = <double>[];

    for (int i = 5; i >= 0; i--) {
      int mes = now.month - i;
      int anio = now.year;
      if (mes <= 0) {
        mes += 12;
        anio--;
      }
      meses.add(_mesAbrev(mes));
      final total = caja.ingresos
          .where((ing) =>
              ing.fecha.month == mes &&
              ing.fecha.year == anio &&
              ing.tipo != TipoIngreso.retiro)
          .fold(0.0, (s, ing) => s + ing.monto);
      valores.add(total);
    }

    if (valores.every((v) => v == 0)) {
      return const _NoDataPlaceholder();
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                  6, (i) => FlSpot(i.toDouble(), valores[i])),
              isCurved: true,
              color: colorScheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: colorScheme.primary.withAlpha(25),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= meses.length) {
                    return const Text('');
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(meses[idx],
                        style: const TextStyle(fontSize: 10)),
                  );
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 52,
                  getTitlesWidget: (value, meta) => Text(
                      '\$${value.toInt()}',
                      style: const TextStyle(fontSize: 9))),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: true),
        ),
      ),
    );
  }

  String _mesAbrev(int mes) {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return meses[mes - 1];
  }
}

class _EstadoPagosPieChart extends StatelessWidget {
  final CajaAhorroProvider caja;
  const _EstadoPagosPieChart({required this.caja});

  @override
  Widget build(BuildContext context) {
    final pagos = caja.getPagosDeSemana(
        caja.semanaActual, DateTime.now().year);

    if (pagos.isEmpty) {
      return const _NoDataPlaceholder();
    }

    final pagados = pagos.where((p) => p.estado == EstadoPago.pagado).length;
    final pendientes =
        pagos.where((p) => p.estado == EstadoPago.pendiente).length;
    final parciales =
        pagos.where((p) => p.estado == EstadoPago.parcial).length;

    final sections = <PieChartSectionData>[
      if (pagados > 0)
        PieChartSectionData(
          value: pagados.toDouble(),
          color: Colors.green,
          title: '$pagados\nPagados',
          radius: 80,
          titleStyle: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      if (pendientes > 0)
        PieChartSectionData(
          value: pendientes.toDouble(),
          color: Colors.orange,
          title: '$pendientes\nPendientes',
          radius: 80,
          titleStyle: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      if (parciales > 0)
        PieChartSectionData(
          value: parciales.toDouble(),
          color: Colors.blue,
          title: '$parciales\nParciales',
          radius: 80,
          titleStyle: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
    ];

    return SizedBox(
      height: 220,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 3,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pagados > 0)
                _Leyenda(color: Colors.green, label: 'Pagados: $pagados'),
              if (pendientes > 0)
                _Leyenda(
                    color: Colors.orange, label: 'Pendientes: $pendientes'),
              if (parciales > 0)
                _Leyenda(color: Colors.blue, label: 'Parciales: $parciales'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  final Color color;
  final String label;
  const _Leyenda({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
              width: 12, height: 12, color: color,
              margin: const EdgeInsets.only(right: 8)),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _NoDataPlaceholder extends StatelessWidget {
  const _NoDataPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            const Text('Sin datos disponibles',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
