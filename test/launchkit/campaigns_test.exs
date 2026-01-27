defmodule Launchkit.CampaignsTest do
  use Launchkit.DataCase

  alias Launchkit.Campaigns

  describe "websites" do
    alias Launchkit.Campaigns.Website

    import Launchkit.CampaignsFixtures

    @invalid_attrs %{name: nil, status: nil, url: nil, analysis: nil}

    test "list_websites/0 returns all websites" do
      website = website_fixture()
      assert Campaigns.list_websites() == [website]
    end

    test "get_website!/1 returns the website with given id" do
      website = website_fixture()
      assert Campaigns.get_website!(website.id) == website
    end

    test "create_website/1 with valid data creates a website" do
      valid_attrs = %{name: "some name", status: "some status", url: "some url", analysis: %{}}

      assert {:ok, %Website{} = website} = Campaigns.create_website(valid_attrs)
      assert website.name == "some name"
      assert website.status == "some status"
      assert website.url == "some url"
      assert website.analysis == %{}
    end

    test "create_website/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Campaigns.create_website(@invalid_attrs)
    end

    test "update_website/2 with valid data updates the website" do
      website = website_fixture()
      update_attrs = %{name: "some updated name", status: "some updated status", url: "some updated url", analysis: %{}}

      assert {:ok, %Website{} = website} = Campaigns.update_website(website, update_attrs)
      assert website.name == "some updated name"
      assert website.status == "some updated status"
      assert website.url == "some updated url"
      assert website.analysis == %{}
    end

    test "update_website/2 with invalid data returns error changeset" do
      website = website_fixture()
      assert {:error, %Ecto.Changeset{}} = Campaigns.update_website(website, @invalid_attrs)
      assert website == Campaigns.get_website!(website.id)
    end

    test "delete_website/1 deletes the website" do
      website = website_fixture()
      assert {:ok, %Website{}} = Campaigns.delete_website(website)
      assert_raise Ecto.NoResultsError, fn -> Campaigns.get_website!(website.id) end
    end

    test "change_website/1 returns a website changeset" do
      website = website_fixture()
      assert %Ecto.Changeset{} = Campaigns.change_website(website)
    end
  end
end
