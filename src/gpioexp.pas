{ Support for GPIO expander for Free Pascal

  Copyright (C) 2013 Simon Ameis <simon.ameis@web.de>

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
}

unit gpioexp;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpgpio, fpspi, fpi2c, mcp23017, bitmanip;

type

  { TGpioI2CController }

  TGpioI2CController = class(TGpioController)
  protected
    fI2CDevice: TI2CDevice;
    property I2C: TI2CDevice read fI2CDevice;
  public
    constructor Create(aDevice: TI2CDevice); reintroduce; virtual;
  end;

  { TGpioSPIController }

  TGpioSPIController = class(TGpioController)
  protected
    fSPIDevice: TSPIDevice;
    property SPI: TSPIDevice read fSPIDevice;
  public
    constructor Create(aDevice: TSPIDevice); reintroduce; virtual;
  end;

  { TMCP23X17 }

  TMCP23X17 = class(TGpioController)
  strict private
    fmcp23X17: TMCP23X17Controller;
  protected
    function GetActiveLow(Index: Longword): Boolean; override;
    class function GetCount: Longword; static; override;
    function GetDirection(Index: Longword): TGpioDirection; override;
    function GetInterruptMode(Index: Longword): TGpioInterruptMode; override;
    function GetValue(index: Longword): Boolean; override;
    procedure SetActiveLow(Index: Longword; AValue: Boolean); override;
    procedure SetDirection(Index: Longword; AValue: TGpioDirection); override;
    procedure SetInterruptMode(Index: Longword; AValue: TGpioInterruptMode);
      override;
    procedure SetValue(index: Longword; aValue: Boolean); override;
  public
    constructor Create(aMCP23X17: TMCP23X17Controller); reintroduce; virtual;
    function GetInterruptStatusA: TGpioInterruptStatusArray;
    function GetInterruptStatusB: TGpioInterruptStatusArray;
    function GetInterruptStatus: TGpioInterruptStatusArray;
  end;


  { TMCP23017 }

  TMCP23017 = class(TGpioI2CController)
  protected
    fProxy: TMCP23X17;
    fMCP23X17Controller: TMCP23X17Controller;
    function GetActiveLow(Index: Longword): Boolean; override;
    class function GetCount: Longword; static; override;
    function GetDirection(Index: Longword): TGpioDirection; override;
    function GetInterruptMode(Index: Longword): TGpioInterruptMode; override;
    function GetValue(Index: Longword): Boolean; override;
    procedure SetActiveLow(Index: Longword; AValue: Boolean); override;
    procedure SetDirection(Index: Longword; AValue: TGpioDirection); override;
    procedure SetInterruptMode(Index: Longword; AValue: TGpioInterruptMode);
      override;
    procedure SetValue(Index: Longword; aValue: Boolean); override;
  public
    constructor Create(aDevice: TI2CDevice); override;
    destructor Destroy; override;
  end;

  { TMCP23S17 }

  TMCP23S17 = class(TGpioSPIController)
  protected
    fProxy: TMCP23X17;
    fMCP23X17Controller: TMCP23X17Controller;
    function GetActiveLow(Index: Longword): Boolean; override;
    class function GetCount: Longword; static; override;
    function GetDirection(Index: Longword): TGpioDirection; override;
    function GetInterruptMode(Index: Longword): TGpioInterruptMode; override;
    function GetValue(Index: Longword): Boolean; override;
    procedure SetActiveLow(Index: Longword; AValue: Boolean); override;
    procedure SetDirection(Index: Longword; AValue: TGpioDirection); override;
    procedure SetInterruptMode(Index: Longword; AValue: TGpioInterruptMode);
      override;
    procedure SetValue(Index: Longword; aValue: Boolean); override;
  public
    constructor Create(aDevice: TSPIDevice); override;
    destructor Destroy; override;
  end;

implementation

{ TMCP23S17 }

function TMCP23S17.GetActiveLow(Index: Longword): Boolean;
begin
  Result := fProxy.GetActiveLow(Index);
end;

class function TMCP23S17.GetCount: Longword;
begin
  Result := TMCP23X17.Count;
end;

function TMCP23S17.GetDirection(Index: Longword): TGpioDirection;
begin
  Result := fProxy.GetDirection(Index);
end;

function TMCP23S17.GetInterruptMode(Index: Longword): TGpioInterruptMode;
begin
  Result := fProxy.GetInterruptMode(Index);
end;

function TMCP23S17.GetValue(Index: Longword): Boolean;
begin
  Result := fProxy.GetValue(Index);
end;

procedure TMCP23S17.SetActiveLow(Index: Longword; AValue: Boolean);
begin
  fProxy.SetActiveLow(Index, AValue);
end;

procedure TMCP23S17.SetDirection(Index: Longword; AValue: TGpioDirection);
begin
  fProxy.SetDirection(Index, AValue);
end;

procedure TMCP23S17.SetInterruptMode(Index: Longword; AValue: TGpioInterruptMode
  );
begin
  fProxy.SetInterruptMode(Index, AValue);
end;

procedure TMCP23S17.SetValue(Index: Longword; aValue: Boolean);
begin
  fProxy.SetValue(Index, AValue);
end;

constructor TMCP23S17.Create(aDevice: TSPIDevice);
begin
  inherited Create(aDevice);
  fMCP23X17Controller := TMCP23S17Controller.Create(aDevice, False);
  fProxy := TMCP23X17.Create(fMCP23X17Controller);
end;

destructor TMCP23S17.Destroy;
begin
  FreeAndNil(fProxy);
  FreeAndNil(fMCP23X17Controller);
  inherited Destroy;
end;

{ TMCP23X17 }

function TMCP23X17.GetActiveLow(Index: Longword): Boolean;
begin
  case Index of
    0..7 : Result := ByteBool(fmcp23X17.IPOLA AND ($01 shl Index      ));
    8..15: Result := ByteBool(fmcp23X17.IPOLB AND ($01 shl (Index - 8)));
  else
    raise ERangeError.CreateFmt(sPinIndexOutOfRange, [0, Count - 1]);
  end;
end;

class function TMCP23X17.GetCount: Longword;
begin
  Result := 16
end;

function TMCP23X17.GetDirection(Index: Longword): TGpioDirection;
begin
  case Index of
    0..7 : Result :=  ifthen(
                        fmcp23X17.IODIRA AND ($01 shl  Index     ) <> $00,
                        gdIn,
                        gdOut
                      );
    8..15: Result :=  ifthen(
                        fmcp23X17.IODIRB AND ($01 shl (Index - 8)) <> $00,
                        gdIn,
                        gdOut
                      );
  else
    raise ERangeError.CreateFmt(sPinIndexOutOfRange, [0, Count - 1]);
  end;
end;

function TMCP23X17.GetInterruptMode(Index: Longword): TGpioInterruptMode;
var
  x: Byte;
begin
  if Index > (Count - 1) then
    raise ERangeError.CreateFmt(sPinIndexOutOfRange, [0, Count - 1]);

  (* MODES:
      gimNone     GPINTEN = 0
      gimRising   GPINTEN = 1 INTCON = 1 DEFVAL = 0
      gimFalling  GPINTEN = 1 INTCON = 1 DEFVAL = 1
      gimBoth     GPINTEN = 1 INTCON = 0
   *)

   case Index of
     0..7 : x := fmcp23X17.GPINTENA AND ($01 shl Index    );
     8..15: x := fmcp23X17.GPINTENB AND ($01 shl Index - 8);
   end;
   if x = $00 then
     exit([]); // interrupt disabled

   case Index of
     0..7 : x := fmcp23X17.INTCONA AND ($01 shl Index    );
     8..15: x := fmcp23X17.INTCONB AND ($01 shl Index - 8);
   end;
   if x = $00 then
     exit(gimBoth); // all changes result in interrupt

   case Index of
     0..7 : x := fmcp23X17.DEFVALA AND ($01 shl Index    );
     8..15: x := fmcp23X17.DEFVALB AND ($01 shl Index - 8);
   end;
   if x = $00 then
     exit([gimRising])    // interrupt if value differs from logical 0
   else
     exit([gimFalling]);  // interrupt if value differs from logical 1
end;

function TMCP23X17.GetValue(index: Longword): Boolean;
begin
  case Index of
    0..7 : Result := ByteBool(fmcp23X17.GPIOA AND ($01 shl  Index     ));
    8..15: Result := ByteBool(fmcp23X17.GPIOB AND ($01 shl (Index - 8)));
  else
    raise ERangeError.CreateFmt(sPinIndexOutOfRange, [0, Count - 1]);
  end;
end;

procedure TMCP23X17.SetActiveLow(Index: Longword; AValue: Boolean);
begin
  case Index of
    0..7 :  if AValue then
              fmcp23X17.IPOLA := fmcp23X17.IPOLA OR      ($01 shl  Index     )
            else
              fmcp23X17.IPOLA := fmcp23X17.IPOLA AND NOT ($01 shl  Index     );
    8..15:  if AValue then
              fmcp23X17.IPOLB := fmcp23X17.IPOLB OR      ($01 shl (Index - 8))
            else
              fmcp23X17.IPOLB := fmcp23X17.IPOLB AND NOT ($01 shl (Index - 8));
  else
    raise ERangeError.CreateFmt(sPinIndexOutOfRange, [0, Count - 1]);
  end;
end;

procedure TMCP23X17.SetDirection(Index: Longword; AValue: TGpioDirection);
begin
  case Index of
    0..7 :  if AValue = gdIn then
              fmcp23X17.IODIRA := fmcp23X17.IODIRA OR      ($01 shl  Index     )
            else
              fmcp23X17.IODIRA := fmcp23X17.IODIRA AND NOT ($01 shl Index      );
    8..15:  if AValue = gdIn then
              fmcp23X17.IODIRB := fmcp23X17.IODIRB OR      ($01 shl (Index - 8))
            else
              fmcp23X17.IODIRB := fmcp23X17.IODIRB AND NOT ($01 shl (Index - 8));
  else
    raise ERangeError.CreateFmt(sPinIndexOutOfRange, [0, Count - 1]);
  end;
end;

procedure TMCP23X17.SetInterruptMode(Index: Longword; AValue: TGpioInterruptMode
  );
begin
  if Index > 15 then
    raise ERangeError.CreateFmt(sPinIndexOutOfRange, [0, Count - 1]);

  (* MODES:
      gimNone     GPINTEN = 0
      gimRising   GPINTEN = 1 INTCON = 1 DEFVAL = 0
      gimFalling  GPINTEN = 1 INTCON = 1 DEFVAL = 1
      gimBoth     GPINTEN = 1 INTCON = 0
   *)

  if AValue = [] then
    case Index of
      0..7 : fmcp23X17.GPINTENA := fmcp23X17.GPINTENA AND NOT($01 shl Index);
      8..15: fmcp23X17.GPINTENB := fmcp23X17.GPINTENB AND NOT($01 shl Index);
    end
  else
  begin
    if gimBoth = AValue then
      case Index of
        0..7 : fmcp23X17.INTCONA := fmcp23X17.INTCONA AND NOT($01 shl Index);
        8..15: fmcp23X17.INTCONB := fmcp23X17.INTCONB AND NOT($01 shl Index);
      end
    else
    begin
      if gimRising in AValue then
        case Index of
          0..7 : fmcp23X17.DEFVALA := fmcp23X17.DEFVALA AND NOT ($01 shl Index);
          8..15: fmcp23X17.DEFVALB := fmcp23X17.DEFVALB AND NOT ($01 shl Index);
        end
      else
        case Index of
          0..7 : fmcp23X17.DEFVALA := fmcp23X17.DEFVALA OR ($01 shl Index);
          8..15: fmcp23X17.DEFVALB := fmcp23X17.DEFVALB OR ($01 shl Index);
        end;

      case Index of
        0..7 : fmcp23X17.INTCONA := fmcp23X17.INTCONA OR ($01 shl Index);
        8..15: fmcp23X17.INTCONB := fmcp23X17.INTCONB OR ($01 shl Index);
      end;
    end;

    case Index of
      0..7 : fmcp23X17.GPINTENA := fmcp23X17.GPINTENA OR ($01 shl Index);
      8..15: fmcp23X17.GPINTENB := fmcp23X17.GPINTENB OR ($01 shl Index);
    end;
  end;
end;

procedure TMCP23X17.SetValue(index: Longword; aValue: Boolean);
begin

  case Index of
    0..7 :  if aValue then
              fmcp23X17.GPIOA := fmcp23X17.GPIOA OR      ($01 shl  Index     )
            else
              fmcp23X17.GPIOA := fmcp23X17.GPIOB AND NOT ($01 shl  Index     );
    8..15:  if aValue then
              fmcp23X17.GPIOB := fmcp23X17.GPIOB OR      ($01 shl (Index - 8))
            else
              fmcp23X17.GPIOB := fmcp23X17.GPIOB AND NOT ($01 shl (Index - 8));
  else
    raise ERangeError.CreateFmt(sPinIndexOutOfRange, [0, Count - 1]);
  end;
end;

constructor TMCP23X17.Create(aMCP23X17: TMCP23X17Controller);
begin
  inherited Create;
  fmcp23X17 := aMCP23X17;
end;

function TMCP23X17.GetInterruptStatusA: TGpioInterruptStatusArray;
var
  fa: Byte;
  cap: Byte;
  i: Byte;
  ri: SizeInt;
begin
  fa := fmcp23X17.INTFA;
  SetLength(Result, CountBits(fa));
  if Length(Result) = 0 then exit;

  ri := 0;
  if fa <> 0 then
  begin
    cap := fmcp23X17.INTCAPA;
    // for each pins in Port A
    for i := 0 to BitSizeOf(fa) - 1 do
    begin
      // check if it caused interrupt
      if (fa AND (1 shl i)) = 1 then
      begin
        // get value
        Result[ri].Value := (cap AND (1 shl i)) <> 0;
        Result[ri].Pin := Self.Pins[i];
        inc(ri);
      end;
    end;
  end;
end;

function TMCP23X17.GetInterruptStatusB: TGpioInterruptStatusArray;
var
  fb: Byte;
  cap: Byte;
  i: Byte;
  ri: SizeInt;
begin
  fb := fmcp23X17.INTFB;
  SetLength(Result, CountBits(fb));
  if Length(Result) = 0 then exit;

  ri := 0;
  if fb <> 0 then
  begin
    cap := fmcp23X17.INTCAPB;
    // for each pins in Port B
    for i := 0 to BitSizeOf(fb) - 1 do
    begin
      // check if it caused interrupt
      if (fb AND (1 shl i)) = 1 then
      begin
        // get value
        Result[ri].Value := (cap AND (1 shl i)) <> 0;
        Result[ri].Pin := Self.Pins[i + 8];
        inc(ri);
      end;
    end;
  end;
end;

function TMCP23X17.GetInterruptStatus: TGpioInterruptStatusArray;
var
  gisA, gisB: TGpioInterruptStatusArray;
begin
  gisA := GetInterruptStatusA;
  gisB := GetInterruptStatusB;
  SetLength(Result, Length(gisA) + Length(gisB));
  if Length(gisA) > 0 then
    Move(gisA[0], Result[0], Length(gisA) * SizeOf(gisA[0]));
  if Length(gisB) > 0 then
    Move(gisB[0], Result[Length(gisA)], Length(gisB) * SizeOf(gisB[0]));
end;

{ TMCP23017 }

class function TMCP23017.GetCount: Longword;
begin
  Result := TMCP23X17.Count;
end;

function TMCP23017.GetActiveLow(Index: Longword): Boolean;
begin
  Result := fProxy.GetActiveLow(Index);
end;

function TMCP23017.GetDirection(Index: Longword): TGpioDirection;
begin
  Result := fProxy.GetDirection(Index);
end;

function TMCP23017.GetInterruptMode(Index: Longword): TGpioInterruptMode;
begin
  Result := fProxy.GetInterruptMode(Index);
end;

function TMCP23017.GetValue(Index: Longword): Boolean;
begin
  Result := fProxy.GetValue(Index);
end;

procedure TMCP23017.SetActiveLow(Index: Longword; AValue: Boolean);
begin
  fProxy.SetActiveLow(Index, AValue);
end;

procedure TMCP23017.SetDirection(Index: Longword; AValue: TGpioDirection);
begin
  fProxy.SetDirection(Index, AValue);
end;

procedure TMCP23017.SetInterruptMode(Index: Longword; AValue: TGpioInterruptMode
  );
begin
  fProxy.SetInterruptMode(Index, AValue);
end;

procedure TMCP23017.SetValue(Index: Longword; aValue: Boolean);
begin
  fProxy.SetValue(Index, AValue);
end;

constructor TMCP23017.Create(aDevice: TI2CDevice);
begin
  inherited Create(aDevice);
  fMCP23X17Controller := TMCP23017Controller.Create(aDevice, False);
  fProxy := TMCP23X17.Create(fMCP23X17Controller);
end;


destructor TMCP23017.Destroy;
begin
  FreeAndNil(fProxy);
  FreeAndNil(fMCP23X17Controller);
  inherited Destroy;
end;

{ TGpioI2CController }

constructor TGpioI2CController.Create(aDevice: TI2CDevice);
begin
  inherited Create;
  fI2CDevice := aDevice;
end;

{ TGpioSPIController }

constructor TGpioSPIController.Create(aDevice: TSPIDevice);
begin
  inherited Create;
  fSPIDevice := aDevice;
end;

end.
