{ Interrupt sample application

  This demo program shows how to wait for an interrupt.

  GPIO 25 is configured as input (chang this below if you're using a differnt
  port. A switch or pushbutton can close the connection between ground (GND) and
  GPIO 25. The 10k pull-up resistor connects +3,3V to GPIO 25 to "pull-up" the
  voltage at GPIO 25 to +3,3V if the switch is open; if it is closed, the
  resistor prevents a short circuit between ground and +3,3V (witch may destroy
  your hardware).

  GPIO 25 <--- SWITCH <- GND
            ^
            |
           10k pull-up resistor
            |
            +3,3V
}
program project1;

{$mode objfpc}{$H+}

uses
  baseunix, fpgpio;

var
  input: TGpioLinuxPin;
  Terminate: Boolean = False;


Procedure DoSig(sig : cint);cdecl;
begin
  if Terminate then
    halt(2);
  Terminate := True;
end;

procedure InstallSignalHandler;
var
  na, oa: sigactionrec;
begin
  new(na);
  new(oa);
  na^.sa_Handler:=SigActionHandler(@DoSig);
  fillchar(na^.Sa_Mask,sizeof(na^.sa_mask),#0);
  na^.Sa_Flags:=0;
  {$ifdef Linux}               // Linux specific
   na^.Sa_Restorer:=Nil;
  {$endif}
  fpSigAction(SIGINT,na,oa);
  begin
    writeln('Error: ',fpgeterrno,'.');
    halt(1);
  end;
  Dispose(na);
  Dispose(oa);
end;

begin
  InstallSignalHandler;

  input := TGpioLinuxPin.Create(25); // GPIO 25
  input.Direction := gdIn;
  input.InterruptMode := [gimRising, gimFalling]; // interrupt on open and close
  repeat
    if input.WaitForInterrupt(0) then
      Writeln('Interrupt on Pin ', input.PinID)
    else
      WriteLn('Timeout');

  until Terminate;

  input.Destroy;
end.

