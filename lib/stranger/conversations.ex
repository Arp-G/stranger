defmodule Stranger.Conversations do
  alias Stranger.{Accounts, Accounts.User, Conversations.Conversation}

  @page_size 15

  def get_conversation(%BSON.ObjectId{} = id) do
    conv = Mongo.find_one(:mongo, "conversations", %{_id: id})
    if conv, do: Conversation.to_struct(conv)
  end

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

  def get_conversations_count(user) do
    Mongo.count_documents!(:mongo, "conversations", %{
      "$and" => [
        %{
          "$or" => [
            %{"participant_one_id" => user},
            %{"participant_two_id" => user}
          ]
        },
        %{"ended_at" => %{"$exists": true}}
      ]
    })
  end

  def get_conversations(user, page \\ 1) do
    conversations =
      Mongo.find(
        :mongo,
        "conversations",
        %{
          "$and" => [
            %{
              "$or" => [
                %{"participant_one_id" => user},
                %{"participant_two_id" => user}
              ]
            },
            %{"ended_at" => %{"$exists": true}}
          ]
        },
        sort: %{"ended_at" => -1},
        skip: (page - 1) * @page_size,
        limit: @page_size
      )
      |> Enum.to_list()

    conversations_ids = conversations |> Enum.map(& &1["_id"])

    messages_count_in_conversations =
      Mongo.aggregate(:mongo, "messages", [
        %{"$match" => %{"conversation_id" => %{"$in" => conversations_ids}}},
        %{
          "$group" => %{
            "_id" => "$conversation_id",
            "count" => %{"$sum" => 1}
          }
        }
      ])
      |> Enum.into(%{}, fn %{"_id" => conv_id, "count" => count} ->
        {conv_id, count}
      end)

    users_map = get_stranger_profiles_from_conversations(conversations, user)

    conversations
    |> Enum.map(fn conv ->
      %{
        id: conv["_id"],
        on: conv["started_at"],
        duration: DateTime.diff(conv["ended_at"], conv["started_at"]),
        user: Map.get(users_map, get_participant(conv, user)),
        messages_count: messages_count_in_conversations[conv["_id"]] || 0
      }
    end)
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

  def get_stranger_for_conversation(conversation_id, user_id) do
    Mongo.find_one(
      :mongo,
      "conversations",
      %{
        "_id" => conversation_id
      }
    )
    |> get_participant(user_id)
  end

  defp get_stranger_profiles_from_conversations(conversations, user) do
    conversations
    |> Enum.reduce(
      MapSet.new(),
      fn conv, users ->
        MapSet.put(users, get_participant(conv, user))
      end
    )
    |> MapSet.to_list()
    |> Accounts.get_users()
    |> Enum.into(%{}, &{&1["_id"], User.to_struct(&1)})
  end

  defp get_participant(
         %{
           "participant_one_id" => p_one,
           "participant_two_id" => p_two
         },
         user
       ) do
    if p_one == user, do: p_two, else: p_one
  end
end
