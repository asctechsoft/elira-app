import 'package:flutter/services.dart' show appFlavor;

enum AppFlavor { alpha, dev, product }

/// Reads Flutter's built-in `appFlavor` constant, which `--flavor dev` already
/// sets. Using it instead of a `--dart-define` removes the class of bugs where
/// someone forgets to pass the define.
AppFlavor get currentFlavor {
  switch (appFlavor) {
    case 'alpha':
      return AppFlavor.alpha;
    case 'product':
      return AppFlavor.product;
    default:
      return AppFlavor.dev;
  }
}

bool get isProductFlavor => currentFlavor == AppFlavor.product;

String get flavorLabel => switch (currentFlavor) {
      AppFlavor.alpha => 'Elira Alpha',
      AppFlavor.dev => 'Elira Dev',
      AppFlavor.product => 'ASC Photo AI',
    };
