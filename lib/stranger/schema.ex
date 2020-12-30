defmodule Stranger.SchemaBehaviour do
  @moduledoc """
    Schema behaviour
  """
  @callback to_struct(map()) :: struct()
  @callback from_struct(struct()) :: map()
end

defmodule Stranger.Schema do
  @moduledoc """
    Schema module
  """
  defmacro __using__(_opts) do
    quote do
      @behaviour Stranger.SchemaBehaviour
      use Ecto.Schema
      import Ecto.Changeset
      alias __MODULE__

      # Convert map to struct
      def to_struct(map) do
        map =
          for {key, val} <- map, into: %{} do
            key = if is_atom(key), do: key, else: String.to_atom(key)
            {key, val}
          end

        struct(__MODULE__, map)
      end

      # Convert struct to map
      def from_struct(struct), do: Map.from_struct(struct)

      # This behaviour can be overridden
      # https://hexdocs.pm/elixir/Kernel.html#defoverridable/1
      defoverridable Stranger.SchemaBehaviour
    end
  end
end
