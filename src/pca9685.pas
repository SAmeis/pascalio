{ Classes for PCA9685 i2c LED / Servo Driver Board
  translation of AdaFruit python library

  Copyright (C) 2020 by fliegermichel

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

unit PCA9685;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpi2c;

const
  // Registers/etc:
  PCA9685_ADDRESS    = $40;
  MODE1              = $00;
  MODE2              = $01;
  SUBADR1            = $02;
  SUBADR2            = $03;
  SUBADR3            = $04;
  PRESCALE           = $FE;
  LED0_ON_L          = $06;
  LED0_ON_H          = $07;
  LED0_OFF_L         = $08;
  LED0_OFF_H         = $09;
  ALL_LED_ON_L       = $FA;
  ALL_LED_ON_H       = $FB;
  ALL_LED_OFF_L      = $FC;
  ALL_LED_OFF_H      = $FD;

  // Bits:
  RESTART            = $80;
  _SLEEP             = $10;
  ALLCALL            = $01;
  INVRT              = $10;
  OUTDRV             = $04;

type

  { TPCA9685 }

  TPCA9685 = class ( TObject )
  private
    dev: TI2CDevice;
    procedure SoftwareReset;
  public
    constructor Create(aDevice: TI2CDevice);
    destructor  Destroy; override;
    procedure   SetPwmFreq(freq_Hz : LongWord);
    procedure   SetPwm(Channel, aOn, aOff : word);
    procedure   SetAllPwm(aon, aoff : word);
    procedure   SetServoPulse(channel : word; pulse : word);
  end;

implementation

uses math;

{ TPCA9685 }


procedure TPCA9685.SoftwareReset;
begin
  dev.WriteByte($06);
end;

constructor TPCA9685.Create(aDevice: TI2CDevice);
var mode : Byte;
begin
  inherited Create;
  dev := aDevice;

  SetAllPwm(0, 0);
  dev.WriteRegByte(MODE2, OUTDRV);
  dev.WriteRegByte(MODE1, ALLCALL);
  sleep(5);
  mode := dev.ReadRegByte(MODE1) and not _SLEEP;
  dev.WriteRegByte(MODE1, mode);
  sleep(5);
end;

destructor TPCA9685.Destroy;
begin
  SetAllPwm(0, 0);
  inherited Destroy;
end;

procedure TPCA9685.SetPwmFreq(freq_Hz: LongWord);
var PreScaleVal : Double;
    PreScaleB : Byte;
    oldmode,
    newmode : Byte;
begin
 PreScaleVal := 25000000;
 PrescaleVal /= 4096;
 PrescaleVal /= freq_Hz;
 PrescaleVal -= 1;
 PrescaleB := Floor(PrescaleVal+0.5);

 oldmode := dev.ReadRegByte(MODE1);
 newmode := (oldmode and $7F) or $10;

 dev.WriteRegByte(MODE1, newmode);
 dev.WriteRegByte(PRESCALE, PreScaleB);
 dev.WriteRegByte(MODE1, oldmode);
 sleep(5);
 dev.WriteRegByte(MODE1, oldMode or $80);
end;

procedure TPCA9685.SetPwm(Channel, aOn, aOff: word);
begin
  dev.WriteRegByte(LED0_ON_L+4*channel, aon and $FF);
  dev.WriteRegByte(LED0_ON_H+4*channel, aon shr 8);
  dev.WriteRegByte(LED0_OFF_L+4*channel, aoff and $FF);
  dev.WriteRegByte(LED0_OFF_H+4*channel, aoff shr 8);
end;

procedure TPCA9685.SetAllPwm(aon, aoff: word);
begin
  dev.WriteRegByte(ALL_LED_ON_L, aon and $FF);
  dev.WriteRegByte(ALL_LED_ON_H, aon shr 8);
  dev.WriteRegByte(ALL_LED_OFF_L, aoff and $FF);
  dev.WriteRegByte(ALL_LED_OFF_H, aoff shr 8);
end;

procedure TPCA9685.SetServoPulse(channel: word; pulse: word);
begin
  SetPwm(Channel, 0, pulse * 4096 div 20000);
end;

end.

