defmodule Exhort.NIF.Unimplemented do
  @moduledoc false
  @callback on_unimplemented() :: reference()
end

defmodule Exhort.NIF.RaiseUnimplemented do
  @moduledoc false
  @behaviour Exhort.NIF.Unimplemented

  @impl true
  def on_unimplemented() do
    raise "unimplemented"
  end
end

defmodule Exhort.NIF.LogUnimplemented do
  @moduledoc false
  @behaviour Exhort.NIF.Unimplemented

  require Logger

  @impl true
  def on_unimplemented() do
    Logger.error("unimplemented")
    make_ref()
  end
end
