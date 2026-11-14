import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HomeTarget { shopRequests }

class HomeTargetNotifier extends Notifier<HomeTarget?> {
  @override
  HomeTarget? build() => null;

  void open(HomeTarget target) => state = target;

  void clear() => state = null;
}

final homeTargetProvider = NotifierProvider<HomeTargetNotifier, HomeTarget?>(
  HomeTargetNotifier.new,
);

class ShopsSegmentNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void request(int segment) => state = segment;

  void clear() => state = null;
}

final shopsSegmentProvider = NotifierProvider<ShopsSegmentNotifier, int?>(
  ShopsSegmentNotifier.new,
);