import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Product with ChangeNotifier {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  bool isFavourite;

  Product(
      {required this.id,
      required this.title,
      required this.description,
      required this.price,
      required this.imageUrl,
      this.isFavourite = false});

      void _setFavouriteValue(bool newValue) {
        isFavourite = newValue;
        notifyListeners();
      }

  Future<void> toggleFavoriteStatus(String token, String userId) async {
    final oldStatus = isFavourite;
    this.isFavourite = !isFavourite;
    notifyListeners();
    final String url =
        'https://flutter-test-672fc-default-rtdb.firebaseio.com/userFavourites/$userId/$id.json?auth=$token';
    try {
      final response = await http.put(Uri.parse(url),
          body: json.encode({'isFavourite': isFavourite}));
      if (response.statusCode >= 400) {
        _setFavouriteValue(oldStatus);
      }
    } catch (error) {
      _setFavouriteValue(oldStatus);
    }
  }
}
