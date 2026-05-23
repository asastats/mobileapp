import 'dart:async';

import 'package:asa_stats/config/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_constants.dart';
import '../datasource/remote/dio/dio_client.dart';
import '../datasource/remote/exception/api_error_handler.dart';
import '../datasource/repository/base/api_response.dart';

class ASArepo {
  final DioClient dioClient;
  final SharedPreferences sharedPreferences;

  ASArepo({
    required this.dioClient,
    required this.sharedPreferences,
  });

  Future<ApiResponse> getAsaAddress(Map<String, dynamic> data) async {
    try {
      Response response = await dioClient.post(
        APIConstants.BASE_URL,
        data: data, // data
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      print("error --> $e");
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponse> getAsaData(String address) async {
    try {
      Response response = await dioClient.get(
        APIConstants.BASE_URL + address,
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      print("error --> $e");
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponse> getGlobalSetting() async {
    try {
      Response response = await dioClient.get(
        APIConstants.GLOBAL_SETTING_URL,
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      print("error --> $e");
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  // -- API V2 ----------------------------------------------------------
  //
  // The three V2 methods below are intentional duplicates of the three V1
  // methods above; they differ in URL (api/v2/ vs api/), in request body
  // shape (`{"addresses": ...}` vs `{"raw": ...}`), and in response shape
  // (`{"bundle": "..."}` JSON object vs bare JSON string). Keep both sets
  // until Phase 5d cleanup. Once every caller is on V2, the V1 methods
  // and the V1 URL constants in api_constants.dart get deleted.

  /// POST a string of one-or-more whitespace/comma/semicolon-separated
  /// Algorand addresses (or .algo names) to ``/api/v2/`` and receive
  /// ``{"bundle": "<40-char hash>"}`` back. The bundle hash is the
  /// lookup key for the subsequent ``getEvaluatedAccountV2`` call.
  Future<ApiResponse> getBundleHashV2(String addresses) async {
    try {
      Response response = await dioClient.post(
        APIConstants.BASE_URL_V2,
        data: {"addresses": addresses},
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      print("error --> $e");
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  /// GET an account's full evaluated payload by address, bundle hash, or
  /// NFD .algo name. Returns the ``EvaluatedAccount`` JSON shape (see
  /// ``lib/models/v2/evaluated_account.dart``).
  Future<ApiResponse> getEvaluatedAccountV2(String addressOrBundle) async {
    try {
      Response response = await dioClient.get(
        APIConstants.BASE_URL_V2 + addressOrBundle + "/",
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      print("error --> $e");
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  /// GET the global-settings payload (asa_colors, nft_colors, slogans,
  /// providers.path). Same shape the V1 endpoint returns; only the URL
  /// has moved.
  Future<ApiResponse> getGlobalSettingV2() async {
    try {
      Response response = await dioClient.get(
        APIConstants.SETTINGS_URL_V2,
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      print("error --> $e");
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<bool> saveAddress(String address) {
    debugPrint("save address :${{...getAddress(), address}.toList()}");
    return sharedPreferences.setStringList(
        AppConstants.ADDRESS, {address, ...getAddress()}.toList());
  }

  List<String> getAddress() {
    return sharedPreferences.getStringList(AppConstants.ADDRESS) ?? [];
  }

  Future<bool> saveResponse(String response) {
    return sharedPreferences.setString(AppConstants.ASA_RESPONSE, response);
  }

  String getResponse() {
    return sharedPreferences.getString(AppConstants.ASA_RESPONSE) ?? "";
  }

  Future<bool> setAutoRefresh(bool auto) {
    return sharedPreferences.setBool(AppConstants.AUTO_REFRESH, auto);
  }

  bool getAutoRefresh() {
    return sharedPreferences.getBool(AppConstants.AUTO_REFRESH) ?? false;
  }

  Future<bool> setPieChartVisibility(bool value) {
    return sharedPreferences.setBool(AppConstants.PIE_CHART_VISIBILITY, value);
  }

  bool getPieChartVisibility() {
    return sharedPreferences.getBool(AppConstants.PIE_CHART_VISIBILITY) ?? true;
  }

  Future<bool> setTotalWithoutNfts(bool value) {
    return sharedPreferences.setBool(AppConstants.TOTAL_WITHOUT_NFTS, value);
  }

  bool getTotalWithoutNfts() {
    return sharedPreferences.getBool(AppConstants.TOTAL_WITHOUT_NFTS) ?? false;
  }

  Future<bool> setHomeFirst(bool value) {
    return sharedPreferences.setBool(AppConstants.HOME_FIRST, value);
  }

  bool getHomeFirst() {
    return sharedPreferences.getBool(AppConstants.HOME_FIRST) ?? false;
  }

  Future<bool> setGlobalSetting(String value) {
    return sharedPreferences.setString(AppConstants.GLOBAL_SETTING, value);
  }

  String getGlobalSettingSF() {
    return sharedPreferences.getString(AppConstants.GLOBAL_SETTING) ?? "{}";
  }

  Future<bool> clearAddress() async {
    await sharedPreferences.setStringList(AppConstants.ADDRESS, []);
    return true;
  }

  Future<bool> clearSharedData() async {
    await sharedPreferences.clear();
    return true;
  }
}
