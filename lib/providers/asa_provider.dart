import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../data/datasource/repository/base/api_response.dart';
import '../data/repository/auth_repo.dart';
import '../models/response/base/response_model.dart';
import '../models/v2/v2.dart' as v2;
import '../utility/toast_service.dart';

class ASAProvider with ChangeNotifier {
  final ASArepo asaRepo;
  String _address = "";
  String _singleAddress = "";
  String _bundleHash = '';
  bool _isLoading = false;
  bool _isCaching = true;
  Map<String, Widget> _imageProviders = {};

  String get address => _address;
  String get singleAddress => _singleAddress;
  String get bundleHash => _bundleHash;
  bool get isLoading => _isLoading;
  bool get isCaching => _isCaching;
  Map<String, Widget> get imageProviders => _imageProviders;

  set address(_) => _address = _;
  set singleAddress(_) => _singleAddress = _;
  set imageProviders(_) => _imageProviders = _;
  set isCaching(_) => _isCaching = _;

  // # V2 state -----------------------------------------------------------
  //
  // ``_accountV2`` holds the parsed V2 ``EvaluatedAccount`` for the
  // primary (bundle) view. ``_accountV2Single`` holds the same shape for
  // the single-address drill (the small-screen "show me just this one
  // address" mode). Phase 5d collapsed the previous dual V1+V2 setup —
  // V1 state, the shim, and the v1 model imports are gone.
  v2.EvaluatedAccount _accountV2 = v2.EvaluatedAccount();
  v2.EvaluatedAccount? _accountV2Single;

  v2.EvaluatedAccount get accountV2 => _accountV2;
  v2.EvaluatedAccount? get accountV2Single => _accountV2Single;

  ASAProvider({required this.asaRepo});

  // -- V2 API calls ---------------------------------------------------

  /// POST raw address text and receive the bundle hash. Returns a
  /// ``ResponseModel`` whose ``data`` is the bundle-hash string
  /// (unpacked from the ``{"bundle": "..."}`` JSON envelope) so the
  /// caller can pass it directly into ``getEvaluatedAccountV2``.
  Future<ResponseModel> getBundleHashV2(String addresses) async {
    notifyListeners();
    _isLoading = true;
    final apiResponse = await asaRepo.getBundleHashV2(addresses);
    ResponseModel responseModel;
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      try {
        final raw = apiResponse.response!.data;
        // The V2 endpoint returns ``{"bundle": "..."}`` — unwrap to the
        // bare hash so call sites can use the result directly as the
        // address-or-bundle path parameter.
        final bundleHash = v2.BundleHash.fromJson(
          raw is Map<String, dynamic>
              ? raw
              : Map<String, dynamic>.from(raw as Map),
        );
        _bundleHash = bundleHash.bundle ?? '';
        responseModel = ResponseModel(
          true,
          _bundleHash.isEmpty ? "Empty bundle" : _bundleHash,
          _bundleHash,
        );
      } catch (e) {
        debugPrint("Unable to parse bundle response: $e");
        responseModel = ResponseModel(
            false, "Unable to parse bundle response", null);
      }
    } else {
      responseModel = ResponseModel(false, apiResponse.error, null);
      ToastService.show(responseModel.message, toastLength: Toast.LENGTH_LONG);
    }
    _isLoading = false;
    notifyListeners();
    return responseModel;
  }

  /// GET a full evaluated account by address / bundle / NFD name.
  ///
  /// On success, the parsed ``EvaluatedAccount`` is stashed in
  /// ``_accountV2`` (or ``_accountV2Single`` when ``isSingle: true``).
  /// On parse failure, sets a failure ``ResponseModel`` but leaves the
  /// previous state untouched so a partial outage doesn't blank the UI.
  Future<ResponseModel> getEvaluatedAccountV2(String addressOrBundle,
      {bool isSingle = false}) async {
    _isLoading = true;
    notifyListeners();
    final apiResponse = await asaRepo.getEvaluatedAccountV2(addressOrBundle);
    ResponseModel responseModel;
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      // Cache the raw response body for cold-start fallback. Stored under
      // the V2 key so existing V1-shaped cached payloads on user devices
      // are naturally orphaned (see AppConstants.ASA_RESPONSE).
      saveResponse(jsonEncode(apiResponse.response?.data));
      try {
        final raw = apiResponse.response!.data;
        final parsed = v2.EvaluatedAccount.fromJson(
          raw is Map<String, dynamic>
              ? raw
              : Map<String, dynamic>.from(raw as Map),
        );
        if (isSingle) {
          _accountV2Single = parsed;
        } else {
          _accountV2 = parsed;
        }
        responseModel = ResponseModel(
            true, "OK", apiResponse.response?.data);
      } catch (e) {
        debugPrint("Unable to parse V2 account response: $e");
        responseModel = ResponseModel(
            false, "Unable to parse API response", apiResponse.response?.data);
      }
    } else {
      responseModel = ResponseModel(false, apiResponse.error, null);
    }
    if (!responseModel.isSuccess) {
      ToastService.show(responseModel.message, toastLength: Toast.LENGTH_LONG);
    }
    _isLoading = false;
    notifyListeners();
    return responseModel;
  }

  /// GET the global-settings payload from the V2 endpoint and persist it
  /// to SharedPreferences for offline access. Same contract as the V1
  /// ``getGlobalSetting()`` — only the URL changed — so the JSON shape
  /// in shared prefs stays compatible, and the bundled
  /// ``assets/json/global_settings.json`` fallback still works.
  Future<ResponseModel> getGlobalSettingV2() async {
    _isLoading = true;
    final apiResponse = await asaRepo.getGlobalSettingV2();
    ResponseModel responseModel;
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      await setGlobalSetting(jsonEncode(apiResponse.response?.data ?? {}));
      responseModel = ResponseModel(
          true, "OK", apiResponse.response?.data);
    } else {
      responseModel = ResponseModel(false, apiResponse.error, null);
      ToastService.show(responseModel.message, toastLength: Toast.LENGTH_LONG);
    }
    _isLoading = false;
    notifyListeners();
    return responseModel;
  }

  // # V1 API methods removed in Phase 5d
  //
  // ``getAsaAddress``, ``getAsaData``, and ``getGlobalSetting`` previously
  // lived here, calling the deprecated v1 URLs. Their V2 replacements are
  // ``getBundleHashV2``, ``getEvaluatedAccountV2``, and
  // ``getGlobalSettingV2`` above.

  // # V1 search functions removed in Phase 5d
  //
  // ``searchAsa``, ``searchNFT``, and ``searchNotEval`` (each ~50 lines
  // of nested ``element.toJson().containsElement(searchText)`` chains)
  // previously lived here. Their V2 replacements are below; same
  // semantics, ~5 lines each, JSON-stringify against the v2 model.


  // # Phase 5d — V2 search functions ----------------------------------
  //
  // Operate on ``accountV2`` lists directly; no v1 shim involved. The
  // implementation is "stringify-and-match" — serialize each item via
  // ``toJson()`` and substring-match the lowercased JSON. This matches
  // the v1 functions' behavior (which also did containsElement against
  // toJson representations) but is far shorter and works against the
  // v2 wire shape directly.
  //
  // Each function takes the search string and returns the filtered
  // sub-list of the corresponding ``accountV2.*`` field. The caller is
  // responsible for assigning the result to their local filtered-list
  // state field; the provider doesn't mutate ``accountV2``.

  /// Filter ``accountV2.asaitems`` by substring match (case-insensitive).
  List<v2.AsaItem> searchAsaitemsV2(
      String searchText, v2.EvaluatedAccount account) {
    if (searchText.isEmpty) return account.asaitems;
    final needle = searchText.toLowerCase();
    return account.asaitems
        .where((item) => jsonEncode(item.toJson()).toLowerCase().contains(needle))
        .toList(growable: false);
  }

  /// Filter ``accountV2.nftcollections`` by substring match. Mirrors
  /// the v1 ``searchNFT``: matches against the collection's own JSON
  /// AND each NFT-item's JSON (so searching by NFT name/id matches
  /// the parent collection).
  List<v2.NftCollection> searchNftCollectionsV2(
      String searchText, v2.EvaluatedAccount account) {
    if (searchText.isEmpty) return account.nftcollections;
    final needle = searchText.toLowerCase();
    return account.nftcollections.where((coll) {
      if (jsonEncode(coll.toJson()).toLowerCase().contains(needle)) return true;
      // Collection-level JSON already includes nested NFT-item JSON via
      // toJson(), so a second per-nft pass is redundant. Kept as a no-op
      // here to make the parallel with v1 obvious.
      return false;
    }).toList(growable: false);
  }

  /// Filter ``accountV2.notevals`` by substring match.
  List<v2.NotEvaluatedItem> searchNotevalsV2(
      String searchText, v2.EvaluatedAccount account) {
    if (searchText.isEmpty) return account.notevals;
    final needle = searchText.toLowerCase();
    return account.notevals
        .where((item) => jsonEncode(item.toJson()).toLowerCase().contains(needle))
        .toList(growable: false);
  }

  Future<bool> saveAddress(String address) {
    return asaRepo.saveAddress(address);
  }

  List<String> getAddress() {
    return asaRepo.getAddress();
  }

  Future<bool> saveResponse(String address) {
    return asaRepo.saveResponse(address);
  }

  String getResponse() {
    return asaRepo.getResponse();
  }

  Future<bool> setAutoRefresh(bool auto) {
    return asaRepo.setAutoRefresh(auto);
  }

  bool isAutoRefreshOn() {
    return asaRepo.getAutoRefresh();
  }

  Future<bool> setPieChartVisibility(bool value) {
    return asaRepo.setPieChartVisibility(value);
  }

  bool getPieChartVisibility() {
    return asaRepo.getPieChartVisibility();
  }

  Future<bool> setTotalWithoutNfts(bool value) {
    return asaRepo.setTotalWithoutNfts(value);
  }

  bool getTotalWithoutNfts() {
    return asaRepo.getTotalWithoutNfts();
  }

  Future<bool> setHomeFirst(bool value) {
    return asaRepo.setHomeFirst(value);
  }

  bool isAddressSaved() {
    return asaRepo.getHomeFirst();
  }

  Future<bool> setGlobalSetting(String value) {
    return asaRepo.setGlobalSetting(value);
  }

  String getGlobalSettingSF() {
    return asaRepo.getGlobalSettingSF();
  }

  Future clearAddress() async {
    return asaRepo.clearAddress();
  }

  void clear() {
    // Phase 5d simplification — the V1 ``ASAModel.fromJson({})`` calls
    // that used to live here crashed on empty input (a pre-existing
    // null-deref in the v1 model), so this had to be wrapped in a
    // try/catch. With the v1 model gone, clear() is just two assignments
    // to the V2 slots.
    _accountV2 = v2.EvaluatedAccount();
    _accountV2Single = null;
    notifyListeners();
  }
}
