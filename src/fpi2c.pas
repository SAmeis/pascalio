{ I2C/SMBus access for Free Pascal

  Copyright (C) 2013 Simon Ameis <simon.ameis@web.de>

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

unit fpi2c;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, i2c_dev, baseunix, rtlconsts;

resourcestring
  sI2CSlaveAddress = 'Could not set slave address.';
  sI2CWrite = 'Could not write to I2C bus.';

type
  TI2CAddress = $02..$FE;
  TI2CRegister = Byte;
  { TI2CDevice }

  TI2CDevice = class(TObject)
  private
    fAddress: TI2CAddress;
  public
    constructor Create(aAddress: TI2CAddress); virtual;
    function ReadByte: Byte; virtual; abstract;
    procedure WriteByte(aByte: Byte); virtual; abstract;
    function ReadRegByte(aRegister: TI2CRegister): Byte; virtual; abstract;
    function ReadRegWord(aRegsiter: TI2CRegister): Word; virtual; abstract;
    procedure WriteRegByte(aRegister: TI2CRegister; aByte: Byte); virtual; abstract;
    procedure WriteRegWord(aRegister: TI2CRegister; aWord: Word); virtual; abstract;
    procedure ReadBlockData(aRegister: TI2CRegister; var aBuffer; aCount: SizeInt); virtual; abstract;

    procedure WriteData(aRegister: TI2CRegister; const Buffer; aCount: SizeInt); virtual; abstract;
    procedure WriteByte(aRegister: TI2CRegister; aByte: Byte); inline;
    procedure WriteWord(aRegister: TI2CAddress; aWord: Word);  inline;
      procedure WriteLongWord(aRegsiter: TI2CAddress; aLongWord: Longword); inline;
    procedure WriteQWord(aRegister: TI2CAddress; const aQWord: QWord); inline;
    property Address: TI2CAddress read fAddress;
  end;

  { TI2CLinuxDevice }

  TI2CLinuxDevice = class(TI2CDevice)
  protected
    fHandle: cint;
    procedure SetSlaveAddress; inline;
  public
    constructor Create(aAddress: TI2CAddress; aBusID: Longword);
    function ReadBlockData(aRegister: TI2CRegister; var aBuffer;
      aCount: SizeInt): SizeInt;
    function ReadByte: Byte; override;
    function ReadRegByte(aRegister: TI2CRegister): Byte; override;
    function ReadRegWord(aRegsiter: TI2CRegister): Word; override;
    procedure WriteByte(aByte: Byte); override;
    procedure WriteData(aRegister: TI2CRegister; const Buffer; aCount: SizeInt
      ); override;
    procedure WriteRegByte(aRegister: TI2CRegister; aByte: Byte); override;
    procedure WriteRegWord(aRegister: TI2CRegister; aWord: Word); override;

    property Handle: cint read fHandle;
  end;

implementation

{ TI2CLinuxDevice }

procedure TI2CLinuxDevice.SetSlaveAddress;
begin
  if FpIOCtl(Handle, I2C_SLAVE, Pointer(Address)) < 0 then
    RaiseLastOSError;
end;

constructor TI2CLinuxDevice.Create(aAddress: TI2CAddress; aBusID: Longword);
const
  I2C_DEV_FNAME = '/dev/i2c-%d';
var
  f: String;
begin
  inherited Create(aAddress);
  f := Format(I2C_DEV_FNAME, [aBusID]);
  fHandle := FpOpen(f, O_RDWR);
  if fHandle < 0 then
    raise EFOpenError.CreateFmt(SFOpenError, [f]);
end;

function TI2CLinuxDevice.ReadBlockData(aRegister: TI2CRegister; var aBuffer;
  aCount: SizeInt): SizeInt;
var
  b: TI2C_SMBUS_VALUES;
  cc: SizeInt;
begin
  if aCount >= 32 then
  begin
    // enough memory for a direct call
    Result := i2c_smbus_read_block_data(Handle, aRegister, @aBuffer)
  end
  else
  begin
    // reading up to 32 bytes and return the first aCount bytes
    Result := 0; // 0 bytes read
    Result := i2c_smbus_read_block_data(Handle, aRegister, @b[0]);
    if Result = -1 then exit;
    if aCount < Result then
      cc := aCount
    else
      cc := Result;
    move(b[0], aBuffer, cc);
  end;
end;

function TI2CLinuxDevice.ReadByte: Byte;
var
  r: LongInt;
begin
  r := i2c_smbus_read_byte(Handle);
  if r > 0 then
    exit(r)
  else
    RaiseLastOSError;
end;

function TI2CLinuxDevice.ReadRegByte(aRegister: TI2CRegister): Byte;
var
  r: LongInt;
begin
  r := i2c_smbus_read_byte_data(Handle, aRegister);
  if r > 0 then
    exit(r)
  else
    RaiseLastOSError;
end;

function TI2CLinuxDevice.ReadRegWord(aRegsiter: TI2CRegister): Word;
var
  r: LongInt;
begin
  r := i2c_smbus_read_word_data(Handle, aRegsiter);
  if r > 0 then
    exit(r)
  else
    RaiseLastOSError;
end;

procedure TI2CLinuxDevice.WriteByte(aByte: Byte);
var
  r: LongInt;
begin
  r := i2c_smbus_write_byte(Handle, aByte);
  if r < 0 then
    RaiseLastOSError;
end;

procedure TI2CLinuxDevice.WriteData(aRegister: TI2CRegister; const Buffer;
  aCount: SizeInt);
var
//  ibuf: Array of byte;
  r: LongInt;
begin
  r := i2c_smbus_write_block_data(Handle, aRegister, aCount, @Buffer);
  if r < 0 then
    RaiseLastOSError;
  //setlength(ibuf, sizeof(aRegister) + aCount);
  //move(aRegister, ibuf[0], sizeof(aRegister));
  //move(Buffer, ibuf[sizeof(aRegister)], aCount);
  //if FpWrite(Handle, ibuff[0], length(ibuf)) <> lenght(ibuf) then
  //  raise EWriteError.Create(sI2CWrite);
end;

procedure TI2CLinuxDevice.WriteRegByte(aRegister: TI2CRegister; aByte: Byte);
var
  r: LongInt;
begin
  r := i2c_smbus_write_byte_data(Handle, aRegister, aByte);
  if r < 0 then
    RaiseLastOSError;
end;

procedure TI2CLinuxDevice.WriteRegWord(aRegister: TI2CRegister; aWord: Word);
var
  r: LongInt;
begin
  r := i2c_smbus_write_word_data(Handle, aRegister, aWord);
  if r < 0 then
    RaiseLastOSError;
end;


{ TI2CDevice }

constructor TI2CDevice.Create(aAddress: TI2CAddress);
begin
  fAddress := aAddress;
end;

procedure TI2CDevice.WriteByte(aRegister: TI2CRegister; aByte: Byte);
begin
  WriteData(aRegister, aByte, sizeof(aByte));
end;

procedure TI2CDevice.WriteWord(aRegister: TI2CAddress; aWord: Word);
var
  b: Word;
begin
  b := NtoBE(aWord);
  WriteData(aRegister, b, SizeOf(b));
end;

procedure TI2CDevice.WriteLongWord(aRegsiter: TI2CAddress; aLongWord: Longword);
var
  lw: DWord;
begin
  lw := NToBE(aLongWord);
  WriteData(aRegsiter, lw, Sizeof(lw));
end;

procedure TI2CDevice.WriteQWord(aRegister: TI2CAddress; const aQWord: QWord);
var
  qw: QWord;
begin
  qw := NToBE(aQWord);
  WriteData(aRegister, qw, sizeof(qw));
end;

end.
