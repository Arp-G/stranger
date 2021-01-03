defmodule Stranger.Accounts.User do
  use Stranger.Schema
  alias Stranger.Accounts.Profile

  @primary_key false
  embedded_schema do
    field(:_id, :integer)
    field(:email, :string, null: false)
    field(:password_hash, :string, null: false)
    field(:password, :string, virtual: true)
    field(:last_sign_in_at, :utc_datetime_usec)
    field(:last_sign_in_ip, :string)
    field(:inserted_at, :utc_datetime)

    embeds_one(:profile, Profile)
  end

  def registration_changeset(attrs, user \\ %User{}) do
    validation_changeset(attrs, user)
    |> validate_unique_email()
    |> put_password_hash()
    |> put_change(:inserted_at, DateTime.utc_now())
  end

  def validation_changeset(attrs, user \\ %User{}) do
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
    # This automatically calls thhe embedded modules changeset/2 function,
    # to run validations on the embedded schema, using :with option we provide a custom function instead of the default changeset/2
    |> cast_embed(:profile)
  end

  def login_changeset(user, attrs) do
    user
    |> cast(attrs, [:last_sign_in_ip])
    |> put_change(:last_sign_in_at, DateTime.utc_now())
  end

  def validate_unique_email(%Ecto.Changeset{changes: %{email: email}} = changeset) do
    Mongo.find_one(:mongo, "users", %{email: email})
    |> if(do: add_error(changeset, :email, "has already been taken"), else: changeset)
  end

  def validate_unique_email(changeset), do: changeset

  defp put_password_hash(%Ecto.Changeset{valid?: true} = changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Argon2.hash_pwd_salt(password))

      _ ->
        changeset
    end
  end

  defp put_password_hash(changeset), do: changeset

  # Override default to_struct
  def to_struct(%{profile: profile} = user) do
    user = Map.put(user, "profile", Profile.to_struct(profile))
    # Call default overriden function
    super(user)
  end

  # Override default to_struct
  def to_struct(%{"profile" => profile} = user) do
    user = Map.put(user, "profile", Profile.to_struct(profile))
    # Call default overriden function
    super(user)
  end

  # Override default from_struct
  def from_struct(%{profile: profile} = user) do
    user = Map.put(user, :profile, Profile.from_struct(profile))

    user
    # Call default overriden function
    |> super()
    |> Map.drop([:_id, :password])
  end
end
