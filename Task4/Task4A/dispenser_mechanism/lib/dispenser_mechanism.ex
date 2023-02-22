defmodule DispenserMechanism do
  @moduledoc """
  Documentation for `DispenserMechanism`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> DispenserMechanism.hello()
      :world

  """
  
 @pusher_pin 22
 @rcm_angles []

  def main() do
    pid = ServoKit.init_standard_servo()
    Process.sleep(2000)
    ServoKit.set_angle(pid, 0, 95)
    # Process.sleep(1000)
    Process.sleep(1000)
    ServoKit.set_angle(pid, 1, 180)
    Process.sleep(1000)
    ServoKit.set_angle(pid, 1, 0)
    Process.sleep(1000)
    ServoKit.set_angle(pid, 1, 180)
    Process.sleep(1000)
    ServoKit.set_angle(pid, 0, 70)
    Process.sleep(1000)
    ServoKit.set_angle(pid, 0, 45)
    Process.sleep(1000)
    ServoKit.set_angle(pid, 1, 0)
    Process.sleep(1000)
    ServoKit.set_angle(pid, 1, 180)
    Process.sleep(1000)
    ServoKit.set_angle(pid, 0, 70)
    Process.sleep(1000)
    ServoKit.set_angle(pid, 0, 95)
    Process.sleep(1000)
    ServoKit.set_angle(pid, 0, 115)
    Process.sleep(1000)
    ServoKit.set_angle(pid, 0, 130)
    Process.sleep(1000)
    ServoKit.set_angle(pid, 1, 0)
    Process.sleep(1000)
    ServoKit.set_angle(pid, 1, 180)
    Process.sleep(1000)
    ServoKit.set_angle(pid, 0, 95)
    Process.sleep(1000)
  end

 def test(n1, n2) do
   Pwm.gpio_pwm(@pusher_pin, n1)
   Process.sleep(1000)
   Pwm.gpio_pwm(@pusher_pin, n2)
   Process.sleep(1000)
 end

end
