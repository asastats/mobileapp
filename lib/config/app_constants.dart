// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:convert';

import 'package:asa_stats/providers/asa_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AppConstants {
  static const String APP_NAME = "ASAState Mobile App";
  static const String FONT_FAMILY = "Oswald";
  static const String FONT_FAMILY_OUTFIT = "Outfit";

  // Shared Preference Keys
  static const String CURRENCY = "currency";

  // secret Keys
  static const String SECRET_KEY = "secret";

  // Global settings file
  static const String GLOBAL_FILE = "assets/json/global_settings.json";

  // test address
  static const String TEXT_ADDRESS = '';
  // "TAMER7T4JKVQTGCU5M2L6G2ONIIHLWI4E5MRUMQDXELUUVG7GSA5HUUKMQ"; // 61 NFT
  // "ROYIQMUFD3XC6HHIHO4P3W4KB6TDP7D5Q4K3JGWV54Q4PEJIHVVI6IIZAI"; // 500+ NFT
  // "VF2QRTQGJHCYVLMXUMN4RTEQF5SBFCZFQV6Y5YXVSUG3OWWYCDXXWYPQYU,OGBOMRANR5ZG55HRVMVKRPEKN6CIHBH5S5W2O3NJOQV4XWDOFAL2ZQZPME,METARMZPL6U5632YG6QM5APSGIO7F4QDJ66EVSELWELK65MWC6LC7WZ5CQ,VIBEGPVL7VJRQYP22KOHJ625RSAAJ7GALL5VNTZRCZFU7OJQVF6WFWG7EA,BSKTQYKQUAOFLMMA455NQ7TIN4HM6NNIWRJE4K5EJIY2J7WZYJYM3NHQOM"; // 3000 NFT
  // "2EVGZ4BGOSL3J64UYDE2BUGTNTBZZZLI54VUQQNZZLYCDODLY33UGXNSIU,VW55KZ3NF4GDOWI7IPWLGZDFWNXWKSRD5PETRLDABZVU5XPKRJJRK3CBSU";
  // refresh timeout
  static const int REFRESH_TIMEOUT = 60;

  // Policy URls
  static const String PRIVACY_POLICY = "";
  static const String TERMS_OF_SERVICE = "";

  static const String THEME = 'theme';
  static const String ADDRESS = 'address';
  static const String ASA_RESPONSE = 'ASA_RESPONSE';
  static const String AUTO_REFRESH = 'auto_refresh';
  static const String PIE_CHART_VISIBILITY = 'PIE_CHART_VISIBILITY';
  static const String HOME_FIRST = 'HOME_FIRST';
  static const String GLOBAL_SETTING = 'GLOBAL_SETTING';

  static const String ABOUT_URL = 'https://www.asastats.com/about/';
  static const String TOKENOMICS_URL = 'https://www.asastats.com/tokenomics/';
  static const String BUY_ASA_URL =
      'https://app.tinyman.org/#/swap?asset_in=0&asset_out=393537671';
  static const String FAQ_URL = 'https://www.asastats.com/faq/';
  static const String DISCLAIMER_URL = 'https://www.asastats.com/disclaimer/';

  static const String TWITTER_URL = 'https://twitter.com/asastatscom';
  static const String DISCORD_URL = 'https://discord.com/invite/Vjx7w7pAC7';
  static const String REDDIT_URL = 'https://www.reddit.com/r/asastats/';
  static const String GITHUB_URL = 'https://github.com/asastats';

  static const int HOME_INDEX = 7;
  static const int ADDRESS_INDEX = 0;
  // static const int HOME_INDEX = 0;
  // static const int HOME_INDEX = 0;

  static String getAsaImage(String id) {
    return "https://www.asastats.com/static/icons/${id}t.png";
  }

  static String getProviderImage(String id) {
    return "https://www.asastats.com/static/icons/providers/$id.png";
  }

  static String getNFTImage(String path) {
    return "https://www.asastats.com/static$path";
  }

  static Future<Map<String, dynamic>> readGlobalJsonFile(
      BuildContext context) async {
    final String response =
        Provider.of<ASAProvider>(context, listen: false).getGlobalSettingSF();
    return jsonDecode(response);
  }

  static String formateNumber(double number, {String points = "0000"}) {
    var formatter = NumberFormat('#,##0.$points');
    List<String> parts = number.toString().split(".");

    if (parts.length == 2) {
      if (parts[1].length < 4) {
        var formattedInteger =
            NumberFormat('#,##0').format(int.parse(parts[0]));

        if (int.parse(parts[1]) == 0) {
          return formattedInteger;
        }

        return "$formattedInteger.${parts[1]}";
      }
    }

    return formatter.format(number).replaceAll(RegExp(r'.000*$'), '');
  }

  static String removeDecimalZeroFormat(double n) {
    return n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 1);
  }

  static String formateNumberWithoutReg(double number,
      {String points = "0000"}) {
    var formatter = NumberFormat('#,##0.$points');
    return formatter.format(number);
  }

  static final containerKey1 = Key("1");
  static final containerKey2 = Key("2");
}
