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
  Classes, SysUtils, fpgpio, fpspi, fpi2c, rtlconsts;

type

  { TGpioI2CController }

  TGpioI2CController = class(TGpioRegisterController)
  protected
    fI2CDevice: TI2CDevice;
    function GetRegisterValue(aRegister: TRegisterAddress): TRegisterValue;
      override;
    procedure SetRegisterValue(aRegister: TRegisterAddress;
      aValue: TRegisterValue); override;
  public
    constructor Create(aDevice: TI2CDevice);
  end;

  { TGpioSPIController }

  TGpioSPIController = class(TGpioRegisterController)
  private
    FAddress: Byte;
    FHasAddress: Boolean;
  protected
    fSPIDevice: TSPIDevice;
    function GetRegisterValue(aRegister: TRegisterAddress): TRegisterValue;
      override;
    procedure SetRegisterValue(aRegister: TRegisterAddress;
      aValue: TRegisterValue); override;
    procedure SetAddress(AValue: Byte); virtual;
  public
    constructor Create(aDevice: TSPIDevice);
    constructor Create(aDevice: TSPIDevice; Address: Byte);
    property HasAddress: Boolean read FHasAddress write FHasAddress;
    property Address: Byte read FAddress write SetAddress;
  end;

  { TMCP23017 }

  TMCP23017 = class(TGpioI2CController)
  private
  protected
    class function GetCount: Longword; static; override;
    function GetRegister(PinIndex: Longword; aRegisterType: TRegisterType; out
      aPinPosition: TPinPosition): TRegisterAddress; override;
  public
  end;

  { TMCP23S17 }

  TMCP23S17 = class(TGpioSPIController)
  private

  protected
    class function GetCount: Longword; static; override;
    function GetRegister(PinIndex: Longword; aRegisterType: TRegisterType; out
      aPinPosition: TPinPosition): TRegisterAddress; override;
    procedure SetAddress(AValue: Byte); override;
  end;

implementation
type
  TMCP23017_REGISTER_INDEX = (
    mriIODIR,
    mriIPOL,
    mriGPINTEN,
    mriDEFVAL,
    mriINTCON,
    mriIOCON,
    mriGPPU,
    mriINTF,
    mriINTCAP,
    mriGPIO,
    mriOLAT
  );

  TMCP23017RegistersSBank = packed record
    IODIR  : Byte;
    IPOL   : Byte;
    GPINTEN: Byte;
    DEFVAL : Byte;
    INTCON : Byte;
    IOCON  : Byte;
    GPPU   : Byte;
    INTF   : Byte;
    INTCAP : Byte;
    GPIO   : Byte;
    OLAT   : Byte;
  end;

  TMCP23017Registers = packed record
    GPIOA: TMCP23017RegistersSBank;
    GPIOB: TMCP23017RegistersSBank;
  end;

  TMCP23017_GPIO_ROW = 0..1;
  TMCP23017_PIN_INDEX = 0..15;
const
  MCP23017_REGISTERS: array[Boolean] of array[0..1] of array[TMCP23017_REGISTER_INDEX] of TRegisterAddress = (
    (
      // IOCON.BANK = 0
      ($00,$02,$04,$06,$08,$0A,$0C,$0E,$10,$12,$14), // GPIO A
      ($01,$03,$05,$07,$09,$0B,$0D,$0F,$11,$13,$15)  // GPIO B
    ),
    (
      // IOCON.BANK = 1
      ($00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$10), // GPIO A
      ($0A,$0B,$0C,$0D,$0F,$10,$11,$12,$13,$14,$15)  // GPIO B
    )
  );

function GetMCP23017RegisterAddress(ICON_BANK: Boolean;
  row: TMCP23017_GPIO_ROW;
  RegisterIndex: TMCP23017_REGISTER_INDEX): TRegisterAddress; inline;
begin
  Result := MCP23017_REGISTERS[ICON_BANK, row, RegisterIndex];
end;

function GetMCP23017RegisterAddressForPin(ICON_BANK: Boolean;
  pin: TMCP23017_PIN_INDEX;
  RegisterIndex: TMCP23017_REGISTER_INDEX;
  out PinIndex: TPinPosition): TRegisterAddress; inline;
var
  row: Longword;
begin
  row := pin div 8;
  if row <= 2 then
  begin
    Result := GetMCP23017RegisterAddress(ICON_BANK, row, RegisterIndex);
    if RegisterIndex <> mriIOCON then
      PinIndex := pin mod 8
    else
      PinIndex := 0;
  end
  else
    raise ERangeError.CreateFmt(SOutOfRange, [low(pin), high(pin)]);
end;

{ TMCP23S17 }

class function TMCP23S17.GetCount: Longword;
begin
  Result := 16
end;

function TMCP23S17.GetRegister(PinIndex: Longword;
  aRegisterType: TRegisterType; out aPinPosition: TPinPosition
  ): TRegisterAddress;
begin
  Result := GetMCP23017RegisterAddressForPin(False, PinIndex, aRegisterType, aPinPosition);
end;

procedure TMCP23S17.SetAddress(AValue: Byte);
begin
  if (AValue and %01000000) <> 0 then
    inherited SetAddress(AValue)
  else
    raise ERangeError.Create('Invalid Device Address.');
end;

{ TMCP23017 }

class function TMCP23017.GetCount: Longword;
begin
  Result := 16;
end;

function TMCP23017.GetRegister(PinIndex: Longword;
  aRegisterType: TRegisterType; out aPinPosition: TPinPosition
  ): TRegisterAddress;
begin
  Result := GetMCP23017RegisterAddressForPin(False, PinIndex, aRegisterType, aPinPosition);
end;

{ TGpioI2CController }

function TGpioI2CController.GetRegisterValue(aRegister: TRegisterAddress
  ): TRegisterValue;
begin
  Result := fI2CDevice.ReadRegByte(aRegister);
end;

procedure TGpioI2CController.SetRegisterValue(aRegister: TRegisterAddress;
  aValue: TRegisterValue);
begin
  fI2CDevice.WriteByte(aRegister, aValue);
end;

constructor TGpioI2CController.Create(aDevice: TI2CDevice);
begin
  inherited Create;
  fI2CDevice := aDevice;
end;

{ TGpioSPIController }

procedure TGpioSPIController.SetAddress(AValue: Byte);
begin
  if FAddress = AValue then Exit;
  FAddress := AValue;
end;

function TGpioSPIController.GetRegisterValue(aRegister: TRegisterAddress
  ): TRegisterValue;
var
  b: Array[0..1] of Byte;
  rb: array[0..2] of Byte;
begin
  if HasAddress then
  begin
    b[0] := Address;
    b[1] := aRegister;
    fSPIDevice.ReadAndWrite(b[0], 2, rb[0], 3);
  end
  else
    fSPIDevice.ReadAndWrite(aRegister, 1, rb[1], 2);
  Result := rb[2];
end;

procedure TGpioSPIController.SetRegisterValue(aRegister: TRegisterAddress;
  aValue: TRegisterValue);
var
  b: Array[0..2] of Byte;
begin
  b[0] := Address;
  b[1] := aRegister;
  b[2] := aValue;
  if HasAddress then
    fSPIDevice.Write(b[0], 3)
  else
    fSPIDevice.Write(b[1], 2);
end;

constructor TGpioSPIController.Create(aDevice: TSPIDevice);
begin
  inherited Create;
  fSPIDevice := aDevice;
  FHasAddress := False;
  FAddress := 0;
end;

constructor TGpioSPIController.Create(aDevice: TSPIDevice; Address: Byte);
begin
  inherited Create;
  fSPIDevice := aDevice;
  FHasAddress := True;
  FAddress := Address;
end;

end.

