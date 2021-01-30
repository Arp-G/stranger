defmodule Stranger.MongoIndexes do
  def create_indexes do
    require Logger
    Logger.info("Using database #{Application.get_env(:stranger, Mongo)[:database]}")

    # ============ INDEXES FOR USER ============

    # Create index on user's email
    Mongo.command(:mongo, %{
      createIndexes: "users",
      indexes: [%{key: %{email: 1}, name: "users_email_index", unique: true}]
    })

    # ============ INDEXES FOR CONVERSATIONS ============

    # Create index on conversation's participants
    Mongo.command(:mongo, %{
      createIndexes: "conversations",
      indexes: [%{key: %{participant_one_id: 1}, name: "conversation_participant_one_index"}]
    })

    Mongo.command(:mongo, %{
      createIndexes: "conversations",
      indexes: [%{key: %{participant_two_id: 1}, name: "conversation_participant_two_index"}]
    })

    # Create index on coversation's ended_at
    Mongo.command(:mongo, %{
      createIndexes: "conversations",
      indexes: [%{key: %{ended_at: 1}, name: "conversation_ended_at_index"}]
    })

    # ============ INDEXES FOR MESSAGES ============

    # Create index on message's conversation_id
    Mongo.command(:mongo, %{
      createIndexes: "messages",
      indexes: [%{key: %{conversation_id: 1}, name: "messages_conversation_index"}]
    })

    # Create index on message's conversation_id
    Mongo.command(:mongo, %{
      createIndexes: "messages",
      indexes: [%{key: %{sendt_at: 1}, name: "messages_sent_at_index"}]
    })
  end
end
