class JsonParse {
  final String input;
  int cursor;
  JsonParse(this.input) : cursor = 0;
  bool get isEOF => cursor >= input.length;
  String get currentChar =>input[cursor];
  void skipWhitespace() {
    while (!isEOF && ' \n\t\r'.contains(currentChar)) {
      cursor++;
    }
  }

  void expect(String expected) {
    if (currentChar!= expected) {
      throw FormatException("Expected '$expected' at position $cursor");
    }
    cursor++;
  }

  dynamic parse() {
    skipWhitespace();
    final result = parseValue();
    skipWhitespace();
    if (!isEOF) {
      throw FormatException(
        "Unexpected content after JSON value at position: $cursor",
      );
    }
    return result;
  }

  dynamic parseValue() {
    skipWhitespace();
    switch (currentChar) {
      case '{':
        return parseObject();
      case '[':
        return parseArray();
      case '"':
        return parseString();
      default:
        if (!isEOF &&
            ('-'.startsWith(currentChar) ||
                RegExp(r'[0-9]').hasMatch(currentChar))) {
          return parseNumber();
        } else {
          return parseLiteral();
        }
    }
  }

  Map<String, dynamic> parseObject() {
    final map = <String, dynamic>{};
    cursor++; // skip '{'
    skipWhitespace();

    while (currentChar!= '}') {
      if (map.isNotEmpty) expect(',');
      final key = parseString();
      skipWhitespace();
      expect(':');
      skipWhitespace();
      final value = parseValue();
      map[key] = value;
      skipWhitespace();
    }
    cursor++; // skip '}'
    return map;
  }

  List<dynamic> parseArray() {
    final list = <dynamic>[];
    cursor++; // skip '['
    skipWhitespace();

    while (currentChar!= ']') {
      if (list.isNotEmpty) expect(',');

      final value = parseValue();
      list.add(value);
      skipWhitespace();
    }

    cursor++; // skip ']'
    return list;
  }

  String parseString() {
    skipWhitespace();
    cursor++; // skip '"'
    final buffer = StringBuffer();
    while (!isEOF && input[cursor] != '"') {
      if (input[cursor] == '\\') {
        cursor++;
        if (isEOF) break;
        switch (input[cursor]) {
          case '"':
            buffer.write('"');
            break;
          case '\\':
            buffer.write('\\');
            break;
          case '/':
            buffer.write('/');
            break;
          case 'b':
            buffer.write('\b');
            break;
          case 'f':
            buffer.write('\f');
            break;
          case 'n':
            buffer.write('\n');
            break;
          case 'r':
            buffer.write('\r');
            break;
          case 't':
            buffer.write('\t');
            break;
          case 'u':
            // Unicode 转义
            cursor++;
            final hex = input.substring(cursor, cursor + 4);
            try {
              final code = int.parse(hex, radix: 16);
              buffer.write(String.fromCharCode(code));
            } catch (e) {
              throw FormatException(
                "Invalid unicode escape: \\u$hex at $cursor",
              );
            }
            cursor += 4;
            continue;
          default:
            throw FormatException(
              "Invalid escape character: \\${input[cursor]} at $cursor",
            );
        }
      } else {
        buffer.write(input[cursor]);
      }
      cursor++;
    }
    expect('"'); // consume closing quote
    return buffer.toString();
  }

  dynamic parseNumber() {
    final start = cursor;
    if (input[cursor] == '-') cursor++;

    void parseDigits() {
      while (!isEOF &&'0123456789'.contains(currentChar))
        cursor++;
    }

    parseDigits();

    if (!isEOF && input[cursor] == '.') {
      cursor++;
      parseDigits();
    }

    if (!isEOF && (input[cursor] == 'e' || input[cursor] == 'E')) {
      cursor++;
      if (!isEOF && (input[cursor] == '+' || input[cursor] == '-')) cursor++;
      parseDigits();
    }

    final numberStr = input.substring(start, cursor);
    if (numberStr.contains('.')) {
      return double.tryParse(numberStr);
    } else {
      return int.tryParse(numberStr);
    }
  }

  dynamic parseLiteral() {
    if (input.startsWith('true', cursor)) {
      cursor += 4;
      return true;
    } else if (input.startsWith('false', cursor)) {
      cursor += 5;
      return false;
    } else if (input.startsWith('null', cursor)) {
      cursor += 4;
      return null;
    }
    throw FormatException("Unexpected literal at position $cursor");
  }
}