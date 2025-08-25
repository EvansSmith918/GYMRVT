class EmaFilter {
  final double alpha; // 0..1 (lower = smoother)
  double? _s;
  EmaFilter({this.alpha = 0.25});
  double filter(double x) {
    _s = (_s == null) ? x : alpha * x + (1 - alpha) * _s!;
    return _s!;
  }
}
