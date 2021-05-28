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

/**
 * Represents a parsed result that encodes wifi network information, like SSID and password.
 *
 * @author Vikram Aggarwal
 */
class WifiParsedResult extends ParsedResult {
  final String ssid;
  final String networkEncryption;
  final String? password;
  final bool hidden;
  final String? identity;
  final String? anonymousIdentity;
  final String? eapMethod;
  final String? phase2Method;

  WifiParsedResult(this.networkEncryption, this.ssid, this.password,
      [this.hidden = false,
      this.identity,
      this.anonymousIdentity,
      this.eapMethod,
      this.phase2Method])
      : super(ParsedResultType.WIFI);

  String getSsid() {
    return ssid;
  }

  String getNetworkEncryption() {
    return networkEncryption;
  }

  String? getPassword() {
    return password;
  }

  bool isHidden() {
    return hidden;
  }

  String? getIdentity() {
    return identity;
  }

  String? getAnonymousIdentity() {
    return anonymousIdentity;
  }

  String? getEapMethod() {
    return eapMethod;
  }

  String? getPhase2Method() {
    return phase2Method;
  }

  @override
  String getDisplayResult() {
    StringBuffer result = StringBuffer();
    ParsedResult.maybeAppend(ssid, result);
    ParsedResult.maybeAppend(networkEncryption, result);
    ParsedResult.maybeAppend(password, result);
    ParsedResult.maybeAppend(hidden.toString(), result);
    return result.toString();
  }
}
