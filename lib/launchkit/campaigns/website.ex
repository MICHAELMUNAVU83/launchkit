defmodule Launchkit.Campaigns.Website do
  use Ecto.Schema
  import Ecto.Changeset

  schema "websites" do
    field :name, :string
    field :status, :string
    field :url, :string
    field :analysis, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(website, attrs) do
    website
    |> cast(attrs, [:name, :url, :analysis, :status])
    |> validate_required([:name, :url, :status])
  end
end
