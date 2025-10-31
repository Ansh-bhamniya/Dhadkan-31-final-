// lib/utils/phone_number_parser.dart

class PhoneNumberParser {
  // Converts spoken numbers to actual digits
  static String textToPhoneNumber(String input) {
    final Map<String, String> numberMap = {
      'zero': '0',
      'oh': '0',        // common for "0"
      'one': '1',
      'two': '2',
      'too': '2',       // handle misrecognitions
      'three': '3',
      'four': '4',
      'for': '4',       // handle misrecognitions
      'five': '5',
      'six': '6',
      'seven': '7',
      'eight': '8',
      'ate': '8',       // handle misrecognitions
      'nine': '9',
    };

    String result = '';
    input = input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ,]'), ''); // clean input
    List<String> parts = input.split(RegExp(r'[ ,]+')); // split by comma or space

    for (int i = 0; i < parts.length; i++) {
      String part = parts[i];

      // Handle "triple", "double" etc.
      if (part == 'triple' && i + 1 < parts.length) {
        String? digit = numberMap[parts[i + 1]];
        if (digit != null) {
          result += digit * 3;
          i++;
        }
      } else if (part == 'double' && i + 1 < parts.length) {
        String? digit = numberMap[parts[i + 1]];
        if (digit != null) {
          result += digit * 2;
          i++;
        }
      } else if (numberMap.containsKey(part)) {
        result += numberMap[part]!;
      } else if (RegExp(r'\d').hasMatch(part)) {
        result += part;
      }
    }

    return result;
  }
}
