import 'package:dhadkan/utils/theme/text_theme.dart';
import 'package:flutter/material.dart';

class Display extends StatelessWidget {
  final data;
  const Display({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(children: [
          Text("Name: ", style: MyTextTheme.textTheme.headlineSmall,),
          Text(data['name']!, style: MyTextTheme.textTheme.bodyMedium,),
        ],),
        Row(children: [
          Text("Hospital: ", style: MyTextTheme.textTheme.headlineSmall,),
          Text(data['hospital']!, style: MyTextTheme.textTheme.bodyMedium,),
        ],),
        Row(children: [
          Text("Phone: ", style: MyTextTheme.textTheme.headlineSmall,),
          Text(data['mobile']!, style: MyTextTheme.textTheme.bodyMedium,),
        ],), 
        Row(children: [
          Text("Email: ", style: MyTextTheme.textTheme.headlineSmall,),
          Text(data['email']!, style: MyTextTheme.textTheme.bodyMedium,),
        ],),       
                 
      ],

    );
  }
}