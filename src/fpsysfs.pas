{ SysFS helper unit

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
unit fpsysfs;

{$mode objfpc}{$H+}

interface

uses
  sysutils, Classes;

resourcestring
  sExportCheckFailed = 'Exporting "%s" failed.';
  sExportTimedOut = 'Exporting "%s" timed out.';

const
  GPIO_LINUX_BASE_DIR = '/sys/class/gpio/';
  GPIO_LINUX_GPIOPIN_DIR = GPIO_LINUX_BASE_DIR + 'gpio%d/';
  PWM_LINUX_BASE_DIR = '/sys/class/pwm/';
  PWM_LINUX_PWMCHIP_DIR = PWM_LINUX_BASE_DIR + 'pwmchip%d/';
  PWM_LINUX_PWMCHIP_NPWM = PWM_LINUX_PWMCHIP_DIR + 'npwm';
  PWM_LINUX_PWMCHIP_EXPORT = PWM_LINUX_PWMCHIP_DIR + 'export';
  PWM_LINUX_PWMCHIP_UNEXPORT = PWM_LINUX_PWMCHIP_DIR + 'unexport';
  PWM_LINUX_PWMCHANNEL_DIR = PWM_LINUX_PWMCHIP_DIR + 'pwm%d/';
  PWM_LINUX_PWMCHANNEL_PERIOD = PWM_LINUX_PWMCHANNEL_DIR + 'period';
  PWM_LINUX_PWMCHANNEL_DUTY_CYCLE = PWM_LINUX_PWMCHANNEL_DIR + 'duty_cycle';
  PWM_LINUX_PWMCHANNEL_POLARITY = PWM_LINUX_PWMCHANNEL_DIR + 'polarity';
  PWM_LINUX_PWMCHANNEL_ENABLE = PWM_LINUX_PWMCHANNEL_DIR + 'enable';

var
  { Milliseconds of sleep in procedure CheckExported
    Set to any negative value, if you create TGpioLinuxPin or TPWMLinux objects
    in a row and set properties afterwards.
    Special values:
    <0 no sleep
     0 context switch to operating system without sleep
  }
  ExportCheckDelay: NativeInt = 20;
  // raise an EExportCheckFailed Exception if CheckExported fails
  ExportCheckFailException: Boolean = false;

type
  EExportCheckFailed = class(Exception);

function ReadFromFile(const aFileName: String; aChars: SizeInt; out CharsRead: SizeInt): String;
function ReadFromFile(const aFileName: String; aChars: SizeInt): String;
procedure WriteToFile(const aFileName: String; const aBuffer; aCount: SizeInt);
procedure WriteToFile(const aFileName: String; const aBuffer: String);
procedure CheckExported(const aDirName: String);

implementation

uses
  BaseUnix, RtlConsts;

function ReadFromFile(const aFileName: String; aChars: SizeInt; out
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
  // the files contain the value followed by a line feed
  Result := Trim(Result);
  CharsRead := Length(Result);
  fpClose(fd);
end;

function ReadFromFile(const aFileName: String;
  aChars: SizeInt): String;
var
  i: SizeInt;
begin
  Result := ReadFromFile(aFileName, aChars, i);
end;

procedure WriteToFile(const aFileName: String;
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

procedure WriteToFile(const aFileName: String;
  const aBuffer: String);
begin
  if length(aBuffer) >= 1 then
    WriteToFile(aFileName, aBuffer[1], length(aBuffer));
end;

procedure CheckExported(const aDirName: String);
begin
  if DirectoryExists(aDirName) then exit;

  if ExportCheckDelay >= 0 then
  begin
    Sleep(ExportCheckDelay);

    if not DirectoryExists(aDirName) then
      raise EExportCheckFailed.CreateFmt(sExportTimedOut, [aDirName]);
  end
  else if ExportCheckFailException then
    raise EExportCheckFailed.CreateFmt(sExportCheckFailed, [aDirName]);
end;

end.

