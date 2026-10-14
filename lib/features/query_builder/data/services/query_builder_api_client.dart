import 'dart:convert';
import 'dart:typed_data';
import 'package:hr_management/core/network/api_client.dart';
import '../models/query_ast.dart';
import '../models/query_metadata.dart';
import '../models/query_template.dart';

class QueryBuilderApiClient {
  /// GET /api/query-builder/metadata
  static Future<MetadataCatalog> fetchMetadata() async {
    final response = await ApiClient.get('/api/query-builder/metadata');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return MetadataCatalog.fromJson(data);
    }
    throw Exception('Failed to load query metadata: ${response.statusCode} ${response.body}');
  }

  /// POST /api/query-builder/count
  static Future<QueryCountResult> countQuery(QueryRequest request) async {
    final response = await ApiClient.post(
      '/api/query-builder/count',
      body: jsonEncode(request.toJson()),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return QueryCountResult.fromJson(data);
    }
    throw Exception('Failed to get query count estimate: ${response.statusCode}');
  }

  /// POST /api/query-builder/preview
  static Future<QueryPreviewResult> previewQuery(QueryRequest request) async {
    final response = await ApiClient.post(
      '/api/query-builder/preview',
      body: jsonEncode(request.toJson()),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return QueryPreviewResult.fromJson(data);
    }
    throw Exception('Failed to fetch query preview: ${response.statusCode}');
  }

  /// POST /api/query-builder/export?format=XLSX|CSV
  static Future<Uint8List> exportReport(QueryRequest request, {String format = 'XLSX'}) async {
    final uri = ApiClient.resolveUri('/api/query-builder/export?format=$format');
    final headers = ApiClient.mergeHeaders({
      'Accept': format.toUpperCase() == 'XLSX'
          ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          : 'text/csv',
    });

    final response = await ApiClient.client.post(
      uri,
      headers: headers,
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception('Export failed: ${response.statusCode}');
  }

  /// GET /api/query-builder/templates
  static Future<List<QueryTemplate>> getTemplates() async {
    final response = await ApiClient.get('/api/query-builder/templates');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => QueryTemplate.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// POST /api/query-builder/templates
  static Future<QueryTemplate> createTemplate(QueryTemplate template) async {
    final response = await ApiClient.post(
      '/api/query-builder/templates',
      body: jsonEncode(template.toJson()),
    );
    if (response.statusCode == 200) {
      return QueryTemplate.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to save template: ${response.statusCode}');
  }

  /// DELETE /api/query-builder/templates/{id}
  static Future<void> deleteTemplate(int id) async {
    final uri = ApiClient.resolveUri('/api/query-builder/templates/$id');
    final response = await ApiClient.client.delete(uri, headers: ApiClient.mergeHeaders());
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete template: ${response.statusCode}');
    }
  }
}
