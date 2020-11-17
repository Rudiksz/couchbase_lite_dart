// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library couchbase_lite_dart;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:meta/meta.dart';

import 'package:ffi/ffi.dart' as pffi;
import 'dart:ffi' as ffi;

import 'package:uuid/uuid.dart';

import 'bindings/library.dart' as cbl;

part 'src/base.dart';
part 'src/database.dart';
part 'src/document.dart';
part 'src/query.dart';
part 'src/replicator.dart';
part 'src/blob.dart';
part 'src/listeners.dart';
part 'src/database_error.dart';
part 'src/fleece/fldoc.dart';
part 'src/fleece/flvalue.dart';
part 'src/fleece/fldict.dart';
part 'src/fleece/flarray.dart';

final Cbl = cbl.CblC();
