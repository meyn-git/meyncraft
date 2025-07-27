import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/logger/logger.infrastructure.dart';
import 'package:meyncraft/meyncraft/source/sysmac/detail/detail.service.dart';

void main() {
  GetIt.I.registerSingleton<Logger>(Logger());
  group('createDetails() function', () {
    test("createDetails(File('foo.smc2'))", () {
      var details = createDetails(File('foo.smc2'));
      expect(details.site, null);
    });
    test("createDetails(File('1234.smc2'))", () {
      var details = createDetails(File('1234.smc2'));
      expect(details.site, '1234');
    });
  });
}
