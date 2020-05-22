program pwm_linux;

uses fppwm;

var
  pwm: TPWMLinux;
begin
  pwm := TPWMLinux.Create(0,0);
  try
    pwm.Period    := 10000;  // 10 kHz total time
    pwm.DutyCycle := 6000;   //  6 kHz active time
    pwm.Enabled   := True;
  finally
    pwm.Destroy;
  end;
end.

