import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'FireData.dart';

void main() {
  runApp(const MyApp());
}

String formatEuro(double amount) {
  // Erstellen eines NumberFormat-Objekts, das Zahlen im deutschen Euro-Format formatiert
  final NumberFormat format =
      NumberFormat.currency(locale: 'de_DE', symbol: '€');

  // Verwenden des Formatierers, um den double als String darzustellen
  return format.format(amount);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fire Calc',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Calc all fire Relevant Stuff'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late FireResult fireResult;
  final TextEditingController _initialAmountController =
      TextEditingController(text: "25000");
  final TextEditingController _interestRateController =
      TextEditingController(text: "12");
  final TextEditingController _monthlyContributionController =
      TextEditingController(text: "2000");
  final TextEditingController _targetMonthlyInterestController =
      TextEditingController(text: "2000");
  final TextEditingController _annualInflationRateController =
      TextEditingController(text: "4");

  var titlesData = FlTitlesData(
      bottomTitles: AxisTitles(
          sideTitles: SideTitles(
              reservedSize: 30,
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    (value ~/ 12).toString() + ", " + (value % 12).toString(),
                  ),
                );
              })),
      rightTitles: AxisTitles(drawBelowEverything: false),
      topTitles: AxisTitles(drawBelowEverything: false));
  var lineTouchData = LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
        return touchedSpots.map((LineBarSpot touchedSpot) {
          final textStyle = TextStyle(
            color: touchedSpot.bar.gradient?.colors.first ??
                touchedSpot.bar.color ??
                Colors.blueGrey,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          );
          return LineTooltipItem(
              formatEuro(touchedSpot.y) +
                  " ${(touchedSpot.x ~/ 12).toString()} Jahre ${(touchedSpot.x % 12).toString()} Monate",
              textStyle);
        }).toList();
      }));

  FireResult findAll(
      double initialAmount,
      double annualInterestRate,
      double targetMonthlyInterest,
      double annualInflationRate,
      double monthlyContribution) {
    double balance = initialAmount;
    double monthlyRate = annualInterestRate / 12;
    int month = 0;
    double interest = 0;
    double adjustedMonthlyInterest = targetMonthlyInterest;
    double totalContributions = initialAmount;
    double totalInterest = 0.0;

    String breakEvenPoint = "Nie";
    String interestSurpassPoint = "Nie";

    List<MonthData> mothEstimates = [];

    while (true) {
      month++;
      interest = balance * monthlyRate;
      totalInterest += interest;
      balance += interest + monthlyContribution;
      totalContributions += monthlyContribution;

      MonthData monthData = MonthData(month, adjustedMonthlyInterest, balance,
          interest, totalInterest, totalContributions);
      mothEstimates.add(monthData);
      // Jedes Jahr die Zielzinsen anpassen
      if (month % 12 == 0) {
        adjustedMonthlyInterest *= (1 + annualInflationRate / 100);
        // print(
        //     "Neue Zielmonatszinsen nach Inflationsanpassung für Jahr ${monthData.jahre()}: €${adjustedMonthlyInterest.toStringAsFixed(2)}");
      }

      // print(
      //     "${monthData.jahre()} Jahre und ${monthData.monate()} Monate: Zinsen = €${interest.toStringAsFixed(2)}, Gesamtsaldo = €${balance.toStringAsFixed(2)}");

      if (totalInterest > totalContributions) {
        breakEvenPoint =
            "${monthData.jahre()} Jahre und ${monthData.monate()} Monate";
        // print(
        //     "Nach $breakEvenPoint übersteigen die kumulierten Zinsen die Gesamteinlagen.");
        break;
      }

      if (interest >= adjustedMonthlyInterest) {
        interestSurpassPoint =
            "${monthData.jahre()} Jahre und ${monthData.monate()} Monate";
        // print(
        //     "Es dauert $interestSurpassPoint, um eine inflationsangepasste monatliche Zinseinnahme von mindestens €${adjustedMonthlyInterest.toStringAsFixed(2)} zu erreichen.");
        // break;
      }
    }
    return FireResult(breakEvenPoint, interestSurpassPoint, totalContributions,
        totalContributions, balance, mothEstimates);
  }

  void _action() {
    setState(() {
      this.fireResult = findAll(
          initialAmount(),
          interestRate(),
          targetMonthlyInterest(),
          annualInflationRate(),
          monthlyContribution());
    });
  }

  double annualInflationRate() =>
      double.parse(_annualInflationRateController.text) / 100;

  double targetMonthlyInterest() =>
      double.parse(_targetMonthlyInterestController.text);

  double monthlyContribution() =>
      double.parse(_monthlyContributionController.text);

  double interestRate() => double.parse(_interestRateController.text) / 100;

  double initialAmount() => double.parse(_initialAmountController.text);

  @override
  void initState() {
    super.initState();
    _action();
  }

  @override
  Widget build(BuildContext context) {
    var interestLine = LineChartBarData(
        color: Colors.green,
        isStrokeCapRound: true,
        spots: fireResult.mothEstimates
            .map((e) => FlSpot(e.month.toDouble(), e.interest))
            .toList());
    var gesamtsaldoLine = LineChartBarData(
        color: Colors.blue,
        isStrokeCapRound: true,
        spots: fireResult.mothEstimates
            .map((e) => FlSpot(e.month.toDouble(), e.balance))
            .toList());
    var totalContributionsLine = LineChartBarData(
        color: Colors.orange,
        isStrokeCapRound: true,
        spots: fireResult.mothEstimates
            .map((e) => FlSpot(e.month.toDouble(), e.totalContributions))
            .toList());
    var totalInterestLine = LineChartBarData(
        color: Colors.pink,
        isStrokeCapRound: true,
        spots: fireResult.mothEstimates
            .map((e) => FlSpot(e.month.toDouble(), e.totalInterest))
            .toList());
    var adjustedMonthlyTargetInterest = LineChartBarData(
        color: Colors.red,
        isStrokeCapRound: true,
        spots: fireResult.mothEstimates
            .map((e) =>
                FlSpot(e.month.toDouble(), e.adjustedMonthlyTargetInterest))
            .toList());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          Container(
            width: double.infinity,
            constraints: BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                TextFormField(
                  controller: _initialAmountController,
                  decoration:
                      InputDecoration(labelText: 'Startkapital in Euro'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                TextFormField(
                  controller: _interestRateController,
                  decoration:
                      InputDecoration(labelText: 'Jahreszinsrate in Prozent'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                TextFormField(
                  controller: _monthlyContributionController,
                  decoration:
                      InputDecoration(labelText: 'Monatliche Sparrate in Euro'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                TextFormField(
                  controller: _targetMonthlyInterestController,
                  decoration: InputDecoration(
                      labelText: 'Ziel für monatliche Zinsen in Euro'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                TextFormField(
                  controller: _annualInflationRateController,
                  decoration: InputDecoration(
                      labelText: 'Jährliche Inflationsrate in Prozent'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _action,
                  child: Text('Berechnen'),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Container(
            margin: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Endkapital ${formatEuro(fireResult.totalBalance)}"),
                Text("Gesamte Einzahlungen ${formatEuro(fireResult.totalContributions)}"),
                Text("Erhaltene Zinszahlungen ${formatEuro(fireResult.totalInterest)}"),
                Text("Wenn du über ${fireResult.breakEvenPoint}, "
                    "monatlich ${formatEuro(monthlyContribution())} zu ${interestRate()}% investierst, "
                    "kommst du am Ende auf ein Endkapital von ${formatEuro(fireResult.totalBalance)}. "
                    "Diese setzen sich zusammen aus ${formatEuro(fireResult.totalContributions)} "
                    "Einzahlungen und ${formatEuro(fireResult.totalInterest)} an Zinsen oder Kapitalerträgen."),
              ],
            ),
          )
          ,
          SizedBox(height: 20),
          Container(
            height: 1000,
            // width: 400,
            margin: EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(
                    child: LineChart(
                  LineChartData(
                      titlesData: titlesData,
                      lineTouchData: lineTouchData,
                      lineBarsData: [
                        gesamtsaldoLine,
                        totalContributionsLine,
                        totalInterestLine,
                      ]),
                )),
                Expanded(
                    child: LineChart(
                  LineChartData(
                      titlesData: titlesData,
                      lineTouchData: lineTouchData,
                      lineBarsData: [
                        interestLine,
                        adjustedMonthlyTargetInterest
                      ]),
                )),
              ],
            ),
          )
        ]),
      ),
    );
  }
}
