import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:shop_app/models/http_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Auth with ChangeNotifier {
  String? _token;
  DateTime? _expiryDate;
  String? _userId;
  Timer? _authTimer;

  bool get isAuth {
    return token != null;
  }

  String? get token {
    if (_expiryDate != null && _expiryDate!.isAfter(DateTime.now()) && _token != null) {
      return _token;
    }
    return null;
  }

  String? get userId {
    return _userId;
  }

  Future<void> signUp(String email, String password) async {
        return _authenticate(email, password, 'signUp');
  }

  Future<void> signIn(String email, String password) async {
        return _authenticate(email, password, 'signInWithPassword');
  }

  Future<void> logout() async {
    _expiryDate = null;
    _token = null;
    _userId = null;
    if (_authTimer != null) {
      _authTimer!.cancel();
    }
    notifyListeners();
    final preps = await SharedPreferences.getInstance();
    preps.remove('userData');
  }

  void _autoLogout() {
    final timeToExpiry = _expiryDate?.difference(DateTime.now()).inSeconds;
    if (_authTimer != null) {
      _authTimer!.cancel();
      _authTimer = null;
    }
    if (timeToExpiry != null) {
      _authTimer = Timer(Duration(seconds: timeToExpiry), logout);
    }
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return false;
    }
    final extractedUserData = prefs.getString('userData') == null ? null : json.decode(prefs.getString('userData')!) as Map;
    final expiryDate = extractedUserData == null ? null : DateTime.parse(extractedUserData['expiryDate'] as String);

    if (expiryDate != null && expiryDate.isBefore(DateTime.now())) {
      return false;
    }

    _token = extractedUserData == null ? null : extractedUserData['token'] as String;
    _userId = extractedUserData == null ? null : extractedUserData['userId'] as String;
    _expiryDate = extractedUserData == null ? null : DateTime.parse(extractedUserData['expiryDate'] as String);
    notifyListeners();
    _autoLogout();

    return true;
  }

  Future<void> _authenticate(String email, String password, String urlSegment) async {
    String url =
        "https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=AIzaSyCblCuTxM_YsGvB-A5JpYIZb0n5LlyTD-4";
        try {
          final response = await http.post(Uri.parse(url), body: json.encode({
          'email': email,
          'password': password,
          'returnSecureToken': true
        }));
        final responseData = json.decode(response.body);
        if (responseData['error'] != null) {
          throw HttpException(responseData['error']['message']);
        }
        _token = responseData['idToken'];
        _userId = responseData['localId'];
        _expiryDate = DateTime.now().add(Duration(seconds: int.parse(responseData['expiresIn'])));
        _autoLogout();
        notifyListeners();

        final prefs = await SharedPreferences.getInstance();
        final userData = json.encode({
          'token': _token,
          'userId': _userId,
          'expiryDate': _expiryDate!.toIso8601String()
        });
        prefs.setString('userData', userData);
        } catch (error) {
          throw error;
        }
  }
}
