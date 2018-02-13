unit DummyGeosUse;

interface

uses
  Geos_c;

implementation

uses
  Dialogs;

{
  GEOS Callback functions
}
procedure GEOSNoticeProc(fmt:PGEOSChar; args:array of const); cdecl;
begin
  // TODO
  MessageDlg('GEOSNoticeProc called: ' + PAnsiChar(fmt), mtConfirmation, [mbOK], 0);
end;

procedure GEOSErrorProc(fmt:PGEOSChar; args:array of const); cdecl;
begin
  // TODO
  MessageDlg('GEOSErrorProc called: ' + PAnsiChar(fmt), mtConfirmation, [mbOK], 0);
end;

initialization

initGEOS(GEOSNoticeProc, GEOSErrorProc);

finalization

finishGEOS;



end.

