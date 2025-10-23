import 'package:flutter/foundation.dart';

enum CoupleMode { personal, joint }

class CoupleModeProvider with ChangeNotifier {
  CoupleMode _currentMode = CoupleMode.personal;
  String? _coupleId;
  String? _partnerId;

  CoupleMode get currentMode => _currentMode;
  String? get coupleId => _coupleId;
  String? get partnerId => _partnerId;

  bool get isCoupleActive => _coupleId != null && _partnerId != null;
  bool get isJointMode => isCoupleActive && _currentMode == CoupleMode.joint;

  void setMode(CoupleMode mode) {
    if (_currentMode != mode) {
      _currentMode = mode;
      notifyListeners();
    }
  }

  void setCoupleData(String? coupleId, String? partnerId) {
    _coupleId = coupleId;
    _partnerId = partnerId;
    // If couple data is cleared, always revert to personal mode
    if (coupleId == null) {
      _currentMode = CoupleMode.personal;
    }
    notifyListeners();
    debugPrint('[CoupleModeProvider] State Updated: coupleId=$_coupleId, partnerId=$_partnerId, mode=$_currentMode');
  }
}
