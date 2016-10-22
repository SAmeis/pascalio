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
    function GetValue(Index: Longword): Longword; override; inline;
    function GetDifferentialValue(Index: Longword): Longword; override; inline;
    class function GetSupportsDifferentialValue: Boolean; override; inline;
    function InternalGetValue(Single: Boolean; Channel: Byte
      ): Longword; virtual; abstract;
  public
    constructor Create(aBus: TSPIDevice);
  end;

  { TMCP300X }

  TMCP300X = class(TMCP3X0X)
  protected                 
    class function GetMaxValue: Longword;
    function InternalGetValue(Single: Boolean; Channel: Byte
      ): Longword; override;
  end;

  { TMCP3008 }

  TMCP3008 = class(TMCP300X)
  protected
    class function GetCount: Longword; static; override;
  end;

  { TMCP3004 }

  TMCP3004 = class(TMCP300X)
  protected
    class function GetCount: Longword; static; override;
  end;

  TMCP320X = class(TMCP3X0X)
  protected
    class function GetMaxValue: Longword; static; override;
    function InternalGetValue(Single: Boolean; Channel: Byte): Longword; override;
  end;

  { TMCP3208 }

  TMCP3208 = class(TMCP320X)
  protected
    class function GetCount: Longword; static; override;
  end;

  { TMCP3004 }

  TMCP3204 = class(TMCP320X)
  protected
    class function GetCount: Longword; static; override;
  end;


implementation

{ TMCP3204 }

class function TMCP3204.GetCount: Longword;
begin
  Result := 4;
end;

{ TMCP3208 }

class function TMCP3208.GetCount: Longword;
begin
  Result := 8;
end;

{ TMCP320X }

class function TMCP320X.GetMaxValue: Longword;
begin
  // 12 bit
  Result := $FFF;
end;

function TMCP320X.InternalGetValue(Single: Boolean; Channel: Byte): Longword;
const
  start_bit = $0400;
  sgl_bit   = $0200;
var
  wbuf: array [0..1] of Byte;
  wword: word absolute wbuf; //< access wbuf as word
  rbuf: array[0..3] of Byte;
  rlong: Longword absolute rbuf;
begin
  if (Channel > (Count - 1)) then
    raise EADCError.CreateFmt(sChannelOutOfBounds, [Channel]);
  // start bit and channel
  wword := start_bit or (Channel shl 6);
  // set single bit, if requested; otherwise differential input is used
  if not single then
    wword := wword or sgl_bit;

  // initialize read buffer
  rlong := 0;
  // pass second byte of longword (= 3 bytes)
  fBus.ReadAndWrite(wbuf[0], Length(wbuf), rbuf[1], Length(rbuf)-1);
  // first byte of longword hasn't been used as read buffer and is still 0
  // second byte of longowrd / first read byte is ignored/garbage
  // lowest 4 bits of second byte and third byte
  Result := rlong and $00000FFF;
end;

{ TMCP3X0X }

function TMCP3X0X.GetValue(Index: Longword): Longword;
begin
  Result := InternalGetValue(True, Index);
end;

function TMCP3X0X.GetDifferentialValue(Index: Longword): Longword;
begin
  Result := InternalGetValue(False, Index);
end;

class function TMCP3X0X.GetSupportsDifferentialValue: Boolean;
begin
  Result := True;
end;

constructor TMCP3X0X.Create(aBus: TSPIDevice);
begin
  fBus := aBus;
  fBus.BitsPerWord := 8;
  fBus.Mode := SPI_MODE_0;
  fbus.LSBFirst := False;
end;

{ TMCP3004 }

class function TMCP3004.GetCount: Longword;
begin
  Result := 4;
end;

{ TMCP3008 }

class function TMCP3008.GetCount: Longword;
begin
  Result := 8;
end;

{ TMCP300X }

class function TMCP300X.GetMaxValue: Longword;
begin
  Result := $03FF; // 10 bit resolution
end;

function TMCP300X.InternalGetValue(Single: Boolean; Channel: Byte): Longword;
const
  sgl_bit = $80;
  diff_bit = $00;
var
  wbuf: array [0..1] of Byte;
  rbuf: array[0..2] of Byte;
begin
  if (Channel > (Count - 1)) then
    raise EADCError.CreateFmt(sChannelOutOfBounds, [Channel]);
  wbuf[0] := 1; // start bit
  if single then
    wbuf[1] := sgl_bit or (Channel shl 4)
  else
    wbuf[1] := diff_bit or (Channel shl 4);
  FillChar(rbuf[0], sizeof(rbuf), 0);
  fBus.ReadAndWrite(wbuf[0], Length(wbuf), rbuf[0], Length(rbuf));
  // first read byte is ignored/garbage
  // lowest 2 bits of second byte and third byte
  Result := ((rbuf[1] and $03) shl 8) + rbuf[2];
end;

end.

