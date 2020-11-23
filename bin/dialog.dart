import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'package:win32/win32.dart';
import 'utils.dart';

const ID_TEXT = 200;
const ID_EDITTEXT = 201;

final hInstance = GetModuleHandle(nullptr);
var textEntered = '';

void main() {
  // Allocate 2KB, which should be sufficient space for the dialog in memory.
  final ptr = allocate<Uint16>(count: 1024);
  var idx = 0;

  idx = setDialog(ptr.elementAt(idx),
      style: WS_POPUP | WS_BORDER | WS_SYSMENU | DS_MODALFRAME | WS_CAPTION,
      title: 'Sample dialog',
      cdit: 4,
      cx: 300,
      cy: 200);

  idx += setDialogItem(ptr.elementAt(idx),
      style: WS_CHILD | WS_VISIBLE | BS_DEFPUSHBUTTON,
      x: 100,
      y: 160,
      cx: 50,
      cy: 14,
      id: IDOK,
      windowSystemClass: 0x0080, // button
      text: 'OK');

  idx += setDialogItem(ptr.elementAt(idx),
      style: WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
      x: 190,
      y: 160,
      cx: 50,
      cy: 14,
      id: IDCANCEL,
      windowSystemClass: 0x0080, // button
      text: 'Cancel');

  idx += setDialogItem(ptr.elementAt(idx),
      style: WS_CHILD | WS_VISIBLE,
      x: 10,
      y: 10,
      cx: 60,
      cy: 20,
      id: ID_TEXT,
      windowSystemClass: 0x0082, // static
      text: 'Some static wrapped text here.');

  idx += setDialogItem(ptr.elementAt(idx),
      style: WS_CHILD | WS_VISIBLE | WS_BORDER,
      x: 20,
      y: 50,
      cx: 100,
      cy: 20,
      id: ID_EDITTEXT,
      windowSystemClass: 0x0081, // edit
      text: '');

  final lpDialogFunc = Pointer.fromFunction<DlgProc>(dialogReturnProc, 0);

  final nResult = DialogBoxIndirectParam(
      hInstance, ptr.cast<DLGTEMPLATE>(), NULL, lpDialogFunc, 0);

  if (nResult <= 0) {
    print('Error: $nResult');
  } else {
    print('Entered: $textEntered');
  }

  // print(ptr
  //     .cast<Uint16>()
  //     .asTypedList(idx)
  //     .map((e) => e.toHexString(16))
  //     .join(', '));

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
            final textPtr = allocate<Uint16>(count: 256).cast<Utf16>();
            GetDlgItemText(hwndDlg, ID_EDITTEXT, textPtr, 256);
            textEntered = textPtr.unpackString(256);
            free(textPtr);
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
