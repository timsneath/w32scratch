import 'dart:ffi';

import 'package:win32/win32.dart';

/// Size in 16-bit WORDs of the DLGTEMPLATE struct
const dlgTemplateSize = 9;

/// Size in 16-bit WORDs of the DLGITEMTEMPLATE struct
const dlgItemTemplateSize = 9;

/// Sets the memory at the pointer location to the string supplied.
///
/// Returns the number of WORDs written.
int setString(Pointer<Uint16> ptr, String string) {
  final units = string.codeUnits;
  final nativeString = ptr.asTypedList(units.length + 1);

  nativeString.setAll(0, units);
  nativeString[units.length] = 0;
  return units.length + 1;
}

/// Sets the memory at the pointer location to the dialog supplied.
///
/// Returns the number of WORDs written.
int setDialog(Pointer<Uint16> ptr,
    {required int style,
    int dwExtendedStyle = 0,
    int cdit = 1,
    int x = 0,
    int y = 0,
    required int cx,
    required int cy,
    int menu = 0,
    int windowClass = 0,
    String title = ''}) {
  // Since everything is aligned in WORD or DWORD boundaries, it's easier to
  // treat this as a 16-bit pointer.
  var idx = 0;

  ptr.cast<DLGTEMPLATE>().ref
    ..style = style
    ..dwExtendedStyle = dwExtendedStyle
    ..cdit = cdit
    ..x = x
    ..y = y
    ..cx = cx
    ..cy = cy;

  idx += dlgTemplateSize;

  // menu
  if (menu == 0x0000) {
    ptr[idx++] = 0x0000;
  } else {
    ptr[idx++] = 0xFFFF;
    ptr[idx++] = menu;
  }

  // window class is 0x0000 -- no window class
  ptr[idx++] = windowClass;

  // title
  if (title.isEmpty) {
    ptr[idx++] = 0x0000;
  } else {
    idx += setString(ptr.elementAt(idx), title);
  }

  // Move idx forward so that it aligns to the next DWORD boundary
  if ((ptr.address + idx) % 4 != 0) {
    ptr[idx++] = 0x0000;
  }
  return idx;
}

/// Sets the memory at the pointer location to the dialog item supplied.
///
/// Returns the number of WORDs written.
int setDialogItem(Pointer<Uint16> ptr,
    {required int style,
    int dwExtendedStyle = 0,
    required int x,
    required int y,
    required int cx,
    required int cy,
    required int id,
    int windowSystemClass = 0,
    String windowClass = '',
    required String text,
    int creationDataByteLength = 0}) {
  if (windowSystemClass == 0 && windowClass == '') {
    throw Exception('Either windowSystemClass or windowClass must be defined.');
  }
  // Since everything is aligned in WORD or DWORD boundaries, it's easier to
  // treat this as a 16-bit pointer.
  var idx = 0;
  ptr.cast<DLGITEMTEMPLATE>().ref
    ..style = style
    ..dwExtendedStyle = dwExtendedStyle
    ..x = x
    ..y = y
    ..cx = cx
    ..cy = cy
    ..id = id;
  idx += dlgItemTemplateSize;

  // Window class
  if (windowClass.isNotEmpty) {
    idx += setString(ptr.elementAt(idx), windowClass);
  } else {
    ptr[idx++] = 0xFFFF;
    ptr[idx++] = windowSystemClass;
  }

  // Text
  idx += setString(ptr.elementAt(idx), text);

  // Creation data
  ptr[idx++] = creationDataByteLength;

  // Move idx forward so that it aligns to the next DWORD boundary
  if ((ptr.address + idx) % 4 != 0) {
    ptr[idx++] = 0x0000;
  }

  return idx;
}
