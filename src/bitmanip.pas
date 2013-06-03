unit bitmanip;

{$mode objfpc}{$H+}

interface

type
  TByteSize = 0..7 ;
  TWordSize = 0..15;
  TDWordSize = 0..31;
  TQWordSizw = 0..63;

function BITSET(aVal: Byte; Index: TByteSize): Byte; inline;
function BITCLS(aVal: Byte; Index: TByteSize): Byte; inline;
function BITVAL(aVal: Byte; Index: TByteSize): Boolean; inline;
function BITTGL(aVal: Byte; Index: TByteSize): Byte; inline;

function BITSET(aVal: Word; Index: TWordSize): Byte; inline;
function BITCLS(aVal: Word; Index: TWordSize): Byte; inline;
function BITVAL(aVal: Word; Index: TWordSize): Boolean; inline;
function BITTGL(aVal: Word; Index: TWordSize): Byte; inline;

function BITSET(aVal: Longword; Index: TDWordSize): Byte; inline;
function BITCLS(aVal: Longword; Index: TDWordSize): Byte; inline;
function BITVAL(aVal: Longword; Index: TDWordSize): Boolean; inline;
function BITTGL(aVal: Longword; Index: TDWordSize): Byte; inline;

function BITSET(aVal: QWord; Index: TQWordSizw): Byte; inline;
function BITCLS(aVal: QWord; Index: TQWordSizw): Byte; inline;
function BITVAL(aVal: QWord; Index: TQWordSizw): Boolean; inline;
function BITTGL(aVal: QWord; Index: TQWordSizw): Byte; inline;


implementation

function BITSET(aVal: Byte; Index: TByteSize): Byte;
begin
  Result := aVal OR ($01 shl Index);
end;

function BITCLS(aVal: Byte; Index: TByteSize): Byte;
begin
  Result := aVal AND NOT ($01 shl Index);
end;

function BITVAL(aVal: Byte; Index: TByteSize): Boolean;
begin
  Result := ByteBool(aVal AND ($01 shl Index));
end;

function BITTGL(aVal: Byte; Index: TByteSize): Byte;
begin
  Result := aVal XOR ($01 shl Index);
end;

function BITSET(aVal: Word; Index: TWordSize): Byte;
begin
  Result := aVal OR ($01 shl Index);
end;

function BITCLS(aVal: Word; Index: TWordSize): Byte;
begin
  Result := aVal AND NOT ($01 shl Index);
end;

function BITVAL(aVal: Word; Index: TWordSize): Boolean;
begin
  Result := ByteBool(aVal AND ($01 shl Index));
end;

function BITTGL(aVal: Word; Index: TWordSize): Byte;
begin
  Result := aVal XOR ($01 shl Index);
end;

function BITSET(aVal: Longword; Index: TDWordSize): Byte;
begin
  Result := aVal OR ($01 shl Index);
end;

function BITCLS(aVal: Longword; Index: TDWordSize): Byte;
begin
  Result := aVal AND NOT ($01 shl Index);
end;

function BITVAL(aVal: Longword; Index: TDWordSize): Boolean;
begin
  Result := ByteBool(aVal AND ($01 shl Index));
end;

function BITTGL(aVal: Longword; Index: TDWordSize): Byte;
begin
  Result := aVal XOR ($01 shl Index);
end;

function BITSET(aVal: QWord; Index: TQWordSizw): Byte;
begin
  Result := aVal OR ($01 shl Index);
end;

function BITCLS(aVal: QWord; Index: TQWordSizw): Byte;
begin
  Result := aVal AND NOT ($01 shl Index);
end;

function BITVAL(aVal: QWord; Index: TQWordSizw): Boolean;
begin
  Result := ByteBool(aVal AND ($01 shl Index));
end;

function BITTGL(aVal: QWord; Index: TQWordSizw): Byte;
begin
  Result := aVal XOR ($01 shl Index);
end;



end.

