//
//  How to access GPIO registers from C-code on the Raspberry-Pi
//  Example program
//  15-January-2012
//  Dom and Gert
//  Revised: 15-Feb-2013
//
//  Ported to Free Pascal on 2013-06-10 by Simon Ameis
unit bcm2708;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ctypes, baseunix, rtlconst;
(*
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
*)

// Access from ARM Running Linux
const
  BCM2708_PERI_BASE = $20000000;
  GPIO_BASE         = (BCM2708_PERI_BASE + $200000); // GPIO controller
  PAGE_SIZE         = (4*1024);
  BLOCK_SIZE        = (4*1024);

var
  mem_fd: cint = 0;
  gpio_map: Pointer = nil;

// I/O access
//volatile unsigned *gpio;
  gpio: PPtrUInt = nil;

procedure INP_GPIO(g: PtrUInt);
procedure OUT_GPIO(g: PtrUInt);
procedure SET_GPIO_ALT(g, a: PtrUInt);
function GPIO_SET: Byte;
function GPIO_CLR: Byte;
procedure setup_io()

implementation

procedure INP_GPIO(g: PtrUInt);
begin
  //#define INP_GPIO(g) *(gpio+((g)/10)) &= ~(7<<(((g)%10)*3))
  (gpio + (g div 10))^ := (gpio + (g div 10))^ AND NOT (7 SHL ((g mod 10) * 3))
end;

procedure OUT_GPIO(g: PtrUInt);
begin
  //#define OUT_GPIO(g) *(gpio+((g)/10)) |=  (1<<(((g)%10)*3))
  (gpio + (g div 10))^ := (gpio + (g div 10))^ OR (1 SHL ((g mod 10) * 3))
end;

procedure SET_GPIO_ALT(g, a: PtrUInt);
var
  r: PtrUInt;
begin
  //#define SET_GPIO_ALT(g,a) *(gpio+(((g)/10))) |= (((a)<=3?(a)+4:(a)==4?3:2)<<(((g)%10)*3))
  if a <= 3 then
    r := a + 4
  else
  if a = 4 then
    r := 3
  else
    r := 2;

  (gpio + ((g div 10)))^ := (gpio + ((g div 10)))^ OR (r SHL ((g MOD 10) * 3));
end;

function GPIO_SET: PPtrUInt;
begin
  //#define GPIO_SET *(gpio+7)  // sets   bits which are 1 ignores bits which are 0
  Result := (gpio + 7);
end;

function GPIO_CLR: PPtrUInt;
begin
  //#define GPIO_CLR *(gpio+10) // clears bits which are 1 ignores bits which are 0
  Result := (gpio + 10);
end;

//
// Set up a memory regions to access GPIO
//
procedure setup_io()
begin
   // open /dev/mem
   if ((mem_fd = FpOpen('/dev/mem', O_RDWR OR O_SYNC) ) < 0) then
      raise EFOpenError.CreateFmt(SFOpenError, ['/dev/mem']);

   // mmap GPIO
   gpio_map := Fpmmap(
      nil,             //Any adddress in our space will do
      BLOCK_SIZE,       //Map length
      PROT_READ OR PROT_WRITE,// Enable reading & writting to mapped memory
      MAP_SHARED,       //Shared with other processes
      mem_fd,           //File to map
      GPIO_BASE         //Offset to GPIO peripheral
   );

   FpClose(mem_fd); //No need to keep mem_fd open after mmap

   if (gpio_map = MAP_FAILED) then
      raise EOSError.CreateFmt('mmap error %d.', [PtrInt(gpio_map)]);//errno also set!

   gpio := gpio_map;
end; // setup_io

end.

