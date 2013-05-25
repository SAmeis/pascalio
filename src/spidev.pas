(*
 * include/linux/spi/spidev.h
 *
 * Copyright (C) 2006 SWAPP
 *      Andrea Paterniani <a.paterniani@swapp-eng.it>
 * Copyright (C) 2013
 *      Simon Ameis <simon.ameis@web.de> (ported to Pascal)
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 * This is a port of <include>/linux/spi/spidev.h
 * ported 2013 by Simon Ameis
 * Because this header files depends on some ioctl() macros, they are
 * included in this file also.
 *)
unit spidev;

{$PACKRECORDS C}
{$MACRO ON}
// _IOC_TYPECHECK is an alias for SizeOf()
{$DEFINE _IOC_TYPECHECK:=SizeOf}

interface

uses
  unixtype;


(* User space versions of kernel symbols for SPI clocking modes,
 * matching <linux/spi/spi.h>
 *)

const
  SPI_CPHA                = $01;
  SPI_CPOL                = $02;

  SPI_MODE_0              = (0 or 0);
  SPI_MODE_1              = (0 or SPI_CPHA);
  SPI_MODE_2              = (SPI_CPOL or 0);
  SPI_MODE_3              = (SPI_CPOL or SPI_CPHA);

  SPI_CS_HIGH             = $04;
  SPI_LSB_FIRST           = $08;
  SPI_3WIRE               = $10;
  SPI_LOOP                = $20;
  SPI_NO_CS               = $40;
  SPI_READY               = $80;

(*---------------------------------------------------------------------------*)

(* IOCTL commands *)

SPI_IOC_MAGIC                  = ord('k');

(**
 * struct spi_ioc_transfer - describes a single SPI transfer
 * @tx_buf: Holds pointer to userspace buffer with transmit data, or null.
 *      If no data is provided, zeroes are shifted out.
 * @rx_buf: Holds pointer to userspace buffer for receive data, or null.
 * @len: Length of tx and rx buffers, in bytes.
 * @speed_hz: Temporary override of the device's bitrate.
 * @bits_per_word: Temporary override of the device's wordsize.
 * @delay_usecs: If nonzero, how long to delay after the last bit transfer
 *      before optionally deselecting the device before the next transfer.
 * @cs_change: True to deselect device before starting the next transfer.
 *
 * This structure is mapped directly to the kernel spi_transfer structure;
 * the fields have the same meanings, except of course that the pointers
 * are in a different address space (and may be of different sizes in some
 * cases, such as 32-bit i386 userspace over a 64-bit x86_64 kernel).
 * Zero-initialize the structure, including currently unused fields, to
 * accommodate potential future updates.
 *
 * SPI_IOC_MESSAGE gives userspace the equivalent of kernel spi_sync().
 * Pass it an array of related transfers, they'll execute together.
 * Each transfer may be half duplex (either direction) or full duplex.
 *
 *      struct spi_ioc_transfer mesg[4];
 *      ...
 *      status = ioctl(fd, SPI_IOC_MESSAGE(4), mesg);
 *
 * So for example one transfer might send a nine bit command (right aligned
 * in a 16-bit word), the next could read a block of 8-bit data before
 * terminating that command by temporarily deselecting the chip; the next
 * could send a different nine bit command (re-selecting the chip), and the
 * last transfer might write some register values.
 *)

type
  spi_ioc_transfer = record
    // tx_buf and rx_buf hold pointers and are 64 bits wide on all plattforms
    {$IF defined(CPU64)}
    tx_buf: Pointer;
    rx_buf: Pointer;
    {$ELSEIF defined(CPU32) AND defined(ENDIAN_LITTLE)}
    tx_buf: Pointer;
    __fppad1: Longword;
    rx_buf: Pointer;
    __fppad2: Longword;
    {$ELSEIF defined(CPU32) AND defined(ENDIAN_BIG)}
    __fppad1: Longword;
    tx_buf: Pointer;
    __fppad2: Longword;
    rx_buf: Pointer;
    {$ELSE}
      {$FATAL Not supported!}
    {$ENDIF}

    len: cuint32;
    speed_hz: cuint32;

    delay_usecs: cuint16;
    bits_per_word: cuint8;
    cs_change: cuint8;
    pad: cuint32;
         (* If the contents of 'struct spi_ioc_transfer' ever change
          * incompatibly, then the ioctl number (currently 0) must change;
          * ioctls with constant size fields get a bit more in the way of
          * error checking than ones (like this) where that field varies.
          *
          * NOTE: struct layout is the same in 64bit and 32bit userspace.
          *)
  end;
const
  _IOC_NRBITS     = 8;
  _IOC_TYPEBITS   = 8;

(*
 * Let any architecture override either of the following before
 * including this file.
 *)

 // THESE VALUES VARY ON VARIOUS PLATFORMS -  see http://lxr.free-electrons.com/ident?i=_IOC_SIZEBITS
{$IF defined(POWERPC) OR defined(POWERPC64)}
  _IOC_SIZEBITS  = 13;
  _IOC_DIRBITS   = 3;
  _IOC_NONE  = byte(1);
  _IOC_WRITE = byte(2);
  _IOC_READ  = byte(4);
{$ELSEIF defined(SPARC) OR defined(SPARC64)}
  _IOC_SIZEBITS  = 13;
  _IOC_DIRBITS   = 3;
  _IOC_NONE  = byte(1);
  _IOC_WRITE = byte(4);
  _IOC_READ  = byte(2);
{$ELSE}
  { MIPS, APLHA
  _IOC_SIZEBITS  = 13;
  _IOC_DIRBITS   = 3;

  _IOC_NONE  = byte(1);
  _IOC_WRITE = byte(4);
  _IOC_READ  = byte(2);
  }

  { PARISC
  _IOC_NONE  = byte(0);
  _IOC_WRITE = byte(2);
  _IOC_READ  = byte(1);
  }

  // generic values for all other architectures
  _IOC_SIZEBITS  = 14;
  _IOC_DIRBITS   = 2;
  _IOC_NONE  = byte(0);
  _IOC_WRITE = byte(1);
  _IOC_READ  = byte(2);
{$ENDIF}

  _IOC_NRMASK     = ((1 shl _IOC_NRBITS)-1);
  _IOC_TYPEMASK   = ((1 shl _IOC_TYPEBITS)-1);
  _IOC_SIZEMASK   = ((1 shl _IOC_SIZEBITS)-1);
  _IOC_DIRMASK    = ((1 shl _IOC_DIRBITS)-1);

  _IOC_NRSHIFT    = 0;
  _IOC_TYPESHIFT  = (_IOC_NRSHIFT+_IOC_NRBITS);
  _IOC_SIZESHIFT  = (_IOC_TYPESHIFT+_IOC_TYPEBITS);
  _IOC_DIRSHIFT   = (_IOC_SIZESHIFT+_IOC_SIZEBITS);

function _IOC(dir, _type,nr:Cardinal; size: SizeInt): TIOCtlRequest; inline;
function _IOR(_type, nr: Cardinal; size: SizeInt): TIOCtlRequest;
function _IOW(_type, nr: cardinal; size: SizeInt): TIOCtlRequest;

// initialized in intialization section of unit
const
  (* Read / Write of SPI mode (SPI_MODE_0..SPI_MODE_3) *)
  SPI_IOC_RD_MODE: TIOCtlRequest = 0;
  SPI_IOC_WR_MODE: TIOCtlRequest = 0;

  (* Read / Write SPI bit justification *)
  SPI_IOC_RD_LSB_FIRST: TIOCtlRequest = 0;
  SPI_IOC_WR_LSB_FIRST: TIOCtlRequest = 0;

  (* Read / Write SPI device word length (1..N) *)
  SPI_IOC_RD_BITS_PER_WORD: TIOCtlRequest = 0;
  SPI_IOC_WR_BITS_PER_WORD: TIOCtlRequest = 0;

  (* Read / Write SPI device default max speed hz *)
  SPI_IOC_RD_MAX_SPEED_HZ: TIOCtlRequest = 0;
  SPI_IOC_WR_MAX_SPEED_HZ: TIOCtlRequest = 0;

function SPI_MSGSIZE(n: SizeInt): SizeInt; inline;
function SPI_IOC_MESSAGE(N: SizeInt): Cardinal; inline;

implementation

function _IOC(dir, _type, nr: Longword; size: SizeInt): TIOCtlRequest;
begin
  _IOC := (dir  shl _IOC_DIRSHIFT) or
          (_type shl _IOC_TYPESHIFT) or
          (nr   shl _IOC_NRSHIFT) or
          (size shl _IOC_SIZESHIFT);
end;

function _IOR(_type, nr: Cardinal; size: SizeInt): TIOCtlRequest;
begin
  _IOR := _IOC(_IOC_READ, _type, nr, size);
end;

function _IOW(_type, nr: cardinal; size: SizeInt): TIOCtlRequest;
begin
  _IOW := _IOC(_IOC_WRITE, _type, nr, size);
end;

(* not all platforms use <asm-generic/ioctl.h> or _IOC_TYPECHECK() ... *)
function SPI_MSGSIZE(n: SizeInt): SizeInt; inline;
begin
  if (n * sizeof(spi_ioc_transfer)) < (1 shl _IOC_SIZEBITS) then
    SPI_MSGSIZE := n * sizeof(spi_ioc_transfer)
  else
    SPI_MSGSIZE := 0;
end;

function SPI_IOC_MESSAGE(N: SizeInt): Cardinal; inline;
begin
  SPI_IOC_MESSAGE := _IOW(SPI_IOC_MAGIC, 0, SPI_MSGSIZE(N));
end;

initialization
SPI_IOC_RD_MODE                 := _IOR(SPI_IOC_MAGIC, 1, SizeOf(cuint8));
SPI_IOC_RD_MODE                 := _IOR(SPI_IOC_MAGIC, 1, sizeof(cuint8));
SPI_IOC_WR_MODE                 := _IOW(SPI_IOC_MAGIC, 1, sizeof(cuint8));
SPI_IOC_RD_LSB_FIRST            := _IOR(SPI_IOC_MAGIC, 2, sizeof(cuint8));
SPI_IOC_WR_LSB_FIRST            := _IOW(SPI_IOC_MAGIC, 2, sizeof(cuint8));
SPI_IOC_RD_BITS_PER_WORD        := _IOR(SPI_IOC_MAGIC, 3, sizeof(cuint8));
SPI_IOC_WR_BITS_PER_WORD        := _IOW(SPI_IOC_MAGIC, 3, sizeof(cuint8));
SPI_IOC_RD_MAX_SPEED_HZ         := _IOR(SPI_IOC_MAGIC, 4, sizeof(cuint32));
SPI_IOC_WR_MAX_SPEED_HZ         := _IOW(SPI_IOC_MAGIC, 4, sizeof(cuint32));
end.

