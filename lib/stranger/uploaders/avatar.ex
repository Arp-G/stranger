defmodule Stranger.Uploaders.Avatar do
  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:original]

  @extension_whitelist ~w(.jpg .jpeg .png)
  # 5mb
  @max_size 5_242_880

  # def call(file_path, user) do

  #   if validate(file_path) do

  #   else
  #     :invalid_file
  #   end

  #   ExAws.S3.put_object("stranger_dev", "abc.jpg", File.read!("priv/static/uploads/img.jpeg")) |> ExAws.request!

  # end

  # Whitelist file extensions:
  def validate({file, _}) do
    file_extension = file.file_name |> Path.extname() |> String.downcase()
    %{size: size} = File.stat!(file.path)
    Enum.member?(@extension_whitelist, file_extension) && size <= @max_siz
    true
  end

  # Override the persisted filenames:
  def filename(version, {_file, scope}) do
    file_hash_key = "user_profile/avatars/#{get_id(scope._id)}/#{version}"

    :crypto.hmac(:sha, Application.get_env(:arc, :hash_secret), file_hash_key)
    |> Base.encode16()
    |> String.downcase()
  end

  # Override the storage directory:
  def storage_dir(_, {_file, scope}) do
    scope_id = get_id(scope._id)
    scope_id_partitions = for <<x::binary-size(3) <- scope_id>>, do: x
    scope_id_path = Enum.join(scope_id_partitions, "/")

    "uploads/Stranger/avatars/#{scope_id_path}"
  end

  def get_id(%BSON.ObjectId{} = id), do: BSON.ObjectId.encode!(id)
end
