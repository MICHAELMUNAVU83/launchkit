defmodule Launchkit.Assets.Image do
  use Ecto.Schema
  import Ecto.Changeset

  schema "images" do
    field :status, :string
    field :prompt, :string
    field :width, :integer
    field :url, :string
    field :storage_path, :string
    field :height, :integer
    field :aspect_ratio, :string
    belongs_to :website, Launchkit.Campaigns.Website

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(image, attrs) do
    image
    |> cast(attrs, [
      :prompt,
      :url,
      :storage_path,
      :width,
      :height,
      :aspect_ratio,
      :status,
      :website_id
    ])
    |> validate_required([:prompt, :url, :storage_path, :width, :height, :aspect_ratio, :status])
  end
end
