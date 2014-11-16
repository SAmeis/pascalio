unit fpgpiocomp;

{$mode objfpc}{$H+}

interface

uses
  {$IFDEF LINUX}baseunix, pthreads, {$ENDIF} Classes, SysUtils, Forms, fpgpio;

type
  EGPIO = class(Exception);

  TCustomGPIO = class;

  TGPIOInterruptEvent = procedure(GPIO: TCustomGPIO; NewValue: Boolean)
    of object;
  { TCustomGPIO }

  TCustomGPIO = class(TComponent)
  private
    fOnInterrupt: TGPIOInterruptEvent;
    fOnPollChange: TGPIOInterruptEvent;
    fOwnsGPIOPin: Boolean;
    function GetActiveLow: Boolean;
    function GetDirection: TGpioDirection;
    function GetInterruptMode: TGpioInterruptMode;
    function GetValue: Boolean;
    function IsActiveLowStored: Boolean;
    function IsInterruptModeStored: Boolean;
    function IsValueStored: Boolean;
    procedure SetActiveLow(aValue: Boolean);
    procedure SetDirection(aValue: TGpioDirection);
    procedure SetInterruptMode(aValue: TGpioInterruptMode);
    procedure SetValue(aValue: Boolean);
  protected type

    { TGPIOEventThread }

    TGPIOEventThread = class(TThread)
    private
      fGPIOPin: TGpioPin;
      fOnException: TDataEvent;
      fOnInteruptAsync: TDataEvent;
    protected
      procedure Execute; override;
    public
      property GPIOPin: TGpioPin read fGPIOPin write fGPIOPin;
      property OnInteruptAsync: TDataEvent read fOnInteruptAsync
        write fOnInteruptAsync;
      property OnException: TDataEvent read fOnException write fOnException;
    end;

    TGPIOInterruptThread = class(TGPIOEventThread)
    protected
      procedure Execute; override;
    end;
    TGPIOPollThread = class(TGPIOEventThread)
    protected
      procedure Execute; override;
    end;
  protected
    fGPIOPin  : TGpioPin;
    fInterruptThread: TGPIOEventThread;

    fDirection: TGpioDirection;
    fValue    : Boolean;
    fInterruptMode: TGpioInterruptMode;
    fActiveLow: Boolean;
    procedure PropagateProperties; virtual;
    procedure UpdateProperties   ; virtual;
    procedure StartInterruptThread; virtual;
    procedure StopInterruptThread ; virtual;
    procedure DoOnInterruptAsync(Data: PtrInt); virtual;

    property OwnsGPIOPin: Boolean read fOwnsGPIOPin write fOwnsGPIOPin;
  public
    destructor Destroy; override;
    property GPIOPin: TGpioPin read fGPIOPin;
  published
    property Direction: TGpioDirection read GetDirection write SetDirection;
    property Value: Boolean read GetValue write SetValue stored IsValueStored;
    property InterruptMode: TGpioInterruptMode read GetInterruptMode
      write SetInterruptMode stored IsInterruptModeStored;
    property ActiveLow: Boolean read GetActiveLow write SetActiveLow
      stored IsActiveLowStored;
    property OnInterrupt: TGPIOInterruptEvent read fOnInterrupt
      write fOnInterrupt;
    property OnPollChange: TGPIOInterruptEvent read fOnPollChange
      write fOnPollChange;
  end;

  { TGenericGPIO }

  TGenericGPIO = class(TCustomGPIO)
  private
    procedure SetGPIOPin(aValue: TGpioPin);
  public
    property GPIOPin: TGpioPin read fGPIOPin write SetGPIOPin;
  published
    property OwnsGPIOPin;
  end;

  { TLinuxGPIO }

  TLinuxGPIO = class(TCustomGPIO)
  private
    fPinID: Longword;
    {$IFDEF LINUX}
    function LinuxPin: TGpioLinuxPin; inline;
    {$ENDIF}
    procedure SetPinID(aValue: Longword);
  public
    constructor Create(AOwner: TComponent); override;
  published
    property PinID: Longword read fPinID write SetPinID;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('PascalIO',[TGenericGPIO]);
  RegisterComponents('PascalIO',[TLinuxGPIO]);
end;

{ TCustomGPIO.TGPIOEventThread }

procedure TCustomGPIO.TGPIOEventThread.Execute;
var
  pin: TGpioPin;
  NewValue: Boolean;
  IntProc: TDataEvent;
begin
  repeat
    pin := fGPIOPin;
    if not Assigned(pin) then
    begin
      if not pin.WaitForInterrupt(-1, NewValue) then continue;
    end;

    IntProc := fOnInteruptAsync;
    if Assigned(IntProc) then
      Application.QueueAsyncCall(IntProc, PtrInt(NewValue));
  until Self.Terminated;
end;

{ TGenericGPIO }

procedure TGenericGPIO.SetGPIOPin(aValue: TGpioPin);
begin
  if fGPIOPin = aValue then Exit;
  fGPIOPin := aValue;
  PropagateProperties;
end;

{ TCustomGPIO }

function TCustomGPIO.GetActiveLow: Boolean;
begin
  Result := fActiveLow;
end;

function TCustomGPIO.GetDirection: TGpioDirection;
begin
  Result := fDirection;
end;

function TCustomGPIO.GetInterruptMode: TGpioInterruptMode;
begin
  Result := fInterruptMode;
end;

function TCustomGPIO.GetValue: Boolean;
begin
  if Assigned(GPIOPin) then
  begin
    fValue := GPIOPin.Value;
    Result := Value;
  end else
    Result := fValue;
end;

function TCustomGPIO.IsActiveLowStored: Boolean;
begin
  Result := ActiveLow = True;
end;

function TCustomGPIO.IsInterruptModeStored: Boolean;
begin
  Result := (Direction = gdIn) and (InterruptMode <> []);
end;

function TCustomGPIO.IsValueStored: Boolean;
begin
  Result := Direction = gdOut;
end;

procedure TCustomGPIO.SetActiveLow(aValue: Boolean);
begin
  if fActiveLow <> aValue then
  begin
    fActiveLow := aValue;
    PropagateProperties;
  end;
end;

procedure TCustomGPIO.SetDirection(aValue: TGpioDirection);
begin
  if fDirection <> aValue then
  begin
    fDirection := aValue;
    // set to default value as setting a value on an output doesn't make sense
    // Value will get direction from GPIO pin if assigned
    if fDirection = gdIn then
      fValue := False;

    PropagateProperties;
  end;
end;

procedure TCustomGPIO.SetInterruptMode(aValue: TGpioInterruptMode);
begin
  if Direction = gdOut then
    fInterruptMode := []
  else
  if fInterruptMode <> aValue then
    fInterruptMode := aValue;

  PropagateProperties;
end;

procedure TCustomGPIO.SetValue(aValue: Boolean);
begin
  if (Direction = gdOut) then
  begin
    fValue := aValue;
    PropagateProperties;
  end;
end;

procedure TCustomGPIO.PropagateProperties;
begin
  if not Assigned(GPIOPin) then exit;

  GPIOPin.ActiveLow := fActiveLow;
  GPIOPin.Direction := fDirection;
  if fDirection = gdOut then
    GPIOPin.Value := fValue
  else
  begin
    GPIOPin.InterruptMode := fInterruptMode;
  end;
  if  (not (csDesigning in ComponentState))
  and (Direction = gdIn)
  and (fInterruptMode <> []) then
    StartInterruptThread
  else
    StopInterruptThread;
end;

procedure TCustomGPIO.UpdateProperties;
begin
  if not Assigned(GPIOPin) then exit;

  fActiveLow := GPIOPin.ActiveLow;
  fDirection := GPIOPin.Direction;
  fValue     := GPIOPin.Value;
  fInterruptMode := GPIOPin.InterruptMode;
end;

procedure TCustomGPIO.StartInterruptThread;
begin
  if Assigned(fInterruptThread) then
    raise EGPIO.Create('Interrupt thread already started.');
  if not Assigned(GPIOPin) then
    raise EGPIO.Create('GPIO pin not set.');

  fInterruptThread := TGPIOEventThread.Create(True, DefaultStackSize);
  fInterruptThread.GPIOPin := Self.GPIOPin;
  fInterruptThread.OnInteruptAsync := @self.DoOnInterruptAsync;
end;

procedure TCustomGPIO.StopInterruptThread;
begin
  if not Assigned(fInterruptThread) then exit; // nothing to do
  fInterruptThread.GPIOPin         := nil;
  fInterruptThread.OnException     := nil;
  fInterruptThread.OnInteruptAsync := nil;
  fInterruptThread.Terminate;
  {$IFDEF LINUX}
    // notfy thread
    pthread_kill(fInterruptThread.ThreadID, SIGINT);
  {$ENDIF}
  fInterruptThread.Destroy;
  fInterruptThread := nil;
end;

procedure TCustomGPIO.DoOnInterruptAsync(Data: PtrInt);
begin
  if csDestroying in ComponentState then exit;

  if Assigned(fOnInterrupt) then
    fOnInterrupt(Self, Boolean(Data));
end;

destructor TCustomGPIO.Destroy;
begin
  Destroying;
  StopInterruptThread;
  inherited Destroy;
end;

{ TLinuxGPIO }
{$IFDEF LINUX}
function TLinuxGPIO.LinuxPin: TGpioLinuxPin;
begin
  Result := TGpioLinuxPin(fGPIOPin);
end;
{$ENDIF}

procedure TLinuxGPIO.SetPinID(aValue: Longword);
begin
  {$IFDEF LINUX}
  if Assigned(fGPIOPin) then
    if LinuxPin.PinID = aValue then
      exit
    else
    begin
      StopInterruptThread;
      FreeAndNil(fGPIOPin);
    end;

  fPinID := aValue;

  if not (csDesigning in ComponentState) then
  begin
    fGPIOPin := TGpioLinuxPin.Create(aValue);
  end else
    fGPIOPin := nil;
  PropagateProperties;
  {$ELSE}
  // just save PinID for component streaming
  fPinID := aValue;
  {$ENDIF}
end;

constructor TLinuxGPIO.Create(AOwner: TComponent);
begin
  OwnsGPIOPin := True;
  inherited Create(AOwner);
end;


end.
