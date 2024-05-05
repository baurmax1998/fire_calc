class MonthData {
  int month;

  double adjustedMonthlyTargetInterest;
  double balance;
  double interest;
  double totalInterest;
  double totalContributions;


  MonthData(this.month, this.adjustedMonthlyTargetInterest, this.balance,
      this.interest, this.totalInterest, this.totalContributions);

  int jahre() {
    return month ~/ 12;
  }

  int monate() {
    return month % 12;
  }
}

class FireData {
  double initialAmount; // Startkapital in Euro
  double interestRate; // Jahreszinsrate von 5%
  int years; // Anlagedauer in Jahren
  double monthlyContribution; // Monatliche Sparrate in Euro
  double targetMonthlyInterest; // Ziel für monatliche Zinsen in Euro
  double annualInflationRate; // Jährliche Inflationsrate von 4%

  FireData(
      this.initialAmount,
      this.interestRate,
      this.years,
      this.monthlyContribution,
      this.targetMonthlyInterest,
      this.annualInflationRate);
}

class FireResult {
  String breakEvenPoint;
  String interestSurpassPoint;
  double totalContributions;
  double totalInterest;
  double totalBalance;
  List<MonthData> mothEstimates;

  FireResult(this.breakEvenPoint, this.interestSurpassPoint,
      this.totalContributions, this.totalInterest, this.totalBalance, this.mothEstimates);
}
