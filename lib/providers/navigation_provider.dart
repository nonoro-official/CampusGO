import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardTabIndex extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final dashboardTabIndexProvider = NotifierProvider<DashboardTabIndex, int>(DashboardTabIndex.new);
