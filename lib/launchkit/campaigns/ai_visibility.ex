defmodule Launchkit.Campaigns.AiVisibility do
  @moduledoc """
  Schema for persisting AI visibility analysis and related blog data per website.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "ai_visibilities" do
    field :visibility_data, :map, default: %{}
    field :blog_topics, {:array, :map}, default: []
    field :generated_blog, :map

    belongs_to :website, Launchkit.Campaigns.Website

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(ai_visibility, attrs) do
    ai_visibility
    |> cast(attrs, [:visibility_data, :blog_topics, :generated_blog, :website_id])
    |> validate_required([:website_id])
    |> foreign_key_constraint(:website_id)
    |> unique_constraint(:website_id)
  end
end
