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
  List<String>? _names;
  List<String>? _nicknames;

  /// The pronunciation of the getNames() field, often in hiragana or katakana.
  ///
  /// In Japanese, the name is written in kanji, which can have multiple readings.
  /// Therefore a hint is often provided, called furigana, which spells the name phonetically.
  String? pronunciation;

  List<String>? _phoneNumbers;
  List<String?>? _phoneTypes;
  List<String>? _emails;
  List<String?>? _emailTypes;
  List<String>? _addresses;
  List<String?>? _addressTypes;

  String? instantMessenger;
  String? note;

  String? org;

  /// birthday formatted as yyyyMMdd (e.g. 19780917)
  String? birthday;

  String? title;
  List<String>? _urls;

  /// A location as a latitude/longitude pair
  List<String>? geo;

  AddressBookParsedResult({
    List<String>? names,
    List<String>? nicknames,
    this.pronunciation,
    List<String>? phoneNumbers,
    List<String?>? phoneTypes,
    List<String>? emails,
    List<String?>? emailTypes,
    this.instantMessenger,
    this.note,
    List<String>? addresses,
    List<String?>? addressTypes,
    this.org,
    this.birthday,
    this.title,
    List<String>? urls,
    this.geo,
  })  : _names = names,
        _nicknames = nicknames,
        _phoneNumbers = phoneNumbers,
        _phoneTypes = phoneTypes,
        _emails = emails,
        _emailTypes = emailTypes,
        _addresses = addresses,
        _addressTypes = addressTypes,
        _urls = urls,
        super(ParsedResultType.ADDRESS_BOOK);

  AddressBookParsedResult.quick(
    List<String>? names,
    List<String>? phoneNumbers,
    List<String?>? phoneTypes,
    List<String>? emails,
    List<String?>? emailTypes,
    List<String>? addresses,
    List<String>? addressTypes,
  ) : this.full(
          names,
          null,
          null,
          phoneNumbers,
          phoneTypes,
          emails,
          emailTypes,
          null,
          null,
          addresses,
          addressTypes,
          null,
          null,
          null,
          null,
          null,
        );

  AddressBookParsedResult.full(
    this._names,
    this._nicknames,
    this.pronunciation,
    this._phoneNumbers,
    this._phoneTypes,
    this._emails,
    this._emailTypes,
    this.instantMessenger,
    this.note,
    this._addresses,
    this._addressTypes,
    this.org,
    this.birthday,
    this.title,
    this._urls,
    this.geo,
  ) : super(ParsedResultType.ADDRESS_BOOK) {
    if (_phoneNumbers != null &&
        _phoneTypes != null &&
        _phoneNumbers!.length != _phoneTypes!.length) {
      throw ArgumentError('Phone numbers and types lengths differ');
    }
    if (_emails != null &&
        _emailTypes != null &&
        _emails!.length != _emailTypes!.length) {
      throw ArgumentError('Emails and types lengths differ');
    }
    if (_addresses != null &&
        _addressTypes != null &&
        _addresses!.length != _addressTypes!.length) {
      throw ArgumentError('Addresses and types lengths differ');
    }
  }

  List<String>? get names => _names;

  List<String>? get nicknames => _nicknames;

  List<String>? get phoneNumbers => _phoneNumbers;

  /// @return optional descriptions of the type of each phone number. It could be like "HOME", but,
  ///  there is no guaranteed or standard format.
  List<String?>? get phoneTypes => _phoneTypes;

  List<String>? get emails => _emails;

  /// @return optional descriptions of the type of each e-mail. It could be like "WORK", but,
  ///  there is no guaranteed or standard format.
  List<String?>? get emailTypes => _emailTypes;

  List<String>? get addresses => _addresses;

  /// @return optional descriptions of the type of each e-mail. It could be like "WORK", but,
  ///  there is no guaranteed or standard format.
  List<String?>? get addressTypes => _addressTypes;

  List<String>? get urls => _urls;

  void addName(String name) {
    _names ??= [];
    _names!.add(name);
  }

  void addNickname(String name) {
    _nicknames ??= [];
    _nicknames!.add(name);
  }

  void addPhoneNumber(String phone, [String? type]) {
    _phoneNumbers ??= [];
    _phoneTypes ??= [];
    _phoneNumbers!.add(phone);
    _phoneTypes!.add(type);
  }

  void addEmail(String email, [String? type]) {
    _emails ??= [];
    _emailTypes ??= [];
    _emails!.add(email);
    _emailTypes!.add(type);
  }

  void addAddress(String address, [String? type]) {
    _addresses ??= [];
    _addressTypes ??= [];
    _addresses!.add(address);
    _addressTypes!.add(type);
  }

  @override
  String get displayResult {
    final result = StringBuffer();
    maybeAppendList(_names, result);
    maybeAppendList(_nicknames, result);
    maybeAppend(pronunciation, result);
    maybeAppend(title, result);
    maybeAppend(org, result);
    maybeAppendList(_addresses, result);
    maybeAppendList(_phoneNumbers, result);
    maybeAppendList(_emails, result);
    maybeAppend(instantMessenger, result);
    maybeAppendList(_urls, result);
    maybeAppend(birthday, result);
    maybeAppendList(geo, result);
    maybeAppend(note, result);
    return result.toString();
  }
}
