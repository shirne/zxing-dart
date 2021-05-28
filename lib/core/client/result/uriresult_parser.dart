/*
 * Copyright 2007 ZXing authors
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








import 'package:zxing/core/client/result/uriparsed_result.dart';

import '../../result.dart';
import 'result_parser.dart';

/**
 * Tries to parse results that are a URI of some kind.
 * 
 * @author Sean Owen
 */
class URIResultParser extends ResultParser {

  static final RegExp ALLOWED_URI_CHARS_PATTERN =
      RegExp(r"[-._~:/?#\\[\\]@!$&'()*+,;=%A-Za-z0-9]+");
  static final RegExp USER_IN_HOST = RegExp(":/*([^/@]+)@[^/]+");
  // See http://www.ietf.org/rfc/rfc2396.txt
  static final RegExp URL_WITH_PROTOCOL_PATTERN = RegExp("[a-zA-Z][a-zA-Z0-9+-.]+:");
  static final RegExp URL_WITHOUT_PROTOCOL_PATTERN = RegExp(
      "([a-zA-Z0-9\\-]+\\.){1,6}[a-zA-Z]{2,}" + // host name elements; allow up to say 6 domain elements
      "(:\\d{1,5})?" + // maybe port
      r"(/|\\?|$)"); // query, path or nothing

  @override
  URIParsedResult? parse(Result result) {
    String rawText = ResultParser.getMassagedText(result);
    // We specifically handle the odd "URL" scheme here for simplicity and add "URI" for fun
    // Assume anything starting this way really means to be a URI
    if (rawText.startsWith("URL:") || rawText.startsWith("URI:")) {
      return new URIParsedResult(rawText.substring(4).trim(), null);
    }
    rawText = rawText.trim();
    if (!isBasicallyValidURI(rawText) || isPossiblyMaliciousURI(rawText)) {
      return null;
    }
    return new URIParsedResult(rawText, null);
  }

  /**
   * @return true if the URI contains suspicious patterns that may suggest it intends to
   *  mislead the user about its true nature. At the moment this looks for the presence
   *  of user/password syntax in the host/authority portion of a URI which may be used
   *  in attempts to make the URI's host appear to be other than it is. Example:
   *  http://yourbank.com@phisher.com  This URI connects to phisher.com but may appear
   *  to connect to yourbank.com at first glance.
   */
  static bool isPossiblyMaliciousURI(String uri) {
    return !ALLOWED_URI_CHARS_PATTERN.hasMatch(uri) || USER_IN_HOST.hasMatch(uri);
  }

  static bool isBasicallyValidURI(String uri) {
    if (uri.contains(" ")) {
      // Quick hack check for a common case
      return false;
    }
    RegExpMatch? m = URL_WITH_PROTOCOL_PATTERN.firstMatch(uri);
    if(m == null){
      return false;
    }

    // match at start only
    return m.start == 0;
  }

}