defmodule Task4c.LineFollower do
  @moduledoc """
    A server module implementing line following logic for Alphabot
    """
  #--------------------
  use GenServer
  use Bitwise
  alias Pigpiox.{GPIO, Pwm}
  #--------------------
  # EXAMPLE USAGE;
  # iex(2)> {:ok, pid} = Task4c.LineFollower.start_link()
  # {:ok, #PID<0.180.0>}
  # iex(3)> Task4c.LineFollower.state_checker(pid)
  # [0, 0, 0, 0, 0]
  # iex(4)> Task4c.LineFollower.lfa_updater(pid)
  # :ok
  # iex(5)> Task4c.LineFollower.state_checker(pid)
  # [134, 124, 156, 653, 735]
  # iex(6)>
  #--------------------

  # NOTE: The functions provided in the boilerplate are for your reference,
  # you’re still free to change arity/arguments of the functions, add new functions,
  # callbacks and add/modify state of GenServer as required by your implementation.

  #-----------------CONSTANTS---------------------
  @level [high: 1, low: 0, on: 1, off: 0]
  @buzzer_pin [buz: 4]
  @calibrated_min 264
  @calibrated_max 964
  @duty_cycle 50
  @diff_error 5
  @lf_sensor_data %{sensor0: 0, sensor1: 0, sensor2: 0, sensor3: 0, sensor4: 0, sensor5: 0}
  @lf_sensor_map %{0 => :sensor0, 1 => :sensor1, 2 => :sensor2, 3 => :sensor3, 4 => :sensor4, 5 => :sensor5}
  @sensor_pins [cs: 5, clock: 25, address: 24, dataout: 23]
  @ref_atoms [:cs, :clock, :address, :dataout]
  @pwm_pins [left: 6, right: 26]
  @motor_pins [lf: 12, lb: 13, rf: 20, rb: 21]
  @motion_list [forward:  [0, 1, 0, 1],
                backward: [1, 0, 1, 0],
                left:     [0, 1, 1, 0],
                right:    [1, 0, 0, 1],
                stop:     [0, 0, 0, 0]]

  #----------------HELPERS------------------

  def getCalibratedMaxMin() do
    sensor_ref = Enum.map(@sensor_pins, fn {atom, pin_no} -> configure_sensor({atom, pin_no}) end)
    sensor_ref = Enum.map(sensor_ref, fn{_atom, ref_id} -> ref_id end)
    sensor_ref = Enum.zip(@ref_atoms, sensor_ref)

    Enum.reduce(0..400, [0, 1023], fn i, [mx, mn] ->
      if (rem(i, 10) == 0) do
        if (i > 0 and i < 100) do
          motor_action(:forward)
        end
        if (i > 100 and i < 200) do
          motor_action(:backward)
        end
        if (i>200 and i<300) do
          motor_action(:right)
        end
        if (i>300) do
          motor_action(:left)
        end
        Pwm.gpio_pwm(@pwm_pins[:left], 50)
        Pwm.gpio_pwm(@pwm_pins[:right], 50)
      end
      # IO.inspect([mx,mn,i])
      readings = get_lfa_readings([0, 1, 2, 3, 4], sensor_ref)
      [Enum.max([mx | readings]), Enum.min([mn | readings])]
    end)

    motor_action(:stop)
  end

  def readCalibrated(feedback_state) do
    # Just an example. Do normalizaton with respect to Min-Max values of your sensor.
    # normalized_state = feedback_state
    normalized_state = Enum.map(feedback_state, fn x ->
      if (x > @calibrated_max) do
        @calibrated_max
      else
        if (x < @calibrated_min) do
          @calibrated_min
        else
          x
        end
      end
    end)


    # NOTE: You can do the Calibration Manually beforehand and add values here.
                            # OR
    # You may calibrate dynamically everytime the robot runs
    Enum.map(feedback_state, fn x -> (x - @calibrated_min) / (@calibrated_max - @calibrated_min) end)

    normalized_state
  end

  def calculatePID(average) do
    # Refer: https://www.waveshare.com/wiki/Tracker_Sensor#Part_3:_PID_control
    # Tune the constants of PID
    # kp = 1.5
    # ki = 0
    # kd = 1/10
    kp = Agent.get(:kp, &(&1))
    ki = Agent.get(:ki, &(&1))
    kd = Agent.get(:kd, &(&1))
    # Apply PID algorithm to generate required power difference between two motors, in order to follow the line's curvature

    proportional = average - 2000
    # |> IO.inspect(label: "p")
    integral = Agent.get(:integral, &(&1)) + proportional
    # |> IO.inspect(label: "i")
    derivative = proportional - Agent.get(:last_proportional, &(&1))
    # |> IO.inspect(label: "d")

    # last_proportional = proportional;
    Agent.update(:last_proportional, fn _ -> proportional end)
    Agent.update(:integral, fn _ -> integral end)

    # power_difference = 0 # Apply your equation here
    power_difference = proportional * kp + integral * ki + derivative * kd
    # |> IO.inspect(label: "pd")
    power_difference = cond do
      power_difference > @duty_cycle -> @duty_cycle
      # power_difference > @duty_cycle-@diff_error -> @duty_cycle-@diff_error
      power_difference < -@duty_cycle -> -@duty_cycle
      true -> power_difference
    end

    power_difference
  end

  def setPid(kp, ki, kd) do
    Agent.update(:kp, fn _ -> kp end)
    Agent.update(:ki, fn _ -> ki end)
    Agent.update(:kd, fn _ -> kd end)
  end

  def calculateAvg(feedback_state) do
    # Refer : https://www.waveshare.com/wiki/Tracker_Sensor#Part_2:_Weighted_average
    Enum.reduce(Enum.with_index(feedback_state), 0,
      fn {value, ind}, acc -> acc + ind*1000*value end) / Enum.sum(feedback_state)

  end

  #----------------Wrappers-------------------
  def start_link() do
    Agent.start_link(fn -> 0 end, name: :integral)
    Agent.start_link(fn -> 0 end, name: :last_proportional)
    Agent.start_link(fn -> 2 end, name: :kp)
    Agent.start_link(fn -> 0 end, name: :ki)
    Agent.start_link(fn -> 1/10 end, name: :kd)
    Agent.start_link(fn -> 0 end, name: :nodes)
    GenServer.start_link(__MODULE__, [])
  end

  def lfa_updater(pid) do
    GenServer.cast(pid,{:get_lfa_readings, pid})
    # lfa_updater(pid)
  end

  def state_checker(pid) do
    GenServer.call(pid, :check_state)
  end

  def move_to_next_node(pid) do
    GenServer.cast(pid,:move_to_next_node)
    # Process.sleep(10)
    # move_to_next_node(pid)
  end

  #----------------Callbacks--------------------

  def init(_state) do
    # Initialize motor directions and speeds
    # Initialize Line Follower Array
    state = [0,0,0,0,0]
    {:ok, state}
  end

  def handle_cast({:get_lfa_readings,pid}, _feedback_state) do
    # Get feedback readings from camera or linefollower array here and update state
    # dummy_val = Enum.at(feedback_state, 0) + 1
    # new_state = [dummy_val,124,156,653,735]

    # sensor_ref = Enum.map(@sensor_pins, fn {atom, pin_no} -> configure_sensor({atom, pin_no}) end)
    # sensor_ref = Enum.map(sensor_ref, fn{_atom, ref_id} -> ref_id end)
    # sensor_ref = Enum.zip(@ref_atoms, sensor_ref)
    # IO.inspect(sensor_ref)
    sensor_ref = Agent.get(:sensor_ref_agent, &(&1))
    normalized_state = if (sensor_ref != 0) do
      new_state = get_lfa_readings([0,1,2,3,4], sensor_ref)
      # Normalize readings with respecct to Calibrated Minimum and Maximum values that your sensors give.
      readCalibrated(new_state)
    else
      [0, 0, 0, 0, 0]
    end
    # IO.inspect([normalized_state, Enum.sum(normalized_state)])
    GenServer.cast(pid,{:get_lfa_readings,pid})
    {:noreply, normalized_state}
  end

  def handle_cast(:move_to_next_node, feedback_state) do
    # Main goal of the function: Use feedback and apply actuation to maintain and follow line
    # (until a node is detected)

    # Use Weighted Averages and PID algorithm to make decision about actuation of motors
    # t1 = Time.utc_now()
    sensor_ref = Agent.get(:sensor_ref_agent, &(&1))
    new_state = get_lfa_readings([0,1,2,3,4], sensor_ref)
    # Normalize readings with respecct to Calibrated Minimum and Maximum values that your sensors give.
    normalized_state = readCalibrated(new_state)
    # |> IO.inspect
    # motor_action(:stop)

    if false do
    # if isBoundary(normalized_state) do
      motor_action(:stop)
      Agent.update(:last_proportional, fn _ -> 0 end)
      Agent.update(:integral, fn _ -> 0 end)
      IO.puts("BOUNDARY")
    else

      if isNode(normalized_state) do
        IO.puts("Node detected")
        motor_action(:stop)
        Process.sleep(180)
        Pwm.gpio_pwm(@pwm_pins[:left], @duty_cycle)
        Pwm.gpio_pwm(@pwm_pins[:right], floor(@duty_cycle*67.5/70))
        motor_action(:forward)
        Process.sleep(300)

        nodes = Agent.get(:nodes, &(&1))
        |> IO.inspect()

        if (nodes == 1) do
          IO.puts("Turning right")
          motor_action(:left)
          Process.sleep(500)
          motor_action(:stop)
        end
        if (nodes == 3) do
          motor_action(:stop)
          IO.puts("buzzing...")
          buzzer_buzz()
          IO.puts("Completed")
        else
          Agent.update(:nodes, fn _ -> nodes+1 end)
          motor_action(:forward)
          handle_cast(:move_to_next_node, [0, 0, 0, 0, 0])
        end
      else

        # IO.inspect(normalized_state)

        average = calculateAvg(normalized_state)
        power_difference = floor(calculatePID(average))
        # power_difference = -10
        # IO.inspect(power_difference)
        # t2 = Time.utc_now()

        # Apply PWM to motors accordingly
        if (power_difference >= 0) do
          Pwm.gpio_pwm(@pwm_pins[:left], @duty_cycle)
          Pwm.gpio_pwm(@pwm_pins[:right], floor((@duty_cycle - power_difference)*67.5/70))
          # IO.inspect(power_difference,label: "power_diff")
        else
          Pwm.gpio_pwm(@pwm_pins[:left], @duty_cycle + power_difference)
          Pwm.gpio_pwm(@pwm_pins[:right], floor(@duty_cycle * 67.5/70))
        end
        # t3 = Time.utc_now()
        #  IO.inspect([Time.diff(t2, t1, :microsecond), Time.diff(t2, t3, :microsecond)])

        # Pwm.gpio_pwm(@pwm_pins[:left], @duty_cycle)
        # Pwm.gpio_pwm(@pwm_pins[:right], floor(@duty_cycle*67.5/70))
        # Pwm.gpio_pwm(@pwm_pins[:right], floor(@duty_cycle))
        # GenServer.cast(:move_to_next_node)
        handle_cast(:move_to_next_node, [0, 0, 0, 0, 0])
      end

    end

    {:noreply, feedback_state}
  end

  def buzzer_buzz do
    # Logger.debug("Testing Buzzer connected ")
    buzzer_init()
    buzzer_control(:high)
    Process.sleep(5000)
    buzzer_control(:low)
  end

  def buzzer_init do
    GPIO.set_mode(@buzzer_pin[:buz], :output)
  end

  def buzzer_control(status) do
    GPIO.write(@buzzer_pin[:buz], @level[status])
  end


  defp isNode(feedback_state) do
    Enum.filter(feedback_state, fn value -> value > 900 end)
    |> Enum.count >= 3
  end

  defp isBoundary(feedback_state) do
    # IO.inspect(feedback_state, label: "Feedback")
    Enum.filter(feedback_state, fn value -> value > 900 end)
    # |> IO.inspect(label: "Boundary")
    |> Enum.count() == 5
  end

  defp configure_sensor({atom, pin_no}) do
    if (atom == :dataout) do
      Circuits.GPIO.open(pin_no, :input, pull_mode: :pullup)
    else
      Circuits.GPIO.open(pin_no, :output)
    end
  end

  def get_lfa_readings(sensor_list, sensor_ref) do
    append_sensor_list = sensor_list ++ [5]
    temp_sensor_list = [5 | append_sensor_list]
    [_ | sensor_data] = append_sensor_list
        |> Enum.with_index
        |> Enum.map(fn {sens_num, sens_idx} ->
              analog_read(sens_num, sensor_ref, Enum.fetch(temp_sensor_list, sens_idx))
              end)
    Enum.each(0..5, fn _ -> provide_clock(sensor_ref) end)
    Circuits.GPIO.write(sensor_ref[:cs], 1)
    # Process.sleep(1)
    sensor_data
  end

  def analog_read(sens_num, sensor_ref, {_, sensor_atom_num}) do

    Circuits.GPIO.write(sensor_ref[:cs], 0)
    %{^sensor_atom_num => sensor_atom} = @lf_sensor_map
    Enum.reduce(0..9, @lf_sensor_data, fn n, acc ->
          read_data(n, acc, sens_num, sensor_ref, sensor_atom_num)
          # |> IO.inspect(label: "read_data")
          |> clock_signal(n, sensor_ref)
        end)[sensor_atom]
  end

  def provide_clock(sensor_ref) do
    Circuits.GPIO.write(sensor_ref[:clock], 1)
    Circuits.GPIO.write(sensor_ref[:clock], 0)
  end

  def read_data(n, acc, sens_num, sensor_ref, sensor_atom_num) do
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

  defp clock_signal(acc, _, sensor_ref) do
    Circuits.GPIO.write(sensor_ref[:clock], 1)
    Circuits.GPIO.write(sensor_ref[:clock], 0)
    acc
  end

  def handle_call(:check_state,_from, feedback_state) do
    # Get feedback readings from camera or linefollower array here and update state
    return_val = feedback_state
    {:reply, return_val, feedback_state}
  end

  def motion_init do
    Enum.map(@motor_pins, fn {_atom, pin_no} -> GPIO.set_mode(pin_no, :output) end)
    motor_action(:stop)
    Enum.each(@pwm_pins, fn {_atom, pin_no} -> Pwm.gpio_pwm(pin_no, @duty_cycle) end)
  end

  def motor_action(motion) do
    @motor_pins |> Enum.zip(@motion_list[motion]) |> Enum.each(fn {{_atom, pin_no}, value} -> GPIO.write(pin_no, value) end)
  end

  def start_motion() do
    Agent.update(:sensor_ref_agent, fn _ ->
      sensor_ref = Enum.map(@sensor_pins, fn {atom, pin_no} -> configure_sensor({atom, pin_no}) end)
      sensor_ref = Enum.map(sensor_ref, fn{_atom, ref_id} -> ref_id end)
      Enum.zip(@ref_atoms, sensor_ref)
    end)
    motion_init()
    setPid(1/10, 0, 1/100)
    motor_action(:forward)
    # Process.sleep(5000)
  end

  def test(action, sleep) do
    motor_action(action)
    Process.sleep(sleep)
    motor_action(:stop)
  end
end
