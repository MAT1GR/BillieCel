import 'package:flutter/foundation.dart';

enum CoupleMode { personal, joint }

class CoupleModeProvider with ChangeNotifier {
  CoupleMode _currentMode = CoupleMode.personal;
  String? _activeCoupleId;

  CoupleMode get currentMode => _currentMode;
  String? get activeCoupleId => _activeCoupleId;

  void setMode(CoupleMode mode) {
    if (_currentMode != mode) {
      _currentMode = mode;
      notifyListeners();
    }
  }

  void setActiveCouple(String? coupleId) {
    if (_activeCoupleId != coupleId) {
      _activeCoupleId = coupleId;
      // If coupleId becomes null, revert to personal mode
      if (coupleId == null) {
        _currentMode = CoupleMode.personal;
      }
      notifyListeners();
    }
  }

  // Helper to check if in joint mode
  bool get isJointMode => _currentMode == CoupleMode.joint && _activeCoupleId != null;
}
