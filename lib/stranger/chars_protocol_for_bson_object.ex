defimpl String.Chars, for: BSON.ObjectId do
  def to_string(bson_object) do
    BSON.ObjectId.encode!(bson_object)
  end
end

defimpl Phoenix.HTML.Safe, for: BSON.ObjectId do
  def to_iodata(bson_object) do
    BSON.ObjectId.encode!(bson_object)
  end
end
