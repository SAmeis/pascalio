program nonpaging;
(*
Sets program in non paging mode; the Linux Kernel will not page memory to swap.
Reference:
http://www.airspayce.com/mikem/bcm2835/
*)
{$mode objfpc}

uses
  heaptrc, unix, baseunix, Linux, cthreads, unixtype
  { you can add units after this };
{$LINKLIB c}
function sched_get_priority_max(__algorith: cint): cint; cdecl; external 'c';
function sched_setscheduler(__pid: TThreadID; __plicy: cint; constref __param: sched_param): cint; cdecl; external 'c';

function mlockall(flags: cint): cint; cdecl; external 'c';

const
  SCHED_FIFO = 1;
  MCL_CURRENT = 1;
  MCL_FUTURE  = 2;

var
  sp: sched_param;
  r: cint;
begin
  FillChar(sp, sizeof(sp), 0);
  sp.__sched_priority := sched_get_priority_max(SCHED_FIFO);
  writeln('sp.__sched_priority: ', sp.__sched_priority);
  r := sched_setscheduler(0, SCHED_FIFO, sp);
  writeln('Result of setscheduler: ', r);
  r := mlockall(MCL_CURRENT OR MCL_FUTURE);
  writeln('Result of mlockall: ', r);
  writeln('done');
end.

