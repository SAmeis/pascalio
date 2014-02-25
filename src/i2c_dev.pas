{ Port of Linux header file i2c-dev.h - i2c-bus driver, char device interface

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

unit i2c_dev;

interface

uses
  baseunix, ctypes;

{$PACKRECORDS C}

(*
 * I2C Message - used for pure i2c transaction, also from /dev interface
 *)
type
  i2c_msg = record
    addr: LongWord; // slave address
    flags: cushort;
    len: cshort;    // msg length
    buf: Pointer;     // pointer to msg data
  end;
  Pi2c_msg = ^i2c_msg;

const
  I2C_M_TEN	= $10;
  I2C_M_RD	= $01;
  I2C_M_NOSTART	= $4000;
  I2C_M_REV_DIR_ADDR= $2000;
  I2C_M_IGNORE_NAK	= $1000;
  I2C_M_NO_RD_ACK		= $0800;

const
  I2C_FUNC_I2C			= $00000001;
  I2C_FUNC_10BIT_ADDR		= $00000002;
  I2C_FUNC_PROTOCOL_MANGLING	= $00000004; // I2C_M_{REV_DIR_ADDR,NOSTART,..}
  I2C_FUNC_SMBUS_PEC		= $00000008;
  I2C_FUNC_SMBUS_BLOCK_PROC_CALL	= $00008000; // SMBus 2.0
  I2C_FUNC_SMBUS_QUICK		= $00010000;
  I2C_FUNC_SMBUS_READ_BYTE	= $00020000;
  I2C_FUNC_SMBUS_WRITE_BYTE	= $00040000;
  I2C_FUNC_SMBUS_READ_BYTE_DATA	= $00080000;
  I2C_FUNC_SMBUS_WRITE_BYTE_DATA	= $00100000;
  I2C_FUNC_SMBUS_READ_WORD_DATA	= $00200000;
  I2C_FUNC_SMBUS_WRITE_WORD_DATA	= $00400000;
  I2C_FUNC_SMBUS_PROC_CALL	= $00800000;
  I2C_FUNC_SMBUS_READ_BLOCK_DATA	= $01000000;
  I2C_FUNC_SMBUS_WRITE_BLOCK_DATA = $02000000;
  I2C_FUNC_SMBUS_READ_I2C_BLOCK	= $04000000; // I2C-like block xfer
  I2C_FUNC_SMBUS_WRITE_I2C_BLOCK	= $08000000; // w/ 1-byte reg. addr.

  I2C_FUNC_SMBUS_BYTE = (I2C_FUNC_SMBUS_READ_BYTE or I2C_FUNC_SMBUS_WRITE_BYTE);
  I2C_FUNC_SMBUS_BYTE_DATA = (I2C_FUNC_SMBUS_READ_BYTE_DATA or I2C_FUNC_SMBUS_WRITE_BYTE_DATA);
  I2C_FUNC_SMBUS_WORD_DATA = (I2C_FUNC_SMBUS_READ_WORD_DATA or I2C_FUNC_SMBUS_WRITE_WORD_DATA);
  I2C_FUNC_SMBUS_BLOCK_DATA = (I2C_FUNC_SMBUS_READ_BLOCK_DATA or I2C_FUNC_SMBUS_WRITE_BLOCK_DATA);
  I2C_FUNC_SMBUS_I2C_BLOCK = (I2C_FUNC_SMBUS_READ_I2C_BLOCK or I2C_FUNC_SMBUS_WRITE_I2C_BLOCK);

(* Old name, for compatibility *)
  I2C_FUNC_SMBUS_HWPEC_CALC	= I2C_FUNC_SMBUS_PEC;

(*
 * Data for SMBus Messages
 *)
  I2C_SMBUS_BLOCK_MAX	= 32;	//* As specified in SMBus standard
  I2C_SMBUS_I2C_BLOCK_MAX	= 32;	// Not specified but we use same structure

type
  TI2C_SMBUS_VALUES = array[0..31] of byte;

  i2c_smbus_data = record
  case integer of
    0: (_byte: byte);
    1: (_word: word);
    // 32 + 2 elements/bytes
    2: (block: array [0..I2C_SMBUS_BLOCK_MAX + 1] of byte); // block[0] is used for length and one more for PEC
  end;
  Pi2c_smbus_data = ^i2c_smbus_data;

(* smbus_access read or write markers *)
type
  // this needs to be exactly 1 byte in size!
  {$PACKENUM 1}
  TI2C_SMBUS_RW_MODE = (
    I2C_SMBUS_WRITE	= 0,
    I2C_SMBUS_READ	= 1
  );

(* SMBus transaction types (size parameter in the above functions)
   Note: these no longer correspond to the (arbitrary) PIIX4 internal codes! *)
   // this needs to be exactly 4 bytes (cint/longint) in size!
  {$PACKENUM 4}
  TI2C_SMBUS_TRANSACTION = (
    I2C_SMBUS_QUICK		     = 0,
    I2C_SMBUS_BYTE		     = 1,
    I2C_SMBUS_BYTE_DATA	   = 2,
    I2C_SMBUS_WORD_DATA	   = 3,
    I2C_SMBUS_PROC_CALL	   = 4,
    I2C_SMBUS_BLOCK_DATA	 = 5,
    I2C_SMBUS_I2C_BLOCK_BROKEN = 6,
    I2C_SMBUS_BLOCK_PROC_CALL  = 7,		// SMBus 2.0
    I2C_SMBUS_I2C_BLOCK_DATA   = 8
  );

  {$PACKENUM DEFAULT}

const
  I2C_RETRIES     = $0701;
  I2C_TIMEOUT     = $0702;

  I2C_SLAVE       = $0703;
  I2C_SLAVE_FORCE = $0706;
  I2C_TENBIT      = $0704;
  I2C_FUNCS       = $0705;
  I2C_RDWR	      = $0707;
  I2C_PEC         = $0708;
  I2C_SMBUS       = $0720;

type
  // used for I2C_SMBUS ioctl call
  i2c_smbus_ioctl_data = record
    read_write: TI2C_SMBUS_RW_MODE;
    command: byte;
    size: TI2C_SMBUS_TRANSACTION;
    data: ^i2c_smbus_data;
  end;
  Pi2c_smbus_ioctl_data = ^i2c_smbus_ioctl_data;

  // used for I2C_RDWR ioctl call
  i2c_rdwr_ioctl_data = record
    msgs: Pi2c_msg; // pointers to i2c_msgs
    nmsgs: cint; // number of i2c_msgs
  end;
  Pi2c_rdwr_ioctl_data = ^i2c_rdwr_ioctl_data;


function i2c_smbus_access(_file: cint; read_write: TI2C_SMBUS_RW_MODE;
  command: byte; size: TI2C_SMBUS_TRANSACTION; data: Pi2c_smbus_data): Longint; inline;
function i2c_smbus_block_process_call(_file: cint; command: byte; _length: byte;
  values: PByte): Longint; inline;
function i2c_smbus_process_call(_file: cint; command: byte; value: word): Longint; inline;
function i2c_smbus_read_block_data(_file: cint; command: byte; values: PByte): Longint; inline;
function i2c_smbus_read_byte(_file: cint): Longint; inline;
function i2c_smbus_read_byte_data(_file: cint; command: byte): Longint; inline;
function i2c_smbus_read_i2c_block_data(_file: cint; command: byte;
  _length: byte; values: PByte): Longint; inline;
function i2c_smbus_read_word_data(_file: cint; command: byte): Longint; inline;
function i2c_smbus_write_block_data(_file: cint; command: byte; _length: byte;
  values: PByte): Longint; inline;
function i2c_smbus_write_byte(_file: cint; value: byte): Longint; inline;
function i2c_smbus_write_byte_data(_file: cint; command: byte; value: byte): Longint; inline;
function i2c_smbus_write_i2c_block_data(_file: cint; command: byte;
  _length: byte; values: PByte): Longint; inline;
function i2c_smbus_write_quick(_file: cint; value: byte): Longint; inline;
function i2c_smbus_write_word_data(_file: cint; command: byte; value: word): Longint; inline;

implementation

function i2c_smbus_access(_file: cint; read_write: TI2C_SMBUS_RW_MODE;
  command: byte; size: TI2C_SMBUS_TRANSACTION; data: Pi2c_smbus_data): Longint; inline;
var
  args: i2c_smbus_ioctl_data;
begin
  args.read_write := read_write;
  args.command := command;
  args.size := size;
  args.data := data;

  Result := FpIOCtl(_file, I2C_SMBUS, @args);
end;

function i2c_smbus_write_quick(_file: cint; value: byte): Longint; inline;
begin
  Result := i2c_smbus_access(_file, TI2C_SMBUS_RW_MODE(value), 0, I2C_SMBUS_QUICK, nil);
end;

function i2c_smbus_read_byte(_file: cint): Longint; inline;
var
  data: i2c_smbus_data;
begin
  if i2c_smbus_access(_file, I2C_SMBUS_READ, 0, I2C_SMBUS_BYTE, @data) <> 0 then
    Result := -1
  else
    Result := $0FF and data._byte;
end;

function i2c_smbus_write_byte(_file: cint; value: byte): Longint; inline;
begin
  Result := i2c_smbus_access(_file, I2C_SMBUS_WRITE, value, I2C_SMBUS_BYTE, nil);
end;

function i2c_smbus_read_byte_data(_file: cint; command: byte): Longint; inline;
var
  data: i2c_smbus_data;
begin
  if i2c_smbus_access(_file, I2C_SMBUS_READ, command, I2C_SMBUS_BYTE_DATA, @data) <> 0 then
    Result := -1
  else
    Result := $0FF and data._byte;
end;

function i2c_smbus_write_byte_data(_file: cint; command: byte; value: byte): Longint; inline;
var
  data: i2c_smbus_data;
begin
  data._byte := value;
  Result := i2c_smbus_access(_file, I2C_SMBUS_WRITE, command, I2C_SMBUS_BYTE_DATA, @data);
end;

function i2c_smbus_read_word_data(_file: cint; command: byte): Longint; inline;
var
  data: i2c_smbus_data;
begin
  if i2c_smbus_access(_file, I2C_SMBUS_READ, command, I2C_SMBUS_WORD_DATA, @data) <> 0 then
    Result := -1
  else
    Result := $0FFFF and data._word;
end;

function i2c_smbus_write_word_data(_file: cint; command: byte; value: word): Longint; inline;
var
  data: i2c_smbus_data;
begin
  data._word := value;
  Result := i2c_smbus_access(_file, I2C_SMBUS_WRITE, command, I2C_SMBUS_WORD_DATA, @data);
end;

function i2c_smbus_process_call(_file: cint; command: byte; value: word): Longint; inline;
var
  data: i2c_smbus_data;
begin
  data._word := value;
  if i2c_smbus_access(_file, I2C_SMBUS_WRITE, command, I2C_SMBUS_PROC_CALL, @data) <> 0 then
    Result := -1
  else
    Result := $0FFFF and data._word;
end;

(* Returns the number of read bytes *)
function i2c_smbus_read_block_data(_file: cint; command: byte; values: PByte): Longint; inline;
var
  data: i2c_smbus_data;
begin
  if i2c_smbus_access(_file, I2C_SMBUS_READ, command, I2C_SMBUS_BLOCK_DATA, @data) <> 0 then
    Result := -1
  else
  begin
    move(data.block[1], values^, data.block[0]);
    Result := data.block[0];
  end;
end;

function i2c_smbus_write_block_data(_file: cint; command: byte; _length: byte; values: PByte): Longint; inline;
var
  data: i2c_smbus_data;
begin
  if _length > 32 then
    _length := 32;
  move(values^, data.block[1], _length);
  data.block[0] := _length;
  Result := i2c_smbus_access(_file, I2C_SMBUS_WRITE, command, I2C_SMBUS_BLOCK_DATA, @data);
end;

(* Returns the number of read bytes *)
(* Until kernel 2.6.22, the length is hardcoded to 32 bytes. If you
   ask for less than 32 bytes, your code will only work with kernels
   2.6.23 and later. *)
function i2c_smbus_read_i2c_block_data(_file: cint; command: byte; _length: byte; values: PByte): Longint; inline;
var
  data: i2c_smbus_data;
  size: TI2C_SMBUS_TRANSACTION;
begin
  if _length > 32 then
    _length := 32;
  data.block[0] := _length;

  if _length = 32 then
    size := I2C_SMBUS_I2C_BLOCK_BROKEN
  else
    size := I2C_SMBUS_I2C_BLOCK_DATA;

  if i2c_smbus_access(_file, I2C_SMBUS_READ, command, size, @data) <> 0 then
    Result := -1
  else
  begin
    move(data.block[1], values^, data.block[0]);
    Result := data.block[0];
  end;
end;

function i2c_smbus_write_i2c_block_data(_file: cint; command: byte; _length: byte; values: PByte): Longint; inline;
var
  data: i2c_smbus_data;
begin
  if _length > 32 then
    _length := 32;
  move(values^, data.block[1], _length);
  data.block[0] := _length;
  Result := i2c_smbus_access(_file, I2C_SMBUS_WRITE, command, I2C_SMBUS_I2C_BLOCK_BROKEN, @data);
end;

(* Returns the number of read bytes *)
function i2c_smbus_block_process_call(_file: cint; command: byte; _length: byte; values: PByte): Longint; inline;
var
  data: i2c_smbus_data;
begin
  if _length > 32 then
    _length := 32;
  move(values^, data.block[1], _length);
  data.block[0] := _length;
  if i2c_smbus_access(_file, I2C_SMBUS_WRITE, command, I2C_SMBUS_BLOCK_PROC_CALL, @data) <> 0 then
    Result := -1
  else
  begin
    move(data.block[1], values^, data.block[0]);
    Result := data.block[0];
  end;
end;


end.

