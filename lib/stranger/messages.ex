defmodule Stranger.Messages do
  alias Stranger.Messages.Message

  def create_message(attrs) do
    attrs
    |> Message.changeset()
    |> case do
      %Ecto.Changeset{valid?: true} = changset ->
        args_map =
          changset
          |> Ecto.Changeset.apply_changes()
          |> Message.from_struct()

        Mongo.insert_one(:mongo, "messages", args_map)

      changeset ->
        changeset
    end
  end
end
