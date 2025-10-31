import 'package:dhadkan/utils/device/device_utility.dart';
import 'package:dhadkan/utils/theme/text_theme.dart';
import 'package:flutter/cupertino.dart';

class TextMessage extends StatelessWidget {
  final String text;
  final bool mine;
  final String time;

  const TextMessage({
    super.key,
    required this.text,
    required this.mine,
    this.time = '',
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MyDeviceUtils.getScreenWidth(context);
    double maxWidth = screenWidth * 0.7;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0), // Equal padding on all sides
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      text,
                      style: MyTextTheme.textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: MyTextTheme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: const Color(0xFF888888),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}