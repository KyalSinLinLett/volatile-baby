defmodule RealtimeChat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      RealtimeChatWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: RealtimeChat.PubSub},
      # Start the Endpoint (http/https)
      RealtimeChatWeb.Endpoint,
      RealtimeChatWeb.Presence
      # Start a worker by calling: RealtimeChat.Worker.start_link(arg)
      # {RealtimeChat.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RealtimeChat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    RealtimeChatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
