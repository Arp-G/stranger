# defmodule StrangerWeb.ChatChannel do
#   use StrangerWeb, :channel

#   def join(
#         "conversation:" <> room_id,
#         _payload,
#         %Phoenix.Socket{assigns: %{user_id: user_id}} = socket
#       ) do
#     {:ok, socket}
#   end

#   def handle_in(
#         "new:msg",
#         %{"body" => message},
#         %Phoenix.Socket{
#           assigns: %{user_id: sender_id},
#           topic: "conversation:" <> room_id
#         } = socket
#       ) do


#         payload = %{
#         #  id: id,
#           sender_id: sender_id,
#          # name: name,
#           message: message,
#           time: DateTime.utc_now()
#         }


#     broadcast!(socket, "new:msg", payload)


#     {:noreply, socket}
#   end
# end
