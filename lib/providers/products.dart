import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop_app/models/http_exception.dart';
import 'package:shop_app/providers/product.dart';

class Products with ChangeNotifier {
  List<Product> _items = [
    // Product(
    //   id: 'p1',
    //   title: 'Red Shirt',
    //   description: 'A red shirt - it is pretty red!',
    //   price: 29.99,
    //   imageUrl:
    //       'https://cdn.pixabay.com/photo/2016/10/02/22/17/red-t-shirt-1710578_1280.jpg',
    // ),
    // Product(
    //   id: 'p2',
    //   title: 'Trousers',
    //   description: 'A nice pair of trousers.',
    //   price: 59.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Trousers%2C_dress_%28AM_1960.022-8%29.jpg/512px-Trousers%2C_dress_%28AM_1960.022-8%29.jpg',
    // ),
    // Product(
    //   id: 'p3',
    //   title: 'Yellow Scarf',
    //   description: 'Warm and cozy - exactly what you need for the winter.',
    //   price: 19.99,
    //   imageUrl:
    //       'https://live.staticflickr.com/4043/4438260868_cc79b3369d_z.jpg',
    // ),
    // Product(
    //   id: 'p4',
    //   title: 'A Pan',
    //   description: 'Prepare any meal you want.',
    //   price: 49.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Cast-Iron-Pan.jpg/1024px-Cast-Iron-Pan.jpg',
    // ),
  ];
  final String? authToken;
  final String? userId;

  Products(this.authToken, this._items, this.userId);

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    final filterString = filterByUser ? 'orderBy="creatorId"&equalTo="$userId"' : "";
    final String URL =
        'https://flutter-test-672fc-default-rtdb.firebaseio.com/products.json?auth=$authToken&$filterString';
    try {
      final response = await http.get(Uri.parse(URL));
      final Map<String, dynamic>? extractedData =
          json.decode(response.body) as Map<String, dynamic>;
      final List<Product> loadedProducts = [];
      if (extractedData == null) {
        return;
      }
      final favouritesRequestUrl =
          "https://flutter-test-672fc-default-rtdb.firebaseio.com/userFavourites/$userId.json?auth=$authToken";
      final favResponse = await http.get(Uri.parse(favouritesRequestUrl));
      final favData = json.decode(favResponse.body);

      extractedData.forEach((productId, productData) {
        loadedProducts.add(Product(
            id: productId,
            title: productData['title'],
            description: productData['description'],
            price: productData['price'],
            imageUrl: productData['imageUrl'],
            isFavourite:
                favData == null ? false : (favData[productId] == null ? false : favData[productId]['isFavourite'])));
      });
      print(json.decode(response.body));
      _items = loadedProducts;
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((product) => product.isFavourite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((item) => id == item.id);
  }

  Future<void> addProduct(Product product) async {
    final String URL =
        'https://flutter-test-672fc-default-rtdb.firebaseio.com/products.json?auth=$authToken';
    try {
      final response = await http.post(Uri.parse(URL),
          body: json.encode({
            'title': product.title,
            'description': product.description,
            'price': product.price,
            'imageUrl': product.imageUrl,
            'creatorId': userId
          }));

      Product newProduct = new Product(
          id: json.decode(response.body)['name'],
          title: product.title,
          description: product.description,
          price: product.price,
          imageUrl: product.imageUrl);
      _items.add(newProduct);
      notifyListeners();
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    int index = _items.indexWhere((product) => product.id == id);
    if (index >= 0) {
      final String url =
          'https://flutter-test-672fc-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken';
      try {
        await http.patch(Uri.parse(url),
            body: json.encode({
              'title': newProduct.title,
              'description': newProduct.description,
              'imageUrl': newProduct.imageUrl,
              'price': newProduct.price,
              'isFavourite': newProduct.isFavourite,
            }));
        _items[index] = newProduct;
        notifyListeners();
      } catch (error) {
        throw error;
      }
    } else {
      print("No product ID found!");
    }
  }

  Future<void> deleteProduct(String id) async {
    final String url =
        'https://flutter-test-672fc-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken';
    final existingProductIndex =
        _items.indexWhere((product) => product.id == id);
    Product? existingProduct = _items[existingProductIndex];

    _items.removeAt(existingProductIndex);
    notifyListeners();
    final response = await http.delete(Uri.parse(url));

    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not delete product!');
    }
    existingProduct = null;
  }
}
