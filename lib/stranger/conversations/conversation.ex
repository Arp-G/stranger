defmodule Stranger.Conversations.Conversation do
  use Stranger.Schema

  alias Stranger.Conversations.Conversation

  @primary_key false
  embedded_schema do
    field(:participant_one_id, :string)
    field(:participant_two_id, :string)
    field(:started_at, :utc_datetime_usec)
    field(:ended_at, :utc_datetime_usec)
  end

  def changeset(attrs) do
    %Conversation{}
    |> cast(attrs, [:participant_one_id, :participant_two_id])
    |> validate_required([:participant_one_id, :participant_two_id])
    |> put_change(:started_at, DateTime.utc_now())
  end
end
