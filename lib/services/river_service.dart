import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/river.dart';

class RiverService extends ChangeNotifier {
  List<River> rivers = [];
  bool isLoading = false;
  String? errorMessage;

  static const String _url =
      'https://raw.githubusercontent.com/ncponyboy/high-country-outdoors/main/rivers.json';

  Future<void> fetchRivers() async {
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
        final List<dynamic> rawRivers =
            (data['rivers'] as List<dynamic>?) ?? [];
        rivers = rawRivers
            .whereType<Map<String, dynamic>>()
            .map(River.fromJson)
            .toList();
        errorMessage = null;
      } else {
        errorMessage =
            'Failed to load river conditions (${response.statusCode}).';
      }
    } catch (e) {
      errorMessage = 'Could not reach the server. Check your connection.';
      debugPrint('RiverService error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
