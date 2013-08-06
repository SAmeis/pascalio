program t_mcp3008;

{$mode objfpc}{$H+}

uses
  fpadc, fpspilib, fpspi, sysutils
  { you can add units after this };
var
  spi: TSPIDevice;
  adc: TADConverter;
begin
  writeln('Using ', TSPILinuxDevice.ClassName, ' on Bus #0 and ChipSelect #0');
  spi := TSPILinuxDevice.Create(0,0);
  adc := TMCP3008.Create(spi);
  try
    while true do
    begin
      writeln('Value: ', adc.Value[0]);
      sleep(500);
    end;
  finally
    adc.Free;
    spi.Free;
  end;
end.
