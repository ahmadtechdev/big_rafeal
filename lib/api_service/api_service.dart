import 'package:dio/dio.dart';
import 'dart:convert';
import '../models/lottery_model.dart';

class ApiService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://lottery.ifdot.shop/api';

  // Fetch all lotteries
  Future<List<Lottery>> fetchLotteries() async {
    try {
      final response = await _dio.get('$_baseUrl/lotteries');

      if (response.statusCode == 200) {
        List<dynamic> lotteryData = response.data['lotteries'];
        return lotteryData.map((json) => Lottery.fromJson(json)).toList();
      } else {
        throw 'Failed to load lotteries with status: ${response.statusCode}';
      }
    } on DioException catch (e) {
      // Handle Dio specific errors
      if (e.response != null) {
        throw 'Failed to load lotteries with status: ${e.response!.statusCode}';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw 'Connection timed out. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        throw 'Cannot connect to server. Please check your internet connection.';
      } else {
        throw 'Something went wrong. Please try again later.';
      }
    } catch (e) {
      throw 'Failed to load lotteries: $e';
    }
  }

  // Register new user
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final headers = {'Content-Type': 'application/json'};

      final data = json.encode({
        "name": name,
        "email": email,
        "role": "user",
        "password": password,
        "phone": phone,
      });

      final response = await _dio.request(
        '$_baseUrl/add_user',
        options: Options(method: 'POST', headers: headers),
        data: data,
      );

      return response.data;
    } on DioException catch (e) {
      // Handle Dio specific errors
      if (e.response != null) {
        // The server responded with an error status code
        if (e.response!.data is Map) {
          final errorMessage =
              e.response!.data['message'] ?? 'Registration failed';
          throw errorMessage;
        } else {
          throw 'Registration failed with status: ${e.response!.statusCode}';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw 'Connection timed out. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        throw 'Cannot connect to server. Please check your internet connection.';
      } else {
        throw 'Something went wrong. Please try again later.';
      }
    } catch (e) {
      throw 'Registration failed: $e';
    }
  }

  // Login user
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final headers = {'Content-Type': 'application/json'};

      final data = json.encode({"email": email, "password": password});

      final response = await _dio.request(
        '$_baseUrl/login',
        options: Options(method: 'POST', headers: headers),
        data: data,
      );

      // Verify the response structure before returning
      if (response.data is Map<String, dynamic>) {
        // Check if the login was successful
        if (response.data['success'] == true &&
            response.data.containsKey('user')) {
          return response.data;
        } else {
          // Handle case where the response is successful but data is incorrect
          throw response.data['message'] ??
              'Login failed: Invalid response format';
        }
      } else {
        throw 'Login failed: Invalid response format';
      }
    } on DioException catch (e) {
      // Handle Dio specific errors
      if (e.response != null) {
        // The server responded with an error status code
        if (e.response!.data is Map) {
          final errorMessage = e.response!.data['message'] ?? 'Login failed';
          throw errorMessage;
        } else {
          throw 'Login failed with status: ${e.response!.statusCode}';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw 'Connection timed out. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        throw 'Cannot connect to server. Please check your internet connection.';
      } else {
        throw 'Something went wrong. Please try again later.';
      }
    } catch (e) {
      throw 'Login failed: $e';
    }
  }
}
