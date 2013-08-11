{ Testing Unit i2c_dev with MCP23017 GPIO extender

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

program project2;

{
  This demo program shows how to use unit i2c_dev to access a simple device
  like the MCP23017.
  It assumes:
  - MCP23017 is connected to I2C Port 1
  - The device address is set to $20 by connecting all thre address pins to GND
  - All A ports will be configured as input (connect to GND or +3V3)
  - All B ports will be configured as output (connect them to a LED)

  How to connect:
                      +---------+
         (blink) LED<-| 1     28|->3V3 (read)
                     /| 2     27|->GND (read)
                    / | 3     26|\
                   /  | 4  M  25| \
          (blink) <   | 5  C  24|  \ whatever you want
                   \  | 6  P  23|  / (will be read)
                    \ | 7  2  22| /
                     \| 8  3  21|/
                 3V3<-| 9  0  20|
                 GND<-|10  1  19|
                      |11  7  18|
                 SCL<-|12     17|->GND
                 SDA<-|13     16|->GND
                      |14     15|->GND
                      +---------+
}

uses
  i2c_dev, BaseUnix;
const
  // I2C bus to which the device is connected
  BUS_NAME = '/dev/i2c-1';
  // device adress (as set by address pins)
  ADDR = $20;

var
  fileh: cint;
  rval: LongInt;
  i: Integer;
begin
  // open device file
  fileh := FpOpen(BUS_NAME, O_RDWR);;
  if fileh < 0 then
  begin
    writeln('Opening file ', BUS_NAME ,' failed: ',fileh);
    halt(1);
  end
  else
    WriteLn('Opening file ', BUS_NAME,' succeeded: ', fileh);

  // set device address
  if (FpIOCtl(fileh, I2C_SLAVE, Pointer(ADDR)) < 0) then
  begin
    writeln('Opening slave ', ADDR, ' failed.');
    halt(1);
  end else
    writeln('Opening slave ', ADDR, ' succeeded');

  // set Input/Output modes
  rval := i2c_smbus_write_byte_data(fileh, $00, $FF); // GPIOA = INPUT
  rval := i2c_smbus_write_byte_data(fileh, $01, $00); // GPIOB = Output

  // gets input values from GPIOA
  rval := i2c_smbus_read_byte_data(fileh, $12);
  writeln('Input Values A: ', rval);

  // blink GPIOB
  for i := 0 to 5 do
  begin
    i2c_smbus_write_byte_data(fileh, $13, $FF); // on
    FpSleep(1);
    i2c_smbus_write_byte_data(fileh, $13, $00); // off
    fpsleep(1);
  end;

  // close file handle!
  fpclose(fileh);
end.

