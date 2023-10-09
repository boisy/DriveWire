(*
 * VirtualDrive Component
 *
 * (C) 2006 BGP
*)
unit VirtualDrive;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, jpeg, mmsystem;

  type
  TVDrive = class(TPanel)

  private
    { Private declarations }
    ImageDriveBody    : TImage;
    ImageDriveDoor    : TImage;
    ImageReadLED      : TImage;
    ImageWriteLED     : TImage;
    LEDTimer          : TTimer;
//    InsertDisk        : TImage;
//    EjectDisk         : TImage;

    LabelDiskLabel    : TLabel;
    LabelDriveNum     : TLabel;
    ButtonInsert      : TImage;
    ButtonEject       : TImage;
    DriveHandle       : TFileStream;

    // Statistical Data
    SectorsRead       : Integer;
    SectorsWritten    : Integer;
    FDiskPath         : TFileName;
    FDriveNum         : Integer;
    FReadLEDDuration  : Integer;
    FWriteLEDDuration : Integer;
    FSectorSize       : Integer;

    procedure OnInsertDisk(Sender: TObject);
    procedure OnEjectDisk(Sender: TObject);
    procedure OnLEDTimer(Sender : TObject);
    procedure TurnOnReadLED(Duration: Integer);
    procedure TurnOnWriteLED(Duration: Integer);
    procedure TurnOffLED;
    function GetDSKFile: string;
    procedure SetDiskPath(Value : TFileName);
    procedure SetDriveNum(Value : Integer);
    procedure SetReadLEDDuration(Value: Integer);
    procedure SetWriteLEDDuration(Value: Integer);
    procedure SetSectorSize(Value: Integer);

  protected
    { Protected declarations }
    function GetDiskPath: String;

  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function ReadSector(LSN : Integer; Sector : PChar) : Integer;
    function WriteSector(LSN : Integer; Sector : PChar) : Integer;

    procedure EjectDisk;

  published
    { Published declarations }
    property DiskPath : TFileName read FDiskPath write SetDiskPath;
    property DriveNum : Integer read FDriveNum write SetDriveNum;
    property SectorSize : Integer read FSectorSize write SetSectorSize;
    property ReadLEDDuration : Integer read FReadLEDDuration write SetReadLEDDuration;
    property WriteLEDDuration : Integer read FWriteLEDDuration write SetWriteLEDDuration;
end;

procedure Register;

//{$R *.DFM}
{$R VirtualDrive.RES}

implementation

(*
 * The constructor
 * Constructs all graphic and sound assets
 *)
constructor TVDrive.Create(AOwner: TComponent);
var
  ResStream : TResourceStream;
begin
  inherited Create(AOwner);

  // Construct drive body
  ImageDriveBody      := TImage.Create(Aowner);
  ImageDriveBody.Picture.Graphic := TJpegImage.Create;
  ResStream := TResourceStream.Create(HInstance, 'DRIVE', RT_RCDATA);
  ImageDriveBody.Picture.Graphic.LoadFromStream(ResStream);
  ResStream.Destroy;
  ImageDriveBody.AutoSize := true;
  ImageDriveBody.Parent := self;
  ImageDriveBody.Left := 0;
  ImageDriveBody.Top := 0;

  // Construct drive door
  ImageDriveDoor      := TImage.Create(ImageDriveBody);
  ImageDriveDoor.Picture.Graphic := TJpegImage.Create;
  ResStream := TResourceStream.Create(HInstance, 'DRIVEFACE', RT_RCDATA);
  ImageDriveDoor.Picture.Graphic.LoadFromStream(ResStream);
  ResStream.Destroy;
  ImageDriveDoor.Parent := self;
  ImageDriveDoor.AutoSize := true;
  ImageDriveDoor.Left := 37;
  ImageDriveDoor.Top := 15;
  ImageDriveDoor.Visible := false;

  // Construct read LED
  ImageReadLED        := TImage.Create(ImageDriveBody);
  ImageReadLED.Picture.Graphic := TJpegImage.Create;
  ResStream := TResourceStream.Create(HInstance, 'GREENLED', RT_RCDATA);
  ImageReadLED.Picture.Graphic.LoadFromStream(ResStream);
  ResStream.Destroy;
  ImageReadLED.AutoSize := true;
  ImageReadLED.Parent := self;
  ImageReadLED.Left := 110;
  ImageReadLED.Top := 45;
  ImageReadLED.Visible := false;
  ImageReadLED.ParentShowHint := false;

  // Construct write LED
  ImageWriteLED      := TImage.Create(ImageDriveBody);
  ImageWriteLED.Picture.Graphic := TJpegImage.Create;
  ResStream := TResourceStream.Create(HInstance, 'REDLED', RT_RCDATA);
  ImageWriteLED.Picture.Graphic.LoadFromStream(ResStream);
  ResStream.Destroy;
  ImageWriteLED.AutoSize := true;
  ImageWriteLED.Parent := self;
  ImageWriteLED.Left := 110;
  ImageWriteLED.Top := 45;
  ImageWriteLED.Visible := false;
  ImageWriteLED.ParentShowHint := false;

  // Construct disk label
  LabelDiskLabel := TLabel.Create(ImageDriveBody);
  LabelDiskLabel.AutoSize := true;
  LabelDiskLabel.Parent := self;
  LabelDiskLabel.Left := 63;
  LabelDiskLabel.Top := 18;
  LabelDiskLabel.Width := 108;
  LabelDiskLabel.Height := 12;
  LabelDiskLabel.Transparent := true;
  LabelDiskLabel.AutoSize := false;
  LabelDiskLabel.Visible := false;
  LabelDiskLabel.Caption := '';

  // Construct drive number label
  LabelDriveNum := TLabel.Create(ImageDriveBody);
  LabelDriveNum.AutoSize := true;
  LabelDriveNum.Parent := self;
  LabelDriveNum.Left := 14;
  LabelDriveNum.Top := 18;
  LabelDriveNum.Width := 20;
  LabelDriveNum.Height := 12;
  LabelDriveNum.Transparent := true;
  LabelDriveNum.AutoSize := true;
  LabelDriveNum.Visible := true;
  LabelDriveNum.Caption := '';
  LabelDriveNum.Font.Size := 18;
  LabelDriveNum.Caption := IntToStr(DriveNum);

  // Construct insert button
  ButtonInsert        := TImage.Create(ImageDriveBody);
  ButtonInsert.Parent := self;
  ButtonInsert.Top    := 18;
  ButtonInsert.Left   := 40;
  ButtonInsert.Width  := 158;
  ButtonInsert.Height := 16;
  ButtonInsert.OnClick  := OnInsertDisk;
  ButtonInsert.ParentShowHint := true;
  ButtonInsert.Hint := 'Click here to insert a new disk';

  // Construct eject button
  ButtonEject         := TImage.Create(ImageDriveBody);
  ButtonEject.Parent  := self;
  ButtonEject.Top     := 42;
  ButtonEject.Left    := 59;
  ButtonEject.Width   := 16;
  ButtonEject.Height  := 11;
  ButtonEject.OnClick := OnEjectDisk;
  ButtonEject.ParentShowHint := true;
  ButtonEject.Hint := 'Click here to eject the disk';

  // Construct timer
  LEDTimer := TTimer.Create(self);
  LEDTimer.Enabled := false;
  LEDTimer.OnTimer := OnLEDTimer;

  self.Width := ImageDriveBody.Width;
  self.Height := ImageDriveBody.Height;

  DriveHandle := nil;
  DiskPath := '';

  self.ShowHint := true;

  FSectorSize := 256;
  FDriveNum := 0;
  SetReadLEDDuration(100);
  SetWriteLEDDuration(100);

  SectorsRead := 0;
  SectorsWritten := 0;
end;



(*
 * The destructor
 * Destroys all graphic and sound assets
 *)
destructor TVDrive.Destroy;
begin
  if DriveHandle <> nil then
    DriveHandle.Destroy;

  // Destroy timer
  LEDTimer.Destroy;

  // Destroy eject button
  ButtonEject.Destroy;

  // Destroy insert button
  ButtonInsert.Destroy;

  // Destroy drive label
  LabelDriveNum.Destroy;

  // Destroy write LED
  ImageWriteLED.Destroy;

  // Destroy read LED
  ImageReadLED.Destroy;

  // Destroy drive label
  LabelDiskLabel.Destroy;

  // Destroy drive door
  ImageDriveDoor.Destroy;

  // Destroy drive body
  ImageDriveBody.Destroy;

  inherited Destroy;
end;



(*
 * Registers the component
 *)
procedure Register;
begin
  RegisterComponents('BGP', [TVDrive]);
end;



(*
 * Perform the file picking for the DSK file
 *)
function TVDrive.GetDSKFile : string;
var
  filePicker : TOpenDialog;
begin
  result := '';
  filePicker := TOpenDialog.Create(nil);
  filePicker.Title := 'Select Image for Drive ' + IntToStr(FDriveNum);
  filePicker.Filter := 'DSK Image|*.dsk|OS9 Image|*.os9';
  if filePicker.Execute = true then begin
    result := filePicker.FileName;
  end;
  filePicker.Destroy;
end;



(*
 * Insert a disk into the virtual drive
*)
procedure TVDrive.SetDiskPath(Value : TFileName);
begin
  (* Open a new path  *)
  if FDiskPath <> Value then
  begin
    (* Eject disk if there is one in the drive *)
    if DriveHandle <> nil then
    begin
      OnEjectDisk(self);
    end;

    FDiskPath := Value;

    (* Exit if an empty disk path is passed *)
    if FDiskPath = '' then
    begin
      exit;
    end;

    try
      begin
        TurnOnReadLED(FReadLEDDuration);
        DriveHandle := TFileStream.Create(DiskPath, fmOpenReadWrite OR fmShareDenyWrite);
      end;
    except on E:Exception do
      begin
        try
          begin
            DriveHandle := TFileStream.Create(DiskPath, fmCreate OR fmShareDenyWrite);
          end;
        except on E:Exception do
          begin
            ShowMessage(E.Message);
            DriveHandle := nil;
            FDiskPath := '';

            exit;
          end;
        end;
      end;
    end;

    ImageDriveDoor.Visible := true;
    LabelDiskLabel.Caption := ExtractFileName(DiskPath);
    LabelDiskLabel.Visible := true;

    // Play insert sound
    TurnOnReadLED(1000);
    PlaySound('INSERT',  hInstance, SND_RESOURCE OR SND_ASYNC);
  end;
end;



(*
 * Event - Insert a disk into the virtual drive
 *)
procedure TVDrive.OnInsertDisk(Sender: TObject);
begin
  (* Only get a new DSK file if there isn't one in the drive already *)
  if DiskPath = '' then
    DiskPath := GetDSKFile;
end;



(*
 * Eject a disk from the virtual drive
 *)
procedure TVDrive.EjectDisk;
begin
  OnEjectDisk(self);
end;



(*
 * Event - Eject a disk from the virtual drive
 *)
procedure TVDrive.OnEjectDisk(Sender: TObject);
begin
  if DriveHandle <> nil then
  begin
    // Play eject sound
    PlaySound('EJECT', hInstance, SND_RESOURCE OR SND_ASYNC);

    DriveHandle.Destroy;
    DriveHandle := nil;
    LabelDiskLabel.Visible := false;
    ImageDriveDoor.Visible := false;
    FDiskPath := '';
  end;
end;



(*
 * Reads a sector from the disk
 *)
function TVDrive.ReadSector(LSN : Integer; Sector : PChar) : Integer;
var
  ReadCount, i : Integer;
begin
  if (DriveHandle <> nil) then
  begin
    TurnOnReadLED(FReadLEDDuration);
    ReadCount := FSectorSize;
    try
      begin
        DriveHandle.Seek(LSN * FSectorSize, soBeginning);
        ReadCount := DriveHandle.Read(Sector^, ReadCount);
      end;
    except on E:Exception do
      begin
        ReadCount := 0;
      end;
    end;

    if ReadCount = 0 then
    begin
      // Make a fake sector
      for i := 0 to FSectorSize - 1 do
      begin
        Sector[i] := #255;
      end;
    end;

    Inc(SectorsRead);

    Result := 0;
  end
  else
  begin
    Result := 1;
  end;
end;



(*
 * Returns the disk path name
 *)
function TVDrive.GetDiskPath : String;
begin
  if (DriveHandle <> nil) then
  begin
    Result := DiskPath;
  end
  else
  begin
    Result := '';
  end;
end;



(*
 * Writes a sector to the disk
 *)
function TVDrive.WriteSector(LSN : Integer; Sector : PChar) : Integer;
var
  WriteCount : Integer;
begin
  if (DriveHandle <> nil) then
  begin
    TurnOnWriteLED(FWriteLEDDuration);
    WriteCount := FSectorSize;

    try
      begin
        DriveHandle.Seek(LSN * FSectorSize, soBeginning);
        DriveHandle.Write(Sector^, WriteCount);
        Inc(SectorsWritten);
        Result := 0;
      end;
    except on E:Exception do
      begin
        Result := 1;
      end;
    end;
  end
  else
  begin
    Result := 1;
  end;
end;


(*
 * Event called when LED timer expires so that LED goes off
 *)
procedure TVDrive.OnLEDTimer(Sender : TObject);
begin
  LEDTimer.Enabled := false;
  TurnOffLED;
end;



(*
 * Turns on Read LED for 'Duration' milliseconds
 *)
procedure TVDrive.TurnOnReadLED(Duration : Integer);
begin
  LEDTimer.Enabled := false;
  ImageReadLED.Visible := true;
  ImageWriteLED.Visible := false;

  if Duration > 0 then
  begin
    LEDTimer.Interval := Duration;
    LEDTimer.Enabled := true;
  end;
end;



(*
 * Turns on Write LED for 'Duration' milliseconds
 *)
procedure TVDrive.TurnOnWriteLED(Duration : Integer);
begin
  LEDTimer.Enabled := false;
  ImageReadLED.Visible := false;
  ImageWriteLED.Visible := true;

  if Duration > 0 then
  begin
    LEDTimer.Interval := Duration;
    LEDTimer.Enabled := true;
  end;
end;



(*
 * Turns off Read LED for 'Duration' milliseconds
 *)
procedure TVDrive.TurnOffLED;
begin
  ImageReadLED.Visible := false;
  ImageWriteLED.Visible := false;
end;



procedure TVDrive.SetDriveNum(Value : Integer);
begin
  FDriveNum := Value;
  LabelDriveNum.Caption := IntToStr(FDriveNum);
end;



procedure TVDrive.SetReadLEDDuration(Value : Integer);
begin
  FReadLEDDuration := Value;
end;



procedure TVDrive.SetSectorSize(Value: Integer);
begin
  // Set the limits of the sector size
  if Value < 256 then
    Value := 256
  else
  if value > 2048 then
    Value := 2048;

  FSectorSize := Value AND $FFFFFF00;
end;

procedure TVDrive.SetWriteLEDDuration(Value : Integer);
begin
  FWriteLEDDuration := Value;
end;


end.
