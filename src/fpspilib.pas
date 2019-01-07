{ Free Pascal SPI Library

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
unit fpspilib;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpspi, fpadc;

type

  TMCP3X0X = class(TADConverter)
  protected                     
    fBus: TSPIDevice;
    function GetValue(Index: Longword): Longint; override;
    function GetDifferentialValue(Index: Longword): Longint; override;
    function GetSupportsDifferentialValue: Boolean; override;
    class function GetBitCount: Byte; virtual; abstract;
    function InternalGetValue(Single: Boolean; Channel: Byte): Longint;
  public
    constructor Create(aBus: TSPIDevice);
  end;

  { TMCP300X }

  TMCP300X = class(TMCP3X0X)
  protected                 
    function GetMaxValue: Longint; override;
    class function GetBitCount: Byte; override;
  end;

  { TMCP3008 }

  TMCP3008 = class(TMCP300X)
  protected
    function GetCount: Longword; override;
  end;

  { TMCP3004 }

  TMCP3004 = class(TMCP300X)
  protected
    function GetCount: Longword; override;
  end;

  TMCP320X = class(TMCP3X0X)
  protected
    function GetMaxValue: Longint; override;
    class function GetBitCount: Byte; override;
  end;

  { TMCP3208 }

  TMCP3208 = class(TMCP320X)
  protected
    function GetCount: Longword; override;
  end;

  { TMCP3004 }

  TMCP3204 = class(TMCP320X)
  protected
    function GetCount: Longword; override;
  end;

  TMCP330X = class(TMCP3X0X)
  protected
    function GetMaxValue: Longint; override;
    function GetMinValue: Longint; override;
    class function GetBitCount: Byte; override;
  end;

  TMCP3304 = class(TMCP330X)
  protected
    function GetCount: Longword; override;
  end;

  TMCP3308 = class(TMCP330X)
  protected
    function GetCount: Longword; override;
  end;

implementation

{ TMCP3308 }

function TMCP3308.GetCount: Longword;
begin
  Result := 8;
end;

{ TMCP3304 }

function TMCP3304.GetCount: Longword;
begin
  Result := 4;
end;

{ TMCP330X }

function TMCP330X.GetMaxValue: Longint;
begin
  // 12 bit
  Result := +4095;
end;

function TMCP330X.GetMinValue: Longint;
begin
  // 12 bit + 1 bit sign
  Result := -4096;
end;

class function TMCP330X.GetBitCount: Byte;
begin
  Result := 13;
end;

{ TMCP3204 }

function TMCP3204.GetCount: Longword;
begin
  Result := 4;
end;

{ TMCP3208 }

function TMCP3208.GetCount: Longword;
begin
  Result := 8;
end;

{ TMCP320X }

function TMCP320X.GetMaxValue: Longint;
begin
  // 12 bit
  Result := $0FFF;
end;

class function TMCP320X.GetBitCount: Byte;
begin
  Result := 12;
end;

{ TMCP3X0X }

function TMCP3X0X.GetValue(Index: Longword): Longint;
begin
  Result := InternalGetValue(True, Index);
end;

function TMCP3X0X.GetDifferentialValue(Index: Longword): Longint;
begin
  Result := InternalGetValue(False, Index);
end;

function TMCP3X0X.GetSupportsDifferentialValue: Boolean;
begin
  Result := True;
end;

function TMCP3X0X.InternalGetValue(Single: Boolean; Channel: Byte): Longint;
var
  wbuf: array [0..1] of Byte;
  wword: word absolute wbuf; //< access wbuf as word
  rbuf: array[0..3] of Byte;
  rlong: Longword absolute rbuf;
begin
  if (Channel > (Count - 1)) then
    raise EADCError.CreateFmt(sChannelOutOfBounds, [Channel]);

  // set start bit
  (* see datatsheet for MCP3004/8, MCP3204/8 or MCP3304/8
   * ADC   Resolution Index of Start Bit in first byte
   * 300X   10 bit    0
   * 320X   12 bit    2
   * 330X   13 bit    3
   * Thus it can be shifted to left (+8 for second byte)
   * the same applies for the Single/Differential Bit and the Channel bits
   *)
  Assert(GetBitCount >= 10, 'Expected at least 10 bit resolution');
  wword := $0001 shl (GetBitCount - 10 + 8);
  // single bit
  if not single then
    wword := wword or ($0001 shl (GetBitCount - 10 + 7));
  // channel
  wword := wword or (Channel shl (GetBitCount - 10 + 4));

  // initialize read buffer
  rlong := 0;
  // pass second byte of longword (= 3 bytes)
  fBus.ReadAndWrite(wbuf[0], Length(wbuf), rbuf[1], Length(rbuf)-1);

  // check if the negative sign is set
  if (rlong and Longword(MinValue)) <> 0 then
    // if it's set, set all higher bits to 1 (two complement negative)
    // MinValue is defined as LongInt and thus already has all needed bits set
    Result := LongInt(rlong or Longword(MinValue))
  else
    // use only valid bits
    Result := rlong and MaxValue;
end;

constructor TMCP3X0X.Create(aBus: TSPIDevice);
begin
  fBus := aBus;
  fBus.BitsPerWord := 8;
  fBus.Mode := SPI_MODE_0;
  fbus.LSBFirst := False;
end;

{ TMCP3004 }

function TMCP3004.GetCount: Longword;
begin
  Result := 4;
end;

{ TMCP3008 }

function TMCP3008.GetCount: Longword;
begin
  Result := 8;
end;

{ TMCP300X }

function TMCP300X.GetMaxValue: Longint;
begin
  Result := $03FF; // 10 bit resolution
end;

class function TMCP300X.GetBitCount: Byte;
begin
  Result := 10;
end;

end.

