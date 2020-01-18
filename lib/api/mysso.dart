import 'package:custed2/locator.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart' hide Headers;

part 'mysso.g.dart';

@RestApi(baseUrl: "http://mysso-cust-edu-cn-s.webvpn.cust.edu.cn:8118/")
abstract class MyssoApi {
  factory MyssoApi() => _MyssoApi(_buildDio());

  static Dio _buildDio() {
    return locator<Dio>()
      ..options.contentType = Headers.formUrlEncodedContentType;
  }

  @GET("/cas/login")
  Future<String> getLoginPage();

  @POST("/cas/login")
  Future<String> login(@Body() MyssoLoginData data);
}

class MyssoLoginData {
  MyssoLoginData({
    this.username,
    this.password,
    this.execution,
  });

  String username;
  String password;
  String execution;

  Map<String, String> toJson() => {
        'username': username,
        'password': password,
        'execution': execution,
        '_eventId': 'submit',
        'geolocation': '',
      };
}