unit bitmanip;

{$mode objfpc}{$H+}

interface

type
  TByteSize  = 0..7 ;
  TWordSize  = 0..15;
  TDWordSize = 0..31;
  TQWordSize = 0..63;

function BITSET(aVal: Byte; Index: TByteSize): Byte; inline;     // set bit
function BITCLS(aVal: Byte; Index: TByteSize): Byte; inline;     // clear bit
function BITVAL(aVal: Byte; Index: TByteSize): Boolean; inline;  // value of bit
function BITTGL(aVal: Byte; Index: TByteSize): Byte; inline;     // toggle bit

function BITSET(aVal: Word; Index: TWordSize): Word; inline;
function BITCLS(aVal: Word; Index: TWordSize): Word; inline;
function BITVAL(aVal: Word; Index: TWordSize): Boolean; inline;
function BITTGL(aVal: Word; Index: TWordSize): Word; inline;

function BITSET(aVal: Longword; Index: TDWordSize): Longword; inline;
function BITCLS(aVal: Longword; Index: TDWordSize): Longword; inline;
function BITVAL(aVal: Longword; Index: TDWordSize): Boolean; inline;
function BITTGL(aVal: Longword; Index: TDWordSize): Longword; inline;

function BITSET(aVal: QWord; Index: TQWordSize): QWord; inline;
function BITCLS(aVal: QWord; Index: TQWordSize): QWord; inline;
function BITVAL(aVal: QWord; Index: TQWordSize): Boolean; inline;
function BITTGL(aVal: QWord; Index: TQWordSize): QWord; inline;

// http://graphics.stanford.edu/~seander/bithacks.html
// http://stackoverflow.com/questions/2261671/python-equivalent-of-c-code-from-bit-twiddling-hacks
function CountBits(v: Byte    ): PtrUInt; inline;
function CountBits(v: Word    ): PtrUInt; inline;
function CountBits(v: Longword): PtrUInt; inline;
function CountBits(v: QWord   ): PtrUInt; inline;

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

function BITTGL(aVal: QWord; Index: TQWordSizw): QWord;
begin
  Result := aVal XOR ($01 shl Index);
end;

function CountBits(v: Byte): PtrUInt;
begin
  v := v - ((v shr 1) AND $55);
  v := (v AND $33) + ((v shr 2) AND $33);
  Result := ((v + (v shr 4) AND $0F) * $01);
end;

function CountBits(v: Word): PtrUInt;
begin
  v := v - ((v shr 1) AND $5555);
  v := (v AND $3333) + ((v shr 2) AND $3333);
  Result := ((v + (v shr 4) AND $0F0F) * $0101) shr 8;
end;

function CountBits(v: Longword): PtrUInt;
begin
  v := v - ((v shr 1) AND $55555555);
  v := (v AND $33333333) + ((v shr 2) AND $33333333);
  Result := ((v + (v shr 4) AND $0F0F0F0F) * $01010101) shr 24;
end;

function CountBits(v: QWord): PtrUInt;
begin
  v := v - ((v shr 1) AND $5555555555555555);
  v := (v AND $3333333333333333) + ((v shr 2) AND $3333333333333333);
  Result := ((v + (v shr 4) AND $0F0F0F0F0F0F0F0F) * $0101010101010101) shr 56;
end;



end.

