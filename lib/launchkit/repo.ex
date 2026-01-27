defmodule Launchkit.Repo do
  use Ecto.Repo,
    otp_app: :launchkit,
    adapter: Ecto.Adapters.Postgres
end
