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
  final String _ssid;
  final String _networkEncryption;
  final String? _password;
  final bool _hidden;
  final String? _identity;
  final String? _anonymousIdentity;
  final String? _eapMethod;
  final String? _phase2Method;

  WifiParsedResult(this._networkEncryption, this._ssid, this._password,
      [this._hidden = false,
      this._identity,
      this._anonymousIdentity,
      this._eapMethod,
      this._phase2Method])
      : super(ParsedResultType.WIFI);

  String getSsid() {
    return _ssid;
  }

  String getNetworkEncryption() {
    return _networkEncryption;
  }

  String? getPassword() {
    return _password;
  }

  bool isHidden() {
    return _hidden;
  }

  String? getIdentity() {
    return _identity;
  }

  String? getAnonymousIdentity() {
    return _anonymousIdentity;
  }

  String? getEapMethod() {
    return _eapMethod;
  }

  String? getPhase2Method() {
    return _phase2Method;
  }

  @override
  String getDisplayResult() {
    StringBuffer result = StringBuffer();
    ParsedResult.maybeAppend(_ssid, result);
    ParsedResult.maybeAppend(_networkEncryption, result);
    ParsedResult.maybeAppend(_password, result);
    ParsedResult.maybeAppend(_hidden.toString(), result);
    return result.toString();
  }
}
