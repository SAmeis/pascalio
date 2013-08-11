{ Testing MCP23017 access using unit fpi2c.

  Copyright (C) 2013 Simon Ameis, <simon.ameis@web.de>

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
}

program project1;
{ This program shows how to access an MCP23017 device using TI2CDevice classes.
  These classes are not thread safe, so only one device should be accessed at
  the same time on one same bus.

  How to connect:
                      +---------+
         (blink) LED<-| 1     28|->3V3 (read)
                      | 2     27|->GND (read)
                      | 3     26|
                      | 4  M  25|
                      | 5  C  24|
                      | 6  P  23|
                      | 7  2  22|
                      | 8  3  21|
                 3V3<-| 9  0  20|
                 GND<-|10  1  19|
                      |11  7  18|
                 SCL<-|12     17|->GND
                 SDA<-|13     16|->GND
                      |14     15|->GND
                      +---------+
}
{$mode objfpc}{$H+}

uses
  sysutils, rpiio, fpi2c, mcp23017, gpioexp, fpgpio;

var
  i2cdev: TI2CDevice;
  controller: TMCP23017;
  led, p33, pgnd: TGpioPin;
  i: Integer;
begin
  i2cdev := TI2CLinuxDevice.Create($40, 1);
  controller := TMCP23017.Create(i2cdev);
  try
    p33 := controller.Pins[7];
    pgnd := controller.Pins[6];
    led := controller.Pins[8];
    p33.Direction := gdIn;
    pgnd.Direction := gdIn;
    led.Direction := gdOut;

    Writeln('p33.value ',p33.Value);
    Writeln('pgnd.value ', pgnd.Value);
    for i := 0 to 6 do
    begin
      led.value := True;
      sleep(1000);
      led.value := False;
      sleep(1000);
    end;
  finally
    controller.Destroy;
    i2cdev.destroy;
  end;
  writeln('shutd down');
end.

