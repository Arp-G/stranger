defmodule Stranger.Accounts do
  alias Stranger.Accounts.{User, Profile}

  def create_user(params) do
    params
    |> User.registration_changeset()
    |> add_user_profile(params)
    |> case do
      %Ecto.Changeset{valid?: true} = changset ->
        args_map =
          changset
          |> Ecto.Changeset.apply_changes()
          |> Map.delete(:password)

        args_map = Map.put(args_map, :profile, Map.from_struct(args_map.profile))

        Mongo.insert_one(:mongo, "users", args_map)

      changeset ->
        changeset
    end
  end

  # Embed th profile data if the user changeset is valid and the profile changeset is valid
  # Else return either the invalid user or profile changeset
  defp add_user_profile(%Ecto.Changeset{valid?: true} = user_changeset, params) do
    params
    |> Profile.changeset()
    |> case do
      %Ecto.Changeset{valid?: true} = profile_changeset ->
        Ecto.Changeset.put_embed(
          user_changeset,
          :profile,
          Ecto.Changeset.apply_changes(profile_changeset)
        )

      profile_changeset ->
        profile_changeset
    end
  end

  defp add_user_profile(user_changeset, _params), do: user_changeset
end
