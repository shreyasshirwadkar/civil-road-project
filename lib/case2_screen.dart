// case2_screen.dart
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class Case2Screen extends StatefulWidget {
  const Case2Screen({super.key});

  @override
  State<Case2Screen> createState() => _Case2ScreenState();
}

class _Case2ScreenState extends State<Case2Screen> {
  // ---------- USER INPUT ----------
  double? fck; // MPa
  double? pWheel; // kg
  String? region; // ΔT region

  // ---------- CONSTANTS ----------
  static const double tyrePressureMpa = 0.8;          // MPa
  static const double mu = 0.15;                     // Poisson's ratio
  static const double conversionFactor = 10.1972;     // kg/cm² ↔ MPa
  static const double alpha = 0.000012;              // Thermal expansion coefficient
 //static const double t = 3.0; // Temperature factor
 double get t {
    if (region == null) return 3.0;               // default
    switch (region!) {
      case 'Maharashtra':                     return 3.0;
      case 'Coastal area bounded by hills':   return 1.6;
      case 'Coastal area unbounded by hills': return 3.5;
      default:                                return 3.0;
    }
  }


 // ΔT per region
  static const Map<String, double> deltaT = {
    'Maharashtra': 17.3,
    'Coastal area bounded by hills': 14.6,
    'Coastal area unbounded by hills': 15.5,
  };

  // ---------- FIXED DESIGN MATRIX ----------
  final List<double> thicknesses = [16, 20, 24, 28, 32]; // cm
  final List<double> ks = [6, 9, 12, 15]; // kg/cm³

  // C-table (rows = k, columns = thickness)
  static const List<List<double>> cTable = [
    [0.92, 0.72, 0.552, 0.414, 0.308],  // k=6
    [0.986, 0.8, 0.692, 0.552, 0.414],  // k=9
    [1.035, 0.92, 0.8, 0.636, 0.496],   // k=12
    [1.054, 0.986, 0.92, 0.82, 0.58],   // k=15
  ];

  // ---------- CALCULATION RESULTS ----------
  double? eKgCm2;
  double? aCm;
  Map<String, List<double>> loadStressMap = {}; // σₑ for each (h,k)
  Map<String, List<double>> tempStressMap = {}; // σₜ for each (h,k)

  // ---------- INTERPOLATE C ----------
  double _interpolateC(double k, double h) {
    int lower = 0;
    for (int i = 0; i < ks.length - 1; i++) {
      if (k >= ks[i] && k < ks[i + 1]) {
        lower = i;
        break;
      }
    }
    int upper = (lower + 1).clamp(0, ks.length - 1);

    int col = thicknesses.indexOf(h);
    if (col != -1) {
      double cLow = cTable[lower][col];
      double cUp = cTable[upper][col];
      return cLow + (cUp - cLow) * (k - ks[lower]) / (ks[upper] - ks[lower]);
    }

    for (int i = 0; i < thicknesses.length - 1; i++) {
      if (h >= thicknesses[i] && h < thicknesses[i + 1]) {
        double t1 = thicknesses[i], t2 = thicknesses[i + 1];
        double cLow1 = cTable[lower][i], cLow2 = cTable[lower][i + 1];
        double cUp1 = cTable[upper][i], cUp2 = cTable[upper][i + 1];
        double cLow = cLow1 + (cLow2 - cLow1) * (h - t1) / (t2 - t1);
        double cUp = cUp1 + (cUp2 - cUp1) * (h - t1) / (t2 - t1);
        return cLow + (cUp - cLow) * (k - ks[lower]) / (ks[upper] - ks[lower]);
      }
    }
    return 0.0;
  }

  // ---------- MAIN CALCULATION ----------
  void _calculate() {
    if (fck == null || pWheel == null || region == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select grade, wheel load and region')),
      );
      return;
    }

    // 1. E = 5000 √fck  (MPa) → kg/cm²
    double eMpa = 5000 * math.sqrt(fck!);
    eKgCm2 = eMpa * conversionFactor;

    // 2. a = √(P/(π·p))
    double tyreP = tyrePressureMpa * conversionFactor;
    aCm = math.sqrt(pWheel! / (math.pi * tyreP));

    // 3. Build stress matrices
    loadStressMap.clear();
    tempStressMap.clear();

    for (double k in ks) {
      List<double> loadStresses = [];
      List<double> tempStresses = [];

      for (double h in thicknesses) {
        // --- Load Stress σₑ ---
        double numerator = eKgCm2! * math.pow(h, 3);
        double denominator = 12 * (1 - math.pow(mu, 2)) * k;
        num l = math.pow(numerator / denominator, 0.25);

        double logLa = math.log(l / aCm!) / math.log(10);
        double bracket = 4 * logLa + 0.666 * (aCm! / l) - 0.034;
        double sigmaE = 0.803 * pWheel! / math.pow(h, 2) * bracket;
        loadStresses.add(sigmaE);

        // --- Temperature Stress σₜₑ = (E × α × t × C) / 2 ---
        double C = _interpolateC(k, h);
        double sigmaT = (eKgCm2! * alpha * this.t * C) / 2;
        tempStresses.add(sigmaT);
      }

      loadStressMap[k.toString()] = loadStresses;
      tempStressMap[k.toString()] = tempStresses;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Case 2 (>50-150 MSA)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------- USER INPUT ----------
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDropdown<double>(
                      label: 'Grade of Concrete (fck) – MPa',
                      value: fck,
                      items: [20.0, 25.0, 30.0, 35.0, 40.0],
                      onChanged: (v) => setState(() => fck = v),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown<double>(
                      label: 'Wheel Load (P) – kg',
                      value: pWheel,
                      items: [5000.0, 7000.0, 9000.0, 11000.0, 13000.0],
                      onChanged: (v) => setState(() => pWheel = v),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown<String>(
                      label: 'Region (ΔT)',
                      value: region,
                      items: deltaT.keys.toList(),
                      onChanged: (v) => setState(() => region = v),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(onPressed: _calculate, child: const Text('Calculate')),
                  ],
                ),
              ),
            ),

            // ---------- RESULTS ----------
            if (loadStressMap.isNotEmpty) ...[
              // const SizedBox(height: 32),
              // _ResultCard(
              //   title: 'Design Parameters',
              //   children: [
              //     _ResultRow('E (kg/cm²)', eKgCm2!.toStringAsFixed(2)),
              //     _ResultRow('a (cm)', aCm!.toStringAsFixed(2)),
              //     _ResultRow('α (thermal coeff.)', alpha.toString()),
              //     _ResultRow('t (factor)', t.toString()),
              //   ],
              // ),

            
              const SizedBox(height: 32),
              const Text(
                'Total Edge Stress = σₑ + σₜₑ  (all k values)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: SizedBox(
                    height: 380,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 700,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawHorizontalLine: true,
                              drawVerticalLine: true,
                              horizontalInterval: 10,
                              verticalInterval: 5,
                              getDrawingHorizontalLine: (value) => FlLine(strokeWidth: 1),
                              getDrawingVerticalLine: (value) => FlLine( strokeWidth: 1),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 10,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, _) => Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 5,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, _) => Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all( width: 1),
                            ),
                            backgroundColor: Colors.white,
                            minX: 15,
                            maxX: 40,
                            minY: 0,
                            maxY: 100,
                            lineBarsData: ks.asMap().entries.map((e) {
                              int idx = e.key;
                              double k = e.value;
                              List<Color> colors = [Colors.red, Colors.green, Colors.blue, Colors.orange];
                              return LineChartBarData(
                                spots: loadStressMap[k.toString()]!.asMap().entries.map((p) {
                                  double sigmaE = p.value;
                                  double sigmaT = tempStressMap[k.toString()]![p.key];
                                  return FlSpot(thicknesses[p.key], sigmaE + sigmaT);
                                }).toList(),
                                isCurved: false,
                                color: colors[idx],
                                dotData: const FlDotData(show: true),
                                barWidth: 3,
                              );
                            }).toList(),
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                //tooltipBgColor: Colors.blueGrey.withOpacity(0.95),
                                tooltipRoundedRadius: 8,
                                tooltipPadding: const EdgeInsets.all(8),
                                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    final h = thicknesses[spot.spotIndex]; // X value
                                    final total = spot.y; // Y value
                                    return LineTooltipItem(
                                      'h = ${h}cm\n'
                                      'TOTAL = ${total.toStringAsFixed(2)} kg/cm²',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: ks.asMap().entries.map((e) {
                  int idx = e.key;
                  double k = e.value;
                  List<Color> colors = [Colors.red, Colors.green, Colors.blue, Colors.orange];
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(color: colors[idx], shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text('k = $k kg/cm³', style: const TextStyle(fontSize: 14)),
                    ],
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),
              const Text(
                'Total Edge Stress Table (σₑ + σₜₑ, kg/cm²)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Center(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 24,
                      headingRowColor: MaterialStateProperty.all(Colors.blueGrey),
                      columns: [
                        const DataColumn(label: Text('h (cm)', style: TextStyle(color: Colors.white))),
                        ...ks.map((k) => DataColumn(label: Text('k=$k', style: const TextStyle(color: Colors.white)))),
                      ],
                      rows: thicknesses.asMap().entries.map((row) {
                        int r = row.key;
                        double h = row.value;
                        return DataRow(
                          color: MaterialStateProperty.all(r.isEven ? Colors.grey[100] : Colors.white),
                          cells: [
                            DataCell(Text(h.toStringAsFixed(0))),
                            ...ks.map((k) {
                              final String key = k.toString();
                              final double sigmaE = loadStressMap[key]![r];
                              final double sigmaT = tempStressMap[key]![r];
                              final double total = sigmaE + sigmaT;
                              return DataCell(Text(total.toStringAsFixed(2)));
                            }),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------- HELPER WIDGETS ----------
  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      value: value,
      items: items
          .map((v) => DropdownMenuItem<T>(value: v, child: Text(v.toString())))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ---------- RESULT DISPLAY ----------
class _ResultCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _ResultCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _ResultRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}