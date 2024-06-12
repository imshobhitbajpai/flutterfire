import 'package:flutter/foundation.dart';
// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_functions;

/// A reference to a particular Callable HTTPS trigger in Cloud Functions.
///
/// You can get an instance by calling [FirebaseFunctions.instance.httpsCallable].
class HttpsCallable {
  HttpsCallable._(this.delegate);

  /// Returns the underlying [HttpsCallablePlatform] delegate for this
  /// [HttpsCallable] instance. This is useful for testing purposes only.
  @visibleForTesting
  final HttpsCallablePlatform delegate;

  /// Executes this Callable HTTPS trigger asynchronously.
  ///
  /// The data passed into the trigger can be any of the following types:
  ///
  /// `null`
  /// `String`
  /// `num`
  /// [List], where the contained objects are also one of these types.
  /// [Map], where the values are also one of these types.
  ///
  /// The request to the Cloud Functions backend made by this method
  /// automatically includes a Firebase Instance ID token to identify the app
  /// instance. If a user is logged in with Firebase Auth, an auth ID token for
  /// the user is also automatically included.
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    assert(_debugIsValidParameterType(parameters));

    Object? updatedParameters;
    if (parameters is Map) {
      Map update = {};
      parameters.forEach((key, value) {
        update[key] = _updateRawDataToList(value);
      });
      updatedParameters = update;
    } else if (parameters is List) {
      List update = parameters.map(_updateRawDataToList).toList();
      updatedParameters = update;
    } else {
      updatedParameters = _updateRawDataToList(parameters);
    }
    return HttpsCallableResult<T>._(await delegate.call(updatedParameters));
  }
}

dynamic _updateRawDataToList(dynamic value) {
  if (value is Uint8List ||
      value is Int32List ||
      value is Int64List ||
      value is Float32List ||
      value is Float64List) {
    return value.toList();
  } else {
    return value;
  }
}

/// Whether a given call parameter is a valid type.
bool _debugIsValidParameterType(dynamic parameter, [bool isRoot = true]) {
  if (parameter is List) {
    for (final element in parameter) {
      if (!_debugIsValidParameterType(element, false)) {
        return false;
      }
    }
    return true;
  }

  if (parameter is Map) {
    for (final key in parameter.keys) {
      if (key is! String) {
        return false;
      }
    }
    for (final value in parameter.values) {
      if (!_debugIsValidParameterType(value, false)) {
        return false;
      }
    }
    return true;
  }

  return parameter == null ||
      parameter is String ||
      parameter is num ||
      parameter is Timestamp ||
      parameter is bool;
}


// Copyright 2018, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


const int _kThousand = 1000;
const int _kMillion = 1000000;
const int _kBillion = 1000000000;

void _check(bool expr, String name, int value) {
  if (!expr) {
    throw ArgumentError('Timestamp $name out of range: $value');
  }
}

/// A Timestamp represents a point in time independent of any time zone or calendar,
/// represented as seconds and fractions of seconds at nanosecond resolution in UTC
/// Epoch time. It is encoded using the Proleptic Gregorian Calendar which extends
/// the Gregorian calendar backwards to year one. It is encoded assuming all minutes
/// are 60 seconds long, i.e. leap seconds are "smeared" so that no leap second table
/// is needed for interpretation. Range is from 0001-01-01T00:00:00Z to
/// 9999-12-31T23:59:59.999999999Z. By restricting to that range, we ensure that we
/// can convert to and from RFC 3339 date strings.
///
/// For more information, see [the reference timestamp definition](https://github.com/google/protobuf/blob/master/src/google/protobuf/timestamp.proto)
@immutable
class Timestamp implements Comparable<Timestamp> {
  /// Creates a [Timestamp]
  Timestamp(this._seconds, this._nanoseconds) {
    _validateRange(_seconds, _nanoseconds);
  }

  /// Create a [Timestamp] fromMillisecondsSinceEpoch
  factory Timestamp.fromMillisecondsSinceEpoch(int milliseconds) {
    int seconds = (milliseconds / _kThousand).floor();
    final int nanoseconds = (milliseconds - seconds * _kThousand) * _kMillion;
    return Timestamp(seconds, nanoseconds);
  }

  /// Create a [Timestamp] fromMicrosecondsSinceEpoch
  factory Timestamp.fromMicrosecondsSinceEpoch(int microseconds) {
    final int seconds = microseconds ~/ _kMillion;
    final int nanoseconds = (microseconds - seconds * _kMillion) * _kThousand;
    return Timestamp(seconds, nanoseconds);
  }

  /// Create a [Timestamp] from [DateTime] instance
  factory Timestamp.fromDate(DateTime date) {
    return Timestamp.fromMicrosecondsSinceEpoch(date.microsecondsSinceEpoch);
  }

  /// Create a [Timestamp] from [DateTime].now()
  factory Timestamp.now() {
    return Timestamp.fromMicrosecondsSinceEpoch(
      DateTime.now().microsecondsSinceEpoch,
    );
  }

  final int _seconds;
  final int _nanoseconds;

  static const int _kStartOfTime = -62135596800;
  static const int _kEndOfTime = 253402300800;

  // ignore: public_member_api_docs
  int get seconds => _seconds;

  // ignore: public_member_api_docs
  int get nanoseconds => _nanoseconds;

  // ignore: public_member_api_docs
  int get millisecondsSinceEpoch =>
      seconds * _kThousand + nanoseconds ~/ _kMillion;

  // ignore: public_member_api_docs
  int get microsecondsSinceEpoch =>
      seconds * _kMillion + nanoseconds ~/ _kThousand;

  /// Converts [Timestamp] to [DateTime]
  DateTime toDate() {
    return DateTime.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch);
  }

  @override
  int get hashCode => Object.hash(seconds, nanoseconds);

  @override
  bool operator ==(Object other) =>
      other is Timestamp &&
      other.seconds == seconds &&
      other.nanoseconds == nanoseconds;

  @override
  int compareTo(Timestamp other) {
    if (seconds == other.seconds) {
      return nanoseconds.compareTo(other.nanoseconds);
    }

    return seconds.compareTo(other.seconds);
  }

  @override
  String toString() {
    return 'Timestamp(seconds=$seconds, nanoseconds=$nanoseconds)';
  }

  static void _validateRange(int seconds, int nanoseconds) {
    _check(nanoseconds >= 0, 'nanoseconds', nanoseconds);
    _check(nanoseconds < _kBillion, 'nanoseconds', nanoseconds);
    _check(seconds >= _kStartOfTime, 'seconds', seconds);
    _check(seconds < _kEndOfTime, 'seconds', seconds);
  }
}

