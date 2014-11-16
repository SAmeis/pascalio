{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit pascaliogui;

interface

uses
  fpgpiocomp, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('fpgpiocomp', @fpgpiocomp.Register);
end;

initialization
  RegisterPackage('pascaliogui', @Register);
end.
