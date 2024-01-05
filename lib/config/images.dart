// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class Images {
  // path
  static const ICONS = "assets/icons/";
  static const IMAGES = "assets/images/";
  static const PROVIDER = "assets/provider/";

  static String APP_LOGO_LIGHT = ICONS + "app_logo_light.png";
  static String APP_LOGO_DARK = ICONS + "app_logo_dark.png";
  static String APP_LOGO_DARK_BIG = ICONS + "app_logo_big.png";

  static String IC_NAV = ICONS + "ic_nav.png";
  static String IC_ABOUT = ICONS + "ic_about.png";
  static String IC_BUY_ASA = ICONS + "ic_buy_ASA.png";
  static String IC_CLOSE = ICONS + "ic_close.png";
  static String IC_DISCLAIMER = ICONS + "ic_disclaimer.png";
  static String IC_FAQ = ICONS + "ic_faq.png";
  static String IC_STATE = ICONS + "ic_state.png";
  static String IC_DROP_DOWN = ICONS + "ic_drop_down.png";
  static String IC_ARROW_UP = ICONS + "ic_arrow_up.png";
  static String IC_TOKENOMICS = ICONS + "ic_tokenomics.png";
  static String IC_GITHUB = ICONS + "ic_github.png";
  static String IC_TWITTER = ICONS + "ic_twitter.png";
  static String IC_MONKEY = ICONS + "ic_monkey.png";
  static String IC_DISCORD = ICONS + "ic_discord.png";
  static String IC_MOON = ICONS + "ic_moon.png";
  static String IC_BIT_COIN = ICONS + "ic_bit_coin.png";
  static String IC_COPY = ICONS + "ic_copy.png";
  static String IC_SUN = ICONS + "ic_sun.png";
  static String IC_SETTING = ICONS + "ic_setting.png";

  static String TOP_RIGHT_VIEW = IMAGES + "top_right_view.png";
  static String NFT_1 = IMAGES + "nft_1.png";
  static String NFT_2 = IMAGES + "nft_2.png";

  //Providers Image
  static String ALGO_CHARTS = "algocharts.png";
  static String ALGO_EXPLORER = "algoexplorer.png";
  static String ALGORAND_STATS = "algorandstats.png";
  static String ANS = "ans.png";
  static String COIN_MARKET_CAT = "coinmarketcap.png";
  static String LIVE_COIN_WATCH = "livecoinwatch.png";
  static String LOFTY_AI = "loftyai.png";
  static String NFD = "nfd.png";
  static String TINY_CHART = "tinychart.png";
  static String VESTIGE = "vestige.png";

  static String appLogo(BuildContext context) {
    return Provider.of<ThemeProvider>(context).darkTheme
        ? APP_LOGO_DARK
        : APP_LOGO_LIGHT;
  }
}
