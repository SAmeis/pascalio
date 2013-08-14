program project1;

{$mode objfpc}{$H+}

uses
  sysutils,
  rpiio, fpi2c, mcp23017
  { you can add units after this };

var
  idev: TI2CLinuxDevice;
  mcp: TMCP23017Controller;
  bval: Byte;
begin
  idev := nil;
  mcp := nil;
  try
    idev := TI2CLinuxDevice.Create($20, 1);
    writeln('Device file handle: ', idev.Handle);
    mcp := TMCP23017Controller.Create(idev, True);
    bval := mcp.GPIOA;
    Writeln('Register GPIOA: ', binstr(bval,8));

    mcp.IODIRB := $00; // GPIOB = Output
    for bval := 0 to 5 do
    begin
      mcp.GPIOB := $FF;
      Sleep(1000);
      mcp.GPIOB := $00;
      Sleep(1000);
    end;
  except
    // this exception handling should be a try/finally block
    // but FPC 2.7.1 doesn't do the default exception handling
    // so this is workaround to avoid memory leaking the exception object
    on e: exception do
    begin
      writeln(ErrOutput, 'E Class  : ', e.ClassName);
      writeln(ErrOutput, 'E Message: ', e.Message);
      writeln(ErrOutput, 'E Address: ', hexStr(ExceptAddr));
    end;
  end;
  mcp.Free;
end.

