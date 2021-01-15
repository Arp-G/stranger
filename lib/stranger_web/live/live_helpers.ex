defmodule StrangerWeb.LiveHelpers do
  def section_class(current_section, section) do
    if section != current_section, do: "d-none", else: ""
  end

  def format_date(form_data) do
    cond do
      # Comes from form_data params when user changes date in form
      form_data.params["dob"] ->
        form_data.params["dob"]
        |> DateTime.from_iso8601()
        |> case do
          {:ok, datetime, 0} -> DateTime.to_date(datetime)
          {:error, _} -> form_data.params["dob"]
        end

      # Comes from form_data data to prefill existing dob in form if present, usefull in update form
      form_data.data.dob ->
        form_data.data.dob
        |> DateTime.to_date()
        |> Date.to_iso8601()

      true ->
        nil
    end
  end
end
