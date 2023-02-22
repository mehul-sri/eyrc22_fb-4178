defmodule Task4c.Main do
@moduledoc """
  A client module implementing line following logic for Alphabot
  """

  def main() do
    IO.puts("Starting bot in 5 sec...")
    Process.sleep(5000)
    Agent.start_link(fn -> 0 end, name: :sensor_ref_agent)
    {:ok, pid} = Task4c.LineFollower.start_link()
    #{:ok, #PID<0.180.0>}
    feedback = Task4c.LineFollower.state_checker(pid)
    #[0, 0, 0, 0, 0]
    success = Task4c.LineFollower.lfa_updater(pid)
    # :ok
    feedback = Task4c.LineFollower.state_checker(pid)
    #[134, 124, 156, 653, 735]
    IO.inspect(feedback, label: "Feedback")

    feedback = Task4c.LineFollower.state_checker(pid)

    Task4c.LineFollower.start_motion()
    # Task4c.LineFollower.motor_action(:stop)
    # for i <- 0..300 do
    Task4c.LineFollower.move_to_next_node(pid)
    # end
    # Task4c.LineFollower.motor_action(:stop)
    #[134, 124, 156, 653, 735]
    IO.inspect(feedback, label: "Feedback")
  end

end
