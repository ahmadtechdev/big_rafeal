import 'package:dio/dio.dart';
import 'dart:convert';
import '../models/banner_model.dart';
import '../models/lottery_model.dart';
import '../models/user_lottery_modal.dart';

class ApiService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://bigrafeal.info/api';

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

  // Add this method to your ApiService class
  Future<List<BannerModal>> fetchBanners() async {
    try {
      final response = await _dio.get('$_baseUrl/banners');

      if (response.statusCode == 200) {
        List<dynamic> bannerData = response.data['banners'];
        return bannerData.map((json) => BannerModal.fromJson(json)).toList();
      } else {
        throw 'Failed to load banners with status: ${response.statusCode}';
      }
    } on DioException catch (e) {
      // Handle Dio specific errors
      if (e.response != null) {
        throw 'Failed to load banners with status: ${e.response!.statusCode}';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw 'Connection timed out. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        throw 'Cannot connect to server. Please check your internet connection.';
      } else {
        throw 'Something went wrong. Please try again later.';
      }
    } catch (e) {
      throw 'Failed to load banners: $e';
    }
  }

  // Add to api_service.dart
  Future<Map<String, dynamic>> saveLotterySale({
    required int userId,
    required String userName,
    required String userEmail,
    required String userNumber,
    required String lotteryName,
    required String purchasePrice,
    required String winningPrice,
    required String lotteryCode,
    required String endDate,
    required String numberOfLottery,
    required String selectedNumbers,
    required String ticketId,
    String winOrLoss = "loss",
  }) async {
    try {
      final headers = {'Content-Type': 'application/json'};



      final data = json.encode({
        "user_id": userId.toString(),
        "ticket_id": ticketId,
        "User_name": userName,
        "User_email": userEmail,
        "User_number": userNumber,
        "lottery_name": lotteryName,
        "purchase_price": purchasePrice,
        "winning_price": winningPrice,
        "image": "", // Default value
        "lottery_code": lotteryCode,
        "end_date": endDate,
        "number_of_lottery": numberOfLottery,
        "lottery_issue_date": DateTime.now().toIso8601String(),
        "selected_numbers": selectedNumbers,
        "w_or_l": winOrLoss
      });

      // Debug log

      final response = await _dio.request(
        '$_baseUrl/add_lottery',
        options: Options(method: 'POST', headers: headers),
        data: data,
      );

      // Debug log

      return response.data;
    } on DioException catch (e) {
      // Debug log
      if (e.response != null) {
        // Debug log
        // Debug log

        if (e.response!.data is Map) {
          final errorMessage = e.response!.data['message'] ?? 'Sale saving failed';
          throw errorMessage;
        } else {
          throw 'Sale saving failed with status: ${e.response!.statusCode}';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw 'Connection timed out. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        throw 'Cannot connect to server. Please check your internet connection.';
      } else {
        throw 'Something went wrong. Please try again later.';
      }
    } catch (e) {
      // Debug log
      throw 'Sale saving failed: $e';
    }
  }

  // Add this to api_service.dart
  Future<bool> checkUserExists(int userId) async {
    try {
      final response = await _dio.get('$_baseUrl/users');

      if (response.statusCode == 200) {
        List<dynamic> users = response.data['user'];
        return users.any((user) => user['id'] == userId);
      } else {
        throw 'Failed to check user existence with status: ${response.statusCode}';
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw 'Failed to check user existence with status: ${e.response!.statusCode}';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw 'Connection timed out. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        throw 'Cannot connect to server. Please check your internet connection.';
      } else {
        throw 'Something went wrong. Please try again later.';
      }
    } catch (e) {
      throw 'Failed to check user existence: $e';
    }
  }



  Future<List<UserLottery>> fetchUserLotteries(int userId) async {
    try {
      final response = await _dio.get('$_baseUrl/shop_lottery/$userId');

      if (response.statusCode == 200) {
        List<dynamic> lotteryData = response.data['lotteries'];
        return lotteryData.map((json) => UserLottery.fromJson(json)).toList();
      } else {
        throw 'Failed to load user lotteries with status: ${response.statusCode}';
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw 'Failed to load user lotteries with status: ${e.response!.statusCode}';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw 'Connection timed out. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        throw 'Cannot connect to server. Please check your internet connection.';
      } else {
        throw 'Something went wrong. Please try again later.';
      }
    } catch (e) {
      throw 'Failed to load user lotteries: $e';
    }
  }

}
