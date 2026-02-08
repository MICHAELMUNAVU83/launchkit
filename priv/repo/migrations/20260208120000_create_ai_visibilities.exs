defmodule Launchkit.Repo.Migrations.CreateAiVisibilities do
  use Ecto.Migration

  def change do
    create table(:ai_visibilities) do
      add :website_id, references(:websites, on_delete: :delete_all), null: false
      add :visibility_data, :map, default: %{}
      add :blog_topics, {:array, :map}, default: []
      add :generated_blog, :map

      timestamps(type: :utc_datetime)
    end

    create unique_index(:ai_visibilities, [:website_id])
  end
end
