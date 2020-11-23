import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'package:win32/win32.dart';
import 'utils.dart';

const sizeOfDlgTemplate = 18;
const sizeOfDlgitemTemplate = 18;

final hInstance = GetModuleHandle(nullptr);

void main() {
  // Allocate sufficient space for the dialog in memory.
  final ptr = allocate<Uint8>(count: 1024);
  var idx = 0;

  idx = setDialog(ptr.elementAt(idx),
      style: WS_POPUP | WS_VISIBLE | WS_SYSMENU | DS_MODALFRAME,
      dwExtendedStyle: WS_EX_TOPMOST,
      cdit: 2,
      cx: 300,
      cy: 200);

  idx += setDialogItem(ptr.elementAt(idx),
      style: WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_PUSHBUTTON | WS_BORDER,
      dwExtendedStyle: WS_EX_NOPARENTNOTIFY,
      x: 100,
      y: 160,
      cx: 50,
      cy: 14,
      id: IDOK,
      windowSystemClass: 0x0080, // button
      text: 'OK',
      creationData: 0);

  idx += setDialogItem(ptr.elementAt(idx),
      style: WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_PUSHBUTTON | WS_BORDER,
      dwExtendedStyle: WS_EX_NOPARENTNOTIFY,
      x: 190,
      y: 160,
      cx: 50,
      cy: 14,
      id: IDCANCEL,
      windowSystemClass: 0x0080, // button
      text: 'Cancel',
      creationData: 0);

  final lpDialogFunc = Pointer.fromFunction<DlgProc>(dialogReturnProc, 0);

  final nResult = DialogBoxIndirectParam(
      hInstance, ptr.cast<DLGTEMPLATE>(), NULL, lpDialogFunc, 0);

  if (nResult <= 0) {
    print('Error: $nResult}');
  }

  print(ptr
      .cast<Uint8>()
      .asTypedList(idx)
      .map((e) => e.toHexString(8))
      .join(', '));

  free(ptr);
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
