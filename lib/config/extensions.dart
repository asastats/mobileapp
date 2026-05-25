extension E on String {
  String lastChars(int n) => substring(length - n);
  String firstChars(int n) => substring(0, n);
}

extension M on Map {
  String getVal(findKey) {
    String val = "";
    forEach((key, value) {
      if (key == findKey.toString()) {
        val = value;
      }
    });
    return val;
  }

  bool containsElement(String searchText) {
    bool exist = false;
    forEach((key, value) {
      // if (value is Map) {
      //   exist = value.containsElement(searchText);
      // } else if (values is List) {
      //   for (var element in values) {
      //     if ((jsonDecode(jsonEncode(element)) as Map)
      //         .containsElement(searchText)) {
      //       exist = true;
      //     }
      //   }
      // } else
      if (value.toString().toLowerCase().contains(searchText)) {
        exist = true;
      }
    });
    return exist;
  }
}

extension N on List {
  String getString(String key) {
    String value = "";
    forEach((element) {
      if (element.toString().contains(key)) {
        value = key;
      }
    });
    return value;
  }

  bool containsElement(String key) {
    bool found = false;
    forEach((element) {
      if (element.toString().contains(key)) {
        found = true;
      }
    });
    return found;
  }
}
