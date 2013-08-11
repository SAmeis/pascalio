program project1;

{$mode objfpc}{$H+}

uses
  bcm2708;

//int main(int argc, char **argv)
procedure TestProgram;
var
  g, rep: cint;
begin
  // Set up gpi pointer for direct register access
  setup_io();

  // Switch GPIO 7..11 to output mode

 (************************************************************************\
  * You are about to change the GPIO settings of your computer.          *
  * Mess this up and it will stop working!                               *
  * It might be a good idea to 'sync' before running this program        *
  * so at least you still have your code changes written to the SD-card! *
 \************************************************************************)

  // Set GPIO pins 7-11 to output
  for g := 7 to 11 do
  begin
    INP_GPIO(g); // must use INP_GPIO before we can use OUT_GPIO
    OUT_GPIO(g);
  end;

  for rep := 0 to 9 do
  begin
     for g := 7 to 11 do
     begin
       GPIO_SET^ := 1 shl g;
       sleep(1);
     end;
     for g := 7 to 11 do
     begin
       GPIO_CLR^ := 1 shl g;
       sleep(1);
     end;
  end;
end; // main

begin
  procedure TestProgram;
end.

