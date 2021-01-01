defmodule StrangerWeb.LiveHelpers do
  def section_class(current_section, section) do
    if section != current_section, do: "d-none", else: ""
  end

  def date_time_to_date(nil), do: nil

  def date_time_to_date(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, 0} -> DateTime.to_date(datetime)
      {:error, _} -> date_string
    end
  end
end
