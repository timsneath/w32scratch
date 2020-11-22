import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

import 'package:win32/win32.dart';

const sizeOfDlgTemplate = 18;
const sizeOfDlgitemTemplate = 18;

final hInstance = GetModuleHandle(nullptr);

/// Allocates space for a dialog template.
///
/// Dialog template is 18 bytes in length, plus three variable-length arrays for
/// menu, class, title for dialog box, plus an additional value if WS_SETFONT is
/// specified.
///
/// Same for dialog item template, which includes additional data.
///
/// See remarks in
/// https://docs.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-dlgtemplate
///
/// So instead of using FFI's `allocate()` method, we instead manually allocate
/// the correct amount of space and then fill it accordingly. This is ugly, but
/// functional.
Pointer allocateTemplate({required int items}) => allocate<Uint8>(
    count: sizeOfDlgTemplate +
        (3 * 2) + /* DLGTEMPLATE POSTFIX */
        (sizeOfDlgitemTemplate * items) +
        100 /* TODO: Calculate actual size */);

void main() {
  final lpTemplate = allocateTemplate(items: 1);

  final dlgTemplate = lpTemplate.cast<DLGTEMPLATE>().ref;
  dlgTemplate.style = WS_POPUP | WS_VISIBLE | WS_SYSMENU | DS_MODALFRAME;
  dlgTemplate.dwExtendedStyle = WS_EX_TOPMOST;
  dlgTemplate.cdit = 1; // Number of child elements, let's start with 1.
  dlgTemplate.x = 0;
  dlgTemplate.y = 0;
  dlgTemplate.cx = 300;
  dlgTemplate.cy = 200;

  // menu is 0x0000 -- no menu
  lpTemplate.elementAt(sizeOfDlgTemplate).cast<Uint16>().value = 0;

  // window class is 0x0000 -- no window class
  lpTemplate.elementAt(sizeOfDlgTemplate + 2).cast<Uint16>().value = 0;

  // title array is 0x0000 -- no title
  lpTemplate.elementAt(sizeOfDlgTemplate + 4).cast<Uint16>().value = 0;

  // now the array of DLGITEMTEMPLATES begins
  final itemTemplate1 =
      lpTemplate.elementAt(sizeOfDlgTemplate + 6).cast<DLGITEMTEMPLATE>().ref;
  itemTemplate1.style =
      WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_PUSHBUTTON | WS_BORDER;
  itemTemplate1.dwExtendedStyle = WS_EX_NOPARENTNOTIFY;
  itemTemplate1.x = 190;
  itemTemplate1.y = 160;
  itemTemplate1.cx = 50;
  itemTemplate1.cy = 14;
  itemTemplate1.id = IDOK;

  final lpItemTemplate1Postfix =
      itemTemplate1.addressOf.cast<Uint8>().elementAt(sizeOfDlgitemTemplate);

  // Window class
  lpItemTemplate1Postfix.cast<Uint16>().value = 0xFFFF;
  lpItemTemplate1Postfix.elementAt(2).cast<Uint16>().value = 0x0080; // button

  // Text
  lpItemTemplate1Postfix.elementAt(4).cast<Uint16>().value = 0x004F; // 'O'
  lpItemTemplate1Postfix.elementAt(6).cast<Uint16>().value = 0x004B; // 'K'
  lpItemTemplate1Postfix.elementAt(8).cast<Uint16>().value = 0x0000; // NUL

  // Creation data
  lpItemTemplate1Postfix.elementAt(10).cast<Uint16>().value = 0x0000; // None

  final lpDialogFunc = Pointer.fromFunction<DlgProc>(dialogReturnProc, 0);

  if (lpDialogFunc.address == 0) {
    throw Exception();
  }

  final hWnd = CreateDialogIndirectParam(
    hInstance,
    dlgTemplate.addressOf,
    NULL,
    lpDialogFunc,
    WM_INITDIALOG,
  );

  if (hWnd == NULL) {
    print('Error: ${GetLastError()}');
  }

  print('Window handle: ${hWnd.toHexString(sizeOf<IntPtr>() * 8)}');

  ShowWindow(hWnd, SW_SHOW);

  print('Press Enter at the command line to close.');
  stdin.readLineSync();

  DestroyWindow(hWnd);
}

// Documentation on this function here:
// https://docs.microsoft.com/en-us/windows/win32/dlgbox/using-dialog-boxes
int dialogReturnProc(int hwndDlg, int message, int wParam, int lParam) {
  switch (message) {
    case WM_COMMAND:
      {
        switch (LOWORD(wParam)) {
          case IDOK:
            print('OK');
            EndDialog(hwndDlg, wParam);
            return TRUE;
          case IDCANCEL:
            print('Cancel');
            EndDialog(hwndDlg, wParam);
            return TRUE;
        }
      }
  }

  return FALSE;
}
