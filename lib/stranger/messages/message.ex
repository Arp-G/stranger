defmodule Stranger.Messages.Message do
  use Stranger.Schema

  alias Stranger.Messages.Message

  @primary_key false
  embedded_schema do
    field(:_id, :string)
    field(:conversation_id, :string)
    field(:sender_id, :string)
    field(:content, :string)
    field(:sent_at, :utc_datetime_usec)
  end

  def changeset(
        %{
          conversation_id: %BSON.ObjectId{} = conversation_id,
          sender_id: %BSON.ObjectId{} = sender_id
        } = attrs
      ) do
    changeset(%{
      attrs
      | conversation_id: BSON.ObjectId.encode!(conversation_id),
        sender_id: BSON.ObjectId.encode!(sender_id)
    })
  end

  def changeset(attrs) do
    %Message{}
    |> cast(attrs, [:conversation_id, :sender_id, :content])
    |> validate_required([:conversation_id, :sender_id, :content])
    |> put_change(:sent_at, DateTime.utc_now())
  end

  # Override default from_struct
  def from_struct(conv) do
    conv
    |> super()
    |> Map.merge(%{
      conversation_id:
        if(conv.conversation_id,
          do: BSON.ObjectId.decode!(conv.conversation_id),
          else: conv.conversation_id
        ),
      sender_id:
        if(conv.sender_id, do: BSON.ObjectId.decode!(conv.sender_id), else: conv.sender_id)
    })
    |> Map.drop([:_id])
  end
end
