import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../data/datasource/repository/base/api_response.dart';
import '../data/repository/auth_repo.dart';
import '../models/response/asa_model.dart';
import '../models/response/base/response_model.dart';
import '../models/response/nftValues.dart';
import '../models/response/notEval.dart';
import '../models/response/values.dart';
import '../models/v2/v2.dart' as v2;
import '../models/v2_to_v1.dart';
import '../utility/toast_service.dart';
import 'package:asa_stats/config/extensions.dart';

class ASAProvider with ChangeNotifier {
  final ASArepo asaRepo;
  ASAModel _asaData = ASAModel();
  late ASAModel _asaDataSingle;
  String _address = "";
  String _singleAddress = "";
  String _bundleHash = '';
  bool _isLoading = false;
  bool _isCaching = true;
  Map<String, Widget> _imageProviders = {};

  ASAModel get asaModel => _asaData.copyWith();
  ASAModel get asaModelSingle => _asaDataSingle;
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

  // -- V2 state -------------------------------------------------------
  //
  // Distinct backing fields from the V1 _asaData / _asaDataSingle.
  // Screens are migrated incrementally (Phase 5c) — every widget that
  // hasn't switched yet keeps reading from _asaData; widgets that have
  // switched read from _accountV2. When all are migrated, the V1 state
  // and methods get deleted (Phase 5d).
  v2.EvaluatedAccount _accountV2 = v2.EvaluatedAccount();
  v2.EvaluatedAccount? _accountV2Single;

  v2.EvaluatedAccount get accountV2 => _accountV2;
  v2.EvaluatedAccount? get accountV2Single => _accountV2Single;

  ASAProvider({required this.asaRepo});

  // -- V2 API calls ---------------------------------------------------

  /// POST raw address text and receive the bundle hash. Replaces the V1
  /// ``getAsaAddress({"raw": ...})`` call. Returns a ``ResponseModel``
  /// whose ``data`` is the bundle-hash string (unpacked from the
  /// ``{"bundle": "..."}`` JSON envelope), so existing callers that pass
  /// the result into the next API call don't need to change shape.
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
  /// Replaces the V1 ``getAsaData(address)`` call.
  ///
  /// On success, the parsed ``EvaluatedAccount`` is stashed in
  /// ``_accountV2`` (or ``_accountV2Single`` when ``isSingle: true``).
  /// On parse failure, sets a failure ``ResponseModel`` but leaves the
  /// previous state untouched so a partial outage doesn't blank the UI.
  ///
  /// During the Phase 5c transition, ``_asaData`` / ``_asaDataSingle``
  /// are ALSO populated via the ``v2ToV1ASAModel`` shim so screens that
  /// haven't been migrated to read V2 directly keep working. Once every
  /// screen reads from ``_accountV2``, Phase 5d removes the dual write
  /// and the shim file.
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
        // Build the V1 shape from the same parsed V2 model. The shim is
        // a pure function — if it ever throws the V2 state is still
        // written below, so the V2-reading screens stay correct.
        final v1Shim = v2ToV1ASAModel(parsed);
        if (isSingle) {
          _accountV2Single = parsed;
          _asaDataSingle = v1Shim;
        } else {
          _accountV2 = parsed;
          _asaData = v1Shim;
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

  // -- V1 API calls (retained until Phase 5d) -------------------------

  Future<ResponseModel> getAsaAddress(Map<String, dynamic> data,
      {bool isSingle = false}) async {
    notifyListeners();
    ResponseModel responseModel;
    _isLoading = true;
    ApiResponse apiRegisterResponse = await asaRepo.getAsaAddress(data);
    if (apiRegisterResponse.response != null &&
        apiRegisterResponse.response!.statusCode == 200) {
      _bundleHash = apiRegisterResponse.response!.data.toString();
      responseModel = ResponseModel(
          true,
          apiRegisterResponse.response?.data.toString() ?? "Empty Data",
          apiRegisterResponse.response?.data);
    } else {
      responseModel = ResponseModel(false, apiRegisterResponse.error, null);
      ToastService.show(responseModel.message, toastLength: Toast.LENGTH_LONG);
    }
    _isLoading = false;
    notifyListeners();
    return responseModel;
  }

  Future<ResponseModel> getAsaData(String data, {bool isSingle = false}) async {
    ResponseModel responseModel;
    _isLoading = true;
    notifyListeners();
    ApiResponse apiRegisterResponse = await asaRepo.getAsaData(data);
    if (apiRegisterResponse.response != null &&
        apiRegisterResponse.response!.statusCode == 200) {
      saveResponse(jsonEncode(apiRegisterResponse.response?.data));
      try {
        if (isSingle) {
          _asaDataSingle =
              ASAModel.fromJson(apiRegisterResponse.response?.data ?? {});
        } else {
          _asaData =
              ASAModel.fromJson(apiRegisterResponse.response?.data ?? {});
        }
        responseModel = ResponseModel(
            true,
            apiRegisterResponse.response?.data.toString() ?? "Empty Data",
            apiRegisterResponse.response?.data);
      } catch (e) {
        debugPrint("Unable to parse API response" + e.toString());
        responseModel = ResponseModel(false, "Unable to parse API response",
            apiRegisterResponse.response?.data);
      }
    } else {
      responseModel = ResponseModel(false, apiRegisterResponse.error, null);
    }
    if (!responseModel.isSuccess) {
      ToastService.show(responseModel.message, toastLength: Toast.LENGTH_LONG);
    }
    _isLoading = false;
    notifyListeners();
    return responseModel;
  }

  Future<ResponseModel> getGlobalSetting() async {
    // notifyListeners();
    ResponseModel responseModel;
    _isLoading = true;
    ApiResponse apiRegisterResponse = await asaRepo.getGlobalSetting();
    if (apiRegisterResponse.response != null &&
        apiRegisterResponse.response!.statusCode == 200) {
      print("api response --> ${apiRegisterResponse.response?.data}");
      await setGlobalSetting(
          jsonEncode(apiRegisterResponse.response?.data ?? {}));
      responseModel = ResponseModel(
          true,
          apiRegisterResponse.response?.data.toString() ?? "Empty Data",
          apiRegisterResponse.response?.data);
    } else {
      responseModel = ResponseModel(false, apiRegisterResponse.error, null);
      ToastService.show(responseModel.message, toastLength: Toast.LENGTH_LONG);
    }
    _isLoading = false;
    notifyListeners();
    return responseModel;
  }

  List<Values>? searchAsa(String searchText, ASAModel asaModel) {
    ASAModel temp = asaModel.copyWith();
    temp.values = temp.values
            ?.where((element) =>
                // basic properties search
                element.toJson().containsElement(searchText) ||
                // ASA Details search
                (element.asa?.toJson().containsElement(searchText) ?? false) ||
                (element.asa?.links?.asMap().containsElement(searchText) ??
                    false) ||
                // Dapps Details search
                (element.dapps
                        ?.where((element) =>
                            // basic dapps properties search
                            (element.toJson().containsElement(searchText)) ||
                            // distribution properties search
                            (element.distribution
                                    ?.where((element) => element
                                        .toJson()
                                        .containsElement(searchText))
                                    .toList()
                                    .isNotEmpty ??
                                false) ||
                            // staking list search
                            (element.staking
                                    ?.asMap()
                                    .containsElement(searchText) ??
                                false) ||
                            // entries properties search
                            (element.entries?.amount
                                    ?.toJson()
                                    .containsElement(searchText) ??
                                false) ||
                            (element.entries?.links
                                    ?.asMap()
                                    .containsElement(searchText) ??
                                false) ||
                            (element.entries?.price
                                    ?.toJson()
                                    .containsElement(searchText) ??
                                false) ||
                            (element.entries?.value
                                    ?.toJson()
                                    .containsElement(searchText) ??
                                false))
                        .toList()
                        .isNotEmpty ??
                    false))
            .toList() ??
        [];

    return temp.values;
  }

  List<NftValues>? searchNFT(String searchText, ASAModel asaModel) {
    ASAModel temp = asaModel.copyWith();
    temp.nftValues = temp.nftValues
            ?.where((element) =>
                // basic details search
                element.toJson().containsElement(searchText) ||
                (element.nfts
                        ?.where((element) =>
                            element.toJson().containsElement(searchText) ||
                            (element.nft
                                    ?.toJson()
                                    .containsElement(searchText) ??
                                false) ||
                            (element.nft?.urls?.containsElement(searchText) ??
                                false) ||
                            (element.nft?.listed?.any((l) =>
                                    l.toJson().containsElement(searchText)) ??
                                false) ||
                            (element.nft?.last
                                    ?.toJson()
                                    .containsElement(searchText) ??
                                false) ||
                            (element.nft?.max
                                    ?.toJson()
                                    .containsElement(searchText) ??
                                false) ||
                            (element.nft?.floor
                                    ?.toJson()
                                    .containsElement(searchText) ??
                                false) ||
                            (element.nft?.attrs?.containsElement(searchText) ??
                                false))
                        .toList()
                        .isNotEmpty ??
                    false))
            .toList() ??
        [];

    temp.nftValues?.forEach((element) {
      element.nfts?.retainWhere((element) =>
          (element.value?.toString().toLowerCase().contains(searchText) ??
              false) ||
          (element.id?.toString().toLowerCase().contains(searchText) ??
              false) ||
          (element.amount?.toString().toLowerCase().contains(searchText) ??
              false) ||
          (element.nft?.id?.toString().toLowerCase().contains(searchText) ??
              false) ||
          (element.nft?.name?.toString().toLowerCase().contains(searchText) ??
              false) ||
          (element.nft?.unit?.toString().toLowerCase().contains(searchText) ??
              false) ||
          (element.nft?.total?.toString().toLowerCase().contains(searchText) ??
              false) ||
          (element.nft?.collection
                  ?.toString()
                  .toLowerCase()
                  .contains(searchText) ??
              false) ||
          (element.nft?.urls?.containsElement(searchText) ?? false) ||
          (element.nft?.listed?.any((l) =>
                  l.toJson().containsElement(searchText)) ??
              false) ||
          (element.nft?.last?.toJson().containsElement(searchText) ?? false) ||
          (element.nft?.max?.toJson().containsElement(searchText) ?? false) ||
          (element.nft?.floor?.toJson().containsElement(searchText) ?? false) ||
          (element.nft?.title
                  ?.toString()
                  .toLowerCase()
                  .contains(searchText) ??
              false) ||
          (element.nft?.desc
                  ?.toString()
                  .toLowerCase()
                  .contains(searchText) ??
              false) ||
          (element.nft?.attrs?.containsElement(searchText) ?? false) ||
          (element.price?.toString().toLowerCase().contains(searchText) ??
              false) ||
          (element.creator?.toString().toLowerCase().contains(searchText) ??
              false));
    });

    return temp.nftValues;
  }

  List<NotEval>? searchNotEval(String searchText, ASAModel asaModel) {
    ASAModel temp = asaModel.copyWith();
    temp.notEval = temp.notEval
            ?.where((element) =>
                (element.asa?.name?.toLowerCase() ?? "")
                    .contains(searchText.toLowerCase()) ||
                (element.asa?.id?.toString().toLowerCase().contains(searchText) ??
                    false) ||
                (element.asa?.total?.toString().toLowerCase().contains(searchText) ??
                    false) ||
                (element.asa?.unit?.toString().toLowerCase().contains(searchText) ??
                    false) ||
                (element.price?.toString().toLowerCase().contains(searchText) ??
                    false) ||
                (element.value?.toString().toLowerCase().contains(searchText) ??
                    false) ||
                (element.dapps
                        ?.where((element) =>
                            element.address.toString().toLowerCase().contains(searchText) ||
                            element.amount
                                .toString()
                                .toLowerCase()
                                .contains(searchText) ||
                            element.appId
                                .toString()
                                .toLowerCase()
                                .contains(searchText) ||
                            element.available
                                .toString()
                                .toLowerCase()
                                .contains(searchText) ||
                            element.dapp.toString().toLowerCase().contains(searchText) ||
                            (element.entries?.amount?.toString().toLowerCase().contains(searchText) ?? false) ||
                            (element.entries?.price?.toString().toLowerCase().contains(searchText) ?? false) ||
                            (element.entries?.value?.text?.toString().toLowerCase().contains(searchText) ?? false) ||
                            (element.entries?.value?.linktext?.toString().toLowerCase().contains(searchText) ?? false) ||
                            (element.entries?.value?.title?.toString().toLowerCase().contains(searchText) ?? false) ||
                            (element.entries?.value?.value?.toString().toLowerCase().contains(searchText) ?? false) ||
                            element.name.toString().toLowerCase().contains(searchText) ||
                            element.next.toString().toLowerCase().contains(searchText) ||
                            element.price.toString().toLowerCase().contains(searchText) ||
                            element.proxy.toString().toLowerCase().contains(searchText) ||
                            element.reward.toString().toLowerCase().contains(searchText) ||
                            element.value.toString().toLowerCase().contains(searchText) ||
                            (element.staking?.contains(searchText) ?? false) ||
                            (element.distribution?.where((element) => element.link.toString().toLowerCase().contains(searchText) || element.link.toString().toLowerCase().contains(searchText) || element.price.toString().toLowerCase().contains(searchText) || element.value.toString().toLowerCase().contains(searchText)).toList().isNotEmpty ?? false))
                        .toList()
                        .isNotEmpty ??
                    false))
            .toList() ??
        [];

    return temp.notEval;
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
    // Reset V2 first, then V1. The legacy ``ASAModel.fromJson({})`` calls
    // below crash on empty input (the v1 model dereferences
    // ``json['addresses'].cast<String>()`` without null-checking), but
    // we depend on those calls remaining in place until Phase 5d retires
    // the v1 model entirely. Resetting V2 first ensures the V2 slots are
    // wiped even if the V1 reset throws. Wrap the V1 reset in a try
    // block so a stale ``_asaData``/``_asaDataSingle`` from the previous
    // session doesn't survive — the catch is a no-op because the throw
    // happens before the assignment, leaving the existing _asaData in
    // place, which is preferable to propagating an exception out of
    // clear() and crashing whatever called it.
    _accountV2 = v2.EvaluatedAccount();
    _accountV2Single = null;
    try {
      _asaData = ASAModel.fromJson({});
      _asaDataSingle = ASAModel.fromJson({});
    } on NoSuchMethodError {
      // Pre-existing v1 fragility — see comment above. Phase 5d cleanup
      // removes the offending lines along with the v1 model.
    }
    notifyListeners();
  }
}
