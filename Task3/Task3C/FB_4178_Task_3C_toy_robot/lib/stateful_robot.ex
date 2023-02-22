defmodule ToyRobot.StatefulRobot do
  alias ToyRobot.StatefulRobot

  def place do
    {:ok, state} = ToyRobot.place
    pid = spawn_link(fn -> listen(state) end)
    Process.register(pid, StatefulRobot)
    pid
  end

  def listen(state) do
    receive do
      {:report, pid} ->
        send(pid, state)
        listen(state)
      {:move} -> ToyRobot.move(state) |> listen
      {:left} -> ToyRobot.left(state) |> listen
      {:right} -> ToyRobot.right(state) |> listen
      {:move_back} -> ToyRobot.move_back(state) |> listen
      {:u_turn} -> ToyRobot.u_turn(state) |> listen
    end
  end

  def move, do: send(StatefulRobot, {:move})

  def left, do: send(StatefulRobot, {:left})

  def right, do: send(StatefulRobot, {:right})

  def move_back, do: send(StatefulRobot, {:move_back})

  def u_turn, do: send(StatefulRobot, {:u_turn})

  def report do
    send(StatefulRobot, {:report, self()})

    receive do
      state -> ToyRobot.report(state)
    end
  end
end
