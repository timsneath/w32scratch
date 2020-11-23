import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'package:win32/win32.dart';

const sizeOfDlgTemplate = 18;
const sizeOfDlgitemTemplate = 18;

/// Sets the memory at the pointer location to the string supplied.
///
/// Returns the number of bytes (not characters) written.
int setString(Pointer ptr, String string) {
  final units = string.codeUnits;
  final nativeString = ptr.cast<Uint16>().asTypedList(units.length + 1);

  nativeString.setAll(0, units);
  nativeString[units.length] = 0;
  return (units.length + 1) * 2;
}

int setDialog(Pointer<Uint8> ptr,
    {required int style,
    required int dwExtendedStyle,
    int cdit = 1,
    int x = 0,
    int y = 0,
    required int cx,
    required int cy,
    int menu = 0,
    int windowClass = 0,
    String title = ''}) {
  var idx = 0;

  ptr.cast<DLGTEMPLATE>().ref
    ..style = style
    ..dwExtendedStyle = dwExtendedStyle
    ..cdit = cdit
    ..x = x
    ..y = y
    ..cx = cx
    ..cy = cy;

  idx += sizeOfDlgTemplate;

  // menu
  if (menu == 0x0000) {
    ptr.elementAt(idx).cast<Uint16>().value = 0x0000;
    idx += 2;
  } else {
    ptr.elementAt(idx).cast<Uint16>().value = 0xFFFF;
    idx += 2;
    ptr.elementAt(idx).cast<Uint16>().value = menu;
    idx += 2;
  }

  // window class is 0x0000 -- no window class
  ptr.elementAt(idx).cast<Uint16>().value = windowClass;
  idx += 2;

  // title
  if (title.isEmpty) {
    ptr.elementAt(idx).cast<Uint16>().value = 0x0000;
    idx += 2;
  } else {
    idx += setString(ptr.elementAt(idx), title);
  }
  return idx;
}

int setDialogItem(Pointer ptr,
    {required int style,
    required int dwExtendedStyle,
    required int x,
    required int y,
    required int cx,
    required int cy,
    required int id,
    int windowSystemClass = 0,
    String windowClass = '',
    required String text,
    int creationData = 0}) {
  if (windowSystemClass == 0 && windowClass == '') {
    throw Exception('Either windowSystemClass or windowClass must be defined.');
  }

  var idx = 0;
  ptr.cast<DLGITEMTEMPLATE>().ref
    ..style = style
    ..dwExtendedStyle = dwExtendedStyle
    ..x = x
    ..y = y
    ..cx = cx
    ..cy = cy
    ..id = id;
  idx += sizeOfDlgitemTemplate;

  // Window class
  if (windowClass.isNotEmpty) {
    idx += setString(ptr.elementAt(idx), windowClass);
  } else {
    ptr.elementAt(idx).cast<Uint16>().value = 0xFFFF;
    idx += 2;

    ptr.elementAt(idx).cast<Uint16>().value = windowSystemClass;
    idx += 2;
  }

  // Text
  idx += setString(ptr.elementAt(idx), text);

  // Creation data
  ptr.elementAt(idx).cast<Uint16>().value = creationData;
  idx += 2;

  // Set idx so that it aligns to the next DWORD boundary
  while ((ptr.address + idx) % 4 != 0) {
    ptr.elementAt(idx++).cast<Uint8>().value = 0x00;
  }

  return idx;
}
