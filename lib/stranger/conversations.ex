defmodule Stranger.Conversations do
  def find_or_create_converastion(participant_one_id, participant_two_id) do
    find_lastest_conversation_for(participant_one_id, participant_one_id) ||
      create_conversation(%{
        participant_one_id: participant_one_id,
        participant_two_id: participant_two_id
      })
  end

  def check_if_user_belongs_to_conversation(user_id, conversation_id) do
    Mongo.find_one(
      :mongo,
      "conversations",
      %{
        _id: conversation_id,
        "$or": [
          %{participant_one_id: user_id},
          %{participant_two_id: user_id}
        ]
      }
    )
  end

  def check_if_conversation_is_active(conversation_id) do
    Mongo.find_one(
      :mongo,
      "conversations",
      %{_id: conversation_id, ended_at: %{"$exists": false}}
    )
  end

  def create_conversation(%{
        participant_one_id: participant_one_id,
        participant_two_id: participant_two_id
      }) do
    {
      :ok,
      %Mongo.InsertOneResult{
        acknowledged: true,
        inserted_id: conversation_id
      }
    } =
      Mongo.insert_one(:mongo, "conversations", %{
        participant_one_id: participant_one_id,
        participant_two_id: participant_two_id,
        started_at: DateTime.utc_now()
      })

    conversation_id
  end

  def update_conversation_with_session(conversation_id, session_id) do
    Mongo.update_one!(:mongo, "conversations", %{_id: conversation_id}, %{
      "$set": %{session_id: session_id}
    })
  end

  def update_conversation_with_end_time(conversation_id) do
    Mongo.update_one!(:mongo, "conversations", %{_id: conversation_id}, %{
      "$set": %{ended_at: DateTime.utc_now()}
    })
  end

  # Find the latest unended conversation for two participants
  def find_lastest_conversation_for(participant_one, pariticipant_two) do
    Mongo.find(
      :mongo,
      "conversations",
      %{
        "$and" => [
          %{
            "$or" => [
              %{
                "$and" => [
                  %{"participant_one_id" => participant_one},
                  %{"participant_two_id" => pariticipant_two}
                ]
              },
              %{
                "$and" => [
                  %{"participant_one_id" => pariticipant_two},
                  %{"participant_two_id" => participant_one}
                ]
              }
            ]
          },
          %{"ended_at" => nil}
        ]
      },
      sort: %{"_id" => -1},
      limit: 1
    )
    |> Enum.take(1)
    |> case do
      [conversation_id] -> conversation_id
      [] -> nil
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
