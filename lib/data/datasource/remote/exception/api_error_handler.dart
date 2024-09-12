import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../repository/base/error_response.dart';

class ApiErrorHandler {
  static dynamic getMessage(error) {
    dynamic errorDescription = "";
    if (error is Exception) {
      try {
        if (error is DioError) {
          switch (error.type) {
            case DioExceptionType.cancel:
              errorDescription = "Request to API server was cancelled";
              break;
            case DioExceptionType.connectionTimeout:
              errorDescription = "Connection timeout with API server";
              break;
            case DioExceptionType.unknown:
              errorDescription =
                  "Connection to API server failed due to internet connection";
              break;
            case DioExceptionType.receiveTimeout:
              errorDescription =
                  "Receive timeout in connection with API server";
              break;
            case DioExceptionType.badCertificate:
              errorDescription = "Certificate problem";
              break;
            case DioExceptionType.connectionError:
              errorDescription = "Connection error";
              break;
            case DioExceptionType.badResponse:
              switch (error.response!.statusCode) {
                case 400:
                  errorDescription = error.response?.data;
                  print("errorDescription " + errorDescription);
                  break;
                case 404:
                case 500:
                case 503:
                  errorDescription = error.response?.statusMessage;
                  break;
                default:
                  late ErrorResponse errorResponse;
                  try {
                    errorResponse =
                        ErrorResponse.fromJson(error.response?.data ?? {});
                    debugPrint("errorResponse " + errorResponse.toString());
                  } catch (e) {
                    debugPrint("DioError " + e.toString());
                    errorDescription = "Something Went Wrong";
                    break;
                  }
                  if (errorResponse.errors.isNotEmpty) {
                    errorDescription = errorResponse;
                  } else {
                    errorDescription =
                        "Failed to load data - status code: ${error.response?.statusCode ?? ""}";
                  }
              }
              break;
            case DioExceptionType.sendTimeout:
              errorDescription = "Send timeout with server";
              break;
          }
        } else {
          errorDescription = "Unexpected error occured";
        }
      } on FormatException catch (e) {
        errorDescription = e.toString();
      }
    } else {
      errorDescription = "is not a subtype of exception";
    }
    return errorDescription;
  }
}
