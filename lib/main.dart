import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:nwpu_helper/pages/login.dart';
import 'package:nwpu_helper/pages/query_classroom.dart';
import 'package:nwpu_helper/utils/global.dart';

void main() {
  Map<String, dynamic> headers = {
    'Access-Control-Allow-Origin': '*',
    'Host':'us.nwpu.edu.cn',
    'Origin':'http://us.nwpu.edu.cn',
    'Referer':'http://us.nwpu.edu.cn'
  };
  dio.options.headers = headers;
  var cookieJar = CookieJar();
  dio.interceptors.add(CookieManager(cookieJar));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData.dark(),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/queryClassroomPage': (context) => QueryClassroomPage(),
      },
    );
  }
}
