program DriveWire;

uses
  Forms,
  DWServer in 'DWServer.pas' {DWForm},
  IniFiles,
  VirtualPrinter in 'VirtualPrinter.pas' {VirtualPrinterForm};

{$R *.res}

 
begin
  Application.Initialize;
  Application.Title := 'DriveWire WinServer';
  Application.CreateForm(TDWForm, DWForm);
  Application.CreateForm(TVirtualPrinterForm, VirtualPrinterForm);
  Application.Run;
end.

