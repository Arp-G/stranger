defmodule Stranger.Messages do
  alias Stranger.Messages.Message

  @page_size 15

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

  def list_messages_for_conversation(conversation_id, page \\ 1) do
    Mongo.find(
      :mongo,
      "messages",
      %{"conversation_id" => conversation_id},
      sort: %{"sent_at" => 1},
      skip: (page - 1) * @page_size,
      limit: @page_size
    )
    |> Enum.map(&Message.to_struct/1)
  end
end
