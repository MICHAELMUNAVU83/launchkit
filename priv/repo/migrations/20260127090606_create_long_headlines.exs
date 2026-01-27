defmodule Launchkit.Repo.Migrations.CreateLongHeadlines do
  use Ecto.Migration

  def change do
    create table(:long_headlines) do
      add :text, :string
      add :character_count, :integer
      add :score, :integer
      add :is_pinned, :boolean, default: false, null: false
      add :website_id, references(:websites, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:long_headlines, [:website_id])
  end
end
