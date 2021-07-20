import 'dart:convert';
import 'dart:io';

import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';

import 'cbl_benchmark.dart';

void main() {
  initializeCblC();

  final doc = Document('testdoc', data: loremDict);

  final benchmarks = [
    CBLBenchmark(
      'Create Document (json)',
      (_) => Document('testdoc', data: loremJson).dispose(),
      active: false,
    ),
    CBLBenchmark(
      'Create Document (map)',
      (_) => Document('testdoc', data: loremMap).dispose(),
      active: false,
    ),
    CBLBenchmark(
      'Create Document (dict)',
      (_) => Document('testdoc', data: loremDict).dispose(),
      active: false,
    ),
    CBLBenchmark(
      'Document.properties',
      (_) {
        print(doc.properties.json);
        doc.properties = FLDict.fromMap({'foor': 'barz'});
        print(doc.properties.json);
      },
    ),
  ];

  benchmarks.forEach((b) => b.active ? b.report() : null);

  exit(0);
}

String loremJson = '''{
    "_id": "5973782bdb9a930533b05cb2",
    "isActive": true,
    "balance": "\$1,446.35",
    "age": 32,
    "eyeColor": "green",
    "name": "Logan Keller",
    "gender": "male",
    "company": "ARTIQ",
    "email": "logankeller@example.com",
    "phone": "+1 (952) 533-2258",
    "friends": [
      {"id": 0, "name": "Colon Salazar"},
      {"id": 1, "name": "French Mcneil"},
      {"id": 2, "name": "Carol Martin"}
    ],
    "favoriteFruit": "banana",
    "lorem": "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi accumsan neque vitae nisl sagittis, eleifend dapibus mi commodo. Cras et risus et leo elementum varius vitae ac lectus. Ut volutpat malesuada lorem, nec luctus leo blandit ac. Nam sit amet ultricies ipsum. Sed nec felis et tellus tempus cursus. Proin laoreet nunc ut felis ornare consectetur. Quisque blandit eros ligula. Aenean interdum, felis quis luctus hendrerit, est nibh ultrices eros, eu sagittis nulla risus vel tortor. Vestibulum nec rutrum felis, quis blandit velit. Cras aliquet magna vulputate eleifend laoreet. Etiam mollis magna sit amet libero posuere fermentum. Proin justo justo, sodales vitae sollicitudin ut, accumsan id sem. Fusce quis efficitur tortor.Etiam faucibus volutpat lacus quis euismod. Morbi finibus sem sit amet elit mattis feugiat. Ut eleifend facilisis metus et mattis. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Interdum et malesuada fames ac ante ipsum primis in faucibus. Morbi nec vulputate tellus, id dapibus dui. Proin sed purus et ante sollicitudin varius vestibulum a leo. Sed sit amet elementum justo. Proin eu posuere leo.Nulla tempor laoreet ipsum, in semper erat. Pellentesque pharetra, sem sit amet hendrerit eleifend, mauris metus sagittis leo, nec tincidunt leo orci vel magna. Integer non nisl in sem ullamcorper condimentum et et dolor. Fusce tristique elit et nunc porttitor molestie tempus ut tortor. Praesent interdum nulla a turpis lobortis, a rhoncus turpis ultricies. Aliquam accumsan, nulla sit amet ultricies imperdiet, nibh odio lacinia velit, quis auctor mi dui sollicitudin enim. Integer sed augue eu ligula sodales ultrices. Sed ante lectus, semper sed odio in, maximus lacinia nunc. Quisque placerat ornare erat vel venenatis. Aliquam at mauris tincidunt, condimentum purus vel, viverra libero. Donec hendrerit, velit sed consectetur sagittis, tellus purus pellentesque ipsum, a blandit risus nibh nec lacus.Sed ullamcorper suscipit ultricies. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Curabitur vulputate, metus non semper laoreet, augue dui tempus nunc, ultrices malesuada orci lectus eget augue. Integer tempus tempor enim ut eleifend. Donec sit amet purus scelerisque, bibendum dolor nec, pretium leo. Nullam hendrerit turpis ut urna dictum laoreet. In finibus in augue ac iaculis. Ut non nisl tortor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Cras vehicula quam nisl, id placerat sem tincidunt non. Praesent lorem mi, mattis iaculis feugiat malesuada, bibendum nec tortor. Sed at dolor iaculis est pellentesque euismod.In bibendum eu ipsum a sollicitudin. Nam rhoncus imperdiet nisl. Interdum et malesuada fames ac ante ipsum primis in faucibus. Ut condimentum, ipsum vel scelerisque tempus, magna mauris imperdiet velit, quis tristique mauris elit ac dui. Nam at elit ligula. Vestibulum fringilla in justo et suscipit. In semper a lorem commodo blandit. Praesent aliquam tempor turpis, ac elementum risus ultrices vitae. Quisque sit amet finibus risus. Donec ex risus, tristique a lobortis non, tempor a erat. Nunc et magna nibh."
}''';

FLDict loremDict = FLDict.fromJson(loremJson);
Map loremMap = jsonDecode(loremJson);
