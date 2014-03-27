{ Distance measurement with ultrasonic module HC-SR04

  Copyright (C) 20104 Simon Ameis simon.ameis@web.de

  Idea: http://www.gtkdb.de/index_36_2272.html

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

program ultrasonic;

uses sysutils, pascalio, fpgpio, baseunix;

const
  GPIO_TRIGGER = 18;
  GPIO_ECHO    = 17;

var
  trigger  : TGpioPin;
  echo     : TGpioPin;
  Terminate: Boolean = False;
  distance : Double;

procedure DoSigInt(sig: cint); cdecl;
begin
  Writeln('Signal ', sig, ' received.');
  Terminate := True;
end;

function MeasureDistance: Double;
var
  StartTime: TDateTime;
  StopTime: TDateTime;
  TimeElapsed: Extended;
begin
  trigger.Value := True;
  WriteLn(ErrOutput, 'TRIGGER set to TRUE');
  Sleep(10);
  trigger.Value := False;
  WriteLn(ErrOutput, 'TRIGGER set to FALSE');

  StartTime := Now;

  while not Terminate and echo.Value = False do
    StartTime := Now;

  while not Terminate and echo.Value = True do
    StopTime := Now;

  TimeElapsed := StopTime - StartTime;
  Writeln(ErrOutput, '  StartTime: ', StartTime);
  Writeln(ErrOutput, '   StopTime: ', StopTime);
  Writeln(ErrOutput, 'TimeElapsed: ', TimeElapsed);
  Writeln(ErrOutput, 'TimeElapsed: ', TimeElapsed *24*60*60*(10**6),'us');

  Result := TimeElapsed * 24 * 60 * 60 * (10 ** 6) / 58;// 34300 / 2;
end;

begin
  // Signal handler for SIG_INT (CTRL+C)
  FpSignal(SIGINT, @DoSigInt);

  // setup GPIO pins
  trigger := TGpioLinuxPin.Create(GPIO_TRIGGER);
  trigger.Direction := gdOut;
  echo    := TGpioLinuxPin.Create(GPIO_ECHO   );
  echo.Direction    := gdIn;

  Terminate := False;
  while not Terminate do
  begin
    distance := MeasureDistance;
    Writeln(Format('Measured Distance = %4.2f cm', [distance]));
    FpSleep(1);
  end;
  trigger.Free;
  echo.Free;
end.

