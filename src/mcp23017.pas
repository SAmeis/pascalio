{ Classes for accessing MCP23017 and MCP23S17

  Copyright (C) 2013 Simon Ameis <simon.ameis@web.de>

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
unit mcp23017;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpspi, fpi2c;

resourcestring
  sInvalidAddress = 'Invalid address (0x%x)';
const
  // first 4 bits are fixed
  // last bit is R/W bit
  MCP23X17_DEFAULT_ADDRESS = %01000000;

type
  EInvalidMCP23X17Address = class(Exception);
  { TMCP23X17Controller }

  TMCP23X17Controller = class (TObject)
  strict private
    fIOCON: Byte; // internal value of IOCON for faster configuration access
    fOwnsDevice: Boolean;
    function GetAddress: Byte;
    procedure SetIOCONValue(AIndex: Integer; AValue: Boolean);
    function GetIOCONValue(AIndex: Integer): Boolean;
  strict private
    // all methods: index must be in range of 1..2
    function GetDEFVAL(AIndex: Integer): Byte;
    function GetGPINTEN(AIndex: Integer): Byte;
    function GetGPIO(AIndex: Integer): Byte;
    function GetGPPU(AIndex: Integer): Byte;
    function GetINTCAP(AIndex: Integer): Byte;
    function GetINTCON(AIndex: Integer): Byte;
    function GetINTF(AIndex: Integer): Byte;
    function GetIOCON(AIndex: Integer): Byte;
    function GetIODIR(AIndex: Integer): Byte;
    function GetIPOL(AIndex: Integer): Byte;
    function GetOLAT(AIndex: Integer): Byte;
    procedure SetDEFVAL(AIndex: Integer; AValue: Byte);
    procedure SetGPINTEN(AIndex: Integer; AValue: Byte);
    procedure SetGPIO(AIndex: Integer; AValue: Byte);
    procedure SetGPPU(AIndex: Integer; AValue: Byte);
    procedure SetINTCON(AIndex: Integer; AValue: Byte);
    procedure SetIOCON(AIndex: Integer; AValue: Byte);
    procedure SetIODIR(AIndex: Integer; AValue: Byte);
    procedure SetIPOL(AIndex: Integer; AValue: Byte);
    procedure SetOLAT(AIndex: Integer; AValue: Byte);
  protected
    function GetRegisterValue(aRegister: Byte): Byte; virtual; abstract;
    procedure SetRegisterValue(aRegister: Byte; aValue: Byte); virtual; abstract;
    constructor Create; virtual;
  public
    // port A
    property IODIRA  : Byte index 1 read GetIODIR   write SetIODIR  ;
    property IPOLA   : Byte index 1 read GetIPOL    write SetIPOL   ;
    property GPINTENA: Byte index 1 read GetGPINTEN write SetGPINTEN;
    property DEFVALA : Byte index 1 read GetDEFVAL  write SetDEFVAL ;
    property INTCONA : Byte index 1 read GetINTCON  write SetINTCON ;
    property IOCONA  : Byte index 1 read GetIOCON   write SetIOCON  ;
    property GPPUA   : Byte index 1 read GetGPPU    write SetGPPU   ;
    property INTFA   : Byte index 1 read GetINTF  ; // ro
    property INTCAPA : Byte index 1 read GetINTCAP; // ro
    property GPIOA   : Byte index 1 read GetGPIO    write SetGPIO   ;
    property OLATA   : Byte index 1 read GetOLAT    write SetOLAT   ;
    // port B
    property IODIRB  : Byte index 2 read GetIODIR   write SetIODIR  ;
    property IPOLB   : Byte index 2 read GetIPOL    write SetIPOL   ;
    property GPINTENB: Byte index 2 read GetGPINTEN write SetGPINTEN;
    property DEFVALB : Byte index 2 read GetDEFVAL  write SetDEFVAL ;
    property INTCONB : Byte index 2 read GetINTCON  write SetINTCON ;
    property IOCONB  : Byte index 2 read GetIOCON   write SetIOCON  ;
    property GPPUB   : Byte index 2 read GetGPPU    write SetGPPU   ;
    property INTFB   : Byte index 2 read GetINTF  ; // ro
    property INTCAPB : Byte index 2 read GetINTCAP; // ro
    property GPIOB   : Byte index 2 read GetGPIO    write SetGPIO   ;
    property OLATB   : Byte index 2 read GetOLAT    write SetOLAT   ;
    // shared
    property IOCON   : Byte index 0 read GetIOCON   write SetIOCON  ;

    // IOCON values
    // indices MUST refer to bit index
    property BANK  : Boolean index 7 read GetIOCONValue write SetIOCONValue;
    property MIRROR: Boolean index 6 read GetIOCONValue write SetIOCONValue;
    property SEQOP : Boolean index 5 read GetIOCONValue write SetIOCONValue;
    property DISSLW: Boolean index 4 read GetIOCONValue write SetIOCONValue;
    property HAEN  : Boolean index 3 read GetIOCONValue write SetIOCONValue; // used in SPI only
    property ODR   : Boolean index 2 read GetIOCONValue write SetIOCONValue;
    property INTPOL: Boolean index 1 read GetIOCONValue write SetIOCONValue;

    // device address
    property Address: Byte read GetAddress;
    property OwnsDevice: Boolean read fOwnsDevice write fOwnsDevice;
  end;

  { TMCP23017Controller }

  TMCP23017Controller = class(TMCP23X17Controller)
  protected
    fI2CDevice: TI2CDevice;
    function GetRegisterValue(aRegister: Byte): Byte; override;
    procedure SetRegisterValue(aRegister: Byte; aValue: Byte); override;
  public
    constructor Create; override;
    constructor Create(aI2CDevice: TI2CDevice; aOwnsDevice: Boolean); virtual;
    destructor Destroy; override;
    property I2CDevice: TI2CDevice read fI2CDevice write fI2CDevice;
  end;

  { TMCP23S17Controller }

  TMCP23S17Controller = class(TMCP23X17Controller)
  protected
    fSPIDevice: TSPIDevice;
    function GetRegisterValue(aRegister: Byte): Byte; override;
    procedure SetRegisterValue(aRegister: Byte; aValue: Byte); override;
  public
    constructor Create; override;
    constructor Create(aSPIDevice: TSPIDevice; aOwnsDevice: Boolean); virtual;
    destructor Destroy; override;
    property SPIDevice: TSPIDevice read fSPIDevice write fSPIDevice;
  end;

implementation

type
    // Comments reflect bit values!
  TMCP23017_REGISTER_INDEX = (
    mriIODIR,     // Input/Output direction 1 = input (default), 0 = output
    mriIPOL,      // Input polarity 1 = reverted value, 0 = real value (default)
    mriGPINTEN,   // Interupt enable 1 = enabled (DEVAL and INTCON must be configured), 0 = disabled (default)
    mriDEFVAL,    // if GPINTEN set, interrupt occures if value differs from value in DEFVAL 0 = default
    mriINTCON,    // Interrupt control 1 = compare DEFVAL, 0 = all changes of value (default)
    mriIOCON,     (* I/O Configuration; bits are:
                   * BANK, MIRROR, SEQOP, DISSLW, HAEN, ODR, INTPOL, not used
                   * #
                   * 7  BANK    Bank mode
                   *            0 = registers of GPIO ports are addressed alternating;
                   *            1 = registers of port A come first, then port B
                   * 6  MIRROR  0 = seperate interrupts (default),
                   *            1 = interrrupts are shared between ports and interrupt pins
                   * 5  SEQOP   Sequential mode (internal register pointer is updated after each operation)
                   * 4  DISSLW  Slew rate function
                   * 3  HAEN    Hardware Address Enable (MCP23S17 only)
                   *            0 = address pins are not used (equals 0)
                   *            1 = address pins are used
                   * 2  ODR     Open Drain for interrupt pins 0 = INTPOL used, 1 = open-drain output (overrides INTPOL)
                   * 1  INTPOL  Interrupt Polarity 0 = active-low, 1 = active-high
                   * 0  not used (cite: unimplented: Read as '0')
                   *)
    mriGPPU,      // Internal Pull up resistors (MCP23017: 100 kOhm) 0 = disabled (default), 1 = enabled
    mriINTF,      // Interrupt Flag (read only) 1 = associated pin caused interrupt
    mriINTCAP,    // Interrupt Capture (read only, cleared on read of GPIO or INTCAP) value of pin on interrupt 0 = logic-low, 1 = logic-high
    mriGPIO,      // Boolean value of GPIO pins (write causes change of OLAT) 0 = logic-low, 1 = logic-high
    mriOLAT       // Output Latches (the value set by master; may differ from GPIO) 0 = logic-low, 1 = logic-high
  );

const
  (*
    Boolean
      False := BANK = 0
      True  := BANK = 1
    1..2
      correspond to property indices of class TMCP23X17Controller
    TMCP23017_REGISTER_INDEX
      the register in question
   *)
  MCP23017_REGISTERS: array[Boolean] of array[1..2] of array[TMCP23017_REGISTER_INDEX] of Byte = (
    (
      // IOCON.BANK = 0
      ($00,$02,$04,$06,$08,$0A,$0C,$0E,$10,$12,$14), // GPIO A
      ($01,$03,$05,$07,$09,$0B,$0D,$0F,$11,$13,$15)  // GPIO B
    ),
    (
      // IOCON.BANK = 1
      ($00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A), // GPIO A
      ($10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$1A)  // GPIO B
    )
  );

{ TMCP23S17Controller }

function TMCP23S17Controller.GetRegisterValue(aRegister: Byte): Byte;
var
  b: Array[0..1] of Byte;
  rb: array[0..2] of Byte;
begin
  if HAEN then
  begin
    b[0] := Address;
    b[1] := aRegister;
    fSPIDevice.ReadAndWrite(b[0], 2, rb[0], 3);
  end
  else
    fSPIDevice.ReadAndWrite(aRegister, 1, rb[1], 2);
  Result := rb[2];
end;

procedure TMCP23S17Controller.SetRegisterValue(aRegister: Byte; aValue: Byte);
var
  b: Array[0..2] of Byte;
begin
  b[0] := Address;
  b[1] := aRegister;
  b[2] := aValue;
  if HAEN then
    fSPIDevice.Write(b[0], 3)
  else
    fSPIDevice.Write(b[1], 2);
end;

constructor TMCP23S17Controller.Create;
begin
  inherited Create;
  fSPIDevice := nil;
end;

constructor TMCP23S17Controller.Create(aSPIDevice: TSPIDevice;
  aOwnsDevice: Boolean);
begin
  Create;
  fSPIDevice := aSPIDevice;
  OwnsDevice := aOwnsDevice;
end;

destructor TMCP23S17Controller.Destroy;
begin
  if OwnsDevice then
    FreeAndNil(fSPIDevice);
  inherited Destroy;
end;

{ TMCP23017Controller }

function TMCP23017Controller.GetRegisterValue(aRegister: Byte): Byte;
begin
  Result := fI2CDevice.ReadRegByte(aRegister);
end;

procedure TMCP23017Controller.SetRegisterValue(aRegister: Byte; aValue: Byte);
begin
  fI2CDevice.WriteRegByte(aRegister, aValue);
end;

constructor TMCP23017Controller.Create;
begin
  inherited Create;
  fI2CDevice := nil;
end;

constructor TMCP23017Controller.Create(aI2CDevice: TI2CDevice;
  aOwnsDevice: Boolean);
begin
  inherited Create;
  fI2CDevice := aI2CDevice;
  // check if invalid address bits are set
//  if (fI2CDevice.Address and %10110001) <> 0 then
//    raise EInvalidMCP23X17Address.CreateFmt(sInvalidAddress, [fI2CDevice.Address]);
  OwnsDevice := aOwnsDevice;
end;

destructor TMCP23017Controller.Destroy;
begin
  if OwnsDevice then
    FreeAndNil(fI2CDevice);
  inherited Destroy;
end;

{ TMCP23X17Controller }

function TMCP23X17Controller.GetDEFVAL(AIndex: Integer): Byte;
var
  r: Byte;
begin
  r := MCP23017_REGISTERS[BANK, AIndex, mriDEFVAL];
  Result := GetRegisterValue(r);
end;

function TMCP23X17Controller.GetAddress: Byte;
begin
  Result := MCP23X17_DEFAULT_ADDRESS;
end;

function TMCP23X17Controller.GetGPINTEN(AIndex: Integer): Byte;
var
  r: Byte;
begin
  r := MCP23017_REGISTERS[BANK, AIndex, mriGPINTEN];
  Result := GetRegisterValue(r);
end;

function TMCP23X17Controller.GetGPIO(AIndex: Integer): Byte;
var
  r: Byte;
begin
  r := MCP23017_REGISTERS[BANK, AIndex, mriGPIO];
  Result := GetRegisterValue(r);
end;

function TMCP23X17Controller.GetGPPU(AIndex: Integer): Byte;
var
  r: Byte;
begin
  r := MCP23017_REGISTERS[BANK, AIndex, mriGPPU];
  Result := GetRegisterValue(r);
end;

function TMCP23X17Controller.GetINTCAP(AIndex: Integer): Byte;
var
  r: Byte;
begin
  r := MCP23017_REGISTERS[BANK, AIndex, mriINTCAP];
  Result := GetRegisterValue(r);
end;

function TMCP23X17Controller.GetINTCON(AIndex: Integer): Byte;
var
  r: Byte;
begin
  r := MCP23017_REGISTERS[BANK, AIndex, mriINTCON];
  Result := GetRegisterValue(r);
end;

function TMCP23X17Controller.GetINTF(AIndex: Integer): Byte;
var
  r: Byte;
begin
  r := MCP23017_REGISTERS[BANK, AIndex, mriINTF];
  Result := GetRegisterValue(r);
end;

function TMCP23X17Controller.GetIOCON(AIndex: Integer): Byte;
var
  r: Byte;
begin
  // this register is shared (same for Port A and Port B)
  // this method may be called with AIndex = 0, thus define a
  // valid Port here
  r := MCP23017_REGISTERS[BANK, 1, mriIOCON];
  Result := GetRegisterValue(r);
end;

function TMCP23X17Controller.GetIOCONValue(AIndex: Integer): Boolean;
begin
  Result := (fIOCON and ($01 shl AIndex)) <> 0;
end;

function TMCP23X17Controller.GetIODIR(AIndex: Integer): Byte;
var
  r: Byte;
begin
  r := MCP23017_REGISTERS[BANK, AIndex, mriIODIR];
  Result := GetRegisterValue(r);
end;

function TMCP23X17Controller.GetIPOL(AIndex: Integer): Byte;
var
  r: Byte;
begin
  r := MCP23017_REGISTERS[BANK, AIndex, mriIPOL];
  Result := GetRegisterValue(r);
end;

function TMCP23X17Controller.GetOLAT(AIndex: Integer): Byte;
var
  r: Byte;
begin
  r := MCP23017_REGISTERS[BANK, AIndex, mriOLAT];
  Result := GetRegisterValue(r);
end;

procedure TMCP23X17Controller.SetDEFVAL(AIndex: Integer; AValue: Byte);
var
  r: Byte;
begin
  r := MCP23017_REGISTERS[BANK, AIndex, mriDEFVAL];
  SetRegisterValue(r, AValue);
end;

procedure TMCP23X17Controller.SetGPINTEN(AIndex: Integer; AValue: Byte);
var
  r: Byte;
begin
  r := MCP23017_REGISTERS[BANK, AIndex, mriGPINTEN];
  SetRegisterValue(r, AValue);
end;

procedure TMCP23X17Controller.SetGPIO(AIndex: Integer; AValue: Byte);
var
  r: Byte;
begin
  r := MCP23017_REGISTERS[BANK, AIndex, mriGPIO];
  SetRegisterValue(r, AValue);end;

procedure TMCP23X17Controller.SetGPPU(AIndex: Integer; AValue: Byte);
var
  r: Byte;
begin
  r := MCP23017_REGISTERS[BANK, AIndex, mriGPPU];
  SetRegisterValue(r, AValue);
end;

procedure TMCP23X17Controller.SetINTCON(AIndex: Integer; AValue: Byte);
var
  r: Byte;
begin
  r := MCP23017_REGISTERS[BANK, AIndex, mriINTCON];
  SetRegisterValue(r, AValue);
end;

procedure TMCP23X17Controller.SetIOCON(AIndex: Integer; AValue: Byte);
var
  r: Byte;
begin
  // define valid port here (register is shared)
  r := MCP23017_REGISTERS[BANK, 1, mriIOCON];
  SetRegisterValue(r, AValue);
  // update internal IOCON value
  fIOCON := AValue;
end;

procedure TMCP23X17Controller.SetIOCONValue(AIndex: Integer; AValue: Boolean);
var
  nv: Byte;
begin
  nv := fIOCON;
  if AValue then
    nv := nv or ($01 shl AIndex)
  else
    nv := nv xor ($01 shl AIndex);
  IOCON := nv;
end;

procedure TMCP23X17Controller.SetIODIR(AIndex: Integer; AValue: Byte);
var
  r: Byte;
begin
  r := MCP23017_REGISTERS[BANK, AIndex, mriIODIR];
  SetRegisterValue(r, AValue);
end;

procedure TMCP23X17Controller.SetIPOL(AIndex: Integer; AValue: Byte);
var
  r: Byte;
begin
  r := MCP23017_REGISTERS[BANK, AIndex, mriIPOL];
  SetRegisterValue(r, AValue);
end;

procedure TMCP23X17Controller.SetOLAT(AIndex: Integer; AValue: Byte);
var
  r: Byte;
begin
  r := MCP23017_REGISTERS[BANK, AIndex, mriOLAT];
  SetRegisterValue(r, AValue);
end;

constructor TMCP23X17Controller.Create;
begin
  fOwnsDevice := False;
end;

end.

