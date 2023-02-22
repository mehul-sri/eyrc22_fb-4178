
defmodule FBThemeAlgo do

  alias Pigpiox.{Pwm}

  @level [high: 1, low: 0, on: 1, off: 0]
  @buzzer_pin [buz: 4]

  @duty_cycle 65

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
  @cell_map %{ 1 => [2],
    2 => [1, 3, 5],
    3 => [2, 6],
    4 => [5, 7],
    5 => [2, 4, 8],
    6 => [3],
    7 => [4,8],
    8 => [5, 7, 9],
    9 => [8]
    }

  @matrix_of_sum [[14, "na", "na"], ["na", "na", 12], ["na", "na", "na"]]

  @rcm_set [3, 8, 7, 1, 5, 2]

  @angles %{
    1 => 20,
    2 => 36,
    3 => 53,
    4 => 70,
    5 => 85,
    6 => 105,
    7 => 120,
    8 => 148,
    9 => 169
  }

  @cn 0
  @dn 1

  @ratio 0.95
  @left_ratio 1.2
  @right_ratio  1


  # def set_angle(rcm) do

  # end

  # def dispense(rcm_set) do

  # end
  def get_direction(curr_node,next_node) do
    sub = next_node - curr_node
    case sub do
      1 -> :west
      -1 -> :east
      3 -> :north
      -3 -> :south
    end
  end

  def get_rotation_direction(curr_dir,moving_dir) do
    case {curr_dir,moving_dir} do
      {:north,:west} -> :left
      {:north,:east} -> :right
      {:south,:west} -> :right
      {:south,:east} -> :left
      {:west,:north} -> :right
      {:west,:south} -> :left
      {:east,:north} -> :left
      {:east,:south} -> :right
    end
  end

  def rotate(rotation) do
    if rotation == :left do
      Pwm.gpio_pwm(@pwm_pins[:left], @duty_cycle)
      Pwm.gpio_pwm(@pwm_pins[:right], floor(@duty_cycle*@left_ratio))
    else
      Pwm.gpio_pwm(@pwm_pins[:left], @duty_cycle)
      Pwm.gpio_pwm(@pwm_pins[:right], floor(@duty_cycle*@right_ratio))
    end

    LineFollower.motor_action(rotation)
    Process.sleep(320)
    LineFollower.motor_action(:stop)
    IO.puts("rotating...")

    rotation |> IO.inspect
  end

  def turn(curr_node,next_node) do
    moving_dir = get_direction(curr_node,next_node)
    curr_dir = Agent.get(:moving_direction, fn x -> x end)
    #do nothing
    if (curr_dir != moving_dir) do
      rotation = get_rotation_direction(curr_dir,moving_dir)
      rotation = cond do
        rotation == :left -> :right
        rotation == :right -> :left
      end
      rotate(rotation)
      rotation
    else
      :straight
    end

  end

  def rollback_if_not_path(rotation) do
    # feedback = LineFollower.get_lfa_readings(@sensor_)
    sensor_ref = Agent.get(:sensor_ref_agent, &(&1))
    feedback = LineFollower.get_lfa_readings([0,1,2,3,4], sensor_ref)
    normalized_state = LineFollower.readCalibrated(feedback)
    if Enum.all?(normalized_state,fn x -> x>800 end) or Enum.all?(normalized_state,fn x-> x<500 end) do
      LineFollower.motor_action(:forward)
      Process.sleep(150)
      rotation = if rotation == :left do
        :right
      else
        :left
      end
      rotate(rotation)

    end
  end

  def wait_until_handled() do
    if (!Agent.get(:handle_cast_done, &(&1))) do
      Process.sleep(100)
      wait_until_handled()
    end
  end

  def run_and_drop(dispense_pid, pid,rcm, [head|tail]) do

    Agent.update(:current_node, fn _ -> head end)
    if Enum.empty?(tail)   do
      #dispense
      IO.puts("Empty")
      LineFollower.motor_action(:stop)
      DispenserMechanism.dispense(dispense_pid,rcm)
    else
      rotate = turn(head,Enum.at(tail,0))
      IO.inspect(Agent.get(:moving_direction, &(&1)))
      if rotate != :straight do
        rollback_if_not_path(rotate) #if it is not a path, it will rollback
      end
      # LineFollower.motor_action(:forward)
      LineFollower.move_to_next_node(pid) #update handle_cast such that if it goes out of line it will stop and search for line from -135 to 135
      Agent.update(:moving_direction, fn _ -> get_direction(head, Enum.at(tail, 0)) end)
      wait_until_handled()

      node = Agent.get(:node, fn x -> x end)
      node = if node == @cn, do: @dn, else: @cn
      Agent.update(:node, fn _ -> node end)

      if node == @cn do
        run_and_drop(dispense_pid,pid,rcm,[head|tail])
      else
        run_and_drop(dispense_pid,pid,rcm,tail)
      end
    end
  end

  def main(cell_map \\ @cell_map, matrix_of_sum \\ @matrix_of_sum , array_of_digit \\ @rcm_set) do
    # IO.puts("Starting bot in 5 sec...")
    # Process.sleep(5000)

    #algorithms
    [optimal_rcm_distribution,optimal_path,matrix_and_position] = Algorithm.algo_run(cell_map,matrix_of_sum,array_of_digit)

    dispense_pid = ServoKit.init_standard_servo()
    ServoKit.set_angle(dispense_pid,0,85)
    pid = init()
    LineFollower.motor_action(:forward)

    Agent.update(:node, fn _ -> @cn end)
    Agent.update(:moving_direction, fn _ -> :west end)
    LineFollower.move_to_next_node(pid)
    # LineFollower.handle_cast(:move_to_next_node, [0, 0, 0, 0, 0])
    wait_until_handled()
    Agent.update(:node, fn _ -> @dn end)

    IO.puts("Abhinav")

    IO.inspect(optimal_path)

    Enum.map(optimal_path,fn {key,value} -> run_and_drop(dispense_pid,pid,Enum.at(optimal_rcm_distribution[matrix_and_position[key]], 0),value) end)

    # LineFollower.buzzer_buzz(1)
    # # for i <- 0..300 do
    # LineFollower.move_to_next_node(pid)
    # end
    # Task4c.LineFollower.motor_action(:stop)
    #[134, 124, 156, 653, 735]

    LineFollower.motor_action(:stop)
  end

  def move_forward() do
    init()
    LineFollower.motor_action(:forward)

    Agent.update(:node, fn _ -> @dn end)
    Agent.update(:moving_direction, fn _ -> :west end)

    Pwm.gpio_pwm(@pwm_pins[:left], floor(@duty_cycle))
    Pwm.gpio_pwm(@pwm_pins[:right], floor(@duty_cycle*@ratio))
  end

  def init() do
    #intialization
    Agent.start_link(fn -> 0 end, name: :sensor_ref_agent)
    {:ok, pid} = LineFollower.start_link()
    #{:ok, #PID<0.180.0>}
    LineFollower.state_checker(pid)
    #[0, 0, 0, 0, 0]
    LineFollower.lfa_updater(pid)
    # :ok
    LineFollower.state_checker(pid)
    #[134, 124, 156, 653, 735]
    # IO.inspect(feedback, label: "Feedback")

    LineFollower.state_checker(pid)
    # feedback = LineFollower.get_lfa_readings([0, 1, 2, 3, 4], )
    # IO.inspect(feedback, label: "Feedback")

    LineFollower.start_motion()
    # Agent.update(:handle_cast_done, fn _ -> false end)

    pid
  end

  def reset() do
    Agent.update(:integral, fn _ -> 0 end)
    Agent.update(:last_proportional, fn _ -> 0 end)
    Agent.update(:kp, fn _ -> 1/10 end)
    Agent.update(:ki, fn _ -> 0 end)
    Agent.update(:kd, fn _ -> 1/100 end)
    Agent.update(:nodes, fn _ -> 0 end)
    Agent.update(:node, fn _ -> 0 end)
    Agent.update(:current_node, fn _ -> 0 end)
    Agent.update(:last_time, fn _ -> 0 end)
    Agent.update(:moving_direction, fn _ -> :north end)
  end

  def move() do
    pid = init()
    LineFollower.motor_action(:forward)
    Agent.update(:node, fn _ -> @cn end)
    LineFollower.move_to_next_node(pid)
    # LineFollower.motor_action(:forward)
    # Agent.update(:node, fn _ -> @dn end)
    # LineFollower.move_to_next_node(pid)
  end

  def stop() do
    Agent.update(:stop_function, fn _ -> true end)
    Process.sleep(200)
    LineFollower.motor_action :stop
  end

  def rotate(dir,time,speed \\ @duty_cycle,ratio \\ @ratio) do
    Pwm.gpio_pwm(@pwm_pins[:right], floor(speed*ratio))
    Pwm.gpio_pwm(@pwm_pins[:left], floor(speed))
    LineFollower.motor_action(dir)
    Process.sleep(time*1000)
    # LineFollower.motor_action(:right)
    # Process.sleep(3000)
    LineFollower.motor_action(:stop)
  end
end
