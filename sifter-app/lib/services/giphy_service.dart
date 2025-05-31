import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../core/error/error_handler.dart';
import '../core/error/error_types.dart';

/// Model for Giphy GIF data
class GiphyGif {
  final String id;
  final String title;
  final String url;
  final String previewUrl;
  final int width;
  final int height;

  GiphyGif({
    required this.id,
    required this.title,
    required this.url,
    required this.previewUrl,
    required this.width,
    required this.height,
  });

  factory GiphyGif.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>?;
    final original = images?['original'] as Map<String, dynamic>?;
    final preview = images?['preview_gif'] as Map<String, dynamic>?;

    return GiphyGif(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      url: original?['url'] ?? '',
      previewUrl: preview?['url'] ?? original?['url'] ?? '',
      width: int.tryParse(original?['width']?.toString() ?? '0') ?? 0,
      height: int.tryParse(original?['height']?.toString() ?? '0') ?? 0,
    );
  }
}

/// Service for interacting with Giphy API
class GiphyService {
  static const String _baseUrl = 'https://api.giphy.com/v1';
  static const String _apiKey = ApiConfig.giphyApiKey;

  /// Search for GIFs with a query
  Future<List<GiphyGif>> searchGifs({
    required String query,
    int limit = 25,
    int offset = 0,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/gifs/search').replace(queryParameters: {
        'api_key': _apiKey,
        'q': query,
        'limit': limit.toString(),
        'offset': offset.toString(),
        'rating': 'g', // Keep it family-friendly
        'lang': 'en',
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final gifs = (data['data'] as List<dynamic>?)
                ?.map((gifData) =>
                    GiphyGif.fromJson(gifData as Map<String, dynamic>))
                .toList() ??
            [];

        return gifs;
      } else {
        throw NetworkError('Failed to search GIFs: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      ErrorHandler().handleError(
        e,
        stackTrace: stackTrace,
        category: ErrorCategory.network,
        severity: ErrorSeverity.medium,
        context: {'action': 'search_gifs', 'query': query},
      );
      debugPrint('Error searching GIFs: $e');
      return [];
    }
  }

  /// Get trending GIFs
  Future<List<GiphyGif>> getTrendingGifs({
    int limit = 25,
    int offset = 0,
  }) async {
    try {
      final uri =
          Uri.parse('$_baseUrl/gifs/trending').replace(queryParameters: {
        'api_key': _apiKey,
        'limit': limit.toString(),
        'offset': offset.toString(),
        'rating': 'g',
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final gifs = (data['data'] as List<dynamic>?)
                ?.map((gifData) =>
                    GiphyGif.fromJson(gifData as Map<String, dynamic>))
                .toList() ??
            [];

        return gifs;
      } else {
        throw NetworkError(
            'Failed to get trending GIFs: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      ErrorHandler().handleError(
        e,
        stackTrace: stackTrace,
        category: ErrorCategory.network,
        severity: ErrorSeverity.medium,
        context: {'action': 'get_trending_gifs'},
      );
      debugPrint('Error getting trending GIFs: $e');
      return [];
    }
  }

  /// Get popular reaction GIFs
  Future<List<GiphyGif>> getReactionGifs() async {
    const reactionTerms = [
      'thumbs up',
      'heart love',
      'laughing funny',
      'surprised wow',
      'crying sad',
      'angry mad',
      'celebrate party',
      'clapping applause',
      'fire awesome',
    ];

    final List<GiphyGif> reactionGifs = [];

    for (final term in reactionTerms) {
      try {
        final gifs = await searchGifs(query: term, limit: 1);
        if (gifs.isNotEmpty) {
          reactionGifs.add(gifs.first);
        }
      } catch (e) {
        // Continue with other terms if one fails
        debugPrint('Failed to get reaction GIF for term: $term');
      }
    }

    return reactionGifs;
  }
}

/// Provider for GiphyService
final giphyServiceProvider = Provider<GiphyService>((ref) {
  return GiphyService();
});
