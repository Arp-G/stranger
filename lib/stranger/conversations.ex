defmodule Stranger.Conversations do
  alias Stranger.Conversations.Conversation

  def create_conversation(attrs) do
    attrs
    |> Conversation.changeset()
    |> case do
      %Ecto.Changeset{valid?: true} = changset ->
        args_map =
          changset
          |> Ecto.Changeset.apply_changes()
          |> Conversation.from_struct()

        Mongo.insert_one(:mongo, "conversations", args_map)

      changeset ->
        changeset
    end
  end

  def end_conversation(conversation_id) do
    Mongo.update_one(
      :mongo,
      "conversations",
      %{_id: conversation_id},
      %{"$set": %{ended_at: DateTime.utc_now()}}
    )
  end
end
