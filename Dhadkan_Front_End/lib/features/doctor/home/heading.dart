import 'package:dhadkan/features/doctor/home/display.dart';
import 'package:dhadkan/utils/device/device_utility.dart';
import 'package:dhadkan/utils/http/http_client.dart';
import 'package:dhadkan/utils/storage/secure_storage_service.dart';
import 'package:flutter/material.dart';

class Heading extends StatefulWidget {
  const Heading({super.key});

  @override
  State<Heading> createState() => _HeadingState();
}

class _HeadingState extends State<Heading> {
  String _token = "";

  Map<String, dynamic> doctorDetails = {
    "name": " ",
    "hospital": " ",
    "mobile": " ",
    "email": " ",

  };

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  _initialize() async {
    String? token = await SecureStorageService.getData('authToken');
    setState(() {
      _token = token ?? '';
    });

  

    try {
      Map<String, dynamic> response = await MyHttpHelper.private_post(
          '/auth/get-details', {}, _token);
      if (response['success'] == 'true'){
        setState(() {
          doctorDetails = response['data'];
          //print(response['data']);
        });
        return;
      }
    }catch(e){
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Error in loading_data")));
      //print(e);
    }
  }





  @override
  Widget build(BuildContext context) {
    double screenWidth = MyDeviceUtils.getScreenWidth(context);
    double width = screenWidth * 0.9;



    return Container(
      height: 140,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 90,
              width: 90,

              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Image.asset('assets/Images/doctor2.png',
              fit: BoxFit.cover,),
            ),
            const SizedBox(width: 20),
            Display(data: doctorDetails),
          ],
        ),
      ),
    );
  }
}
