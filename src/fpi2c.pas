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
  Classes, SysUtils, i2c_dev, baseunix, rtlconsts, flqueue;

resourcestring
  sI2CSlaveAddress = 'Could not set slave address.';
  sI2CWrite = 'Could not write to I2C bus.';
  rsBufferNotSet = 'Buffer not set';
  rsBufferToLarge = 'Buffer to large. Must be 1 byte.';
  rsReadWriteBitSet = 'Read/Write bit is set in address.';

type
  TI2CAddress = $02..$FE;
  TI2CRegister = Byte;

  EI2CQueueObjectInconsistency = class(Exception);

  { TI2CQueueObject }

  TI2CQueueObject = class(TObject)
  public type
    // i2c/smbus data buffer
    TBufferLength = 0..31;

  strict private
    fFatalException: TObject;
    fReadyEvent: PRTLEvent;
    fWriteEvent: PRTLEvent;
    fAddress: TI2CAddress;
    fCommand: Byte;
    fUseCommand: Boolean;
    fRead: Boolean;
    fBufLen: Byte;
    fBuffer: array [TBufferLength] of Byte;

    procedure SetCommand(aValue: Byte);
  public
    constructor Create;
    destructor Destroy; override;
    // raise EI2CQueueObjectInconsistency on error
    procedure CheckConsistency;

    // waits until data is written
    // rises FatalException if assigned
    procedure WaitForWrite;
    // sets event state
    procedure SetDataWritten;


    // buffer manipulation
    // requested amount of bytes to read
    procedure SetReadBufferLength(aLen: TBufferLength);
    // data to be written
    procedure SetWriteBuffer(const aBuf; aLen: TBufferLength);
    // actual data read
    procedure SetResultBuffer(const aBuf; aLen: TBufferLength);
    // reading result buffer
    // waits until data is available
    // rises FatalException if assigned
    procedure GetResultBuffer(var aBuf; aLen: TBufferLength);
    // get the buffer for writing
    procedure GetWriteBuffer(var aBuf; aMaxLen: TBufferLength; out aLen: TBufferLength);
    // this is RO, change buffer length via SetWriteBuffer() or SetReadBufferLength()
    property BufferLength: Byte read fBufLen;

    // device address
    property Address: TI2CAddress read fAddress write fAddress;
    // read/write bit
    property Read: Boolean read fRead;

    // Device register/command
    property Command: Byte read fCommand write SetCommand;
    // Set to TRUE, if Command is changed
    property UseCommand: Boolean read fUseCommand write fUseCommand;

    // holds an object, if something went terribly wrong
    property FatalException: TObject read fFatalException write fFatalException;
  end;

  { TI2CBus
    Threadsafe i2c bus access
  }

  TI2CBus = class(TThread)
  strict private
    fBus: Longword;
  protected
    fQueue: tFLQueue;
    fThreadWakeup: PRTLEvent;

    // Don't override Execute(), it's already done
    procedure Execute; override;
    // just override ProvessObject()
    procedure ProcessObject(aObj: TI2CQueueObject); virtual; abstract;

    property Queue: tFLQueue read fQueue;
  public
    constructor Create(aBus: Longword); virtual;
    destructor Destroy; override;

    // use this for non blocking queueing, returns immediatly
    procedure QueueObject(aObj: TI2CQueueObject);

    // blocking queuing, threadsafe
    // returns on action done
    function ReadByte(aAddress: TI2CAddress): Byte;
    procedure WriteByte(aAddress: TI2CAddress; aByte: Byte);
    function ReadRegByte(aAddress: TI2CAddress; aRegister: TI2CRegister): Byte;
    function ReadRegWord(aAddress: TI2CAddress; aRegsiter: TI2CRegister): Word;
    procedure WriteRegByte(aAddress: TI2CAddress; aRegister: TI2CRegister; aByte: Byte);
    procedure WriteRegWord(aAddress: TI2CAddress; aRegister: TI2CRegister; aWord: Word);
    procedure ReadBlockData(aAddress: TI2CAddress; aRegister: TI2CRegister; var aBuffer; aCount: SizeInt);
    procedure WriteBlockData(aAddress: TI2CAddress; aRegister: TI2CRegister; const Buffer; aCount: SizeInt);

    (* not supported so far
    procedure WriteByte(aAddress: TI2CAddress; aRegister: TI2CRegister; aByte: Byte);
    procedure WriteWord(aAddress: TI2CAddress; aRegister: TI2CAddress; aWord: Word);
    procedure WriteLongWord(aAddress: TI2CAddress; aRegsiter: TI2CAddress; aLongWord: Longword);
    procedure WriteQWord(aAddress: TI2CAddress; aRegister: TI2CAddress; const aQWord: QWord);
    *)
    property Bus: Longword read fBus;
  end;

  { TI2CDevice
    Non-Threadsafe i2c bus access
  }

  TI2CDevice = class(TObject)
  strict private
    fAddress: TI2CAddress;
  protected
    procedure SetAddress(aValue: TI2CAddress); inline; virtual;
  public
    // doesnot call SetAddress(), because class may not be full instantiated
    constructor Create(aAddress: TI2CAddress); virtual;
    function ReadByte: Byte; virtual; abstract;
    procedure WriteByte(aByte: Byte); virtual; abstract;
    function ReadRegByte(aRegister: TI2CRegister): Byte; virtual; abstract;
    function ReadRegWord(aRegsiter: TI2CRegister): Word; virtual; abstract;
    procedure WriteRegByte(aRegister: TI2CRegister; aByte: Byte); virtual; abstract;
    procedure WriteRegWord(aRegister: TI2CRegister; aWord: Word); virtual; abstract;
    procedure ReadBlockData(aRegister: TI2CRegister; var aBuffer; aCount: SizeInt); virtual; abstract;
    procedure WriteBlockData(aRegister: TI2CRegister; const Buffer; aCount: SizeInt); virtual; abstract;

    // convenicence methods
    // do we need the first two?
    procedure WriteByte(aRegister: TI2CRegister; aByte: Byte); inline;
    procedure WriteWord(aRegister: TI2CRegister; aWord: Word);  inline;
    procedure WriteLongWord(aRegsiter: TI2CRegister; aLongWord: Longword); inline;
    procedure WriteQWord(aRegister: TI2CRegister; const aQWord: QWord); inline;

    property Address: TI2CAddress read fAddress write SetAddress;
  end;

  { TI2CThreadSaveDevice
    Thread save proxy using TI2CBus; don't implemnt a bus which uses this
    proxy class!
  }

  TI2CThreadSaveDevice = class(TI2CDevice)
  strict private
    fBus: TI2CBus;
  public
    constructor Create(aAddress: TI2CAddress; aBus: TI2CBus);
    procedure ReadBlockData(aRegister: TI2CRegister; var aBuffer;
      aCount: SizeInt); override;
    function ReadByte: Byte; override;
    function ReadRegByte(aRegister: TI2CRegister): Byte; override;
    function ReadRegWord(aRegsiter: TI2CRegister): Word; override;
    procedure WriteBlockData(aRegister: TI2CRegister; const Buffer;
      aCount: SizeInt); override;
    procedure WriteByte(aByte: Byte); override;
    procedure WriteRegByte(aRegister: TI2CRegister; aByte: Byte); override;
    procedure WriteRegWord(aRegister: TI2CRegister; aWord: Word); override;

    property Bus: TI2CBus read fBus;
  end;

  { TI2CLinuxDevice
    Only this class uses the Linux' Kernel interface
    Thus by moving this class (and all depending classes)
    to another unit, the units licence should be changed
    to LGPL with linking exception
  }

  TI2CLinuxDevice = class(TI2CDevice)
  protected
    fHandle: cint;
    procedure SetAddress(aValue: TI2CAddress); inline; override;
  public
    constructor Create(aAddress: TI2CAddress; aBusID: Longword);
    function ReadBlockData(aRegister: TI2CRegister; var aBuffer;
      aCount: SizeInt): SizeInt;
    function ReadByte: Byte; override;
    function ReadRegByte(aRegister: TI2CRegister): Byte; override;
    function ReadRegWord(aRegsiter: TI2CRegister): Word; override;
    procedure WriteByte(aByte: Byte); override;
    procedure WriteBlockData(aRegister: TI2CRegister; const Buffer; aCount: SizeInt
      ); override;
    procedure WriteRegByte(aRegister: TI2CRegister; aByte: Byte); override;
    procedure WriteRegWord(aRegister: TI2CRegister; aWord: Word); override;

    property Handle: cint read fHandle;
  end;

  { TI2CLinuxBus }

  TI2CLinuxBus = class(TI2CBus)
  private
    fDevice: TI2CLinuxDevice;
  protected
    constructor Create(aBus: Longword); override;
    procedure ProcessObject(aObj: TI2CQueueObject); override;
  public
    property Device: TI2CLinuxDevice read fDevice;
  end;

implementation

{ TI2CThreadSaveDevice }

constructor TI2CThreadSaveDevice.Create(aAddress: TI2CAddress; aBus: TI2CBus);
begin
  inherited Create(aAddress);
  fBus := aBus;
end;

procedure TI2CThreadSaveDevice.ReadBlockData(aRegister: TI2CRegister;
  var aBuffer; aCount: SizeInt);
begin
  fBus.ReadBlockData(Address, aRegister, aBuffer, aCount);
end;

function TI2CThreadSaveDevice.ReadByte: Byte;
begin
  Result := fBus.ReadByte(Address);
end;

function TI2CThreadSaveDevice.ReadRegByte(aRegister: TI2CRegister): Byte;
begin
  Result := fBus.ReadRegByte(Address, aRegister);
end;

function TI2CThreadSaveDevice.ReadRegWord(aRegsiter: TI2CRegister): Word;
begin
  Result := fBus.ReadRegWord(Address, aRegister);
end;

procedure TI2CThreadSaveDevice.WriteBlockData(aRegister: TI2CRegister;
  const Buffer; aCount: SizeInt);
begin
  fBus.WriteBlockData(Address, aRegister, Buffer, aCount);
end;

procedure TI2CThreadSaveDevice.WriteByte(aByte: Byte);
begin
  fBus.WriteByte(Address, aByte);
end;

procedure TI2CThreadSaveDevice.WriteRegByte(aRegister: TI2CRegister; aByte: Byte
  );
begin
  fBus.WriteRegByte(Address, aRegister, aByte);
end;

procedure TI2CThreadSaveDevice.WriteRegWord(aRegister: TI2CRegister; aWord: Word
  );
begin
  fBus.WriteRegWord(Address, aRegister, aWord);
end;

{ TI2CLinuxBus }

constructor TI2CLinuxBus.Create(aBus: Longword);
begin
  inherited Create(aBus);
  fDevice := TI2CLinuxDevice.Create($00, aBus);
end;

procedure TI2CLinuxBus.ProcessObject(aObj: TI2CQueueObject);
var
  bbuf: Byte;
  wbuf: Word;
  b: array[aobj.TBufferLength] of Byte;
  i: SizeInt;
begin
  if not Assigned(fDevice) then exit;
  try
    aObj.CheckConsistency;

    fDevice.Address := aObj.Address;
    if aObj.UseCommand then
    begin
      if aObj.Read then
        case aObj.BufferLength of
          1: aObj.ByteValue := fDevice.ReadRegByte(aObj.Command)
          2: aObj.WordValue := fDevice.ReadRegWord(aObj.Command);
        else
          i := fDevice.ReadBlockData(aObj.Command, b[0], aObj.BufferLength);
          if i = -1 then
            aObj.SetResultBuffer(b[0], 0)
          else
            aObj.SetResultBuffer(b[0], i);
        end
      else // aObj.Read = FALSE
        case aObj.BufferLength of
          1:
          begin
            aObj.GetWriteBuffer(bbuf, 1, i);
            fDevice.WriteRegByte(aObj.Command, bbuf);
          end;
          2:
          begin
            aObj.GetWriteBuffer(wbuf, 2, i);
            fDevice.WriteRegWord(aObj.Command, wbuf);
          end;
        else
          aObj.GetWriteBuffer(b[0], Length(b), i);
          fDevice.WriteBlockData(aObj.Command, b[0], i);
        end;
        aObj.SetDataWritten;
    end else // aObj.UseCommand = FALSE
    begin
      // ONLY VALID if BufferLength = 1
      if aObj.BufferLength = 1 then
      begin
        if aObj.Read then
        begin
          bbuf := fDevice.ReadByte;
          aobj.SetResultBuffer(bbuf, 1);
        end
        else
        begin
          aObj.GetWriteBuffer(bbuf, 1, i);
          fDevice.WriteByte(bbuf);
          aObj.SetDataWritten;
        end;
      end;
    end; // END aObj.UseCommand

  except
    // this may be
    // - EI2CQueueObjectInconsistency
    // - EOSError
    on e: Exception do
    begin
      aObj.FatalException := e;
      // set events for waiting thread
      aObj.SetDataWritten;
      aobj.SetBuffer(b[0], 0);
    end;
  end;
end;

{ TI2CBus }

destructor TI2CBus.Destroy;
begin
  Terminate;
  RTLeventSetEvent(fThreadWakeup);
  WaitFor;
  FreeAndNil(fQueue);
  RTLeventdestroy(fThreadWakeup);
  inherited Destroy;
end;

procedure TI2CBus.QueueObject(aObj: TI2CQueueObject);
begin
  aObj.CheckConsistency;
  // add to queue and wake up thread
  fQueue.push(aObj);
  RTLeventSetEvent(fThreadWakeup);
end;

procedure TI2CBus.Execute;
var
  co: TI2CQueueObject;
begin
  repeat
    co := fQueue.pop;
    if co <> nil then
    begin
      // do the work
      ProcessObject(co);
      // reset event
      RTLeventResetEvent(fThreadWakeup);
    end
    else
      RTLeventWaitFor(fThreadWakeup);
  until Terminated;
end;

constructor TI2CBus.Create(aBus: Longword);
begin
  inherited Create(True);
  fQueue := tFLQueue.create(10);
  fThreadWakeup := RTLEventCreate;
  fBus := aBus;
end;

function TI2CBus.ReadByte(aAddress: TI2CAddress): Byte;
var
  o: TI2CQueueObject;
begin
  o := TI2CQueueObject.Create;
  o.Address := aAddress;
  o.UseCommand := False;
  o.SetReadBufferLength(sizeof(Result));
  QueueObject(o);

  try
    o.GetResultBuffer(Result, SizeOf(Result));
  finally
    FreeAndNil(o);
  end;
end;

procedure TI2CBus.WriteByte(aAddress: TI2CAddress; aByte: Byte);
var
  o: TI2CQueueObject;
begin
  o := TI2CQueueObject.Create;
  o.Address := aAddress;
  o.UseCommand := False;
  o.SetWriteBuffer(aByte, SizeOf(aByte));
  QueueObject(o);

  try
    o.WaitForWrite;
  finally
    FreeAndNil(o);
  end;
end;

function TI2CBus.ReadRegByte(aAddress: TI2CAddress; aRegister: TI2CRegister
  ): Byte;
var
  o: TI2CQueueObject;
begin
  o := TI2CQueueObject.Create;
  o.Address := aAddress;
  o.Command := aRegister;
  o.SetReadBufferLength(sizeof(Result));
  QueueObject(o);

  try
    o.GetResultBuffer(Result, SizeOf(Result));
  finally
    FreeAndNil(o);
  end;
end;

function TI2CBus.ReadRegWord(aAddress: TI2CAddress; aRegsiter: TI2CRegister
  ): Word;
var
  o: TI2CQueueObject;
begin
  o := TI2CQueueObject.Create;
  o.Address := aAddress;
  o.Command := aRegister;
  o.SetWriteBuffer(Result, SizeOf(Result));
  QueueObject(o);

  try
    o.GetResultBuffer(Result, SizeOf(Result));
  finally
    FreeAndNil(o);
  end;
end;

procedure TI2CBus.WriteRegByte(aAddress: TI2CAddress; aRegister: TI2CRegister;
  aByte: Byte);
var
  o: TI2CQueueObject;
begin
  o := TI2CQueueObject.Create;
  o.Address := aAddress;
  o.Command := aRegister;
  o.SetWriteBuffer(aByte, sizeof(aByte));
  QueueObject(o);

  try
    o.WaitForWrite;
  finally
    FreeAndNil(o);
  end;
end;

procedure TI2CBus.WriteRegWord(aAddress: TI2CAddress; aRegister: TI2CRegister;
  aWord: Word);
var
  o: TI2CQueueObject;
begin
  o := TI2CQueueObject.Create;
  o.Address := aAddress;
  o.Command := aRegister;
  o.SetWriteBuffer(aWord, sizeof(aWord));
  QueueObject(o);

  try
    o.WaitForWrite;
  finally
    FreeAndNil(o);
  end;
end;

procedure TI2CBus.ReadBlockData(aAddress: TI2CAddress; aRegister: TI2CRegister;
  var aBuffer; aCount: SizeInt);
var
  o: TI2CQueueObject;
begin
  o := TI2CQueueObject.Create;
  o.Address := aAddress;
  o.Command := aRegister;
  o.SetReadBufferLength(aCount);
  QueueObject(o);

  try
    o.GetResultBuffer(aBuffer, aCount);
  finally
    FreeAndNil(o);
  end;
end;

procedure TI2CBus.WriteBlockData(aAddress: TI2CAddress;
  aRegister: TI2CRegister; const Buffer; aCount: SizeInt);
var
  o: TI2CQueueObject;
begin
  o := TI2CQueueObject.Create;
  o.Address := aAddress;
  o.Command := aRegister;
  o.SetWriteBuffer(Buffer, aCount);
  QueueObject(o);

  try
    o.WaitForWrite;
  finally
    FreeAndNil(o);
  end;
end;

{ TI2CQueueObject }

procedure TI2CQueueObject.SetCommand(aValue: Byte);
begin
  fCommand := aValue;
  fUseCommand := True;
end;


constructor TI2CQueueObject.Create;
begin
  fReadyEvent := RTLEventCreate;
  fWriteEvent := RTLEventCreate;
end;

destructor TI2CQueueObject.Destroy;
begin
  RTLeventdestroy(fReadyEvent);
  RTLeventdestroy(fWriteEvent);
  fReadyEvent := nil;
  fWriteEvent := nil;
  inherited Destroy;
end;

procedure TI2CQueueObject.CheckConsistency;
begin
  // checks all requirements for a valid i2c operation

  // Buffer has to be set.
  if (BufferLength <= low(TBufferLength))
  or (BufferLength > high(TBufferLength) then
    raise EI2CQueueObjectInconsistency.Create(rsBufferNotSet);

  // can only read/write Bytes without command
  if (not UseCommand) and (BufferLength <> 1) then
    raise EI2CQueueObjectInconsistency.Create(rsBufferToLarge);

  // Read/Write bit set in address (may be corrected)
  if (Address and $01) = $01 then
    raise EI2CQueueObjectInconsistency.Create(rsReadWriteBitSet);
end;

procedure TI2CQueueObject.WaitForWrite;
begin
  RTLeventWaitFor(fWriteEvent);
  if Assigned(FatalException) then
    raise FatalException;
end;

procedure TI2CQueueObject.SetDataWritten;
begin
  RTLeventSetEvent(fWriteEvent);
end;

procedure TI2CQueueObject.SetReadBufferLength(aLen: TBufferLength);
begin
  fBufLen := aLen;
  fRead := True;
end;

procedure TI2CQueueObject.SetWriteBuffer(const aBuf; aLen: TBufferLength);
begin
  if aLen < length(fBuffer) then
    fBufLen := aLen
  else
    fBufLen := Length(fBuffer);

  move(aBuf, fBuffer[0], ByteCount);
  fRead := False;
end;

procedure TI2CQueueObject.SetResultBuffer(const aBuf; aLen: TBufferLength);
begin
  if aLen < length(fBuffer) then
    fBufLen := aLen
  else
    fBufLen := Length(fBuffer);

  move(aBuf, fBuffer[0], ByteCount);
  RTLeventSetEvent(fReadyEvent);
end;

procedure TI2CQueueObject.GetResultBuffer(var aBuf; aLen: TBufferLength);
begin
  // result buffer only set for reading requests
  if not Read then exit;

  RTLeventWaitFor(fReadyEvent);
  if Assigned(FatalException) then
    raise FatalException;

  if alen <= fBufLen then
    move(fBuffer[0], aBuf, aLen)
  else
    move(fBuffer[0], aBuf, fBufLen);
end;

procedure TI2CQueueObject.GetWriteBuffer(var aBuf; aMaxLen: TBufferLength; out
  aLen: TBufferLength);
begin
  if not Read then
  begin
    if aMaxLen <= fBufLen then
      aLen := aMaxLen
    else
      aLen := fBufLen;
    move(fBuffer[0], aBuf, aLen);
  end
  else
    aLen := 0;
end;

{ TI2CLinuxDevice }

procedure TI2CLinuxDevice.SetAddress(aValue: TI2CAddress);
begin
  inherited SetAddress(aValue);
  if FpIOCtl(Handle, I2C_SLAVE, Pointer(aValue)) < 0 then
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
  Address := aAddress;
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

procedure TI2CLinuxDevice.WriteBlockData(aRegister: TI2CRegister; const Buffer;
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

procedure TI2CDevice.SetAddress(aValue: TI2CAddress);
begin
  fAddress := aValue;
end;

constructor TI2CDevice.Create(aAddress: TI2CAddress);
begin
  fAddress := aAddress;
end;

procedure TI2CDevice.WriteByte(aRegister: TI2CRegister; aByte: Byte);
begin
  WriteData(aRegister, aByte, sizeof(aByte));
end;

procedure TI2CDevice.WriteWord(aRegister: TI2CRegister; aWord: Word);
var
  b: Word;
begin
  b := NtoBE(aWord);
  WriteData(aRegister, b, SizeOf(b));
end;

procedure TI2CDevice.WriteLongWord(aRegsiter: TI2CRegister; aLongWord: Longword
  );
var
  lw: DWord;
begin
  lw := NToBE(aLongWord);
  WriteData(aRegsiter, lw, Sizeof(lw));
end;

procedure TI2CDevice.WriteQWord(aRegister: TI2CRegister; const aQWord: QWord);
var
  qw: QWord;
begin
  qw := NToBE(aQWord);
  WriteData(aRegister, qw, sizeof(qw));
end;

end.

