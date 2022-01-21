import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/providers/auth.dart';
import 'package:shop_app/providers/cart.dart';
import 'package:shop_app/providers/orders.dart';
import 'package:shop_app/providers/products.dart';
import 'package:shop_app/screens/auth_screen.dart';
import 'package:shop_app/screens/cart_screen.dart';
import 'package:shop_app/screens/edit_product_screen.dart';
import 'package:shop_app/screens/orders_screen.dart';
import 'package:shop_app/screens/product_detail_screen.dart';
import 'package:shop_app/screens/products_overview_screen.dart';
import 'package:shop_app/screens/splash_screen.dart';
import 'package:shop_app/screens/user_products_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => Auth()),
        ChangeNotifierProxyProvider<Auth, Products>(
          update: (ctx, auth, previousProducts) => Products(
              auth.token ?? null, previousProducts!.items, auth.userId ?? null),
          create: (ctx) => Products("null", [], ""),
        ),
        ChangeNotifierProvider(create: (context) => Cart()),
        ChangeNotifierProxyProvider<Auth, Orders>(
          update: (ctx, auth, previousOrders) =>
              Orders(auth.token!, previousOrders!.orders, auth.userId!),
          create: (ctx) => Orders("null", [], "null"),
        )
      ],
      child: Consumer<Auth>(
          builder: (ctx, authData, child) => MaterialApp(
                title: 'Flutter Demo',
                theme: ThemeData(
                    primarySwatch: Colors.purple,
                    accentColor: Colors.deepOrange,
                    fontFamily: 'Lato'),
                home: authData.isAuth
                    ? ProductsOverviewScreen()
                    : FutureBuilder(
                        future: authData.tryAutoLogin(),
                        builder: (ctx, authResultSnapshot) =>
                            authResultSnapshot.connectionState ==
                                    ConnectionState.waiting
                                ? SplashScreen()
                                : AuthScreen(),
                      ),
                routes: {
                  ProductDetailScreen.ROUTE_NAME: (context) =>
                      ProductDetailScreen(),
                  CartScreen.ROUTE_NAME: (context) => CartScreen(),
                  OrdersScreen.ROUTE_NAME: (context) => OrdersScreen(),
                  UserProductsScreen.ROUTE_NAME: (context) =>
                      UserProductsScreen(),
                  EditProductScreen.ROUTE_NAME: (context) =>
                      EditProductScreen(),
                  AuthScreen.ROUTE_NAME: (context) => AuthScreen()
                },
              )),
    );
  }
}
