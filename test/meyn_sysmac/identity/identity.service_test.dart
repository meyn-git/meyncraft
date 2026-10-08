import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meyncraft/meyn_sysmac/identity/identity.service.dart';
import 'package:shouldly/shouldly.dart';
import 'package:petitparser/petitparser.dart';

void main() {
  group('nameParser() function', () {
    test("nameParser.parse('1').should.beOfType<Failure>()", () {
      nameParser.parse('1').should.beOfType<Failure>();
    });
    test("nameParser.parse('a').should.beOfType<Success<String>>()", () {
      nameParser.end().parse('a').should.beOfType<Success<String>>();
    });
    test("nameParser.parse('A').should.beOfType<Success<String>>()", () {
      nameParser.end().parse('A').should.beOfType<Success<String>>();
    });
    test("nameParser.parse('A1_ 1b').should.beOfType<Success<String>>()", () {
      nameParser.end().parse('A1_ 1b').should.beOfType<Success<String>>();
    });
    test("nameParser.parse('A1_ ! 1b').should.beOfType<Success<String>>()", () {
      nameParser.end().parse('A1_ ! 1b').should.beOfType<Failure>();
    });
  });

  group('parseSysmacFilePath() function', () {
    test(" parseSysmacFilePath('N:\\321')", () {
      var site = parseSysmacFilePath('N:\\321');
      site.should.beNull();
    });

    test(" parseSysmacFilePath('N:\\4321')", () {
      var site = parseSysmacFilePath('N:\\4321');
      site.should.not.beNull();
      site!.code.should.be('4321');
      site.companyName.should.beNull();
      site.city.should.beNull();
      site.country.should.beNull();
    });

    test(" parseSysmacFilePath('N:\\4321-Maple Leaf')", () {
      var site = parseSysmacFilePath('N:\\4321-Maple Leaf');
      site.should.not.beNull();
      site!.code.should.be('4321');
      site.companyName.should.be('Maple Leaf');
      site.city.should.beNull();
      site.country.should.beNull();
    });

    test(" parseSysmacFilePath('N:\\4321-Maple Leaf-London ON')", () {
      var site = parseSysmacFilePath('N:\\4321-Maple Leaf-London ON');
      site.should.not.beNull();
      site!.code.should.be('4321');
      site.companyName.should.be('Maple Leaf');
      site.city.should.be('London ON');
      site.country.should.beNull();
    });

    test(" parseSysmacFilePath('N:\\4321-Maple Leaf-London ON-Canada')", () {
      var site = parseSysmacFilePath('N:\\4321-Maple Leaf-London ON-Canada');
      site.should.not.beNull();
      site!.code.should.be('4321');
      site.companyName.should.be('Maple Leaf');
      site.city.should.be('London ON');
      site.country.should.be('Canada');
    });
  });
  group('createIdentity() function', () {
    test("createIdentity(File('foo.smc2'))", () {
      var identity = createIdentity(File('foo.smc2'));
      expect(identity.site, null);
    });
    test("createIdentity(File('1234.smc2'))", () {
      var identity = createIdentity(File('1234.smc2'));
      expect(identity.site, isNotNull);
      expect(identity.site!.code, '1234');
    });
  });
}
