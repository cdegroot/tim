defmodule OutdoorTemp.Server do
  @rtl_433_cmd "rtl_433 -R 73"

  use GenServer
  require Logger

  defmodule State do
    defstruct [:port, :id]
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  ## Server side

  def init([]) do
    Logger.info("Starting rtl_433 reader")
    port = Port.open({:spawn, @rtl_433_cmd}, [{:line, 132}, :stderr_to_stdout])
    {:ok, %State{port: port}}
  end
  
  def handle_info({_port, {:data, {:eol, '\tSensor ID:\t ' ++ sensor_id}}}, state) do
    {:noreply, %State{state | id: to_string(sensor_id)}}
  end

  def handle_info({_port, {:data, {:eol, '\tTemperature:\t ' ++ temp}}}, state) do
    # We get a charlist with 'x.x C' here
    temp = temp
    |> to_string
    |> String.split(" ")
    |> hd
    |> String.to_float
    Logger.info("  temp for #{state.id} is #{inspect temp}")
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.info(" ignore #{inspect msg}")
    {:noreply, state}
  end
end
