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

import 'parsed_result.dart';
import 'parsed_result_type.dart';

/// Represents a parsed result that encodes contact information, like that in an address book
/// entry.
///
/// @author Sean Owen
class AddressBookParsedResult extends ParsedResult {
  final List<String>? _names;
  final List<String>? _nicknames;
  final String? _pronunciation;
  final List<String>? _phoneNumbers;
  final List<String?>? _phoneTypes;
  final List<String>? _emails;
  final List<String?>? _emailTypes;
  final String? _instantMessenger;
  final String? _note;
  final List<String>? _addresses;
  final List<String?>? _addressTypes;
  final String? _org;
  final String? _birthday;
  final String? _title;
  final List<String>? _urls;
  final List<String>? _geo;

  AddressBookParsedResult.quick(
      List<String>? names,
      List<String>? phoneNumbers,
      List<String?>? phoneTypes,
      List<String>? emails,
      List<String?>? emailTypes,
      List<String>? addresses,
      List<String>? addressTypes)
      : this(names, null, null, phoneNumbers, phoneTypes, emails, emailTypes,
            null, null, addresses, addressTypes, null, null, null, null, null);

  AddressBookParsedResult(
      this._names,
      this._nicknames,
      this._pronunciation,
      this._phoneNumbers,
      this._phoneTypes,
      this._emails,
      this._emailTypes,
      this._instantMessenger,
      this._note,
      this._addresses,
      this._addressTypes,
      this._org,
      this._birthday,
      this._title,
      this._urls,
      this._geo)
      : super(ParsedResultType.ADDRESS_BOOK) {
    if (_phoneNumbers != null &&
        _phoneTypes != null &&
        _phoneNumbers!.length != _phoneTypes!.length) {
      throw Exception("Phone numbers and types lengths differ");
    }
    if (_emails != null &&
        _emailTypes != null &&
        _emails!.length != _emailTypes!.length) {
      throw Exception("Emails and types lengths differ");
    }
    if (_addresses != null &&
        _addressTypes != null &&
        _addresses!.length != _addressTypes!.length) {
      throw Exception("Addresses and types lengths differ");
    }
  }

  List<String>? get names => _names;

  List<String>? get nicknames => _nicknames;

  /// In Japanese, the name is written in kanji, which can have multiple readings. Therefore a hint
  /// is often provided, called furigana, which spells the name phonetically.
  ///
  /// @return The pronunciation of the getNames() field, often in hiragana or katakana.
  String? get pronunciation => _pronunciation;

  List<String>? get phoneNumbers => _phoneNumbers;

  /// @return optional descriptions of the type of each phone number. It could be like "HOME", but,
  ///  there is no guaranteed or standard format.
  List<String?>? get phoneTypes => _phoneTypes;

  List<String>? get emails => _emails;

  /// @return optional descriptions of the type of each e-mail. It could be like "WORK", but,
  ///  there is no guaranteed or standard format.
  List<String?>? get emailTypes => _emailTypes;

  String? get instantMessenger => _instantMessenger;

  String? get note => _note;

  List<String>? get addresses => _addresses;

  /// @return optional descriptions of the type of each e-mail. It could be like "WORK", but,
  ///  there is no guaranteed or standard format.
  List<String?>? get addressTypes => _addressTypes;

  String? get title => _title;

  String? get org => _org;

  List<String>? get urls => _urls;

  /// @return birthday formatted as yyyyMMdd (e.g. 19780917)
  String? get birthday => _birthday;

  /// @return a location as a latitude/longitude pair
  List<String>? get geo => _geo;

  @override
  String get displayResult {
    StringBuffer result = StringBuffer();
    ParsedResult.maybeAppendList(_names, result);
    ParsedResult.maybeAppendList(_nicknames, result);
    ParsedResult.maybeAppend(_pronunciation, result);
    ParsedResult.maybeAppend(_title, result);
    ParsedResult.maybeAppend(_org, result);
    ParsedResult.maybeAppendList(_addresses, result);
    ParsedResult.maybeAppendList(_phoneNumbers, result);
    ParsedResult.maybeAppendList(_emails, result);
    ParsedResult.maybeAppend(_instantMessenger, result);
    ParsedResult.maybeAppendList(_urls, result);
    ParsedResult.maybeAppend(_birthday, result);
    ParsedResult.maybeAppendList(_geo, result);
    ParsedResult.maybeAppend(_note, result);
    return result.toString();
  }
}
