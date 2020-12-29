defmodule Stranger.Accounts.Profile do
  use Ecto.Schema
  use Arc.Ecto.Schema

  import Ecto.Changeset
  alias Stranger.Accounts.Profile
  alias Stranger.Uploaders.Avatar

  @primary_key false
  embedded_schema do
    field(:first_name, :string)
    field(:last_name, :string)
    field(:avatar, Avatar.Type)
    field(:dob, :utc_datetime)
    field(:hobbies, :string)
    field(:bio, :string)
  end

  def changeset(attrs, user_profile \\ %Profile{}) do
    user_profile
    |> cast(attrs, [:first_name, :last_name, :dob, :hobbies, :bio])
    |> validate_required([:first_name, :last_name])
    |> validate_change(:dob, &validate_date_not_in_the_future/2)
  end

  def avatar_changeset(user_profile, attrs) do
    case attrs["avatar"] do
      "" ->
        avatar = if user_profile.avatar, do: user_profile.avatar.file_name, else: ""

        with :ok <- Avatar.delete({avatar, user_profile}) do
          user_profile |> cast(attrs, [:avatar])
        end

      _ ->
        cast_attachments(user_profile, attrs, [:avatar])
    end
  end

  defp validate_date_not_in_the_future(field, date) do
    case Date.compare(date, Date.utc_today()) do
      :gt -> [{field, "cannot be in the future"}]
      _ -> []
    end
  end

  # defp dob_date_to_datetime(%Ecto.Changeset{valid?: true, changes: %{dob: dob}} = changeset) do
  #   {:ok, datetime, 0} = DateTime.from_iso8601("#{dob} 00:00:00Z")
  #   put_change(changeset, :dob, datetime)
  # end

  # defp dob_date_to_datetime(changeset), do: changeset
end
