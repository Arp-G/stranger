defmodule Stranger.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Stranger.Accounts.{User, Profile}

  @primary_key false
  embedded_schema do
    field(:email, :string, null: false)
    field(:password_hash, :string, null: false)
    field(:password, :string, virtual: true)
    field(:last_sign_in_at, :utc_datetime_usec)
    field(:last_sign_in_ip, :string)
    field(:inserted_at, :utc_datetime)

    embeds_one(:profile, Profile)
  end

  def registration_changeset(attrs, user \\ %User{}) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_format(:email, ~r/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
    |> update_change(:email, &String.downcase/1)
    |> validate_confirmation(
      :password,
      required: true,
      message: "does not match password"
    )
    |> validate_format(:password, ~r/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$/)
    |> cast_embed(:profile)
    |> validate_unique_email()
    |> put_password_hash()
    |> put_change(:inserted_at, DateTime.utc_now())
  end

  def login_changeset(user, attrs) do
    user
    |> cast(attrs, [:last_sign_in_ip])
    |> put_change(:last_sign_in_at, DateTime.utc_now())
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Argon2.hash_pwd_salt(password))

      _ ->
        changeset
    end
  end

  defp validate_unique_email(%Ecto.Changeset{changes: %{email: email}} = changeset) do
    Mongo.find_one(:mongo, "users", %{email: email})
    |> if(do: add_error(changeset, :email, "has already been taken"), else: changeset)
  end
end
