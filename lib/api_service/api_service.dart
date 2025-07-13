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
  Future<Map<String, dynamic>> saveLotterySale({
    required int userId,
    required int lotteryId,
    required String selectedNumbers,
    required double purchasePrice,
    required int category,
    required String uniqueId,
    int? cancel,
  }) async {
    try {
      final headers = {'Content-Type': 'application/json'};

      final data = json.encode({
        "user_id": userId.toString(),
        "lottery_id": lotteryId.toString(),
        "selected_numbers": selectedNumbers,
        "purchase_price": purchasePrice.toString(),
        "category": category.toString(),
        "uniqueID": uniqueId,
        if (cancel != null) 'cancel': cancel.toString(),
      });

      final response = await _dio.request(
        '$_baseUrl/add_lottery',
        options: Options(method: 'POST', headers: headers),
        data: data,
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
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
      throw 'Sale saving failed: $e';
    }
  }

  // In api_service.dart
  Future<Map<String, dynamic>> fetchSalesReport({
    required int userId,
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final response = await _dio.request(
        '$_baseUrl/report?user_id=$userId&from_date=$fromDate&to_date=$toDate',
        options: Options(method: 'POST'),
      );
        print("AHmad");
        print(response.data);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw 'Failed to load sales report with status: ${response.statusCode}';
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw 'Failed to load sales report with status: ${e.response!.statusCode}';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw 'Connection timed out. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        throw 'Cannot connect to server. Please check your internet connection.';
      } else {
        throw 'Something went wrong. Please try again later.';
      }
    } catch (e) {
      throw 'Failed to load sales report: $e';
    }
  }
  // In api_service.dart
  Future<List<UserLottery>> fetchUserTickets(int userId) async {
    try {
      final response = await _dio.get('$_baseUrl/get-tickets/$userId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        List<dynamic> ticketData = response.data['tickets'];
        return ticketData.map((json) => UserLottery.fromJson(json)).toList();
      } else {
        throw 'Failed to load tickets: ${response.data['message']}';
      }
    } on DioException catch (e) {
      // Handle Dio specific errors
      if (e.response != null) {
        throw 'Failed to load tickets with status: ${e.response!.statusCode}';
      } else {
        throw 'Failed to load tickets: ${e.message}';
      }
    } catch (e) {
      throw 'Failed to load tickets: $e';
    }
  }

  Future<Map<String, dynamic>> checkTicketResult(String ticketId) async {
    try {
      final response = await _dio.request(
        '$_baseUrl/scan-qr?order_id=$ticketId',
        // '$_baseUrl/scan-qr?ticket_id=36',
        options: Options(method: 'POST'),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        // Handle cases where status code is not 200 but still returns valid data
        if (response.data is Map && response.data.containsKey('success')) {
          return response.data;
        }
        throw 'Failed to check ticket result with status: ${response.statusCode}';
      }
    } on DioException catch (e) {
      if (e.response != null) {
        // Handle cases where server returns error responses with data
        if (e.response!.data is Map && e.response!.data.containsKey('success')) {
          return e.response!.data;
        }
        throw 'Failed to check ticket result with status: ${e.response!.statusCode}';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw 'Connection timed out. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        throw 'Cannot connect to server. Please check your internet connection.';
      } else {
        throw 'Something went wrong. Please try again later.';
      }
    } catch (e) {
      throw 'Failed to check ticket result: $e';
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

  // Add this to api_service.dart
  Future<Map<String, dynamic>> claimTickets({
    required String orderId,
    required String userId,
  }) async {
    try {
      final data = FormData.fromMap({
        'order_id': orderId,
        'user_id': userId,
      });

      final response = await _dio.request(
        '$_baseUrl/claim-tickets',
        options: Options(method: 'POST'),
        data: data,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw 'Failed to claim tickets with status: ${response.statusCode}';
      }
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response!.data is Map) {
          final errorMessage = e.response!.data['message'] ?? 'Ticket claim failed';
          throw errorMessage;
        } else {
          throw 'Ticket claim failed with status: ${e.response!.statusCode}';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw 'Connection timed out. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        throw 'Cannot connect to server. Please check your internet connection.';
      } else {
        throw 'Something went wrong. Please try again later.';
      }
    } catch (e) {
      throw 'Ticket claim failed: $e';
    }
  }

  Future<Map<String, dynamic>> cancelTicket(String orderId, int userId) async {
    try {

      final response = await _dio.request(
        '$_baseUrl/cancel-tickets',
        options: Options(method: 'POST'),
        data: {
          'order_id': orderId,
          'user_id': userId.toString(),
        },
      );



      print(response.data);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw 'Failed to cancel ticket with status: ${response.statusCode}';
      }
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response!.data is Map) {
          final errorMessage = e.response!.data['message'] ?? 'Ticket cancellation failed';
          throw errorMessage;
        } else {
          throw 'Ticket cancellation failed with status: ${e.response!.statusCode}';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw 'Connection timed out. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        throw 'Cannot connect to server. Please check your internet connection.';
      } else {
        throw 'Something went wrong. Please try again later.';
      }
    } catch (e) {
      throw 'Ticket cancellation failed: $e';
    }
  }
}