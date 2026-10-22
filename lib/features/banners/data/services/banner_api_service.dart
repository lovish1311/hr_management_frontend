import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hr_management/core/network/api_client.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/features/banners/data/models/banner_model.dart';

class BannerApiService {
  const BannerApiService();

  /// Retrieves active live banners for the dashboard carousel
  Future<List<BannerModel>> getActiveBanners({String? department}) async {
    String url = '/api/v1/banners/active';
    if (department != null && department.trim().isNotEmpty) {
      url += '?department=${Uri.encodeComponent(department.trim())}';
    }

    final response = await ApiClient.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => BannerModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load active banners (${response.statusCode}): ${response.body}');
  }

  /// Retrieves distinct corporate departments for targeting
  Future<List<String>> getDepartments() async {
    final response = await ApiClient.get('/api/v1/banners/departments');
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Retrieves filtered feed for the Engage Social Hub (/engage)
  Future<List<BannerModel>> getEngageFeed({
    BannerType? tab,
    CelebrationType? filter,
    String? department,
  }) async {
    final queryParams = <String, String>{};
    if (tab != null) queryParams['tab'] = tab.toServerString();
    if (filter != null) queryParams['filter'] = filter.toServerString();
    if (department != null && department.trim().isNotEmpty) {
      queryParams['department'] = department.trim();
    }

    final uri = Uri(
      path: '/api/v1/banners/engage',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final response = await ApiClient.get(uri.toString());
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => BannerModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load engage feed (${response.statusCode}): ${response.body}');
  }

  /// Toggles or sets social emoji reaction on a banner idempotently
  Future<BannerReactionSummary> toggleReaction(
    int bannerId,
    String reactionType, {
    String? action,
  }) async {
    String url = '/api/v1/banners/$bannerId/react?reactionType=$reactionType';
    if (action != null && action.trim().isNotEmpty) {
      url += '&action=${action.trim().toUpperCase()}';
    }

    final response = await ApiClient.post(url);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return BannerReactionSummary.fromJson(data);
    }
    throw Exception('Failed to update reaction (${response.statusCode}): ${response.body}');
  }

  /// Admin view: retrieves all banners for management console
  Future<List<BannerModel>> getAllBannersForManagement() async {
    final response = await ApiClient.get('/api/v1/banners/manage');
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => BannerModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load management banners (${response.statusCode}): ${response.body}');
  }

  /// Single banner lookup
  Future<BannerModel> getBannerById(int id) async {
    final response = await ApiClient.get('/api/v1/banners/$id');
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return BannerModel.fromJson(data);
    }
    throw Exception('Failed to load banner #$id (${response.statusCode}): ${response.body}');
  }

  /// Creates a new promotional or celebration banner
  Future<BannerModel> createBanner(Map<String, dynamic> payload) async {
    final response = await ApiClient.post(
      '/api/v1/banners',
      body: jsonEncode(payload),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return BannerModel.fromJson(data);
    }
    throw Exception('Failed to create banner (${response.statusCode}): ${response.body}');
  }

  /// Updates an existing banner with version concurrency guard
  Future<BannerModel> updateBanner(int id, Map<String, dynamic> payload) async {
    final response = await ApiClient.put(
      '/api/v1/banners/$id',
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return BannerModel.fromJson(data);
    }
    throw Exception('Failed to update banner #$id (${response.statusCode}): ${response.body}');
  }

  /// Toggles banner active status
  Future<BannerModel> toggleBannerStatus(int id) async {
    final response = await ApiClient.patch('/api/v1/banners/$id/toggle');
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return BannerModel.fromJson(data);
    }
    throw Exception('Failed to toggle banner status (${response.statusCode}): ${response.body}');
  }

  /// Soft deletes / deactivates a banner
  Future<void> deleteBanner(int id) async {
    final response = await ApiClient.delete('/api/v1/banners/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete banner (${response.statusCode}): ${response.body}');
    }
  }

  /// Uploads binary banner image file to server (max 5MB)
  /// Returns the relative image URL (e.g. `/api/v1/banners/images/{filename}`)
  Future<String> uploadImage(List<int> bytes, String filename) async {
    final uri = ApiClient.resolveUri('/api/v1/banners/upload-image');
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll(AuthStorage.authHeaders);
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['imageUrl']?.toString() ?? '';
    }
    throw Exception('Failed to upload image (${response.statusCode}): ${response.body}');
  }
}
