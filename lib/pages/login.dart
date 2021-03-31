import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nwpu_helper/constant/constants.dart';
import 'package:nwpu_helper/utils/global.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final accountTextController;
  late final passwordTextController;
  late final rememberedPassword;
  bool rememberPassword = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs().whenComplete(() {
      setState(() {});
    });
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    rememberPassword = prefs.getBool(Constants.REMEMBER_PASSWORD) ?? false;
    rememberedPassword = rememberPassword;
    accountTextController = TextEditingController(
        text: prefs.getString(Constants.STUDENT_NUMBER) ?? '');
    passwordTextController = TextEditingController(
        text:
            rememberPassword ? prefs.getString(Constants.PASSWORD) ?? '' : '');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);

        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: size.height / 4,
              ),
              Text(
                "登录页面",
                style: Theme.of(context).textTheme.headline4,
              ),
              SizedBox(
                height: size.height / 8,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: AccountTextField(
                  controller: accountTextController,
                ),
              ),
              SizedBox(
                height: size.height / 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: PasswordTextField(
                  controller: passwordTextController,
                  enableShowPassword: !rememberedPassword,
                ),
              ),
              SizedBox(
                height: size.height / 40,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 120.0),
                child: CheckboxListTile(
                  title: Text("记住密码"),
                  value: rememberPassword,
                  onChanged: (bool? value) {
                    setState(() {
                      rememberPassword = value ?? false;
                    });
                  },
                ),
              ),
              SizedBox(
                height: size.height / 20,
              ),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  prefs.setBool(Constants.REMEMBER_PASSWORD, rememberPassword);
                  if (rememberPassword)
                    prefs.setString(
                        Constants.PASSWORD, passwordTextController.text);
                  prefs.setString(
                      Constants.STUDENT_NUMBER, accountTextController.text);
                  login(context);
                },
                child: SizedBox(
                  width: size.width / 2,
                  height: 40,
                  child: Center(
                    child: Text(
                      "登录",
                      style: TextStyle(fontSize: 14.0),
                    ),
                  ),
                ),
                style: ButtonStyle(
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21.11))),
                    backgroundColor: MaterialStateProperty.all(
                        Theme.of(context).accentColor)),
              )
            ],
          ),
        ),
      ),
    );
  }

  void login(BuildContext context) async {
    await dio.get('http://us.nwpu.edu.cn/eams/login.action');
    dio
        .post('http://us.nwpu.edu.cn/eams/login.action',
            data: {
              "username": accountTextController.text,
              "password": passwordTextController.text,
              "encodedPassword": '',
              "session_locale": 'zh_CN'
            },
            options: Options(contentType: Headers.formUrlEncodedContentType))
        .then((response) {
      var result = response.data.toString();
      if (result.contains('密码错误')) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('登录失败，密码错误')));
      } else if (result.contains('账户不存在')) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('登录失败，账户不存在')));
      } else if (result.contains('验证码不正确')) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('登录失败，失败尝试过多，请尝试更换网络环境')));
      }
    }).onError((DioError error, _) {
      if (error.response?.statusCode == 302) {
        Navigator.pushReplacementNamed(context, '/queryClassroomPage');
      }
    });
  }
}

class AccountTextField extends StatelessWidget {
  final controller;

  const AccountTextField(
      {Key? key, required TextEditingController this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
          labelText: "学号",
          fillColor: Colors.grey.withOpacity(0.1),
          filled: true,
          prefixIcon: Icon(Icons.person),
          contentPadding: EdgeInsets.all(5),
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(21.11))),
    );
  }
}

class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final bool enableShowPassword;

  const PasswordTextField(
      {Key? key, required this.controller, required this.enableShowPassword})
      : super(key: key);

  @override
  _PasswordTextFieldState createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool passwordVisibility = false;
  bool enableShowPassword = false;

  @override
  void initState() {
    super.initState();
    enableShowPassword = widget.enableShowPassword;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: !passwordVisibility,
      enableSuggestions: false,
      autocorrect: false,
      decoration: InputDecoration(
          labelText: "密码",
          fillColor: Colors.grey.withOpacity(0.1),
          filled: true,
          prefixIcon: Icon(Icons.lock),
          suffixIcon: IconButton(
            splashRadius: 20.0,
            icon: enableShowPassword
                ? Icon(passwordVisibility
                    ? Icons.remove_red_eye_outlined
                    : Icons.remove_red_eye_rounded)
                : Icon(Icons.backspace_outlined),
            onPressed: () {
              if (enableShowPassword) {
                setState(() {
                  passwordVisibility = !passwordVisibility;
                });
              } else {
                widget.controller.clear();
                setState(() {
                  enableShowPassword = true;
                });
              }
            },
          ),
          contentPadding: EdgeInsets.all(5),
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(21.11))),
    );
  }
}
