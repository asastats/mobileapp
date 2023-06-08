import 'package:flutter/foundation.dart';

class MenuProvider with ChangeNotifier {
  int _selectedIndex = 0;
  int _lastIndex = 0;
  final List<int> _screenStack = [0];
  int get selectedIndex => _selectedIndex;
  List<int> get screenStack => [..._screenStack];

  void setIndex(int index, {bool save = true}) {
    _lastIndex = _selectedIndex;
    _selectedIndex = index;
    if (save && _lastIndex != _selectedIndex) pushInScreenStack(_lastIndex);
    notifyListeners();
  }

  void pushInScreenStack(int value) {
    _screenStack.add(value);
  }

  int popInScreenStack() {
    return _screenStack.removeLast();
  }
}
