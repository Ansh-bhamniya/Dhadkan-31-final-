import 'package:flutter/cupertino.dart';

import '../../utils/device/device_utility.dart';

class Wrapper extends StatelessWidget {
  final Widget child;
  final double top;
  final double bottom;

  const Wrapper(
      {super.key, required this.child, this.top = 0, this.bottom = 0});

  @override
  Widget build(BuildContext context) {
    var screenWidth = MyDeviceUtils.getScreenWidth(context);
    var paddingWidth = screenWidth * 0.05;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
            left: paddingWidth, right: paddingWidth, top: top, bottom: bottom),
        child: child,
      ),
    );
  }
}
