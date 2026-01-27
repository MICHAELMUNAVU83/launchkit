defmodule Launchkit.Assets.Description do
  use Ecto.Schema
  import Ecto.Changeset

  schema "descriptions" do
    field :text, :string
    field :character_count, :integer
    field :score, :integer
    field :is_pinned, :boolean, default: false
    belongs_to :website, Launchkit.Campaigns.Website

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(description, attrs) do
    description
    |> cast(attrs, [:text, :character_count, :score, :is_pinned, :website_id])
    |> validate_required([:text, :character_count, :score, :is_pinned])
  end
end
