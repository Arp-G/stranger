defmodule StrangerWeb.LiveHelpers do
  def section_class(current_section, section) do
    if section != current_section, do: "d-none", else: ""
  end
end
