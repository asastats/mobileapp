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
import '../utility/toast_service.dart';
import 'package:asa_stats/config/extensions.dart';

class ASAProvider with ChangeNotifier {
  final ASArepo asaRepo;
  ASAModel _asaData = ASAModel();
  late ASAModel _asaDataSingle;
  String _address = "";
  String _singleAddress = "";
  bool _isLoading = false;
  bool _isCaching = true;
  Map<String, Widget> _imageProviders = {};

  ASAModel get asaModel => _asaData.copyWith();
  ASAModel get asaModelSingle => _asaDataSingle;
  String get address => _address;
  String get singleAddress => _singleAddress;
  bool get isLoading => _isLoading;
  bool get isCaching => _isCaching;
  Map<String, Widget> get imageProviders => _imageProviders;

  set address(_) => _address = _;
  set singleAddress(_) => _singleAddress = _;
  set imageProviders(_) => _imageProviders = _;
  set isCaching(_) => _isCaching = _;

  ASAProvider({required this.asaRepo});

  Future<ResponseModel> getAsaAddress(Map<String, dynamic> data,
      {bool isSingle = false}) async {
    notifyListeners();
    ResponseModel responseModel;
    _isLoading = true;
    ApiResponse apiRegisterResponse = await asaRepo.getAsaAddress(data);
    if (apiRegisterResponse.response != null &&
        apiRegisterResponse.response!.statusCode == 200) {
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
                            (element.nft?.listed
                                    ?.toJson()
                                    .containsElement(searchText) ??
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
          (element.nft?.listed?.toJson().containsElement(searchText) ??
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
    // Clear Provider
    _asaData = ASAModel.fromJson({});
    _asaDataSingle = ASAModel.fromJson({});
    notifyListeners();
  }
}
