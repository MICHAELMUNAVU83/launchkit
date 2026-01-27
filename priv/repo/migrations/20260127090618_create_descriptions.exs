defmodule Launchkit.Repo.Migrations.CreateDescriptions do
  use Ecto.Migration

  def change do
    create table(:descriptions) do
      add :text, :string
      add :character_count, :integer
      add :score, :integer
      add :is_pinned, :boolean, default: false, null: false
      add :website_id, references(:websites, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:descriptions, [:website_id])
  end
end
