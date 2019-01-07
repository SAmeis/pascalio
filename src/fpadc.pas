{ Free Pascal Analog/Digital Converter access unit

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


unit fpadc;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

resourcestring
  sDiffNotSupported = '%s does not support differential input mode.';
  sChannelOutOfBounds = 'Channel index (%d) out of bounds.';

type
  { EDifferentialNotSupported }

  EADCError = class(Exception);
  EDifferentialNotSupported = class(EADCError)
  public
    constructor Create(const aClassName: ShortString);
    constructor Create(aClass: TClass);
  end;

  { TADConverter }

  TADConverter = class(TObject)
  protected                                                 
    function GetCount: Longword; virtual; abstract;
    function GetMaxValue: Longint; virtual; abstract;
    function GetMinValue: Longint; virtual;
    function GetSupportsDifferentialValue: Boolean; virtual;
    function GetDifferentialValue(Index: Longword): Longint; virtual;
    function GetValue(Index: Longword): Longint; virtual; abstract;
  public
    property MaxValue: Longint read GetMaxValue;
    property MinValue: Longint read GetMinValue;
    property Count: Longword read GetCount;
    property SupportsDifferentialValue: Boolean read GetSupportsDifferentialValue;
    property Value[Index: Longword]: Longint read GetValue;
    property DifferentialValue[Index: Longword]: Longint read GetDifferentialValue;
  end;

implementation

{ TADConverter }

function TADConverter.GetMinValue: Longint;
begin
  Result := 0;
end;

function TADConverter.GetSupportsDifferentialValue: Boolean;
begin
  Result := False;
end;

function TADConverter.GetDifferentialValue(Index: Longword): Longint;
begin
  Raise EDifferentialNotSupported.Create(Self.ClassType);
end;

{ EPDNotSupported }

constructor EDifferentialNotSupported.Create(const aClassName: ShortString);
begin
  inherited CreateFmt(sDiffNotSupported, [aClassName]);
end;

constructor EDifferentialNotSupported.Create(aClass: TClass);
begin
  Create(aClass.ClassName);
end;

end.

