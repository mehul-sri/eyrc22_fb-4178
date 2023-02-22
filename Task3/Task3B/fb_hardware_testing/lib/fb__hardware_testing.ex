defmodule FB_HardwareTesting do
  @moduledoc """
  Documentation for `FB_HardwareTesting`.
  Different functions provided for testing components of Alpha Bot.
  test_buzzer       - to test Buzzer
  test_wlf_sensors  - to test white line sensors
  test_ir           - to test IR proximity sensors
  test_motion       - to test Motion of the Robot
  test_pwm          - to test Speed of the Robot
  test_servo_a      - to test Servo motor a
  test_servo_b      - to test Servo motor a
  """

  require Logger
  use Bitwise
  alias Pigpiox.{GPIO, Pwm}

  @level [high: 1, low: 0, on: 1, off: 0]

  
  @buzzer_pin [buz: 4]
  @sensor_pins [cs: 5, clock: 25, address: 24, dataout: 23]
  @ir_pins [dr: 16, dl: 19]
  @motor_pins [lf: 12, lb: 13, rf: 20, rb: 21]
  @pwm_pins [left: 6, right: 26]

  @ref_atoms [:cs, :clock, :address, :dataout]
  @lf_sensor_data %{sensor0: 0, sensor1: 0, sensor2: 0, sensor3: 0, sensor4: 0, sensor5: 0}
  @lf_sensor_map %{0 => :sensor0, 1 => :sensor1, 2 => :sensor2, 3 => :sensor3, 4 => :sensor4, 5 => :sensor5}

  @motion_list [forward:  [0, 1, 0, 1],
                backward: [1, 0, 1, 0],
                left:     [0, 1, 1, 0],
                right:    [1, 0, 0, 1],
                stop:     [0, 0, 0, 0]]

  @duty_cycle 100
  @pwm_frequency 50

  #-------------------------------------------------------------------
  @doc """
  Tests Buzzer
  Example:
      iex> FB_HardwareTesting.test_buzzer
      Testing Buzzer connected
      :ok
  """
  def test_buzzer do
    Logger.debug("Testing Buzzer connected ")
    buzzer_init()
    buzzer_control(:high)
    Process.sleep(500)
    buzzer_control(:low)
  end

  @doc """
  Tests motion of the Robot
  Example:
      iex> FB_HardwareTesting.test_motion
      :ok
  Note: On executing above function Robot will move forward, backward, left, right
  for 500ms each and then stops
  """
  def test_motion do
    Logger.debug("Testing Motion of the Robot ")
    motion_init()
    motions = [:forward,:backward,:left,:right,:stop]
    Enum.each(motions, fn motion -> motor_action(motion);Process.sleep(500) end)
  end

  @doc """
  Controls speed of the Robot
  Example:
      iex> FB_HardwareTesting.test_pwm
      Forward with pwm value = 100
      Forward with pwm value = 50
      Forward with pwm value = 0
      {:ok, :ok, :ok}
  Note: On executing above function Robot will move in forward direction with different velocities
  """
  def test_pwm do
    Logger.debug("Testing PWM for Motion control")
    motion_init()
    motor_action(:forward)
    duty_cycles = [100, 50, 0]
    Enum.map(duty_cycles, fn value -> motion_pwm(value) end)
  end

  @doc """
  Tests servo motor a
  Example:
      iex> FB_HardwareTesting.test_servo_a
      Testing Servo Motor a
      {:ok, #PID<0.238.0>}
  """
  def test_servo_a do
    Logger.debug("Testing Servo Motor a ")
    Logger.remove_backend(:console)
    pid = ServoKit.init_standard_servo()
    ServoKit.set_angle(pid, 0, 0)	# args(pid, channel, angle in degrees)
    Process.sleep(1000)
    ServoKit.set_angle(pid, 0, 180)	# args(pid, channel, angle in degrees)
    Logger.add_backend(:console)
  end

  @doc """
  Tests servo motor b
  Example:
      iex> FB_HardwareTesting.test_servo_b
      Testing Servo Motor b
      {:ok, #PID<0.238.0>}
  """
  def test_servo_b do
    Logger.debug("Testing Servo Motor b ")
    Logger.remove_backend(:console)
    pid = ServoKit.init_standard_servo()
    ServoKit.set_angle(pid, 1, 180)	# args(pid, channel, angle in degrees)
    Process.sleep(1000)
    ServoKit.set_angle(pid, 1, 0)	# args(pid, channel, angle in degrees)
    Logger.add_backend(:console)
  end

  @doc """
  Tests white line sensor modules reading
  Example:
      iex> FB_HardwareTesting.test_wlf_sensors
      [958, 851, 969, 975, 943]  // on white surface
      [449, 356, 312, 321, 267]  // on black surface
  """
  def test_wlf_sensors do
    Logger.debug("Testing white line sensors connected ")
    sensor_ref = Enum.map(@sensor_pins, fn {atom, pin_no} -> configure_sensor({atom, pin_no}) end)
    sensor_ref = Enum.map(sensor_ref, fn{_atom, ref_id} -> ref_id end)
    sensor_ref = Enum.zip(@ref_atoms, sensor_ref)
    get_lfa_readings([0,1,2,3,4], sensor_ref)
  end

  @doc """
  Tests IR Proximity sensor's readings
  Example:
      iex> FB_HardwareTesting.test_ir
      [1, 1]     // No obstacle
      [1, 0]     // Obstacle in front of Right IR Sensor
      [0, 1]     // Obstacle in front of Left IR Sensor
      [0, 0]     // Obstacle in front of both Sensors
  Note: You can adjust the potentiometer provided on the IR sensor to get proper results
  """
  def test_ir do
    Logger.debug("Testing IR Proximity Sensors")
    ir_ref = Enum.map(@ir_pins, fn {_atom, pin_no} -> Circuits.GPIO.open(pin_no, :input, pull_mode: :pullup) end)
    ir_values = Enum.map(ir_ref,fn {_, ref_no} -> Circuits.GPIO.read(ref_no) end)
  end


  #-------------------------------------------------------------------
  @doc """
  Function to configure buzzer pin as output
  """
  def buzzer_init do
    GPIO.set_mode(@buzzer_pin[:buz], :output)
  end

  @doc """
  Function to configure motor pins as output
  """
  def motion_init do
    Enum.map(@motor_pins, fn {_atom, pin_no} -> GPIO.set_mode(pin_no, :output) end)
    motor_action(:stop)
    Enum.each(@pwm_pins, fn {_atom, pin_no} -> Pwm.gpio_pwm(pin_no, @duty_cycle) end)
  end

  #-------------------------------------------------------------------
  @doc """
  Supporting function for test_buzzer
  Controls the status of buzzer by giving any of the following agrument:
  [:high, :low, :on, :off]
  Example:
    iex> FB_HardwareTesting.buzzer_control(:high)
    :ok
  """
  def buzzer_control(status) do
    GPIO.write(@buzzer_pin[:buz], @level[status])
  end

  @doc """
  Supporting function for test_motion
  Sets the direction of motors by giving any of the following agrument:
  [:forward, :backward, :left, :right, :stop]
  Example:
    iex> FB_HardwareTesting.motor_action(:forward)
    :ok
  """
  def motor_action(motion) do
    @motor_pins |> Enum.zip(@motion_list[motion]) |> Enum.each(fn {{_atom, pin_no}, value} -> GPIO.write(pin_no, value) end)
  end

  @doc """
  Supporting function for test_pwm
  Note: "motor" can take any one value from following: [:left, :right] and
  "duty" variable can take value from 0 to 255. Value 255 indicates 100% duty cycle
  Example:
    iex> FB_HardwareTesting.pwm(:left, 100)
    :ok
  """
  def pwm(motor, duty) do
    Pwm.gpio_pwm(@pwm_pins[motor], duty)
  end

  #-------------------------------------------------------------------
  @doc """
  Supporting function for test_pwm
  """
  defp motion_pwm(value) do
    IO.puts("Forward with pwm value = #{value}")
    pwm(:left, value)
    pwm(:right, value)
    Process.sleep(2000)
  end

  @doc """
  Supporting function for test_wlf_sensors
  Configures sensor pins as input or output
  [cs: output, clock: output, address: output, dataout: input]
  """
  defp configure_sensor({atom, pin_no}) do
    if (atom == :dataout) do
      Circuits.GPIO.open(pin_no, :input, pull_mode: :pullup)
    else
      Circuits.GPIO.open(pin_no, :output)
    end
  end

  @doc """
  Supporting function for test_wlf_sensors
  Reads the sensor values into an array. "sensor_list" is used to provide list
  of the sesnors for which readings are needed
  The values returned are a measure of the reflectance in abstract units,
  with higher values corresponding to lower reflectance (e.g. a black
  surface or void)
  """
  defp get_lfa_readings(sensor_list, sensor_ref) do
    append_sensor_list = sensor_list ++ [5]
    temp_sensor_list = [5 | append_sensor_list]
    [_ | sensor_data] = append_sensor_list
        |> Enum.with_index
        |> Enum.map(fn {sens_num, sens_idx} ->
              analog_read(sens_num, sensor_ref, Enum.fetch(temp_sensor_list, sens_idx))
              end)
    Enum.each(0..5, fn n -> provide_clock(sensor_ref) end)
    Circuits.GPIO.write(sensor_ref[:cs], 1)
    Process.sleep(250)
    sensor_data
  end

  @doc """
  Supporting function for test_wlf_sensors
  """
  defp analog_read(sens_num, sensor_ref, {_, sensor_atom_num}) do

    Circuits.GPIO.write(sensor_ref[:cs], 0)
    %{^sensor_atom_num => sensor_atom} = @lf_sensor_map
    Enum.reduce(0..9, @lf_sensor_data, fn n, acc ->
                                          read_data(n, acc, sens_num, sensor_ref, sensor_atom_num)
                                          |> clock_signal(n, sensor_ref)
                                        end)[sensor_atom]
  end

  @doc """
  Supporting function for test_wlf_sensors
  """
  defp read_data(n, acc, sens_num, sensor_ref, sensor_atom_num) do
    if (n < 4) do

      if (((sens_num) >>> (3 - n)) &&& 0x01) == 1 do
        Circuits.GPIO.write(sensor_ref[:address], 1)
      else
        Circuits.GPIO.write(sensor_ref[:address], 0)
      end
      Process.sleep(1)
    end

    %{^sensor_atom_num => sensor_atom} = @lf_sensor_map
    if (n <= 9) do
      Map.update!(acc, sensor_atom, fn sensor_atom -> ( sensor_atom <<< 1 ||| Circuits.GPIO.read(sensor_ref[:dataout]) ) end)
    end
  end

  @doc """
  Supporting function for test_wlf_sensors used for providing clock pulses
  """
  defp provide_clock(sensor_ref) do
    Circuits.GPIO.write(sensor_ref[:clock], 1)
    Circuits.GPIO.write(sensor_ref[:clock], 0)
  end

  @doc """
  Supporting function for test_wlf_sensors used for providing clock pulses
  """
  defp clock_signal(acc, n, sensor_ref) do
    Circuits.GPIO.write(sensor_ref[:clock], 1)
    Circuits.GPIO.write(sensor_ref[:clock], 0)
    acc
  end

end
