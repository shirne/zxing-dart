/*
 * Copyright 2010 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'parsed_result.dart';
import 'parsed_result_type.dart';

/// Represents a parsed result that encodes wifi network information, like SSID and password.
///
/// @author Vikram Aggarwal
class WifiParsedResult extends ParsedResult {
  String ssid;
  String networkEncryption;
  String? password;
  bool hidden;
  String? identity;
  String? anonymousIdentity;
  String? eapMethod;
  String? phase2Method;

  WifiParsedResult(
    this.networkEncryption,
    this.ssid,
    this.password, [
    this.hidden = false,
    this.identity,
    this.anonymousIdentity,
    this.eapMethod,
    this.phase2Method,
  ]) : super(ParsedResultType.WIFI);

  @override
  String get displayResult {
    final result = StringBuffer();
    maybeAppend(ssid, result);
    maybeAppend(networkEncryption, result);
    maybeAppend(password, result);
    maybeAppend(hidden.toString(), result);
    return result.toString();
  }
}
