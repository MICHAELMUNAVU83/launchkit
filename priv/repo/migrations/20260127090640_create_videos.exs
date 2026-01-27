defmodule Launchkit.Repo.Migrations.CreateVideos do
  use Ecto.Migration

  def change do
    create table(:videos) do
      add :prompt, :string
      add :url, :string
      add :storage_path, :string
      add :duration_seconds, :integer
      add :aspect_ratio, :string
      add :status, :string
      add :source_image_id, references(:images, on_delete: :nothing)
      add :website_id, references(:websites, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:videos, [:source_image_id])
    create index(:videos, [:website_id])
  end
end
