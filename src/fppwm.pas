{ PWM classes for Free Pascal

  Copyright (C) 2020, Simon Ameis <simon.ameis@web.de>

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
unit fppwm;

{$mode objfpc}{$H+}
{$ModeSwitch typehelpers}

interface

uses
  Classes, SysUtils, {$IFDEF LINUX}baseunix, {$ENDIF} rtlconsts;

type
  TPWMPolarity = (pwmNormal, pwmInverse);
  EInvalidPolarity = class(Exception);

  TPWMPolarityHelper = type helper for TPWMPolarity
    class function Parse(const aStr: String): TPWMPolarity; static;
    class function ToString(aValue: TPWMPolarity): String; static;
    function ToString: String;
  end;

  TPWM = class(TObject)
  strict protected
    function GetDutyCycle: Longword; virtual; abstract;
    function GetEnabled: Boolean; virtual; abstract;
    function GetPeriod: Longword; virtual; abstract;
    function GetPolarity: TPWMPolarity; virtual; abstract;
    procedure SetDutyCycle(AValue: Longword); virtual; abstract;
    procedure SetEnabled(AValue: Boolean); virtual; abstract;
    procedure SetPeriod(AValue: Longword); virtual; abstract;
    procedure SetPolarity(AValue: TPWMPolarity); virtual; abstract;
  public
    property Period: Longword read GetPeriod write SetPeriod;
    property DutyCycle: Longword read GetDutyCycle write SetDutyCycle;
    property Polarity: TPWMPolarity read GetPolarity write SetPolarity;
    property Enabled: Boolean read GetEnabled write SetEnabled;
  end;

{$IFDEF LINUX}
type
  TPWMLinux = class(TPWM)
  strict private const
    // maximum longint string length
    LONGINT_MAX_STR_LEN = 11;
  strict private
    fChannel: Longint;
    fChip: Longint;
    class function GetChannelCount(aChip: Longint): Longint; static;
    class function GetChipCount: Longint; static;
  strict protected
    function GetDutyCycle: Longword; override;
    function GetEnabled: Boolean; override;
    function GetPeriod: Longword; override;
    function GetPolarity: TPWMPolarity; override;
    procedure SetDutyCycle(AValue: Longword); override;
    procedure SetEnabled(AValue: Boolean); override;
    procedure SetPeriod(AValue: Longword); override;
    procedure SetPolarity(AValue: TPWMPolarity); override;
  strict protected
    class procedure SetExport(aExport: Boolean; aChip, aChannel: Longint);
  public
    class property ChipCount: Longint read GetChipCount;
    class property ChannelCount[aChip: Longint]: Longint read GetChannelCount;
  public             
    property Chip: Longint read fChip;
    property Channel: Longint read fChannel;
    constructor Create(aChip, aChannel: Longint);
    destructor Destroy; override;
  end;

{$ENDIF}

implementation

{$IFDEF LINUX}
uses
  fpsysfs;

{$ENDIF}

{ TPWMPolarityHelper }

class function TPWMPolarityHelper.Parse(const aStr: String): TPWMPolarity;
begin
  case aStr of
    'normal' : exit(pwmNormal);
    'inverse': exit(pwmInverse);
  else
    raise EInvalidPolarity.CreateFmt('Invalid polarity string "%s".', [aStr]);
  end;
end;

class function TPWMPolarityHelper.ToString(aValue: TPWMPolarity): String;
begin
  case aValue of
    pwmNormal : Result := 'normal';
    pwmInverse: Result := 'inverse';
  end;
end;

function TPWMPolarityHelper.ToString: String;
begin
  Result := ToString(Self);
end;

{$IFDEF LINUX}
{ TPWMLinux }

class function TPWMLinux.GetChipCount: Longint; static;
var
  searchRec: TRawByteSearchRec;
  lastFile: RawByteString = '';
  ChipNoLength: SizeInt;
begin
  // this assumes, the pwmchips start with 0 and have no numbering holes
  // didn't check this in real world
  Result := 0;
  if FindFirst(PWM_LINUX_BASE_DIR + 'pwmchip*', faAnyFile, searchRec) = 0 then
  begin
    repeat
      if CompareStr(lastFile, searchRec.Name) > 0 then
        lastFile := searchRec.Name;
    until FindNext(searchRec) <> 0;
    ChipNoLength := Length(lastFile)-length('pwmchip');
    lastFile := RightStr(lastFile, ChipNoLength);
    Result := StrToInt(lastFile);
  end;
  FindClose(searchRec);
end;

function TPWMLinux.GetDutyCycle: Longword;
var
  fn, p: String;
begin
  fn := Format(PWM_LINUX_PWMCHANNEL_DUTY_CYCLE, [fChip, fChannel]);
  p := ReadFromFile(fn, LONGINT_MAX_STR_LEN);
  Result := p.ToInteger;
end;

function TPWMLinux.GetEnabled: Boolean;
var
  fn, s: String;
begin
  fn := Format(PWM_LINUX_PWMCHANNEL_ENABLE, [fChip, fChannel]);
  s := ReadFromFile(fn, 1);
  Result := s <> '0';
end;

function TPWMLinux.GetPeriod: Longword;
var
  fn, p: String;
begin
  fn := Format(PWM_LINUX_PWMCHANNEL_PERIOD, [fChip, fChannel]);
  p := ReadFromFile(fn, LONGINT_MAX_STR_LEN);
  Result := p.ToInteger;
end;

function TPWMLinux.GetPolarity: TPWMPolarity;
var
  fn, polStr: String;
begin
  fn := Format(PWM_LINUX_PWMCHANNEL_POLARITY, [fChip, fChannel]);
  polStr := ReadFromFile(fn, 7);
  Result := TPWMPolarity.Parse(polStr);
end;

procedure TPWMLinux.SetDutyCycle(AValue: Longword);
var
  fn, p: String;
begin
  fn := Format(PWM_LINUX_PWMCHANNEL_DUTY_CYCLE, [fChip, fChannel]);
  p := AValue.ToString;
  WriteToFile(fn, p);
end;

procedure TPWMLinux.SetEnabled(AValue: Boolean);
var
  fn, s: String;
begin
  fn := Format(PWM_LINUX_PWMCHANNEL_ENABLE, [fChip, fChannel]);
  if AValue then
    s := '1'
  else
    s := '0';
  WriteToFile(fn, s);
end;

procedure TPWMLinux.SetPeriod(AValue: Longword);
var
  fn, p: String;
begin
  fn := Format(PWM_LINUX_PWMCHANNEL_PERIOD, [fChip, fChannel]);
  p := AValue.ToString;
  WriteToFile(fn, p);
end;

procedure TPWMLinux.SetPolarity(AValue: TPWMPolarity);
var
  polStr, fn: String;
begin
  polStr := AValue.ToString;
  fn := Format(PWM_LINUX_PWMCHANNEL_POLARITY, [fChip, fChannel]);
  WriteToFile(fn, polStr[1], Length(polStr));
end;

class procedure TPWMLinux.SetExport(aExport: Boolean; aChip, aChannel: Longint);
var
  s, exportedDir, fn: String;
begin
  if aExport then
  begin
    fn := Format(PWM_LINUX_PWMCHIP_EXPORT, [aChip]);
    exportedDir := Format(PWM_LINUX_PWMCHANNEL_DIR, [aChip, aChannel]);
  end
  else
    fn := Format(PWM_LINUX_PWMCHIP_UNEXPORT, [aChip]);

  s := aChannel.ToString;
  WriteToFile(fn, s[1], Length(s));

  if aExport then
    CheckExported(exportedDir);
end;

class function TPWMLinux.GetChannelCount(aChip: Longint): Longint; static;
var
  npwmFilename, npwm: String;
begin
  npwmFilename := Format(PWM_LINUX_PWMCHIP_NPWM, [aChip]);
  npwm := ReadFromFile(npwmFilename, LONGINT_MAX_STR_LEN);
  Result := StrToInt(npwm);
end;

constructor TPWMLinux.Create(aChip, aChannel: Longint);
begin
  fChip := aChip;
  fChannel := aChannel;
  SetExport(True, aChip, aChannel);
end;

destructor TPWMLinux.Destroy;
begin
  SetExport(false, fChip, fChannel);
  inherited Destroy;
end;

{$ENDIF}

end.
