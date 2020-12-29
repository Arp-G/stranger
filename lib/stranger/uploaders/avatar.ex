defmodule Stranger.Uploaders.Avatar do
  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:original]

  @extension_whitelist ~w(.jpg .jpeg .gif .png)

  # Whitelist file extensions:
  def validate({file, _}) do
    file_extension = file.file_name |> Path.extname() |> String.downcase()
    %{size: size} = File.stat! file.path
    require IEx
    IEx.pry
    Enum.member?(@extension_whitelist, file_extension) && size < 1000
  end

  # Override the persisted filenames:
  def filename(version, {_file, scope}) do
    source = Ecto.get_meta(scope, :source)
    file_hash_key = "#{source}/avatars/#{scope.id}/#{version}"

    :crypto.hmac(:sha, Application.get_env(:arc, :hash_secret), file_hash_key)
    |> Base.encode16()
    |> String.downcase()
  end

  # Override the storage directory:
  def storage_dir(_, {_file, scope}) do
    source = Ecto.get_meta(scope, :source)
    scope_id = scope.id |> Integer.to_string() |> String.pad_leading(12, "0")
    scope_id_partitions = for <<x::binary-size(3) <- scope_id>>, do: x
    scope_id_path = Enum.join(scope_id_partitions, "/")

    "uploads/Stranger/#{source}/avatars/#{scope_id_path}"
  end
end
