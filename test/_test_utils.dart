import 'dart:io';

Future asyncSleep(int millis) => Future.delayed(Duration(milliseconds: millis));

void deleteDBFile(String path) {
  if (Directory('$path.cblite2').existsSync()) {
    Directory('$path.cblite2').delete(recursive: true);
  }
}
