(* SPI Linux demo program
 *
 * This simple program demonstrates how to use the class TSPILinuxDevice to
 * access a SPI bus on a Linux published in the file system by the spidev
 * driver.
 *
 * This program assumes a imaginary SPI device on bus 0 and chipselect 1,
 * which writes back $0F00 regardless of the input value.
 *)
program Project1;
{$mode objfpc}
uses
  fpspi;

var
  spi: TSPILinuxDevice;
  rbuf, wbuf: Word;
begin
  // SPI Bus 0
  // 2nd ChipSelect
  // The numbers are directly mapped to the file name /dev/spidevB.C
  // with B = Bus and C = Chipselect
  // see https://www.kernel.org/doc/Documentation/spi/spidev
  spi := TSPILinuxDevice.Create(0, 1);
  // set a SPI mode
  spi.Mode := SPI_MODE_0;
  try
    // data sent to device
    wbuf := $1010;
    // The read and write buffers don't need to be of the same size
    // the larger one will determine the total bytes sent
    // If length(wbuf) < length(rbuf), the remaining bytes will be sent as 0
    spi.ReadAndWrite(wbuf, sizeof(wbuf), rbuf, sizeof(rbuf));
    // handle result
    if rbuf = $0F00 then
      WriteLn('Hello World');
  finally
    spi.Destroy;
  end;
end.

