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

import '../../result.dart';
import 'result_parser.dart';
import 'wifi_parsed_result.dart';

/// Parses a WIFI configuration string. Strings will be of the form:
///
/// `WIFI:T:[network type];S:[network SSID];P:[network password];H:[hidden?];;`
///
/// For WPA2 enterprise (EAP), strings will be of the form:
///
/// `WIFI:T:WPA2-EAP;S:[network SSID];H:[hidden?];E:[EAP method];PH2:[Phase 2 method];A:[anonymous identity];I:[username];P:[password];;`
///
/// "EAP method" can e.g. be "TTLS" or "PWD" or one of the other fields in
/// <a href="https://developer.android.com/reference/android/net/wifi/WifiEnterpriseConfig.Eap.html">WifiEnterpriseConfig.Eap</a>
/// and "Phase 2 method" can e.g. be "MSCHAPV2" or any of the other fields in
/// <a href="https://developer.android.com/reference/android/net/wifi/WifiEnterpriseConfig.Phase2.html">WifiEnterpriseConfig.Phase2</a>
///
/// The fields can appear in any order. Only "S:" is required.
///
/// @author Vikram Aggarwal
/// @author Sean Owen
/// @author Steffen Kieß
class WifiResultParser extends ResultParser {
  @override
  WifiParsedResult? parse(Result result) {
    String rawText = ResultParser.getMassagedText(result);
    if (!rawText.startsWith('WIFI:')) {
      return null;
    }
    rawText = rawText.substring('WIFI:'.length);
    final ssid = matchSinglePrefixedField('S:', rawText, ';', false);
    if (ssid == null || ssid.isEmpty) {
      return null;
    }
    final pass = matchSinglePrefixedField('P:', rawText, ';', false);
    String? type = matchSinglePrefixedField('T:', rawText, ';', false);
    type ??= 'nopass';

    // Unfortunately, in the past, H: was not just used for bool 'hidden', but 'phase 2 method'.
    // To try to retain backwards compatibility, we set one or the other based on whether the string
    // is 'true' or 'false':
    bool hidden = false;
    String? phase2Method =
        matchSinglePrefixedField('PH2:', rawText, ';', false);
    final hValue = matchSinglePrefixedField('H:', rawText, ';', false);
    if (hValue != null) {
      // If PH2 was specified separately, or if the value is clearly bool, interpret it as 'hidden'
      if (phase2Method != null ||
          'true' == hValue.toLowerCase() ||
          'false' == hValue.toLowerCase()) {
        hidden = 'true' == hValue.toLowerCase();
      } else {
        phase2Method = hValue;
      }
    }

    final identity = matchSinglePrefixedField('I:', rawText, ';', false);
    final anonymousIdentity =
        matchSinglePrefixedField('A:', rawText, ';', false);
    final eapMethod = matchSinglePrefixedField('E:', rawText, ';', false);

    return WifiParsedResult(
      type,
      ssid,
      pass,
      hidden,
      identity,
      anonymousIdentity,
      eapMethod,
      phase2Method,
    );
  }
}
