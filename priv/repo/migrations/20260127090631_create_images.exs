defmodule Launchkit.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
    create table(:images) do
      add :prompt, :text
      add :url, :text
      add :storage_path, :text
      add :width, :integer
      add :height, :integer
      add :aspect_ratio, :string
      add :status, :string
      add :website_id, references(:websites, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:images, [:website_id])
  end
end
