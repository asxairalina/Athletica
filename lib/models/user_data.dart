class UserData {
  static String _fullName = 'Иван Иванов';
  static int _height = 175;
  static double _weight = 70.0;

  static String get fullName => _fullName;
  static int get height => _height;
  static double get weight => _weight;

  static void updateWeight(double newWeight) {
    _weight = newWeight;
  }

  static void updateProfile({
    String? fullName,
    int? height,
    double? weight,
  }) {
    if (fullName != null) _fullName = fullName;
    if (height != null) _height = height;
    if (weight != null) _weight = weight;
  }
}
