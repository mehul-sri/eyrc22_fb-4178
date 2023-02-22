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

  """
  DRAWBACKS
  1) :left = right rotation and :right  = left rotation
  """
  alias Pigpiox.{Pwm}

  @dispense_duty_cycle 70 #speed for dispensing
  @pwm_pins [left: 6, right: 26]
  @pusher_pin 20
  @sleep 1000 # used in drop_and_rotate to give delay between rotation of dispensor and acctuator linear movement

  # rcm angles (experimental)
  @angles %{
    1 => 17,
    2 => 37,
    3 => 54,
    4 => 72,
    5 => 88,
    6 => 107,
    7 => 126,
    8 => 154,
    9 => 169
  }

  @count_limit 300  # count limit threshold

  @ir_pins [dr: 16, dl: 19]
  @delay 90 #While detecting box on this node, It stops after [K*@delay] (K is experimental) and check the box (default value is experimental)
  @left_ratio 1.2 # for left rotation correction
  @right_ratio  1 # for right rotation correction
  @push 0 # push acctuator
  @pull 180 # pull actuator

  # dispense the set of rcm's in the box
  def dispense(pid,arr) do
    """
      INPUT
        pid     : ServoKit pid (Dispensing Pid)
        arr     : Set of RCM to be dropped on this node

      OUTPUT
        {:ok}   : If dispensing successfully handled
        {:error}: If box is not detected (Dispensing failed)
    """

    # Get the box
    feedback = detectBox()

    # if not found:
    if Enum.at(feedback,0) == :error do
      {:error}
    else
      # Get the count
      {:ok,rollback_count} = feedback

      # PAUSE
      Process.sleep(2*@sleep)

      # pull the actuator and align the dispensor with the bot
      ServoKit.set_angle(pid,1,@pull)
      Process.sleep(@sleep)
      ServoKit.set_angle(pid,0,@angles[5])

      # sort the rcm list in assending order and call the drop_and_rotate with the arguement as rcm angle to be dropped (using @angles)
      arr
      |> Enum.sort
      |> Enum.map( fn acc ->
        drop_and_rotate(pid,  @angles[acc])
        IO.inspect(acc,label: "RCM dropped: ")
      end)

      # Align the dispensor to the bot
      ServoKit.set_angle(pid,0,@angles[5])
      Process.sleep(2*@sleep)

      # rollback to detect line and return {:ok}
      detectLine(rollback_count)
    end

  end


  def detectBox(count \\ 0, correction_delay \\ 1.25) do
    """
      correction_delay: align box with bot after detecting the box
      Turing in left direction

      if successfull in box detection:
      return {:ok,count} which tells how many times k*@delay has been used which will be used to rollback the effect caused in detection of boxes
    else:
    :error
    """

    # if count increases the threshold (@count_limit), It will return {:error}
    if count >= @count_limit do
      {:error}
    else

      # due to inconsistency of power in right wheel, Multiplying the power with a ratio ( @left_ratio for left turing and @right_ratio for right turing)
      # Ratios are Experimental
      Pwm.gpio_pwm(@pwm_pins[:left], @dispense_duty_cycle)
      Pwm.gpio_pwm(@pwm_pins[:right], floor(@dispense_duty_cycle*@left_ratio))

      # ROTATING LEFT
      LineFollower.motor_action(:left)

      # K = 0.5
      Process.sleep(floor(@delay/2))

      # if box detected once, we check for next 5 reading to confirm the box location
      if boxDetected?() and Enum.all?(Enum.map(1..5, fn _ -> boxDetected?() end)) do

        # Some experimental setup to align the box with the bot (correction_delay )
        IO.puts("BOX DETECTED SUCCESSFULLY")
        LineFollower.motor_action(:right)
        Process.sleep(floor(@delay*correction_delay))

        # STOP
        LineFollower.motor_action(:stop)

        # return count
        {:ok, count }
      else
        # if not detected, increment count
        detectBox(count + 1)
      end
    end
  end

  # If sensor opposite to the direction of motion detect box, it return true else false
  def boxDetected?() do
    get_proximity_readings()
    |> Enum.at(0) == 1
  end

  # Read the reading from proximity sensor and then mapping (detection to 1 and not detection to 0)
  def get_proximity_readings() do
    ir_ref = Enum.map(@ir_pins, fn {_atom, pin_no} -> Circuits.GPIO.open(pin_no, :input, pull_mode: :pullup) end)
    Enum.map(ir_ref,fn {_, ref_no} -> Circuits.GPIO.read(ref_no) end)
    |> Enum.map(fn x ->
      case x do
        1 -> 0
        0 -> 1
      end
    end)
  end

  # rotate the dispensor and drop the RCM
  def drop_and_rotate(pid,angle) do

    """
      Set The dispensor to [angle] and push the acctuator [ 0 degree ] and pull it back [180 degree]
      Channel 0 : Dispensor
      Channel 1 : Linear Acctuator

    """
    # ROTATE DISPENSOR
    ServoKit.set_angle(pid,0,angle)
    Process.sleep(@sleep)

    # PUSHING ACCTUATOR
    ServoKit.set_angle(pid,1,@push)
    Process.sleep(@sleep)

    # PULLING ACCTUATOR
    ServoKit.set_angle(pid,1,@pull)
    Process.sleep(@sleep)
  end

  # rollback using count to come back on line
  def detectLine(count) do

    # due to inconsistency of power in right wheel, Multiplying the power with a ratio ( @left_ratio for left turing and @right_ratio for right turing)
    # Ratios are Experimental

    Pwm.gpio_pwm(@pwm_pins[:left], @dispense_duty_cycle)
    Pwm.gpio_pwm(@pwm_pins[:right], floor(@dispense_duty_cycle*@right_ratio))

    # ROTATING RIGHT (ROLLBACK)
    LineFollower.motor_action(:right)

    # rotating until count * k * delay
    # K = 0.5
    for _ <- 1..count do
      Process.sleep(floor(@delay/2))
    end

    # STOP
    LineFollower.motor_action(:stop)
    {:ok}
  end

end
