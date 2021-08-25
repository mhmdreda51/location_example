import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'constance.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Future getWeather() async {
    try {
      var response = await Dio().get(
          'https://api.weatherapi.com/v1/current.json?key=68ea3b75c9c2462787e52106211203&q=$location&aqi=yes');
      Map<String, dynamic> data = jsonDecode(response.toString());
      setState(() {
        country = data['location']['country'].toString();
        location = data['location']['name'].toString();
        temp = data['current']['temp_c'].round();
        time = data['location']['localtime'].toString();
        tempf = data['current']['temp_f'].round();
        humidity = data['current']['humidity'].round();
        wind = data['current']['wind_kph'].round();
        cacheIcon = data['current']['condition']['icon'].toString();
        src = 'https:' + cacheIcon;
        loading = true;
      });
    } on Exception catch (e) {
      print(e.toString().toUpperCase());
    }
  }

  Future getWeatherByLocation(latitude, longitude) async {
    String url =
        'http://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=1597989eb92811c5b84bbcddc8072a37&units=metric';
    var response = await Dio().get(url);
    var convert =
        jsonDecode(response.toString()); // using dio you need only response
    setState(() {
      loading = true;
      location = convert['name'];
      temp = convert['main']['temp'].round();
      humidity = convert['main']['humidity'];
      country = convert['sys']['country'];
    });
  }

  Future getLocation() async {
    var permissionResult = await Permission.locationWhenInUse.status;
    switch (permissionResult) {
      case PermissionStatus.restricted:
      case PermissionStatus.permanentlyDenied:
        print('location permission denied');

        break;
      case PermissionStatus.denied:
        await Permission.locationWhenInUse.request();
        getWeather();
        _showLocationDeniedDialog();
        break;
      case PermissionStatus.granted:
        print('getting location');
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        if (position != null) {
          getWeatherByLocation(position.latitude, position.longitude);
        }
        break;
      default:
    }
  }

  void _showLocationDeniedDialog() {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          // ThemeData appTheme = AppStateContainer.of(context).theme;

          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text('Location is disabled :(',
                style: TextStyle(color: Colors.black)),
            actions: <Widget>[
              TextButton(
                child: Text('Enable!'),
                style: TextButton.styleFrom(
                  // primary: appTheme.accentColor,
                  elevation: 1,
                ),
                onPressed: () {
                  openAppSettings();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  @override
  void initState() {
    super.initState();
    this.getWeather();
    this.getLocation();
  }

  bool loading = false;
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double height = size.height.toDouble();

    return Container(
      decoration: BoxDecoration(
        // background color
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff0e1e29),
            Color(0xff5292a4),
          ],
        ),
      ),
      child: loading
          ? Scaffold(
              backgroundColor: Colors.transparent,
              appBar: buildAppBar(),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            child: buildTextField(),
                            width: size.width / 1.6,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.search,
                              size: 20,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                location = controller.text;
                                controller.text = "";
                                loading = false;
                              });
                              getWeather();
                            },
                          )
                        ],
                      ),
                    ),
                    // buildWeatherIcon(),
                    buildTempField(height),
                    // buildRowData(
                    //   data: tempf.toString() + ' f',
                    //   text: 'Temp in F',
                    // ),
                    SizedBox(height: 10),
                    buildRowData(
                      data: humidity.toString() + ' %',
                      text: 'Humidity',
                    ),
                    SizedBox(height: 10),
                    // buildRowData(
                    //   data: wind.toString() + ' Kph',
                    //   text: 'Wind',
                    // ),
                    SizedBox(height: 10),
                    Divider(thickness: 2),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            )
          : Scaffold(
              body: Container(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
    );
  }

  Image buildWeatherIcon() {
    return Image.network(
      src,
      height: 70,
      width: 70,
      fit: BoxFit.cover,
    );
  }

  Row buildRowData({
    String text,
    String data,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: customGrey,
        ),
        Text(
          data,
          style: customGrey,
        ),
      ],
    );
  }

  FittedBox buildTempField(double height) {
    return FittedBox(
      fit: BoxFit.fill,
      child: Row(
        children: [
          Text(
            temp.toString(),
            style: TextStyle(fontSize: height / 8, color: Colors.white),
          ),
          SizedBox(width: 5),
          Text(
            '°C',
            style: TextStyle(
              fontSize: height / 8.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Search Bar
  TextField buildTextField() {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search City',
        hintStyle: TextStyle(
          color: Colors.grey,
        ),
      ),
      style: TextStyle(
        color: Colors.white,
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            Icons.my_location,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              getLocation();
              // on referesh  weather get updated
            });
          },
        ),
      ],
      title: appData(),
    );
  }

  Column appData() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          time.toString(),
          // time
          style: smallText,
        ),
        SizedBox(height: 7),
        FittedBox(
          fit: BoxFit.fitWidth,
          child: Row(
            children: [
              Icon(
                Icons.room,
                color: Colors.red,
                size: 20,
              ),
              SizedBox(width: 5),
              // location
              Text(
                location.toString() + " ," + country.toString().toUpperCase(),
                style: smallText.copyWith(
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
