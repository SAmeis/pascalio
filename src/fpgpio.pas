{ General Purpose Input/Output access classes for Free Pascal

  Copyright (C) 2013, Simon Ameis <simon.ameis@web.de>

  This library is free software; you can redistribute it and/or modify it
  under the terms of the GNU Library General Public License as published by
  the Free Software Foundation; either version 2 of the License, or (at your
  option) any later version with the following modification:

  As a special exception, the copyright holders of this library give you
  permission to link this library with independent modules to produce an
  executable, regardless of the license terms of these independent modules,and
  to copy and distribute the resulting executable under terms of your choice,
  provided that you also meet, for each linked independent module, the terms
  and conditions of the license of that module. An independent module is a
  module which is not derived from or based on this library. If you modify
  this library, you may extend this exception to your version of the library,
  but you are not obligated to do so. If you do not wish to do so, delete this
  exception statement from your version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
  for more details.

  You should have received a copy of the GNU Library General Public License
  along with this library; if not, write to the Free Software Foundation,
  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
}


unit fpgpio;

{$mode objfpc}{$H+}

{$IFNDEF GPIO_INLINE}
  {$MACRO ON}
  {$DEFINE inline;:=}
{$ELSE}
  {$INLINE ON}
{$ENDIF}
interface

uses
  Classes, SysUtils, baseunix, rtlconsts;

resourcestring
  sInvalidEdge         = 'Invalid interrupt mode.';
  sNoInterrupt         = 'Interrupt is not supported.';
  sDirectInterrupt     = 'Direct Interrupt is not supported.';
  sIndirectInterrupt   = 'Indirect Interrupt is not supported.';
  sInterruptModeNotSet = 'No interrupt mode set.';
  sPinIndexOutOfRange  = 'Pin Index must be between %d and %d.';

type
  TGpioCapability     = (gcPullup, gcPulldown, gcInterrupt, gcIndirectInterrupt);
  TGpioDirection      = (gdOut, gdIn);
  TGpioInterruptModes = (gimRising, gimFalling);
  TGpioInterruptMode  = set of TGpioInterruptModes;

const
  gimBoth = [gimRising, gimFalling];
  gimNone = TGpioInterruptMode([]);

operator :=(v: TGpioInterruptModes): TGpioInterruptMode;

function ifthen(cond: Boolean; TrueValue: TGpioDirection; FalseValue: TGpioDirection): TGpioDirection; inline;

type
  EInterruptError         = class(Exception);
  ENoInterrupt            = class(EInterruptError);
  EDirectInterruptError   = class(EInterruptError);
  EIndirectInterruptError = class(EInterruptError);

  TGpioPin = class;
  TInterruptCascade = array of TGpioPin;

  TGpioInterruptStatus = record
    Pin: TGpioPin;   // pin, at which interrupt occured
    Value: Boolean;  // Pin.Value at time of interrupt, or--if unknown--when handled
  end;
  TGpioInterruptStatusArray = array of TGpioInterruptStatus;
  TOnGpioInterrupt = procedure (Sender: TGpioPin; InterruptValue: Boolean) of object;

  { TGpioPin }

  TGpioPin = class(TObject)
  protected
    function GetAcitveLow: Boolean; virtual; abstract;
    procedure SetAcitveLow(AValue: Boolean); virtual; abstract;
    function GetDirection: TGpioDirection; virtual; abstract;
    function GetInterruptMode: TGpioInterruptMode; virtual; abstract;
    function GetValue: Boolean; virtual; abstract;
    procedure SetDirection(AValue: TGpioDirection); virtual; abstract;
    procedure SetInterruptMode(AValue: TGpioInterruptMode); virtual; abstract;
    procedure SetValue(AValue: Boolean); virtual; abstract;
  public
    function WaitForInterrupt(timeout: LongInt): Boolean; virtual;
    function WaitForInterruptIndirect(timeout: Longint; Const Cascade: array of TGpioPin): Boolean; virtual;
    function PollChange(delay: Longint; timeout: Longint; out value: Boolean): Boolean; virtual;
    property Direction: TGpioDirection read GetDirection write SetDirection;
    property Value: Boolean read GetValue write SetValue;
    property InterruptMode: TGpioInterruptMode read GetInterruptMode write SetInterruptMode;
    property AcitveLow: Boolean read GetAcitveLow write SetAcitveLow;
  end;

  { TGpioController }

  TGpioController = class(TObject)
  strict private
    fPins: Array of TGpioPin;
    function GetPin(Index: SizeUInt): TGpioPin;
  protected
    function GetActiveLow(Index: Longword): Boolean; virtual; abstract;
    function GetDirection(Index: Longword): TGpioDirection; virtual; abstract;
    procedure SetActiveLow(Index: Longword; AValue: Boolean); virtual; abstract;
    procedure SetDirection(Index: Longword; AValue: TGpioDirection); virtual; abstract;
    class function GetCount: Longword; static; virtual; abstract;
    function GetValue(Index: Longword): Boolean; virtual; abstract;
    procedure SetValue(Index: Longword; aValue: Boolean); virtual; abstract;
    function GetInterruptMode(Index: Longword): TGpioInterruptMode; virtual; abstract;
    procedure SetInterruptMode(Index: Longword; AValue: TGpioInterruptMode); virtual; abstract;
    // constructor does internal setup; override it to your needs and publish it
    constructor Create; virtual;
  public
    destructor Destroy; override;
    property InterruptMode[Index: Longword]: TGpioInterruptMode read GetInterruptMode write SetInterruptMode;
    property Direction[Index: Longword]: TGpioDirection read GetDirection write SetDirection;
    property Value[Index: Longword]: Boolean read GetValue write SetValue;
    property ActiveLow[Index: Longword]: Boolean read GetActiveLow write SetActiveLow;
    class property Count: Longword read GetCount;
    property Pins[Index: SizeUInt]: TGpioPin read GetPin;
  end;

  { TGpioControlledPin }

  TGpioControlledPin = class(TGpioPin)
  strict private
    fController: TGpioController;
    fOnInterrupt: TOnGpioInterrupt;
    fIndex: Longword;
  private
    // keep the constructor private - it should be called only called from TGpioController!
    constructor Create(aController: TGpioController; aIndex: Longword);
  protected
    function GetAcitveLow: Boolean; override;
    function GetDirection: TGpioDirection; override;
    function GetInterruptMode: TGpioInterruptMode; override;
    function GetValue: Boolean; override;
    procedure SetAcitveLow(AValue: Boolean); override;
    procedure SetDirection(AValue: TGpioDirection); override;
    procedure SetInterruptMode(AValue: TGpioInterruptMode); override;
    procedure SetValue(AValue: Boolean); override;
  public
    property Controller: TGpioController read fController;
    property Index: Longword read fIndex;
    property OnInterrupt: TOnGpioInterrupt read fOnInterrupt write fOnInterrupt;
  end;

  TRegisterType = (rtValue, rtDirection, rtActiveLow, rtInterruptFlag, rtInterruptValue, rtIntEnable, rtIntDefVal, rtIntCtrl, rtPullup, rtPulldown);
  TRegisterAddress = Byte;
  TPinPosition = $00 .. $07;
  TRegisterValue = bitpacked array[TPinPosition] of Boolean;

  { TGpioRegisterController }

  TGpioRegisterController = class(TGpioController)
  protected
    function GetActiveLow(Index: Longword): Boolean; override;
    function GetDirection(Index: Longword): TGpioDirection; override;
    function GetValue(index: Longword): Boolean; override;
    procedure SetActiveLow(Index: Longword; AValue: Boolean); override;
    procedure SetDirection(Index: Longword; AValue: TGpioDirection); override;
    procedure SetValue(index: Longword; aValue: Boolean); override;
  protected
    function GetRegister(PinIndex: Longword; aRegisterType: TRegisterType; out aPinPosition: TPinPosition): TRegisterAddress; virtual; abstract;
    function GetRegisterValue(aRegister: TRegisterAddress): TRegisterValue; virtual; abstract;
    procedure SetRegisterValue(aRegister: TRegisterAddress; aValue: TRegisterValue); virtual; abstract;
    function GetRegisterValueS(aPinIndex: Longword; aRegisterType: TRegisterType): Boolean; virtual;
    procedure SetRegisterValueS(aPinIndex: Longword; aRegisterType: TRegisterType; aValue: Boolean); virtual;
    property RegisterValue[aRegister: TRegisterAddress]: TRegisterValue read GetRegisterValue write SetRegisterValue;
  end;

  ENoEdge = class(Exception);
  EInvalidEgde = class(Exception);

  { TGpioLinuxPin }

  TGpioLinuxPin = class(TGpioPin)
  private
    fPinID: Longword;
  protected
    function GetAcitveLow: Boolean; override;
    class function ReadFromFile(const aFileName: String; aChars: SizeInt; out CharsRead: SizeInt): String;
    class function ReadFromFile(const aFileName: String; aChars: SizeInt): String;
    procedure SetAcitveLow(AValue: Boolean); override;
    class procedure WriteToFile(const aFileName: String; const aBuffer; aCount: SizeInt);
    class procedure WriteToFile(const aFileName: String; const aBuffer: String);
    class procedure SetExport(aExport: Boolean; aPin: Longword);
    class function GetEdgeString(aInterruptMode: TGpioInterruptMode): String;
    class function EgeStringToInterruptMode(const aValue: String): TGpioInterruptMode;
  protected
    function GetDirection: TGpioDirection; override;
    function GetInterruptMode: TGpioInterruptMode; override;
    function GetValue: Boolean; override;
    procedure SetDirection(AValue: TGpioDirection); override;
    procedure SetInterruptMode(AValue: TGpioInterruptMode); override;
    procedure SetValue(AValue: Boolean); override;
  public
    constructor Create(aID: Longword);
    destructor Destroy; override;
    function WaitForInterrupt(timeout: LongInt): Boolean; override;
    property PinID: Longword read fPinID;
  end;

implementation

const
  GPIO_LINUX_BASE_DIR = '/sys/class/gpio/';
  GPIO_LINUX_GPIOPIN_DIR = GPIO_LINUX_BASE_DIR + 'gpio%d/';

operator := (v: TGpioInterruptModes): TGpioInterruptMode;
begin
  Result := [v];
end;

function ifthen(cond: Boolean; TrueValue: TGpioDirection;
  FalseValue: TGpioDirection): TGpioDirection;
begin
  if cond then
    Result := TrueValue
  else
    Result := FalseValue;
end;

{ TGpioController }

function TGpioController.GetPin(Index: SizeUInt): TGpioPin;
begin
  if (Index > High(fPins)) then
    raise EListError.CreateFmt(SListIndexError, [Index]);
  Result := fPins[Index];
end;

constructor TGpioController.Create;
var
  i: Integer;
begin
  SetLength(fPins, Count);
  if Length(fPins) > 0 then
  begin
    FillByte(fPins[0], SizeOf(fPins[0]) * Length(fPins), 0);
    for i := Low(fPins) to High(fPins) do
      fPins[i] := TGpioControlledPin.Create(self, i);
  end;
end;

destructor TGpioController.Destroy;
var
  i: Integer;
begin
  for i := Low(fPins) to high(fPins) do
  begin
    fPins[i].Free;
    fPins[i] := nil;
  end;
  SetLength(fPins, 0);
  inherited Destroy;
end;

{ TGpioControlledPin }

constructor TGpioControlledPin.Create(aController: TGpioController;
  aIndex: Longword);
begin
  fController := aController;
  fIndex := aIndex;
end;

function TGpioControlledPin.GetAcitveLow: Boolean;
begin
  Result := fController.ActiveLow[fIndex];
end;

function TGpioControlledPin.GetDirection: TGpioDirection;
begin
  Result := fController.Direction[fIndex];
end;

function TGpioControlledPin.GetInterruptMode: TGpioInterruptMode;
begin
    Result := fController.InterruptMode[fIndex];
end;

function TGpioControlledPin.GetValue: Boolean;
begin
  Result := fController.Value[fIndex];
end;

procedure TGpioControlledPin.SetAcitveLow(AValue: Boolean);
begin
  fController.ActiveLow[fIndex] := AValue;
end;

procedure TGpioControlledPin.SetDirection(AValue: TGpioDirection);
begin
  fController.Direction[fIndex] := AValue;
end;

procedure TGpioControlledPin.SetInterruptMode(AValue: TGpioInterruptMode);
begin
  fController.InterruptMode[fIndex] := AValue;
end;

procedure TGpioControlledPin.SetValue(AValue: Boolean);
begin
  fController.Value[fIndex] := AValue;
end;

{ TGpioRegisterController }

function TGpioRegisterController.GetActiveLow(Index: Longword): Boolean;
begin
  Result := GetRegisterValueS(Index, rtActiveLow);
end;

function TGpioRegisterController.GetDirection(Index: Longword): TGpioDirection;
var
  r: Boolean;
begin
  // this is true for MCP23017---so override it if needed!
  r := GetRegisterValueS(Index, rtDirection);
  if r then
    Result := gdIn
  else
    Result := gdOut;
end;

function TGpioRegisterController.GetValue(index: Longword): Boolean;
begin
  Result := GetRegisterValueS(index, rtValue);
end;

procedure TGpioRegisterController.SetActiveLow(Index: Longword; AValue: Boolean
  );
begin
  SetRegisterValueS(Index, rtActiveLow, AValue);
end;

procedure TGpioRegisterController.SetDirection(Index: Longword;
  AValue: TGpioDirection);
begin
  case AValue of
    gdIn : SetRegisterValueS(Index, rtDirection, True);
    gdOut: SetRegisterValueS(Index, rtDirection, False);
  else
    raise ERangeError.CreateFmt(SOutOfRange, [low(AValue), High(AValue)]);
  end;
end;

procedure TGpioRegisterController.SetValue(index: Longword; aValue: Boolean);
begin
  SetRegisterValueS(index, rtValue, aValue);
end;

function TGpioRegisterController.GetRegisterValueS(aPinIndex: Longword;
  aRegisterType: TRegisterType): Boolean;
var
  pp: TPinPosition;
  ra: TRegisterAddress;
  rv: TRegisterValue;
begin
  ra := GetRegister(aPinIndex, aRegisterType, pp);
  rv := GetRegisterValue(ra);
  Result := rv[pp];
end;

procedure TGpioRegisterController.SetRegisterValueS(aPinIndex: Longword;
  aRegisterType: TRegisterType; aValue: Boolean);
var
  pp: TPinPosition;
  ra: TRegisterAddress;
  rv: TRegisterValue;
begin
  ra := GetRegister(aPinIndex, aRegisterType, pp);
  rv := GetRegisterValue(ra);
  if aValue = rv[pp] then exit; // value already set
  rv[pp] := aValue;
  SetRegisterValue(ra, rv);
end;

{ TGpioLinuxPin }

function TGpioLinuxPin.GetAcitveLow: Boolean;
var
  f, s: String;
begin
  f := Format(GPIO_LINUX_GPIOPIN_DIR+'active_low', [PinID]);
  s := ReadFromFile(f, 1);
  Result := not(s = '0');
end;

class function TGpioLinuxPin.ReadFromFile(const aFileName: String; aChars: SizeInt; out
  CharsRead: SizeInt): String;
var
  fd: cint;
begin
  if aChars <= 0 then
    exit(EmptyStr);

  SetLength(Result, aChars);
  fd := FpOpen(aFileName, O_RDONLY);
  if fd = -1 then
    raise EFOpenError.CreateFmt(SFOpenError, [aFileName]);
  CharsRead := FpRead(fd, Result[1], length(Result));
  SetLength(Result, CharsRead);
  fpClose(fd);
end;

class function TGpioLinuxPin.ReadFromFile(const aFileName: String;
  aChars: SizeInt): String;
var
  i: SizeInt;
begin
  Result := ReadFromFile(aFileName, aChars, i);
end;

procedure TGpioLinuxPin.SetAcitveLow(AValue: Boolean);
var
  s, f: String;
begin
  f := Format(GPIO_LINUX_GPIOPIN_DIR+'active_low', [PinID]);
  if AValue then
    s := '1'
  else
    s := '0';

  WriteToFile(f, s);
end;

class procedure TGpioLinuxPin.WriteToFile(const aFileName: String;
  const aBuffer; aCount: SizeInt);
var
  fd: cint;
begin
  fd := fpOpen(aFileName, O_WRONLY);
  if fd = -1 then
    EFOpenError.CreateFmt(SFOpenError, [aFileName]);
  FpWrite(fd, aBuffer, aCount);
  FpClose(fd);
end;

class procedure TGpioLinuxPin.WriteToFile(const aFileName: String;
  const aBuffer: String);
begin
  if length(aBuffer) >= 1 then
    WriteToFile(aFileName, aBuffer[1], length(aBuffer));
end;

class procedure TGpioLinuxPin.SetExport(aExport: Boolean; aPin: Longword);
const
  EXPORT_FILE = GPIO_LINUX_BASE_DIR+'export';
  UNEXPORT_FILE = GPIO_LINUX_BASE_DIR+'unexport';
var
  s: String;
begin
  s := IntToStr(aPin);
  if aExport then
    WriteToFile(EXPORT_FILE, s[1], length(s))
  else
    WriteToFile(UNEXPORT_FILE, s[1], length(s));
end;

class function TGpioLinuxPin.GetEdgeString(aInterruptMode: TGpioInterruptMode
  ): String;
begin
  if aInterruptMode = [] then
    Result := 'none'
  else if aInterruptMode = [gimFalling] then
    Result := 'falling'
  else if aInterruptMode = [gimRising] then
    Result := 'rising'
  else if aInterruptMode = [gimRising, gimFalling] then
    Result := 'both'
  else
    raise EInvalidEgde.Create(sInvalidEdge);
end;

class function TGpioLinuxPin.EgeStringToInterruptMode(const aValue: String
  ): TGpioInterruptMode;
begin
  case aValue of
    'none'   : Result := []                     ;
    'falling': Result := [gimFalling]           ;
    'rising' : Result := [gimRising]            ;
    'both'   : Result := [gimRising, gimFalling];
  else
    raise EInvalidEgde.CreateFmt('Invallid egde string: %s', [aValue]);
  end;
end;

function TGpioLinuxPin.GetDirection: TGpioDirection;
var
  s: String;
  f: String;
begin
  f := Format(GPIO_LINUX_GPIOPIN_DIR+'direction', [PinID]);
  s := ReadFromFile(f, 1);
  case s of
    'in' : Result := gdIn ;
    'out': Result := gdOut;
  end;
end;

function TGpioLinuxPin.GetInterruptMode: TGpioInterruptMode;
var
  s: String;
  f: String;
begin
  f := Format(GPIO_LINUX_BASE_DIR+'edge', [PinID]);
  s := ReadFromFile(f, 7);
  Result := EgeStringToInterruptMode(s);
end;

function TGpioLinuxPin.GetValue: Boolean;
var
  f: String;
  s: String;
begin
  f := Format(GPIO_LINUX_GPIOPIN_DIR+'value', [PinID]);
  s := ReadFromFile(f, 1);
  Result := not(s = '0');
end;

procedure TGpioLinuxPin.SetDirection(AValue: TGpioDirection);
var
  f: String;
  s: String;
begin
  case AValue of
    gdOut: s := 'out';
    gdIn : s := 'in';
  else
    exit;
  end;
  f := Format(GPIO_LINUX_GPIOPIN_DIR+'direction', [PinID]);
  WriteToFile(f, s);
end;

procedure TGpioLinuxPin.SetInterruptMode(AValue: TGpioInterruptMode);
var
  f, s: String;
begin
  f := Format(GPIO_LINUX_BASE_DIR+'edge', [PinID]);
  s := GetEdgeString(AValue);
  WriteToFile(f, s);
end;

procedure TGpioLinuxPin.SetValue(AValue: Boolean);
const
  VALUE_FILE = GPIO_LINUX_GPIOPIN_DIR + 'value';
var
  s: String;
  f: String;
begin
  if aValue then
    s := '1'
  else
    s := '0';
  f := format(VALUE_FILE, [PinID]);
  WriteToFile(f, s);
end;

constructor TGpioLinuxPin.Create(aID: Longword);
begin
  fPinID := aID;
  SetExport(True, aID);
end;

destructor TGpioLinuxPin.Destroy;
begin
  SetExport(False, PinID);
  inherited Destroy;
end;

function TGpioLinuxPin.WaitForInterrupt(timeout: LongInt): Boolean;
var
  s: String;
  fd: cint;
  fdset: array[0..0] of pollfd;
  rc: cint;
begin
  s := Format(GPIO_LINUX_GPIOPIN_DIR + 'value', [PinID]);

  // interrupt can't be done without a mode set prior
  if InterruptMode = [] then
    raise EInterruptError.Create(sInterruptModeNotSet);

  fd := fpOpen(s, O_RDONLY, 0);
  if fd = -1 then
    raise EFOpenError.CreateFmt(SFOpenError, [s]);
  try
    FillByte(fdset[0], sizeof(fdset), 0);
    fdset[0].fd := fd;
    fdset[0].events := POLLPRI;

    rc := FpPoll(@fdset[0], 1, timeout);
    if rc < 0 then
      raise EInterruptError.Create('Interrupt failed.')
    else if rc = 0 then
      exit(False); // timeout;

    if (fdset[0].revents and POLLPRI) <> 0 then
      exit(True); // interrupt occured
  finally
    fpClose(fd);
  end;
end;

{ TGpioPin }

function TGpioPin.WaitForInterrupt(timeout: LongInt): Boolean;
begin
  raise EDirectInterruptError.Create(sDirectInterrupt);
end;

function TGpioPin.WaitForInterruptIndirect(timeout: Longint;
  const Cascade: array of TGpioPin): Boolean;
var
  l: SizeInt;
begin
  l := Length(Cascade);
  case l of
    0: Result := Self.WaitForInterrupt(timeout);
    1: Result := Cascade[0].WaitForInterrupt(timeout);
  else
    Result := Cascade[0].WaitForInterruptIndirect(
        timeout,
        Cascade[1..High(Cascade)]
      );
  end;
end;

function TGpioPin.PollChange(delay: Longint; timeout: Longint;
  out value: Boolean): Boolean;

  function NowMS: QWord; inline;
  begin
    Result := trunc(now * 24 * 60 * 60 * 1000);
  end;

var
  d1: QWord;
  nval: Boolean;
begin
  d1 := NowMS;
  value := GetValue;
  repeat
     nval := GetValue;
     if nval <> value then
     begin
       value := nval;
       Result := True;
       exit;  // hard exit to avoid changing result
     end;
    if delay >= 0 then
      sleep(delay);
  until NowMS >  (d1 + timeout);
  Result := False;
end;

end.

