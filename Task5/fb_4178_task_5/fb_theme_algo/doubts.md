## Doubts
- calling `get_lfa_readings` manually is better or using the `GenServer.cast(pid,{:get_lfa_readings, pid})` and then `GenServer.call(pid, :check_state)`