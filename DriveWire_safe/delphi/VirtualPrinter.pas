unit VirtualPrinter;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Printers;

type
  TVirtualPrinterForm = class(TForm)
    Memo1: TMemo;
    Button1: TButton;
    Button2: TButton;
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    buffer : String;
  public
    { Public declarations }
    procedure Flush;
    procedure AddByteToBuffer(data: Char);
    function GetBuffer: String;
    procedure SetBuffer(data: String);
  end;

var
  VirtualPrinterForm: TVirtualPrinterForm;

implementation

{$R *.dfm}

procedure TVirtualPrinterForm.AddByteToBuffer(data : Char);
begin
  buffer := buffer + data;
end;

function TVirtualPrinterForm.GetBuffer : String;
begin
  result := buffer;
end;

procedure TVirtualPrinterForm.SetBuffer(data : String);
begin
  buffer := data;
end;

procedure TVirtualPrinterForm.Flush;
var
  i : Integer;
  line : String;
begin
  for i := 1 to Length(buffer) do
  begin
    if (buffer[i] = #13) then
    begin
      Memo1.Lines.Add(line);
      line := '';
    end
    else
      if (buffer[i] <> #10) then
        line := line + buffer[i];
  end;
  if line <> '' then
    Memo1.Lines.Add(line);
  Show;
  buffer := '';
end;

procedure TVirtualPrinterForm.Button2Click(Sender: TObject);
begin
  Memo1.Lines.Clear;
end;

procedure TVirtualPrinterForm.Button1Click(Sender: TObject);
var
  printDialog : TPrintDialog;
  myPrinter : TPrinter;
  myFile : TextFile;
  i : Integer;
  Line : Integer;
begin
 // Create a printer selection dialog
  printDialog := TPrintDialog.Create(VirtualPrinterForm);

  // If the user has selected a printer (or default), then print!
  if printDialog.Execute then
  begin
    // Use the Printer function to get access to the
    // global TPrinter object.
    // All references below are to the TPrinter object
    myPrinter := Printer;
    with myPrinter do
    begin
      Line := 0;
      Printer.BeginDoc;
      for i := 0 to Memo1.Lines.Count - 1 do
      Printer.Canvas.Font.Size := 10;
      Printer.Canvas.Font.Name := 'Courier New';
      begin
        Printer.Canvas.TextOut(0, Line, Memo1.Lines[i]);
        Line := Line + Abs(Printer.Canvas.Font.Height);
        if (Line >= Printer.pageHeight) then
          Printer.newPage
      end;
      Printer.EndDoc;
    end;
  end;
end;

end.
