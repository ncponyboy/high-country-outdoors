import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ski_resort.dart';

class SkiService extends ChangeNotifier {
  List<SkiResort> resorts = [];
  bool isLoading = false;
  String? errorMessage;

  static const String _url =
      'https://raw.githubusercontent.com/ncponyboy/high-country-outdoors/main/ski_conditions.json';

  Future<void> fetchResorts() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(_url)).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> rawResorts =
            (data['resorts'] as List<dynamic>?) ?? [];
        resorts = rawResorts
            .whereType<Map<String, dynamic>>()
            .map(SkiResort.fromJson)
            .toList();
        errorMessage = null;
      } else {
        errorMessage =
            'Failed to load ski conditions (${response.statusCode}).';
      }
    } catch (e) {
      errorMessage = 'Could not reach the server. Check your connection.';
      debugPrint('SkiService error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
