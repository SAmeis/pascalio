program project1;

{$mode objfpc}{$H+}

uses
  sysutils,
  rpiio, fpi2c,
  { you can add units after this };

var
  idev: TI2CLinuxDevice;
  bval: Byte;
begin
  idev := nil;
  try
    idev := TI2CLinuxDevice.Create($20, 1);
    writeln('Device file handle: ', idev.Handle);
    bval := idev.ReadRegByte($12);
    Writeln('Register $12 (GPIOA): ', binstr(bval,8));

    idev.WriteRegByte($01, $00); // GPIOB = Output
    for bval := 0 to 5 do
    begin
      idev.WriteRegByte($13, $FF);
      Sleep(1000);
      idev.WriteRegByte($13, $00);
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
  idev.Free;
end.

