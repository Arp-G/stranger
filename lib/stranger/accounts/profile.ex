defmodule Stranger.Accounts.Profile do
  use Stranger.Schema
  use Arc.Ecto.Schema

  alias Stranger.Uploaders.Avatar

  @primary_key false
  embedded_schema do
    field(:first_name, :string)
    field(:last_name, :string)
    field(:avatar, Avatar.Type)
    field(:dob, :utc_datetime)
    field(:country, :string)
    field(:bio, :string)
  end

  def changeset(user_profile, attrs) do
    user_profile
    |> cast(sanitize_dob(attrs), [:first_name, :last_name, :dob, :country, :bio])
    |> validate_required([:first_name, :last_name])
    |> validate_length(:country, max: 50)
    |> validate_length(:bio, max: 200)
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

  defp sanitize_dob(
         %{
           "dob" =>
             <<_YY::binary-size(4), "-", _MM::binary-size(2), "-", _DD::binary-size(2)>> = dob
         } = attrs
       ) do
    Map.put(attrs, "dob", "#{dob} 00:00:00Z")
  end

  defp sanitize_dob(attrs), do: attrs
end
