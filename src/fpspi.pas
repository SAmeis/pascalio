{ Free Pascal SPI Access

  Copyright (C) 2013 Simon Ameis <simon.ameis@web.de>

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


unit fpspi;

{$mode objfpc}{$H+}
{.$DEFINE InheritFromTStream}
interface

uses
  Classes, SysUtils, {$IFDEF LINUX}spidev, baseunix, {$ENDIF}RtlConsts;

resourcestring
  rsSPIIoCtlErr = 'System call IoCtl failed. Request code %d.';

type
  {$PACKSET 1}
  TSPIMode = set of (SPI_CPHA, SPI_CPOL);

const
  SPI_MODE_0 = TSPIMode([]);
  SPI_MODE_1 = [SPI_CPHA];
  SPI_MODE_2 = [SPI_CPOL];
  SPI_MODE_3 = [SPI_CPOL, SPI_CPHA];

type

  { TSPIDevice }
  {$IFDEF InheritFromTStream}
  TSPIDevice = class(TStream)
  {$ELSE}
  TSPIDevice = class(TObject)
  {$ENDIF}
  protected
    function GetBitsPerWord: Byte; virtual; abstract;
    procedure SetBitsPerWord(AValue: Byte); virtual; abstract;
    function GetLSBFirst: Boolean; virtual; abstract;
    function GetMaxFrequency: Longword; virtual; abstract;
    function GetMode: TSPIMode; virtual; abstract;
    procedure SetLSBFirst(AValue: Boolean); virtual; abstract;
    procedure SetMaxFrequency(AValue: Longword); virtual; abstract;
    procedure SetMode(AValue: TSPIMode); virtual; abstract;
  public
    // define abstract methods Read() and Write() if they are not inherited
    // by TStream.
    {$IFNDEF InheritFromTStream}
    function Read(var Buffer; Count: Longint): Longint; virtual;
    function Write(const Buffer; Count: Longint): Longint; virtual;
    {$ENDIF}
    procedure ReadAndWrite(const aWriteBuffer; aWriteCount: Longint;
      Var aReadBuffer; aReadCount: Longint); virtual; abstract;
    property Mode: TSPIMode read GetMode write SetMode default SPI_MODE_0;
    property LSBFirst: Boolean read GetLSBFirst write SetLSBFirst default False;
    property MaxFrequency: Longword read GetMaxFrequency write SetMaxFrequency default 0;
    property BitsPerWord: Byte read GetBitsPerWord write SetBitsPerWord default 8;
  end;

{$IFDEF LINUX}
  TSPI_IOC_Transfer_Array = array of spi_ioc_transfer;

  { TSPILinuxDevice }

  TSPILinuxDevice = class(TSPIDevice)
  private
    fBus: Longword;
    fCS: Longword;
    fHandle: cint;
  protected
    function GetBitsPerWord: Byte; override;
    function GetLSBFirst: Boolean; override;
    function GetMaxFrequency: Longword; override;
    function GetMode: TSPIMode; override;
    procedure SetBitsPerWord(AValue: Byte); override;
    procedure SetLSBFirst(AValue: Boolean); override;
    procedure SetMaxFrequency(AValue: Longword); override;
    procedure SetMode(AValue: TSPIMode); override;

    function GetDevicePath: String;
    procedure DoIoCtlError(Ndx: TIOCtlRequest); inline;
  public
    constructor Create(aBus: Longword; aChipSelect: Longword);
    destructor Destroy; override;

    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    procedure ReadAndWrite(const aWriteBuffer; aWriteCount: Longint;
      Var aReadBuffer; aReadCount: Longint); override;
    procedure ReadAndWrite(in_out_data: TSPI_IOC_Transfer_Array);

    property Bus: Longword read fBus;
    property ChipSelect: Longword read fCS;
  end;
{$ENDIF}

(* Please implement a software spi device
  TSPISoftDevice = class(TSPIDevice)
  end;
  *)
implementation

{ TSPIDevice }

function TSPIDevice.Read(var Buffer; Count: Longint): Longint;
var
  // minimal dummy read buffer
  ReadBuffer: Byte;
begin
  ReadAndWrite(Buffer, Count, ReadBuffer, SizeOf(ReadBuffer));
end;

function TSPIDevice.Write(const Buffer; Count: Longint): Longint;
var
  // minimal dummy write buffer
  WriteBuffer: Byte;
begin
  ReadAndWrite(WriteBuffer, SizeOf(WriteBuffer), Buffer, Count);
end;

{$IFDEF LINUX}
{ TSPILinuxDevice }

function TSPILinuxDevice.GetBitsPerWord: Byte;
var
  b: Byte;
begin
  if FpIOCtl(fHandle, SPI_IOC_RD_BITS_PER_WORD, @b) = -1 then
    DoIoCtlError(SPI_IOC_RD_BITS_PER_WORD);

  if b = 0 then
    Result := 8
  else
    Result := b;
end;

function TSPILinuxDevice.GetLSBFirst: Boolean;
begin
  if FpIOCtl(fHandle, SPI_IOC_RD_LSB_FIRST, @Result) = -1 then
    DoIoCtlError(SPI_IOC_RD_LSB_FIRST);
end;

function TSPILinuxDevice.GetMaxFrequency: Longword;
begin
  if FpIOCtl(fHandle, SPI_IOC_RD_MAX_SPEED_HZ, @Result) = -1 then
    DoIoCtlError(SPI_IOC_RD_MAX_SPEED_HZ);
end;

function TSPILinuxDevice.GetMode: TSPIMode;
begin
  if FpIOCtl(fHandle, SPI_IOC_RD_MODE, @Result) = -1 then
    DoIoCtlError(SPI_IOC_RD_MODE);
end;

procedure TSPILinuxDevice.SetBitsPerWord(AValue: Byte);
begin
  if FpIOCtl(fHandle, SPI_IOC_WR_BITS_PER_WORD, @AValue) = -1 then
    DoIoCtlError(SPI_IOC_WR_BITS_PER_WORD);
end;

procedure TSPILinuxDevice.SetLSBFirst(AValue: Boolean);
var
  b: Shortint;
begin
  if AValue then
    b := -1
  else
    b := 0;
  if FpIOCtl(fHandle, SPI_IOC_WR_LSB_FIRST, @b) = -1 then
    DoIoCtlError(SPI_IOC_WR_LSB_FIRST);
end;

procedure TSPILinuxDevice.SetMaxFrequency(AValue: Longword);
begin
  if FpIOCtl(fHandle, SPI_IOC_WR_MAX_SPEED_HZ, @AValue) = -1 then
    DoIoCtlError(SPI_IOC_WR_MAX_SPEED_HZ);
end;

procedure TSPILinuxDevice.SetMode(AValue: TSPIMode);
begin
  if FpIOCtl(fHandle, SPI_IOC_RD_MODE, @AValue) = -1 then
    DoIoCtlError(SPI_IOC_RD_MODE);
end;

function TSPILinuxDevice.GetDevicePath: String;
const
  DEV_PATH = '/dev/spidev';
var
  s: String;
begin
  str(fBus, s);
  Result := DEV_PATH + s + '.';
  str(fCS, s);
  Result += s;
end;

procedure TSPILinuxDevice.DoIoCtlError(Ndx: TIOCtlRequest); inline;
var
  e: EOSError;
begin
  e := EOSError.CreateFmt(rsSPIIoCtlErr, [Ndx]);
  e.ErrorCode := baseunix.errno;
  raise e;
end;

constructor TSPILinuxDevice.Create(aBus: Longword; aChipSelect: Longword);
var
  f: String;
begin
  fBus := aBus;
  fCS := aChipSelect;

  f := GetDevicePath;

  fHandle := FpOpen(f, O_RDWR);
  if fHandle = -1 then
    raise EFOpenError.CreateFmt(SFOpenError, [f]);
end;

destructor TSPILinuxDevice.Destroy;
begin
  FpClose(fHandle);
  inherited Destroy;
end;

function TSPILinuxDevice.Read(var Buffer; Count: Longint): Longint;
begin
  Result := FpRead(fHandle, Buffer, Count);
end;

function TSPILinuxDevice.Write(const Buffer; Count: Longint): Longint;
begin
  Result := FpWrite(fHandle, Buffer, Count);
end;

procedure TSPILinuxDevice.ReadAndWrite(const aWriteBuffer;
  aWriteCount: Longint; var aReadBuffer; aReadCount: Longint);
var
  intRB: array of Byte;
  intWB: array of Byte;
  ml: Longint;
  xfer: TSPI_IOC_Transfer_Array;
begin
  if aWriteCount < aReadCount then
    ml := aReadCount
  else
    ml := aWriteCount;

  if ml <= 0 then exit;

  SetLength(intRB, ml);
  SetLength(intWB, ml);
  FillByte(intRB[0], ml, 0);
  FillByte(intWB[0], ml, 0);
  move(aWriteBuffer, intWB[0], aWriteCount);

  SetLength(xfer, 1);
  FillByte(xfer[0], SizeOf(xfer), 0);

  with xfer[0] do
  begin
    tx_buf := @intWB[0];
    rx_buf := @intRB[0];
    len := ml;
    delay_usecs := 0;
    bits_per_word := 8;
  end;

  ReadAndWrite(xfer);
  move(intRB[0], aReadBuffer, aReadCount);
end;

procedure TSPILinuxDevice.ReadAndWrite(in_out_data: TSPI_IOC_Transfer_Array);
var
  status: Longint;
begin
  if Length(in_out_data) = 0 then
    exit;
  status := FpIOCtl(fHandle, SPI_IOC_MESSAGE(Length(in_out_data)), @in_out_data[0]);
  if status < 0 then
    DoIoCtlError(SPI_IOC_MESSAGE(Length(in_out_data)));
end;
{$ENDIF}

end.

