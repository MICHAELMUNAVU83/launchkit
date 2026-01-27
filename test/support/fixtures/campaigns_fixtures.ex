defmodule Launchkit.CampaignsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Launchkit.Campaigns` context.
  """

  @doc """
  Generate a website.
  """
  def website_fixture(attrs \\ %{}) do
    {:ok, website} =
      attrs
      |> Enum.into(%{
        analysis: %{},
        name: "some name",
        status: "some status",
        url: "some url"
      })
      |> Launchkit.Campaigns.create_website()

    website
  end
end
