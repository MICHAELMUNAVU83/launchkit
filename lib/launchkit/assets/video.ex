defmodule Launchkit.Assets.Video do
  use Ecto.Schema
  import Ecto.Changeset

  schema "videos" do
    field :status, :string
    field :prompt, :string
    field :url, :string
    field :storage_path, :string
    field :duration_seconds, :integer
    field :aspect_ratio, :string
    field :source_image_id, :id
    belongs_to :website, Launchkit.Campaigns.Website

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(video, attrs) do
    video
    |> cast(attrs, [
      :prompt,
      :url,
      :storage_path,
      :duration_seconds,
      :aspect_ratio,
      :status,
      :website_id
    ])
    |> validate_required([:prompt, :url, :storage_path, :duration_seconds, :aspect_ratio, :status])
  end
end
