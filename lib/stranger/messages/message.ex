defmodule Stranger.Messages.Message do
  use Stranger.Schema

  alias Stranger.Messages.Message

  @primary_key false
  embedded_schema do
    field(:conversation_id, :string)
    field(:sender_id, :string)
    field(:content, :string)
    field(:sent_at, :utc_datetime_usec)
  end

  def changeset(attrs) do
    %Message{}
    |> cast(attrs, [:conversation_id, :sender_id, :content])
    |> validate_required([:conversation_id, :sender_id, :content])
    |> put_change(:sent_at, DateTime.utc_now())
  end
end
