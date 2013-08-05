{****************************************************************************
*                                                                           *
*                          free-lock queue                                  *
*                                                                           *
*                                                                           *
* Language:             FPC Pascal v2.2.0+ / Delphi 6+                      *
*                                                                           *
* Required switches:    none                                                *
*                                                                           *
* Author:               Dariusz Mazur                                       *
* Date:                 20.01.2008                                          *
* Version:              0.6                                                 *
* Licence:              MPL or GPL
*                                                                           *
*        Send bug reports and feedback to  darekm @@ emadar @@ com          *
*   You can always get the latest version/revision of this package from     *
*                                                                           *
*           http://www.emadar.com/fpc/lockfree.htm                          *
*                                                                           *
*                                                                           *
* Description:  Free-lock algotithm to handle queue FIFO                    *
*               Has two implementation queue based on curcular array        *
*               proposed by Dariusz Mazur                                   *
*               use only single CAS                                         *
*               tFlQueue: for queue of tObject (pointer)                    *
*               gFlQueue: generic queue of any record                       *
* caution : if You set too small size of array and store data excess size   *
*           of queue data will be lost                                      *
*                                                                           *
*  This program is distributed in the hope that it will be useful,          *
*  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
*                                                                           *
*                                                                           *
*****************************************************************************
*                      BEGIN LICENSE BLOCK                                  *

The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: flqueue.pas, released 20.01.2008.
The Initial Developer of the Original Code is Dariusz Mazur


Alternatively, the contents of this file may be used under the terms of the
GNU General Public License Version 2 (the "GPL"), in which case
the provisions of the GPL are applicable instead of those above.
If you wish to allow use of your version of this file only under the terms
of the GPL and not to allow others to use your version of this file
under the MPL, indicate your decision by deleting the provisions above and
replace them with the notice and other provisions required by the GPL.
If you do not delete the provisions above, a recipient may use your version
of this file under either the MPL or the GPL.

*                     END LICENSE BLOCK                                     * }

{ changelog
v.0.06 27.01.2008 change implementation of circural array (bug find by Martin Friebe }



unit flqueue;

interface
uses
  {$IFNDEF FPC}
   windows,
  {$ELSE}
    {$IFDEF ver2_2}
       {$DEFINE USEGENERIC}
    {$ENDIF}
  {$ENDIF}

  classes;



type
  tNodeQueue = tObject;
  tFLQueue = class
  private
      fSize : longword;
      fMask : longword;
      tab : array of tNodeQueue;
      tail,
      head,
      temp    : integer;
      procedure setobject(lp : integer;const aobject : tNodeQueue);
      function getLength:integer;
      function getObject(lp : integer):tNodeQueue;
  public
      constructor create(aPower : integer =10);  {allocate tab with size equal 2^aPower, for 10 size is equal 1024}
      procedure push(const tm : tNodeQueue);
      function pop: tNodeQueue;
      property length : integer read getLength;

  end;

{$IFDEF USEGENERIC}

  generic gFlQueue<_R>=class
      tab : array of _R;
      fSize : longword;
      fMask : longword;
      tail,
      head,
      temp    : integer;
      procedure setobject(lp : integer;const aobject : _R);
      function getObject(lp : integer):_R;
  public
     constructor create(aPower : integer);{allocate tab with size equal 2^aPower}
     procedure push(const tm : _R);
     function pop(var tm: _R):boolean;
  end;


{$ENDIF}

implementation

constructor tFLQueue.create(aPower : integer );
begin
  fMask:=not($FFFFFFFF shl aPower);
  fSize:=1 shl aPower;
  setLength(tab,fSize);
  temp:=0;
  tail:=0;
  head:=0;
end;

procedure tFLQueue.setObject(lp : integer;const aobject : tNodeQueue);
begin
  tab[lp and fMask]:=aObject;
end;

function tFLQueue.getObject(lp : integer):tNodeQueue;
begin
  result:=tab[lp and fMask];
end;

procedure tFlQueue.push(const tm : tNodeQueue);
var
  newTemp,
  lastTail,
  newTail : integer;
begin
  newTemp:=interlockedIncrement(temp);
  lastTail:=newTemp-1;
  setObject(lastTail,tm);
  repeat
    pointer(newTail):=interlockedCompareExchange(pointer(tail),pointer(newTemp),pointer(lastTail));
  until (newTail=lastTail);

end;

function tFLQueue.pop:tNodeQueue;
var
  newhead,
  lastHead : integer;
begin
  repeat
    lastHead:=head;
    if tail<>head then begin
      pointer(newHead):=interlockedCompareExchange(pointer(head),pointer(lastHead+1),pointer(lasthead));
      if newHead=lastHead then begin
         result:=getObject(lastHead);
         exit;
      end;
    end else begin
       result:=nil;
       exit;
    end;
  until false;
end;

function tFLQueue.getLength:integer;

begin

  result:=tail-head;

end;


{$IFDEF USEGENERIC}


constructor gFLQueue.create(aPower : integer);
begin
  fMask:=not($FFFFFFFF shl aPower);
  fSize:=1 shl aPower;
  setLength(tab,fSize);
  tail:=0;
  head:=0;
  temp:=0;
end;

procedure gFLQueue.setObject(lp : integer;const aobject : _R);
begin
  tab[lp and fMask]:=aObject;
end;

function gFLQueue.getObject(lp : integer):_R;
begin
  result:=tab[lp and fMask];
end;

procedure gFlQueue.push(const tm : _R);
var
  newTemp,
  lastTail,
  newTail : integer;
begin
  newTemp:=interlockedIncrement(temp);
  lastTail:=newTemp-1;
  setObject(lastTail,tm);
  repeat
    pointer(newTail):=interlockedCompareExchange(pointer(tail),pointer(newTemp),pointer(lastTail));
  until (newTail=lastTail);

end;

function gFLQueue.pop(var tm:_R):boolean;
var
  newhead,
  lastHead : integer;
begin
  repeat
    lastHead:=head;
    if tail<>head then begin
      pointer(newHead):=interlockedCompareExchange(pointer(head),pointer(lastHead+1),pointer(lasthead));
      if newHead=lastHead then begin
         tm:=getObject(lastHead);
         result:=true;
         exit;
      end;
    end else begin
       result:=false;
       exit;
    end;
  until false;
end;






{$ENDIF}

end.
