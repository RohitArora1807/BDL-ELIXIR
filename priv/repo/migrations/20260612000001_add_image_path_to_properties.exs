defmodule ElixirApp.Repo.Migrations.AddImagePathToProperties do
  use Ecto.Migration

  def change do
    alter table(:properties) do
      add :image_path, :string
    end
  end
end
