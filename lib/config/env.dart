import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get API_KEY {
    return dotenv.env['API_KEY'] ?? "";
  }
}
