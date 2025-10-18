import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class Case1Screen extends StatefulWidget {
  const Case1Screen({super.key});

  @override
  _Case1ScreenState createState() => _Case1ScreenState();
}

class _Case1ScreenState extends State<Case1Screen> {
  double? fck;
  double? pWheel;
  final List<double> thicknesses = [16, 20, 24, 28, 32];
  final List<double> ks = [6, 9, 12, 15];
  Map<String, List<double>> stressData = {};
  final double tyrePressureMpa = 0.8;
  final double mu = 0.15;
  final double conversionFactor = 10.197162;

  void calculateStresses() {
    if (fck == null || pWheel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both grade and wheel load')),
      );
      return;
    }

    double eMpa = 5000 * math.sqrt(fck!);
    double e = eMpa * conversionFactor;
    double tyreP = tyrePressureMpa * conversionFactor;
    double a = math.sqrt(pWheel! / (math.pi * tyreP));

    stressData.clear();

    for (double k in ks) {
      List<double> stresses = [];
      for (double h in thicknesses) {
        num l = math.pow(
          (e * math.pow(h, 3)) / (12 * (1 - math.pow(mu, 2)) * k),
          0.25,
        );
        double logLa = math.log(l / a) / math.log(10);
        double al = a / l;
        double bracket = 4 * logLa + 0.666 * al - 0.034;
        double sigmaE = 0.803 * pWheel! / math.pow(h, 2) * bracket;
        stresses.add(sigmaE);
      }
      stressData[k.toString()] = stresses;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Case 1 (>0-50 MSA)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<double>(
                      decoration: InputDecoration(
                        labelText: 'Select Grade of Concrete (fck)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: fck,
                      items: [20.0, 25.0, 30.0, 35.0, 40.0]
                          .map((val) => DropdownMenuItem(value: val, child: Text(val.toString())))
                          .toList(),
                      onChanged: (val) => setState(() => fck = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<double>(
                      decoration: InputDecoration(
                        labelText: 'Select Wheel Load (P) kg',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: pWheel,
                      items: [5000.0, 7000.0, 11000.0, 13000.0]
                          .map((val) => DropdownMenuItem(value: val, child: Text(val.toString())))
                          .toList(),
                      onChanged: (val) => setState(() => pWheel = val),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: calculateStresses,
                      child: const Text('Calculate'),
                    ),
                  ],
                ),
              ),
            ),
            if (stressData.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text(
                'Edge Stress vs Thickness',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
 
              // Legend for k values
              
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                color: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: InteractiveViewer(
                      panEnabled: true,
                      scaleEnabled: true,
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 1.5,
                        height: 400,
                        child: LineChart(
                          LineChartData(
                            backgroundColor: Colors.black,
                            gridData: FlGridData(
                              show: true,
                              drawHorizontalLine: true,
                              drawVerticalLine: true,
                              horizontalInterval: 10,
                              verticalInterval: 1,
                              getDrawingHorizontalLine: (value) => const FlLine(color: Colors.white30, strokeWidth: 1),
                              getDrawingVerticalLine: (value) => const FlLine(color: Colors.white30, strokeWidth: 1),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= 0 && value.toInt() < thicknesses.length) {
                                      return Text(
                                        thicknesses[value.toInt()].toString(),
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  interval: 10,
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) => Text(
                                    value.toStringAsFixed(0),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            minX: 0,
                            maxX: thicknesses.length - 1,
                            minY: 0,
                            maxY: 80,
                            lineBarsData: ks.asMap().entries.map((entry) {
                              int index = entry.key;
                              double k = entry.value;
                              List<Color> colors = [Colors.red, Colors.green, Colors.blue, Colors.orange];
                              return LineChartBarData(
                                spots: stressData[k.toString()]!
                                    .asMap()
                                    .entries
                                    .map((e) => FlSpot(e.key.toDouble(), e.value))
                                    .toList(),
                                isCurved: false,
                                color: colors[index],
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(show: false),
                              );
                            }).toList(),
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (spot) => Colors.blueGrey.withOpacity(0.8),
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    return LineTooltipItem(
                                      '${spot.y.toStringAsFixed(2)} kg/cm²',
                                      const TextStyle(color: Colors.white),
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
                children: ks.asMap().entries.map((entry) {
                  int index = entry.key;
                  double k = entry.value;
                  List<Color> colors = [Colors.red, Colors.green, Colors.blue, Colors.orange];
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colors[index],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'k = ${k.toStringAsFixed(0)} kg/cm³',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              const Text(
                'Stress Table (kg/cm²)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Center(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      border: TableBorder.all(color: Colors.grey, width: 1),
                      columnSpacing: 24,
                      dataTextStyle: const TextStyle(fontSize: 14),
                      headingTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      headingRowColor: MaterialStateColor.resolveWith((states) => Colors.blueGrey),
                      dataRowColor: MaterialStateColor.resolveWith((states) => states.contains(MaterialState.selected) ? Colors.grey[300]! : Colors.white),
                      columns: [
                        DataColumn(
                          label: const Text('Thick\n(cm)'),
                          tooltip: 'Thickness (cm)',
                        ),
                        ...ks.map((k) => DataColumn(
                              label: Text('k=${k.toStringAsFixed(0)}'),
                              tooltip: 'k=${k.toStringAsFixed(0)} kg/cm³',
                            )),
                      ],
                      rows: thicknesses.asMap().entries.map((entry) {
                        int idx = entry.key;
                        double th = entry.value;
                        return DataRow(
                          color: MaterialStateColor.resolveWith((states) => idx % 2 == 0 ? Colors.grey[100]! : Colors.white),
                          cells: [
                            DataCell(Text(th.toStringAsFixed(0))),
                            ...ks.map((k) => DataCell(
                                  Text(stressData[k.toString()]![idx].toStringAsFixed(2)),
                                )),
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
}