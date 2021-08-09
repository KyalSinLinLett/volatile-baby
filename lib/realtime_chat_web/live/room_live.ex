defmodule RealtimeChatWeb.RoomLive do
  use RealtimeChatWeb, :live_view
  require Logger

  @impl true
  def mount(%{"id" => room_id}, _session, socket) do
    topic = "room:" <> room_id
    username = MnemonicSlugs.generate_slug(2)
    if connected?(socket) do
      RealtimeChatWeb.Endpoint.subscribe(topic)
      RealtimeChatWeb.Presence.track(self(), topic, username, %{})
    end
    {:ok, assign(socket,
      room_id: room_id,
      topic: topic,
      username: username,
      message: "",
      messages: [],
      user_list: [],
      temporary_assigns: [messages: []]
    )}
  end

  @impl true
  def handle_event("submit_message", %{"chat" => %{"message" => message}}, socket) do
    message = %{time: DateTime.utc_now() |> DateTime.to_time(), uuid: UUID.uuid4(), content: message, username: socket.assigns.username}

    RealtimeChatWeb.Endpoint.broadcast(socket.assigns.topic, "new-message", message)
    {:noreply, assign(socket, message: "")}
  end

  @impl true
  def handle_event("form_update", %{"chat" => %{"message" => message}}, socket) do
    {:noreply, assign(socket, message: message)}
  end

  @impl true
  def handle_info(%{event: "new-message", payload: message}, socket) do
    {:noreply, assign(socket, messages: [message])}
  end

  def handle_info(%{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, socket) do
    join_messages =
      joins
      |> Map.keys()
      |> Enum.map(fn username -> %{type: :system, time: DateTime.utc_now() |> DateTime.to_time(), uuid: UUID.uuid4(), content: "#{username} joined..."} end)

    leave_messages =
      leaves
      |> Map.keys()
      |> Enum.map(fn username -> %{type: :system, time: DateTime.utc_now() |> DateTime.to_time(), uuid: UUID.uuid4(), content: "#{username} left..."} end)

    user_list =
      RealtimeChatWeb.Presence.list(socket.assigns.topic)
      |> Map.keys()

    {:noreply, assign(socket, messages: join_messages ++ leave_messages, user_list: user_list)}
  end

  def display_message(%{type: :system, time: time, uuid: uuid, content: content}) do
    ~E"""
    <p id="<%= uuid %>"><em><i><%= time %></i>-<%= content %></em></p>
    """
  end

  def display_message(%{time: time, uuid: uuid, content: content, username: username}) do
    ~E"""
    <p id="<%= uuid %>"><strong><i><%= time %></i>-<%= username %></strong>:: <%= content %></p>
    """
  end

end
