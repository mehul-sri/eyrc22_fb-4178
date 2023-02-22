defmodule LineFollower do

#--------------------
    use GenServer
    use Bitwise
    alias Pigpiox.{GPIO, Pwm}

#-----------------CONSTANTS---------------------
    @level [high: 1, low: 0, on: 1, off: 0]
    @buzzer_pin [buz: 4]
    @duty_cycle 60
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

    # the pid values
    @proportional 1/5
    @integral 0
    @derivative 1/40

    @buzzer_time 5

    # sequence for the searchLine function
    @search_seq [:forward, :backward, :right, :right, :right, :right,:left, :left, :left, :left, :left, :left, :left]


    @delay 70

    # ratio of power to give to the right wheel (left wheel's gear
    # has some problem due to which it rotate slower on same power)
    @ratio 0.95


    @cnConfirmCount 20
    @dnConfirmCount 5
    @maxbound 10

    # power ratios for turning in left and right directions respectively
    @left_ratio 1.2
    @right_ratio  1

#----------------HELPERS------------------

    # returns the maximum and minimum values read by the sensors.
    def getCalibratedMaxMin(n \\ 58) do
      """
        Parameters
        ----------
        n: number of samples to take
      """
      sensor_ref = Enum.map(@sensor_pins, fn {atom, pin_no} -> configure_sensor({atom, pin_no}) end)
      sensor_ref = Enum.map(sensor_ref, fn{_atom, ref_id} -> ref_id end)
      sensor_ref = Enum.zip(@ref_atoms, sensor_ref)

      maxmin = Enum.reduce(0..n, [0, 1023], fn i, [mx, mn] ->
        if (rem(i, 10) == 0) do

          # take 25 samples by rotating in one direction
          if (i >= 0 and i < 25) do
            Pwm.gpio_pwm(@pwm_pins[:right], floor(@duty_cycle*@right_ratio))
            Pwm.gpio_pwm(@pwm_pins[:left], floor(@duty_cycle))
            motor_action(:right)
            Process.sleep(100)
          end

          # stop at 25
          if (i==25) do
            motor_action(:stop)
            Process.sleep(1000)
          end

          # then take 25 samples by rotating in other direction
          if (i > 25) do
            Pwm.gpio_pwm(@pwm_pins[:right], floor(@duty_cycle*@left_ratio))
            Pwm.gpio_pwm(@pwm_pins[:left], floor(@duty_cycle))
            motor_action(:left)
            Process.sleep(100)
          end
        end

        # get the readings
        readings = get_lfa_readings([0, 1, 2, 3, 4], sensor_ref)

        # calculate the max and min
        [Enum.max([mx | readings]), Enum.min([mn | readings])]
      end)

      motor_action(:stop)
      maxmin
    end

    # gets the readings of the IR sensors
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
      sensor_data
    end

    def analog_read(sens_num, sensor_ref, {_, sensor_atom_num}) do
      Circuits.GPIO.write(sensor_ref[:cs], 0)
      %{^sensor_atom_num => sensor_atom} = @lf_sensor_map
      Enum.reduce(0..9, @lf_sensor_data, fn n, acc ->
            read_data(n, acc, sens_num, sensor_ref, sensor_atom_num)
            |> clock_signal(n, sensor_ref)
          end)[sensor_atom]
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

    # scale the sensor values according to the values fetched during calibration
    def readCalibrated(feedback_state) do
      [max, min] = Agent.get(:maxmin, &(&1))
      normalized_state = Enum.map(feedback_state, fn x ->
        if (x > max) do
          max
        else
          if (x < min) do
            min
          else
            x
          end
        end
      end)

      Enum.map(feedback_state, fn x -> (x - min) / (max - min) end)

      normalized_state
    end

    # returns the power difference required to bring the bot on the line
    def calculatePID(average) do
      kp = Agent.get(:kp, &(&1))
      ki = Agent.get(:ki, &(&1))
      kd = Agent.get(:kd, &(&1))

      # Apply PID algorithm to generate required power difference between two motors, in order to follow the line's curvature
      proportional = average - 2000
      integral = Agent.get(:integral, &(&1)) + proportional
      derivative = proportional - Agent.get(:last_proportional, &(&1))

      Agent.update(:last_proportional, fn _ -> proportional end)
      Agent.update(:integral, fn _ -> integral end)

      power_difference = proportional * kp + integral * ki + derivative * kd
      power_difference = cond do
        power_difference > @duty_cycle -> @duty_cycle
        power_difference < -@duty_cycle -> -@duty_cycle
        true -> power_difference
      end

      power_difference
    end

    # can be used to set the kp, kd, ki values
    def setPid(kp, ki, kd) do
      Agent.update(:kp, fn _ -> kp end)
      Agent.update(:ki, fn _ -> ki end)
      Agent.update(:kd, fn _ -> kd end)
    end

    # calculates the weighted average of the sensor readings
    def calculateAvg(feedback_state) do
      Enum.reduce(Enum.with_index(feedback_state), 0,
        fn {value, ind}, acc -> acc + ind*1000*value end) / Enum.sum(feedback_state)
    end

    # calculate the buzzer for `n` seconds
    def buzzer_buzz(n \\ @buzzer_time) do
      buzzer_init()
      buzzer_control(:high)
      Process.sleep(n*1000)
      buzzer_control(:low)
    end

    # search for a line (when lost) by rotating
    defp searchLine(seq \\ @search_seq)

    defp searchLine([]) do
      sensor_ref = Agent.get(:sensor_ref_agent, &(&1))
      state = get_lfa_readings([0,1,2,3,4], sensor_ref) |> readCalibrated
      if isAllBlack(state) do
        motor_action(:stop)
      else
        motor_action(:forward)
      end
    end

    """
      Parameters
      ----------
      `[head | tail]`: A list containing directions to rotate in
    """
    defp searchLine([head | tail]) do
      sensor_ref = Agent.get(:sensor_ref_agent, &(&1))
      state = get_lfa_readings([0,1,2,3,4], sensor_ref) |> readCalibrated
      |> IO.inspect(label: "searching")

      # rotate unless line is found
      if isAllBlack(state) do
        turn(head)
        searchLine(tail)
      else
        motor_action(:forward)
      end
    end

    # returns true if all sensors give low readings
    defp isAllBlack(feedback_state) do
      Enum.all?(feedback_state, fn x -> x < 700 end)
    end

    # turns the bot to the specified side with some delay
    defp turn(side) do
      Pwm.gpio_pwm(@pwm_pins[:left], @duty_cycle)
      Pwm.gpio_pwm(@pwm_pins[:right], floor(@duty_cycle*@ratio))
      motor_action(side)
      if side == :backward do
        Process.sleep(trunc(@delay))
      else
        Process.sleep(trunc(@delay*1.5))
      end
    end

    # returns true if any 3 of the readings are >= a threshold
    defp isNode?(feedback_state) do
      a= Enum.filter(feedback_state, fn x -> x >= 825 end) |> Enum.count()
      a>=3
      # Enum.sum(feedback_state) > 3600
    end

    # # confirm if the node detected is really a node and not a zig-zag turn
    # defp confirmNode?(count, node) do
    #   IO.inspect(count)
    #   sensor_ref = Agent.get(:sensor_ref_agent, &(&1))
    #   state = get_lfa_readings([0,1,2,3,4], sensor_ref) |> readCalibrated()
    #   if (!isNode?(state)) do

    #     IO.inspect("Node Crossed")
    #     motor_action(:stop)
    #     if (node == :dn && count >= @cnConfirmCount || (count >= @dnConfirmCount and count <= @maxbound) ) do
    #         true
    #     else
    #         false
    #     end
    #   else

    #     # if isNode?(state)  do
    #       average = calculateAvg(state)
    #       power_difference = floor(calculatePID(average))
    #       duty_multiple =1
    #       if (power_difference >= 0) do
    #         Pwm.gpio_pwm(@pwm_pins[:left], floor(@duty_cycle))
    #         # Pwm.gpio_pwm(@pwm_pins[:right], floor((@duty_cycle)*67.5/70))
    #         Pwm.gpio_pwm(@pwm_pins[:right], floor((@duty_cycle - power_difference)*@ratio*duty_multiple))
    #         # Pwm.gpio_pwm(@pwm_pins[:left], @duty_cycle)
    #         # Pwm.gpio_pwm(@pwm_pins[:right], @duty_cycle)
    #       else
    #         # Pwm.gpio_pwm(@pwm_pins[:left], @duty_cycle)
    #         # Pwm.gpio_pwm(@pwm_pins[:right], @duty_cycle)
    #         Pwm.gpio_pwm(@pwm_pins[:left], floor((@duty_cycle + power_difference)*duty_multiple))
    #         Pwm.gpio_pwm(@pwm_pins[:right], floor(@duty_cycle * duty_multiple*@ratio))
    #       # Pwm.gpio_pwm(@pwm_pins[:left], @duty_cycle)
    #       # Pwm.gpio_pwm(@pwm_pins[:right], floor(@duty_cycle*@ratio))
    #       end
    #       motor_action(:forward)
    #       Process.sleep(floor(@delay/2))
    #       motor_action(:stop)
    #       Process.sleep(floor(@delay/2))
    #       confirmNode?(count+1, node)
    #     # else
    #     #   false
    #     # end
    #   end
    # end


# ----------------Wrappers-------------------
    def start_link() do
      Agent.start_link(fn -> 0 end, name: :integral)
      Agent.start_link(fn -> 0 end, name: :last_proportional)
      Agent.start_link(fn -> 2 end, name: :kp)
      Agent.start_link(fn -> 0 end, name: :ki)
      Agent.start_link(fn -> 1/10 end, name: :kd)
      Agent.start_link(fn -> 0 end, name: :nodes)
      Agent.start_link(fn -> :cn end, name: :node)
      Agent.start_link(fn -> 0 end, name: :current_node)
      Agent.start_link(fn -> 0 end, name: :last_time)
      Agent.start_link(fn -> :north end, name: :moving_direction)
      Agent.start_link(fn -> true end, name: :handle_cast_done)
      Agent.start_link(fn -> [1023, 0] end, name: :maxmin)
      Agent.start_link(fn -> false end, name: :stop_function)

      GenServer.start_link(__MODULE__, [])
    end

    def buzzer_init do
      GPIO.set_mode(@buzzer_pin[:buz], :output)
    end

    def buzzer_control(status) do
      GPIO.write(@buzzer_pin[:buz], @level[status])
    end


    def lfa_updater(pid) do
      GenServer.cast(pid,{:get_lfa_readings, pid})
      # lfa_updater(pid)
    end

    def state_checker(pid) do
      GenServer.call(pid, :check_state)
    end

    def move_to_next_node(pid) do
      Agent.update(:handle_cast_done, fn _ -> false end)
      GenServer.cast(pid,:move_to_next_node)
    end

    defp configure_sensor({atom, pin_no}) do
      if (atom == :dataout) do
        Circuits.GPIO.open(pin_no, :input, pull_mode: :pullup)
      else
        Circuits.GPIO.open(pin_no, :output)
      end
    end

    def provide_clock(sensor_ref) do
      Circuits.GPIO.write(sensor_ref[:clock], 1)
      Circuits.GPIO.write(sensor_ref[:clock], 0)
    end

    defp clock_signal(acc, _, sensor_ref) do
      Circuits.GPIO.write(sensor_ref[:clock], 1)
      Circuits.GPIO.write(sensor_ref[:clock], 0)
      acc
    end

    def motion_init do
      Enum.map(@motor_pins, fn {_atom, pin_no} -> GPIO.set_mode(pin_no, :output) end)
      motor_action(:stop)
      Enum.each(@pwm_pins, fn {_atom, pin_no} -> Pwm.gpio_pwm(pin_no, @duty_cycle) end)
    end

    def motor_action(motion) do
      @motor_pins |> Enum.zip(@motion_list[motion]) |> Enum.each(fn {{_atom, pin_no}, value} -> GPIO.write(pin_no, value) end)
    end

    def start_motion(p \\@proportional,i \\ @integral,d \\ @derivative) do
      Agent.update(:sensor_ref_agent, fn _ ->
        sensor_ref = Enum.map(@sensor_pins, fn {atom, pin_no} -> configure_sensor({atom, pin_no}) end)
        sensor_ref = Enum.map(sensor_ref, fn{_atom, ref_id} -> ref_id end)
        Enum.zip(@ref_atoms, sensor_ref)
      end)
      motion_init()
      setPid(p, i, d)
      motor_action(:stop)
      maxmin = getCalibratedMaxMin()
      |> IO.inspect(label: "maxmin")
      Agent.update(:maxmin, fn _ -> maxmin end)

      Process.sleep(500)
    end


#----------------Callbacks--------------------

    def init(_state) do
      # Initialize Line Follower Array
      state = [0,0,0,0,0]
      {:ok, state}
    end

    def handle_cast({:get_lfa_readings,pid}, _feedback_state) do
      # Get feedback readings from camera or linefollower array here and update state

      sensor_ref = Agent.get(:sensor_ref_agent, &(&1))
      normalized_state = if (sensor_ref != 0) do
        new_state = get_lfa_readings([0,1,2,3,4], sensor_ref)
        # Normalize readings with respecct to Calibrated Minimum and Maximum values that your sensors give.
        readCalibrated(new_state)
      else
        [0, 0, 0, 0, 0]
      end
      GenServer.cast(pid,{:get_lfa_readings,pid})
      {:noreply, normalized_state}
    end

    def handle_cast(:move_to_next_node, feedback_state) do
      sensor_ref = Agent.get(:sensor_ref_agent, &(&1))
      new_state = get_lfa_readings([0,1,2,3,4], sensor_ref)

      # Normalize readings with respecct to Calibrated Minimum and Maximum values that your sensors give.
      normalized_state = readCalibrated(new_state) |> IO.inspect

      node = Agent.get(:node, &(&1))
      if isAllBlack(normalized_state) do
        motor_action(:stop)
        searchLine()
      end
      if isNode?(normalized_state) do
        IO.inspect("called")
        motor_action(:stop)
        Process.sleep(200)
        Pwm.gpio_pwm(@pwm_pins[:left], @duty_cycle)
        Pwm.gpio_pwm(@pwm_pins[:right], floor(@duty_cycle*@ratio))
        # if confirmNode?(0, node) do
        if true do
          IO.inspect("Node detected")
          IO.inspect(normalized_state)

          # TODO: remove two lines below
          motor_action(:stop)
          Process.sleep(200)
          Pwm.gpio_pwm(@pwm_pins[:left], @duty_cycle)
          Pwm.gpio_pwm(@pwm_pins[:right], floor(@duty_cycle*@ratio))

          motor_action(:forward)
          IO.inspect(node)
          if (node == :cn) do
            Process.sleep(trunc(290) |> IO.inspect(label: "1"))
          else
            Process.sleep(trunc(420) |> IO.inspect(label: "2"))
          end
          motor_action(:stop)
          Process.sleep(200)
          Agent.update(:handle_cast_done, fn _ -> true end)
        else
          motor_action(:forward)
          if (!Agent.get(:stop_function, &(&1))) do
            handle_cast(:move_to_next_node, [0, 0, 0, 0, 0])
          end
        end
      else

        average = calculateAvg(normalized_state)
        power_difference = floor(calculatePID(average))

        duty_multiple = if (node == :dn) do
          1
        else
          1
        end
        # Apply PWM to motors accordingly
        if (power_difference >= 0) do
          Pwm.gpio_pwm(@pwm_pins[:left], floor(@duty_cycle))
          Pwm.gpio_pwm(@pwm_pins[:right], floor((@duty_cycle - power_difference)*@ratio*duty_multiple))
        else
          Pwm.gpio_pwm(@pwm_pins[:left], floor((@duty_cycle + power_difference)*duty_multiple))
          Pwm.gpio_pwm(@pwm_pins[:right], floor(@duty_cycle * duty_multiple*@ratio))
        end

        motor_action(:forward)
        if (!Agent.get(:stop_function, &(&1))) do
          handle_cast(:move_to_next_node, [0, 0, 0, 0, 0])
        end
      end

      {:noreply, feedback_state}
    end


    def handle_call(:check_state,_from, feedback_state) do
      # Get feedback readings from camera or linefollower array here and update state
      return_val = feedback_state
      {:reply, return_val, feedback_state}
    end

end
