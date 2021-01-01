defmodule Stranger.Accounts do
  alias Stranger.Accounts.{User, Profile}

  def create_user(params) do
    params
    |> User.registration_changeset()
    |> case do
      %Ecto.Changeset{valid?: true} = changset ->
        args_map =
          changset
          |> Ecto.Changeset.apply_changes()
          |> User.from_struct()

        case Mongo.insert_one(:mongo, "users", args_map) do
          {:ok, _} ->
            {
              :ok,
              Mongo.find_one(:mongo, "users", %{email: args_map.email}) |> User.to_struct()
            }

          _ ->
            {:error, changset}
        end

      changeset ->
        {:error, changeset}
    end
  end

  def sign_in(last_sign_in_ip, email, password) do
    with({:ok, user} <- get_by_email(email), do: verify_password(password, user))
    |> case do
      {:ok, user} ->
        {:ok, %{"_id" => user_id}} =
          update_user_signin_details(user, %{last_sign_in_ip: last_sign_in_ip})

        token =
          Phoenix.Token.sign(
            Application.get_env(:stranger, :secret_key),
            Application.get_env(:stranger, :salt),
            user_id
          )

        {:ok, token}

      _ ->
        {:error, :unauthorized}
    end
  end

  def update_avatar(%User{email: email}, filename) do
    Mongo.update_one(:mongo, "users", %{email: email}, %{"$set": %{"profile.avatar": filename}})
  end

  # Embed th profile data if the user changeset is valid and the profile changeset is valid
  # Else return either the invalid user or profile changeset
  # defp add_user_profile(%Ecto.Changeset{valid?: true} = user_changeset, params) do
  #   params
  #   |> Profile.changeset(%Profile{})
  #   |> case do
  #     %Ecto.Changeset{valid?: true} = profile_changeset ->
  #       Ecto.Changeset.put_embed(
  #         user_changeset,
  #         :profile,
  #         Ecto.Changeset.apply_changes(profile_changeset)
  #       )

  #     profile_changeset ->
  #       profile_changeset
  #   end
  # end

  defp add_user_profile(user_changeset, _params), do: user_changeset

  defp verify_password(password, %User{password_hash: password_hash} = user)
       when is_binary(password) do
    if Argon2.verify_pass(password, password_hash), do: {:ok, user}, else: :error
  end

  defp get_by_email(email) when is_binary(email) do
    case Mongo.find_one(:mongo, "users", %{email: email}) do
      nil ->
        Argon2.no_user_verify()
        {:error, "Login error."}

      user ->
        {:ok, User.to_struct(user)}
    end
  end

  defp update_user_signin_details(user, attrs) do
    attrs = User.login_changeset(user, attrs).changes

    Mongo.find_one_and_update(:mongo, "users", %{email: user.email}, %{"$set": attrs})
  end
end
