unit DWServer;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, ExtCtrls, StdCtrls,
  Controls, Buttons, Forms,
  Dialogs, OoMisc, AdPort, AdSelCom, jpeg,
  VirtualDrive, ToolWin, ComCtrls, Menus, IniFiles, DateUtils, VirtualPrinter;

type
  TProtocol = function (COMObject : TApdComPort; Count : Word) : Integer of object;

  TDWForm = class(TForm)
    DrivePanel: TPanel;
    CoCoType: TBitBtn;
    CheckBoxLogging : TCheckBox;
    Image1: TImage;
    LoggingTimerEffects: TTimer;
    PortComboBox: TComboBox;
    CheckBoxStatistics: TCheckBox;
    MemoLog: TMemo;
    ClearLogButton: TButton;
    CopyLogButton: TButton;
    GroupBoxStatistics: TGroupBox;
    EditLastOpCode: TEdit;
    EditLastLSN: TEdit;
    EditSectorsRead: TEdit;
    EditSectorsWritten: TEdit;
    EditLastGetStat: TEdit;
    EditLastSetStat: TEdit;
    EditReadRetries: TEdit;
    EditWriteRetries: TEdit;
    EditReadsOK: TEdit;
    EditWritesOK: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    StatisticsTimerEffects: TTimer;
    procedure StatisticsTimerEffectsTimer(Sender: TObject);
    procedure CheckBoxStatisticsClick(Sender: TObject);
    procedure CopyLogButtonClick(Sender: TObject);
    procedure ClearLogButtonClick(Sender: TObject);
    procedure ResetButtonClick(Sender: TObject);
    procedure LoggingTimerEffectsTimer(Sender: TObject);
    procedure CheckBoxLoggingClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure CoCoTypeClick(Sender: TObject);
    procedure ApdComPortTriggerAvail(CP: TObject; Count: Word);
    procedure COMBoxClick(Sender: TObject);
  private
    { Private declarations }

    NextProc    : TProtocol;
    COMPort     : TApdComPort;
    Drive       : array[0..3] of TVDrive;
    Settings    : TIniFile;
    Retry       : Boolean;
    TargetWidth, WidthDirection : Integer;
    TargetHeight, HeightDirection : Integer;
    INIVersion   : Integer;
    byteCount    : Integer;
    bytes        : String;
    postRead     : Integer;
    errorByte    : Char;
    DriveNum     : Integer;
    CSum         : Integer;
    cocoCSum     : Integer;
    LSN          : Integer;
    printer      : TVirtualPrinterForm;

    // DriveWire Protocol Procedures
    function DWPPCommand(COMObject: TApdComPort; Count: Word) : Integer;
    function DoOP_RESET(COMObject: TApdComPort; Count: Word) : Integer;
    function DoOP_PRINT(COMObject: TApdComPort; Count: Word) : Integer;
    function DoOP_PRINTFLUSH(COMObject: TApdComPort; Count: Word) : Integer;
    function DoOP_INIT(COMObject: TApdComPort; Count: Word) : Integer;
    function DoOP_READ(COMObject: TApdComPort; Count: Word) : Integer;
    function DoOP_REREAD(COMObject: TApdComPort; Count: Word) : Integer;
    function DoOP_READEX(COMObject: TApdComPort; Count: Word) : Integer;
    function DoOP_REREADEX(COMObject: TApdComPort; Count: Word) : Integer;
    function DoOP_WRITE(COMObject: TApdComPort; Count: Word) : Integer;
    function DoOP_REWRITE(COMObject: TApdComPort; Count: Word) : Integer;
    function DoOP_GETSTAT(COMObject: TApdComPort; Count: Word) : Integer;
    function DoOP_SETSTAT(COMObject: TApdComPort; Count: Word) : Integer;
    function DoOP_TERM(COMObject: TApdComPort; Count: Word) : Integer;
    function DoOP_TIME(COMObject: TApdComPort; Count: Word) : Integer;

    function DoCSum(Sector : PChar) : Integer;
    procedure SetCoCoButton(BaudRate : Integer);
    function StatCodeToString(Code : Integer) : String;
    procedure LogMessage(Message: String);

  public
    { Public declarations }
  end;

const
  CURRENT_INI_VERSION = 1;

{$R DWServer.RES}


var
  DWForm: TDWForm;

implementation

{$R *.dfm}


procedure TDWForm.FormDestroy(Sender: TObject);
var
  i : Integer;
begin
  Settings.WriteInteger('Version', 'INI', CURRENT_INI_VERSION);
  Settings.WriteInteger('COM', 'Port', Integer(PortComboBox.Items.Objects[PortComboBox.ItemIndex]));
  Settings.WriteInteger('COM', 'Baud', COMPort.Baud);

  for i:= 0 to 3 do
  begin
    Settings.WriteString('Disks', 'Disk' + IntToStr(i), Drive[i].DiskPath);
  end;

  Settings.WriteInteger('Logging', 'LogFlag', Integer(CheckBoxLogging.Checked));
  Settings.WriteInteger('Logging', 'StatsFlag', Integer(CheckBoxStatistics.Checked));

  Settings.WriteString('Print', 'Buffer', printer.GetBuffer());
  Settings.WriteInteger('Position', 'Top', Top);
  Settings.WriteInteger('Position', 'Left', Left);

  Settings.Destroy;

  printer.Destroy;
end;


procedure TDWForm.FormCreate(Sender: TObject);
var
  i, SavedCom : Integer;
  t : String;
begin
  (* Initialize vars, drive handles and file names *)
  Retry := false;
  NextProc := DWPPCommand;
  COMPort := TApdComPort.Create(self);
  COMPort.AutoOpen := False;
  COMPort.DataBits := 8;
  COMPort.DTR := false;
  COMPort.OnTriggerAvail := ApdComPortTriggerAvail;
  COMPort.Baud := 115200;
  printer := TVirtualPrinterForm.Create(self);

  DrivePanel.Width := 0;
  DrivePanel.Height := 0;

  bytes := '';
  byteCount := 0;

  for i := 0 to 3 do
  begin
    Drive[3 - i] := TVDrive.Create(DrivePanel);
    Drive[3 - i].Top := (i * Drive[3 - i].Height);
    Drive[3 - i].Left := 0;
    Drive[3 - i].Parent := DrivePanel;
    Drive[3 - i].Visible := true;
    Drive[3 - i].Enabled := true;
    Drive[3 - i].Show;
    Drive[3 - i].DriveNum := (3 - i);

    DrivePanel.Width := Drive[3 - i].Width;
    DrivePanel.Height := DrivePanel.Height + Drive[3 - i].Height;

  end;

//  EditSectorsRead.Text := '';
//  EditSectorsWritten.Text := '';

(*
  // Show available serial ports
  COMGroup.Items.Clear;
  COMGroup.Columns := 2;
  for i := 1 to 8 do begin
    COMGroup.Items.Add ('COM' + IntToStr (i));
    if IsPortAvailable(i) = false then
      COMGroup.Buttons[i - 1].Enabled := false;
  end;
*)

  // Show available serial ports
  PortComboBox.Clear;
  PortComboBox.AddItem('No Device', Pointer(0));
  for i := 1 to 12 do
  try
    if IsPortAvailable(i) = true then
    begin
      PortComboBox.AddItem('COM' + IntToStr(i), Pointer(i));
    end;
  except on E:Exception do
  end;

  PortComboBox.ItemIndex := 0;

  // Read INI file
  Settings := TIniFile.Create('drivewire.ini');
  INIVersion := Settings.ReadInteger('Version', 'INI', 0);

  if INIVersion > CURRENT_INI_VERSION then begin
    MessageDlg('The INI file was created by a newer version of DriveWire',
      mtWarning, [mbOK], 0);
  end;

  SavedCom := Settings.ReadInteger('COM', 'Port', 0);
  for I := 0 to PortComboBox.Items.Count - 1 do
  begin
    if Integer(PortComboBox.Items.Objects[i]) = SavedCom then
    begin
      PortComboBox.ItemIndex := i;
      COMBoxClick(self);
      break;
    end;
  end;

  // COM Info
  SetCoCoButton(Settings.ReadInteger('COM', 'Baud', 115200));

  // Logging
  CheckBoxLogging.Checked := Boolean(Settings.ReadInteger('Logging', 'LogFlag', 0));
  CheckBoxStatistics.Checked := Boolean(Settings.ReadInteger('Logging', 'StatsFlag', 0));

  // Printing
  printer.SetBuffer(Settings.ReadString('Print', 'Buffer', ''));

  // Position
  Top := Settings.ReadInteger('Position', 'Top', 30);
  Left := Settings.ReadInteger('Position', 'Left', 30);

  // Disks
  for i := 0 to 3 do
  begin
    t := Settings.ReadString('Disks', 'Disk' + IntToStr(i), '');

    if t <> '' then
    begin
      Drive[i].DiskPath := t;
    end;
  end;

  // Set up logging memo
  MemoLog.Clear;

end;


procedure TDWForm.ApdComPortTriggerAvail(CP: TObject; Count: Word);
begin
  (* Called when data is available from the serial port *)
  NextProc(ComPort, Count);
end;

procedure TDWForm.COMBoxClick(Sender: TObject);
begin
  if COMPort.ComNumber <> Integer(PortComboBox.Items.Objects[PortComboBox.ItemIndex]) then
  begin
    // Close the COM port
    COMPort.Open := false;

    // Determine which port was clicked on
    if PortComboBox.ItemIndex > 0 then
    begin
      COMPort.ComNumber := Integer(PortComboBox.Items.Objects[PortComboBox.ItemIndex]);

      // Open the new COM port
      try
        COMPort.Open := true;
      except
        on E : Exception do
        begin
          if E.ClassName = 'EAlreadyOpen' then
          begin
            ShowMessage('This port is already in use by another application.');
          end
          else
            ShowMessage(E.ClassName+' error raised, with message : '+E.Message);
          COMPort.ComNumber := 0;
          PortComboBox.ItemIndex := 0;
        end;
      end;
    end
    else
    begin
      PortComboBox.ItemIndex := 0;
      COMPort.ComNumber := 0;
    end;
  end;
end;


(*
 * Processes the command byte (the first byte) of a DriveWire packet
 *)
function TDWForm.DWPPCommand(COMObject : TApdComPort; Count : Word) : Integer;
var
  commandChar : char;
begin
  // Go no further if the count is zero
  while Count > 0 do begin
    Count := Count - 1;

    // Get the command character
    commandChar := COMObject.GetChar;

    if (commandChar = Char(255)) OR (commandChar = Char(254)) then
    begin
          // OP_RESET: no other bytes coming in... call directly
          Count := DoOP_RESET(COMObject, Count);
    end
    else
    case commandChar of
      'F':
        begin
          // OP_PRINTFLUSH: no other bytes coming in... call directly
          Count := DoOP_PRINTFLUSH(COMObject, Count);
        end;

      'P':
        begin
          // OP_PRINT: send subsequent bytes to the next function
          NextProc := DoOP_PRINT;
          Count := NextProc(COMObject, Count);
        end;

      'I':
        begin
          // OP_INIT: no other bytes coming in... call directly
          Count := DoOP_INIT(COMObject, Count);
        end;

      'R':
        begin
          // OP_READ: send subsequent bytes to the next function
          NextProc := DoOP_READ;
          Count := NextProc(COMObject, Count);
        end;

      'r':
        begin
          // OP_REREAD: send subsequent bytes to the next function
          NextProc := DoOP_REREAD;
          Count := NextProc(COMObject, Count);
        end;

      #210: // 'R'+128
        begin
          // OP_READEX: send subsequent bytes to the next function
          NextProc := DoOP_READEX;
          Count := NextProc(COMObject, Count);
        end;

      #242: // 'r'+128
        begin
          // OP_REREADEX: send subsequent bytes to the next function
          NextProc := DoOP_REREADEX;
          Count := NextProc(COMObject, Count);
        end;

      'W':
        begin
          // OP_WRITE: send subsequent bytes to the next function
          NextProc := DoOP_WRITE;
          Count := NextProc(COMObject, Count);
        end;

      'w':
        begin
          // OP_REWRITE: send subsequent bytes to the next function
          NextProc := DoOP_REWRITE;
          Count := NextProc(COMObject, Count);
        end;

      'G':
        begin
          // OP_GETSTAT: send subsequent bytes to the next function
          NextProc := DoOP_GETSTAT;
          Count := NextProc(COMObject, Count);
        end;

      'S':
        begin
          // OP_SETSTAT: send subsequent bytes to the next function
          NextProc := DoOP_SETSTAT;
          Count := NextProc(COMObject, Count);
        end;

      'T':
        begin
          // OP_TERM: no other bytes coming in... call directly
          Count := DoOP_TERM(COMObject, Count);
        end;

      '#':
        begin
          // OP_TIME: no other bytes coming in... call directly
          Count := DoOP_TIME(COMObject, Count);
        end;
    end;
  end;

  Result := Count;

end;

function TDWForm.DoOP_PRINT(COMObject: TApdComPort; Count: Word) : Integer;
begin
  while (Count > 0) AND (byteCount < 1) do begin
    // Harvest available bytes
    byteCount := byteCount + 1;
    bytes := bytes + COMObject.GetChar;
    Count := Count - 1;
  end;

  if byteCount = 1 then
  begin
    byteCount := 0;
    NextProc  := DWPPCommand;     // reset next function ptr
    printer.AddByteToBuffer(bytes[1]);
    bytes     := '';              // reset byte buffer
  end;
  Result := Count;
end;

function TDWForm.DoOP_PRINTFLUSH(COMObject: TApdComPort; Count: Word) : Integer;
begin
  EditLastOpCode.Text := 'OP_PRINTFLUSH';
  if CheckBoxLogging.Checked = true then
  begin
    LogMessage(EditLastOpCode.Text);
  end;
  Result := Count;

  // Flush the contents of the printer buffer to the printer
  // Clear the printer buffer
  printer.Flush();
end;


function TDWForm.DoOP_INIT(COMObject: TApdComPort; Count: Word) : Integer;
begin
  EditLastOpCode.Text := 'OP_INIT';
  if CheckBoxLogging.Checked = true then
  begin
    LogMessage(EditLastOpCode.Text);
  end;
  Result := Count;
end;


function TDWForm.DoOP_READ(COMObject: TApdComPort; Count: Word) : Integer;
var
  PSector         : PChar;
  Sector          : Array[0..255] of Byte;
  DriveNum        : Integer;
  LSN             : Integer;
  tempInt         : Integer;
  sectsRead       : Double;
  sectsReRead     : Double;
  readPlusReRead  : Double;
  percentage      : Double;
  CSum            : Integer;
  ErrorByte       : Char;
  LogStr          : String;
  CSumStr         : String;

begin
  while (Count > 0) AND (byteCount < 4) do
  begin
    // Harvest available bytes
    byteCount := byteCount + 1;
    bytes := bytes + COMObject.GetChar;
    Count := Count - 1;
  end;

  (* Enter this conditional if we have all 4 bytes *)
  if byteCount = 4 then begin
    byteCount := 0;               // reset byte count
    PSector   := @Sector;         // point to sector buffer
    NextProc  := DWPPCommand;     // reset next function ptr

    DriveNum  := Integer(bytes[1]);
    LSN       := Integer(bytes[2]) * 65536
              + Integer(bytes[3]) * 256
              + Integer(bytes[4]);

    bytes     := '';              // reset bytes buffer

    // Determine validity of drive number
    if (DriveNum < 0) OR (DriveNum > 3) then
    begin
      // Send E$UNIT error and exit function
      ErrorByte := Char(240);
      COMObject.PutChar(ErrorByte);

      Retry := false;
      Result := count;

      exit;
    end;

    // Seek and Read sector
    CSum := 0;

    if Drive[DriveNum].ReadSector(LSN, PSector) = 0 then
    begin
      ErrorByte := Char(0);
      COMObject.PutChar(ErrorByte);

      // Send sector to client
      COMObject.PutBlock(Sector, 256);

      // Compute checksum
      CSum := DoCSum(PSector);
      CSumStr := Char((CSum SHR 8) AND 255) + Char(CSum AND 255);

      // Send checksum data
      COMObject.PutString(CSumStr);
    end else
    begin
      // Send error
      ErrorByte := Char(244);
      COMObject.PutChar(ErrorByte);
    end;

    // Update statistics/log
    EditLastLSN.Text := IntToStr(LSN);

    if Retry = true then
    begin
      EditLastOpCode.Text := 'OP_REREAD';
      tempInt := StrToInt(EditReadRetries.Text);
      Inc(tempInt);
      EditReadRetries.Text := IntToStr(tempInt);
    end
    else
    begin
      EditLastOpCode.Text := 'OP_READ';
      tempInt := StrToInt(EditSectorsRead.Text);
      Inc(tempInt);
      EditSectorsRead.Text := IntToStr(tempInt);
    end;

    if CheckBoxLogging.Checked = true then
    begin
      LogStr := EditLastOpCode.Text + '[' + IntToStr(DriveNum) + '] LSN[' + EditLastLSN.Text + '] Checksum[' + IntToStr(CSum) + '] Error[' + IntToStr(Integer(ErrorByte)) + ']';
      LogMessage(LogStr);
    end;

    if EditSectorsRead.Text <> '0' then
    begin
      sectsRead := StrToFloat(EditSectorsRead.Text);
      sectsReRead := StrToFloat(EditReadRetries.Text);
      readPlusReRead := sectsRead + sectsReRead;

      if readPlusReRead > 0 then
      begin
        percentage := (sectsRead / readPlusReRead) * 100;
        EditReadsOk.Text := FloatToStr(percentage) + '%';
      end;
    end;

    NextProc := DWPPCommand;
  end;

  Retry := false;

  Result := Count;
end;


function TDWForm.DoOP_READEX(COMObject: TApdComPort; Count: Word) : Integer;
var
  PSector         : PChar;
  Sector          : Array[0..255] of Byte;
  tempInt         : Integer;
  sectsRead       : Double;
  sectsReRead     : Double;
  readPlusReRead  : Double;
  percentage      : Double;
  LogStr          : String;

begin
  if (postRead = 0) then
  begin
    while (Count > 0) AND (byteCount < 4) do
    begin
      // Harvest available bytes
      byteCount := byteCount + 1;
      bytes := bytes + COMObject.GetChar;
      Count := Count - 1;
    end;

    (* Enter this conditional if we have all 4 bytes *)
    if byteCount = 4 then
    begin
      postRead  := 1;
      byteCount := 0;               // reset byte count
      PSector   := @Sector;         // point to sector buffer

      DriveNum  := Integer(bytes[1]);
      LSN       := Integer(bytes[2]) * 65536
                + Integer(bytes[3]) * 256
                + Integer(bytes[4]);

      bytes     := '';              // reset bytes buffer

      // Determine validity of drive number
      if (DriveNum < 0) OR (DriveNum > 3) then
      begin
        // Send E$UNIT error and exit function
        ErrorByte := Char(240);
      end
      else
      begin
        // Seek and Read sector
        if Drive[DriveNum].ReadSector(LSN, PSector) = 0 then
        begin
          CSum := DoCSum(PSector);
          ErrorByte := Char(0);
        end
        else
        begin
          ErrorByte := Char(244);
        end;
      end;

      // Send sector to client
      COMObject.PutBlock(Sector, 256);
    end;
  end
  else
  // postRead = 1
  begin
    while (Count > 0) AND (byteCount < 2) do
    begin
      // Harvest available bytes
      byteCount := byteCount + 1;
      bytes := bytes + COMObject.GetChar;
      Count := Count - 1;
    end;
    if byteCount = 2 then
    begin
      // Get checksum from CoCo
      cocoCSum := Integer(bytes[1]) * 256 + Integer(bytes[2]);
      bytes := '';
      byteCount := 0;
      postRead := 0;
      NextProc  := DWPPCommand;     // reset next function ptr

      // Compute checksum
      // Compare checksum data
      if (ErrorByte = Char(0)) AND (CSum <> cocoCSum) then
      begin
        ErrorByte := Char(243);
      end;

      // Send error
      COMObject.PutChar(ErrorByte);

      // Update statistics/log
      EditLastLSN.Text := IntToStr(LSN);

      if Retry = true then
      begin
        EditLastOpCode.Text := 'OP_REREADEX';
        tempInt := StrToInt(EditReadRetries.Text);
        Inc(tempInt);
        EditReadRetries.Text := IntToStr(tempInt);
      end
      else
      begin
        EditLastOpCode.Text := 'OP_READEX';
        tempInt := StrToInt(EditSectorsRead.Text);
        Inc(tempInt);
        EditSectorsRead.Text := IntToStr(tempInt);
      end;

      if CheckBoxLogging.Checked = true then
      begin
        LogStr := EditLastOpCode.Text + '[' + IntToStr(DriveNum) + '] LSN[' + EditLastLSN.Text + '] Checksum[' + IntToStr(CSum) + '] Error[' + IntToStr(Integer(ErrorByte)) + ']';
        LogMessage(LogStr);
      end;

      if EditSectorsRead.Text <> '0' then
      begin
        sectsRead := StrToFloat(EditSectorsRead.Text);
        sectsReRead := StrToFloat(EditReadRetries.Text);
        readPlusReRead := sectsRead + sectsReRead;

        if readPlusReRead > 0 then
        begin
          percentage := (sectsRead / readPlusReRead) * 100;
          EditReadsOk.Text := FloatToStr(percentage) + '%';
        end;
      end;
    end;
  end;
  Retry := false;

  Result := Count;
end;


function TDWForm.DoOP_REREAD(COMObject: TApdComPort; Count: Word) : Integer;
begin
  Retry := true;
  Result := DoOP_READ(COMObject, Count);
end;


function TDWForm.DoOP_REREADEX(COMObject: TApdComPort; Count: Word) : Integer;
begin
  Retry := true;
  Result := DoOP_READEX(COMObject, Count);
end;


function TDWForm.DoOP_WRITE(COMObject: TApdComPort; Count: Word) : Integer;
var
  PSector           : PChar;
  DriveNum          : Integer;
  LSN               : Integer;
  tempInt           : Integer;
  sectsWritten      : Double;
  sectsReWritten    : Double;
  writePlusReWrite  : Double;
  percentage        : Double;
  CSum              : Integer;
  CSumStr           : String;
  LogStr            : String;
  ErrorByte         : Char;

begin
  while (Count > 0) AND (byteCount < 262) do begin
    // Harvest available bytes
    byteCount := byteCount + 1;
    bytes := bytes + COMObject.GetChar;
    Count := Count - 1;
  end;

  if byteCount = 262 then
  begin
    byteCount := 0;               // reset byte count
    PSector   := @bytes[5];       // point to sector buffer
    NextProc  := DWPPCommand;     // reset next function ptr

    DriveNum  := Integer(bytes[1]);
    LSN       := Integer(bytes[2]) * 65536
              + Integer(bytes[3]) * 256
              + Integer(bytes[4]);

    // Determine validity of drive number
    if (DriveNum < 0) OR (DriveNum > 3) then
    begin
      // Send E$UNIT error and exit function
      ErrorByte := Char(240);
      COMObject.PutChar(ErrorByte);

      Retry := false;
      Result := count;

      exit;
    end;

    if EditSectorsWritten.Text <> '0' then
    begin
      sectsWritten := StrToFloat(EditSectorsWritten.Text);
      sectsReWritten := StrToFloat(EditWriteRetries.Text);
      writePlusReWrite := sectsWritten + sectsReWritten;

      if writePlusReWrite > 0 then
      begin
        percentage := (sectsWritten / writePlusReWrite) * 100;
        EditWritesOk.Text := FloatToStr(percentage) + '%';
      end;
    end;

    // Compute checksum
    CSum := DoCSum(PSector);
    CSumStr := Char((CSum SHR 8) AND 255) + Char(CSum AND 255);

    if (CSumStr[1] = bytes[261]) AND (CSumStr[2] = bytes[262]) then
    begin
      // Seek and Write sector
      if Drive[DriveNum].WriteSector(LSN, PSector) = 0 then
      begin
        // Send SUCCESS
        ErrorByte := Char(0);
      end
      else
      begin
        // Send error
        ErrorByte := Char(245);
      end;
      COMObject.PutChar(ErrorByte);
    end
    else
    begin
      // Send CRC error
      ErrorByte := Char(243);
      COMObject.PutChar(ErrorByte);
    end;

    bytes    := '';

    // Update statistics/log
    EditLastLSN.Text := IntToStr(LSN);
    if Retry = true then
    begin
      EditLastOpCode.Text := 'OP_REWRITE';
      tempInt := StrToInt(EditWRiteRetries.Text);
      Inc(tempInt);
      EditWriteRetries.Text := IntToStr(tempInt);
    end
    else
    begin
      EditLastOpCode.Text := 'OP_WRITE';
      tempInt := StrToInt(EditSectorsWritten.Text);
      Inc(tempInt);
      EditSectorsWritten.Text := IntToStr(tempInt);
    end;
    if CheckBoxLogging.Checked = true then
    begin
      LogStr := EditLastOpCode.Text + '[' + IntToStr(DriveNum) + '] LSN[' + EditLastLSN.Text + '] Checksum[' + IntToStr(CSum) + '] Error[' + IntToStr(Integer(ErrorByte)) + ']';
      LogMessage(LogStr);
    end;

    Retry := false;
  end;

  Result := Count;
end;


function TDWForm.DoOP_REWRITE(COMObject: TApdComPort; Count: Word) : Integer;
begin
  Retry := true;
  Result := DoOP_WRITE(COMObject, Count);
end;


function TDWForm.DoOP_GETSTAT(COMObject: TApdComPort; Count: Word) : Integer;
var
  DriveNum  : Integer;
  GSCode    : Integer;

begin
  while (Count > 0) AND (byteCount < 2) do begin
    // Harvest available bytes
    byteCount := byteCount + 1;
    bytes := bytes + COMObject.GetChar;
    Count := Count - 1;
  end;

  if byteCount = 2 then
  begin
    byteCount := 0;               // reset byte count
    NextProc  := DWPPCommand;     // reset next function ptr

    DriveNum  := Integer(bytes[1]);
    GSCode    := Integer(bytes[2]);
    EditLastOpCode.Text := 'OP_GETSTAT';
    EditLastGetStat.Text := StatCodeToString(GSCode);
    if CheckBoxLogging.Checked = true then
    begin
      LogMessage(EditLastOpCode.Text + '[' + IntToStr(DriveNum) + '] Code[' + EditLastGetStat.Text + ']');
    end;
    bytes     := '';              // reset byte buffer
  end;

  Result := Count;
end;


function TDWForm.DoOP_SETSTAT(COMObject: TApdComPort; Count: Word) : Integer;
var
  DriveNum  : Integer;
  SSCode    : Integer;

begin
  while (Count > 0) AND (byteCount < 2) do begin
    // Harvest available bytes
    byteCount := byteCount + 1;
    bytes := bytes + COMObject.GetChar;
//    bytes[byteCount] := COMObject.GetChar;
    Count := Count - 1;
  end;

  if byteCount = 2 then
  begin
    byteCount := 0;               // reset byte count
    NextProc  := DWPPCommand;     // reset next function ptr

    DriveNum  := Integer(bytes[1]);
    SSCode    := Integer(bytes[2]);
    EditLastOpCode.Text := 'OP_SETSTAT';
    EditLastSetStat.Text := StatCodeToString(SSCode);
    if CheckBoxLogging.Checked = true then
    begin
      LogMessage(EditLastOpCode.Text + '[' + IntToStr(DriveNum) + '] Code[' + EditLastSetStat.Text + ']');
    end;

    bytes     := '';              // reset byte buffer

    // Special: if setstat is SS.SQD, eject disk
    if EditLastSetStat.Text = 'SS.SQD' then
    begin
      Drive[DriveNum].EjectDisk;
    end;
  end;

  Result := Count;
end;


function TDWForm.DoOP_TERM(COMObject: TApdComPort; Count: Word) : Integer;
begin
  EditLastOpCode.Text := 'OP_TERM';
  if CheckBoxLogging.Checked = true then
  begin
    LogMessage(EditLastOpCode.Text);
  end;
  Result := Count;
end;


function TDWForm.DoOP_TIME(COMObject: TApdComPort; Count: Word) : Integer;
var
  Current : TDateTime;
begin
  // Get current time and send
  Current := Date + Time;

  COMObject.PutChar(Char(YearOf(Current) - 1900));
  COMObject.PutChar(Char(MonthOf(Current)));
  COMObject.PutChar(Char(DayOf(Current)));
  COMObject.PutChar(Char(HourOf(Current)));
  COMObject.PutChar(Char(MinuteOf(Current)));
  COMObject.PutChar(Char(SecondOf(Current)));

  EditLastOpCode.Text := 'OP_TIME';
  if CheckBoxLogging.Checked = true then
  begin
    LogMessage(EditLastOpCode.Text);
  end;
  Result := Count;
end;


function TDWForm.DoOP_RESET(COMObject: TApdComPort; Count: Word) : Integer;
begin
  ResetButtonClick(nil);
  EditLastOpCode.Text := 'OP_RESET';
  if CheckBoxLogging.Checked = true then
  begin
    LogMessage(EditLastOpCode.Text);
  end;
  Result := Count;
end;


function TDWForm.DoCSum(Sector : PChar) : Integer;
var
  i     : Integer;
begin
  Result := 0;

  for i :=0 to 255 do begin
    Result := Result + Integer(Sector^);
    Inc(Sector);
  end;
end;


procedure TDWForm.CoCoTypeClick(Sender: TObject);
begin
  case COMPort.Baud of
    38400:
      ComPort.Baud := 57600;
    57600:
      ComPort.Baud := 115200;
    115200:
      ComPort.Baud := 38400;
  end;

  SetCoCoButton(COMPort.Baud);
end;


procedure TDWForm.SetCoCoButton(BaudRate : Integer);
var
  ResStream : TResourceStream;
begin
  case BaudRate of
    38400:
    begin
      CoCoType.Caption := 'CoCo 1 @ 38,400 bps';
      ResStream := TResourceStream.Create(hInstance, 'COCO1', RT_RCDATA);
      CoCoType.Glyph.LoadFromStream(ResStream);
      ResStream.Destroy;
      COMPort.Baud := 38400;
    end;

    57600:
    begin
      CoCoType.Caption := 'CoCo 2 @ 57,600 bps';
      ResStream := TResourceStream.Create(hInstance, 'COCO2', RT_RCDATA);
      CoCoType.Glyph.LoadFromStream(ResStream);
      ResStream.Destroy;
      COMPort.Baud := 57600;
    end;

    115200:
    begin
      CoCoType.Caption := 'CoCo 3 @ 115,200 bps';
      ResStream := TResourceStream.Create(hInstance, 'COCO3', RT_RCDATA);
      CoCoType.Glyph.LoadFromStream(ResStream);
      ResStream.Destroy;
      COMPort.Baud := 115200;
    end;
  end;
end;


procedure TDWForm.CheckBoxLoggingClick(Sender: TObject);
begin
  if CheckBoxLogging.Checked = true then
  begin
    HeightDirection := 1;
    TargetHeight := Height + MemoLog.Height + 54;
  end
  else
  begin
    HeightDirection := 0;
    TargetHeight := Height - MemoLog.Height - 54;
  end;

  LoggingTimerEffects.Enabled := true;
end;


procedure TDWForm.CheckBoxStatisticsClick(Sender: TObject);
begin
  if CheckBoxStatistics.Checked = true then
  begin
    WidthDirection := 1;
    TargetWidth := Width + GroupBoxStatistics.Width + 10;
  end
  else
  begin
    WidthDirection := 0;
    TargetWidth := Width - GroupBoxStatistics.Width - 10;
  end;

  StatisticsTimerEffects.Enabled := true;
end;


procedure TDWForm.StatisticsTimerEffectsTimer(Sender: TObject);
begin
  if WidthDirection = 1 then begin
    Width := Width + 20;
    MemoLog.Width := MemoLog.Width + 20;
    CopyLogButton.Left := CopyLogButton.Left + 20;
    if Width >= TargetWidth then begin
      StatisticsTimerEffects.Enabled := false;
    end;
  end
  else
  begin
    Width := Width - 20;
    MemoLog.Width := MemoLog.Width - 20;
    CopyLogButton.Left := CopyLogButton.Left - 20;
    if Width <= TargetWidth then begin
      StatisticsTimerEffects.Enabled := false;
    end;
  end;
end;


procedure TDWForm.LoggingTimerEffectsTimer(Sender: TObject);
begin
  if HeightDirection = 1 then begin
    Height := Height + 24;
    if Height >= TargetHeight then
    begin
      LoggingTimerEffects.Enabled := false;
    end;
  end
  else
  begin
    Height := Height - 24;
    if Height <= TargetHeight then
    begin
      LoggingTimerEffects.Enabled := false;
    end;
  end;
end;

procedure TDWForm.ResetButtonClick(Sender: TObject);
begin
  EditLastOpCode.Text := 'NONE';
  EditLastLSN.Text := '0';
  EditSectorsRead.Text := '0';
  EditSectorsWritten.Text := '0';
  EditLastGetStat.Text := '0';
  EditLastSetStat.Text := '0';
  EditReadRetries.Text := '0';
  EditWriteRetries.Text := '0';
  EditReadsOK.Text := '0';
  EditWritesOK.Text := '0';
end;


procedure TDWForm.ClearLogButtonClick(Sender: TObject);
begin
  MemoLog.Clear;
end;


procedure TDWForm.CopyLogButtonClick(Sender: TObject);
begin
  MemoLog.SelectAll;
  MemoLog.CopyToClipboard;
  MemoLog.SelLength := 0;
end;


function TDWForm.StatCodeToString(Code : Integer) : String;
begin
  case Code of
   $00:
    begin
      result := 'SS.Opt'
    end;
   $02:
    begin
      result := 'SS.Size'
    end;
   $03:
    begin
      result := 'SS.Reset'
    end;
   $04:
    begin
      result := 'SS.WTrk'
    end;
   $05:
    begin
      result := 'SS.Pos'
    end;
   $06:
    begin
      result := 'SS.EOF'
    end;
   $0A:
    begin
      result := 'SS.Frz'
    end;
   $0B:
    begin
      result := 'SS.SPT'
    end;
   $0C:
    begin
      result := 'SS.SQD'
    end;
   $0D:
    begin
      result := 'SS.DCmd'
    end;
   $0E:
    begin
      result := 'SS.DevNm'
    end;
   $0F:
    begin
      result := 'SS.FD'
    end;
   $10:
    begin
      result := 'SS.Ticks'
    end;
   $11:
    begin
      result := 'SS.Lock'
    end;
   $12:
    begin
      result := 'SS.VarSect'
    end;
   $13:
    begin
      result := 'SS.Eject'
    end;
   $14:
    begin
      result := 'SS.BlkRd'
    end;
   $15:
    begin
      result := 'SS.BlkWr'
    end;
   $16:
    begin
      result := 'SS.Reten'
    end;
   $17:
    begin
      result := 'SS.WFM'
    end;
   $18:
    begin
      result := 'SS.RFM'
    end;
   $1B:
    begin
      result := 'SS.Relea'
    end;
   $1C:
    begin
      result := 'SS.Attr'
    end;
   $1E:
    begin
      result := 'SS.RsBit'
    end;
   $20:
    begin
      result := 'SS.FDInf'
    end;
   $26:
    begin
      result := 'SS.DSize'
    end;
   else
    begin
      result := IntToStr(Code);
    end;
  end;
end;


procedure TDWForm.LogMessage(Message : String);
var
  Current : String;
begin
  DateTimeToString(Current, 'yyyy-mm-dd hh:nn:ss', Date + Time);
  MemoLog.Lines.Add(Current + ' ' + Message);
end;


end.

