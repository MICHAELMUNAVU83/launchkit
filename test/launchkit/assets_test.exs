defmodule Launchkit.AssetsTest do
  use Launchkit.DataCase

  alias Launchkit.Assets

  describe "headlines" do
    alias Launchkit.Assets.Headline

    import Launchkit.AssetsFixtures

    @invalid_attrs %{text: nil, character_count: nil, score: nil, is_pinned: nil}

    test "list_headlines/0 returns all headlines" do
      headline = headline_fixture()
      assert Assets.list_headlines() == [headline]
    end

    test "get_headline!/1 returns the headline with given id" do
      headline = headline_fixture()
      assert Assets.get_headline!(headline.id) == headline
    end

    test "create_headline/1 with valid data creates a headline" do
      valid_attrs = %{text: "some text", character_count: 42, score: 42, is_pinned: true}

      assert {:ok, %Headline{} = headline} = Assets.create_headline(valid_attrs)
      assert headline.text == "some text"
      assert headline.character_count == 42
      assert headline.score == 42
      assert headline.is_pinned == true
    end

    test "create_headline/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Assets.create_headline(@invalid_attrs)
    end

    test "update_headline/2 with valid data updates the headline" do
      headline = headline_fixture()
      update_attrs = %{text: "some updated text", character_count: 43, score: 43, is_pinned: false}

      assert {:ok, %Headline{} = headline} = Assets.update_headline(headline, update_attrs)
      assert headline.text == "some updated text"
      assert headline.character_count == 43
      assert headline.score == 43
      assert headline.is_pinned == false
    end

    test "update_headline/2 with invalid data returns error changeset" do
      headline = headline_fixture()
      assert {:error, %Ecto.Changeset{}} = Assets.update_headline(headline, @invalid_attrs)
      assert headline == Assets.get_headline!(headline.id)
    end

    test "delete_headline/1 deletes the headline" do
      headline = headline_fixture()
      assert {:ok, %Headline{}} = Assets.delete_headline(headline)
      assert_raise Ecto.NoResultsError, fn -> Assets.get_headline!(headline.id) end
    end

    test "change_headline/1 returns a headline changeset" do
      headline = headline_fixture()
      assert %Ecto.Changeset{} = Assets.change_headline(headline)
    end
  end

  describe "long_headlines" do
    alias Launchkit.Assets.LongHeadline

    import Launchkit.AssetsFixtures

    @invalid_attrs %{text: nil, character_count: nil, score: nil, is_pinned: nil}

    test "list_long_headlines/0 returns all long_headlines" do
      long_headline = long_headline_fixture()
      assert Assets.list_long_headlines() == [long_headline]
    end

    test "get_long_headline!/1 returns the long_headline with given id" do
      long_headline = long_headline_fixture()
      assert Assets.get_long_headline!(long_headline.id) == long_headline
    end

    test "create_long_headline/1 with valid data creates a long_headline" do
      valid_attrs = %{text: "some text", character_count: 42, score: 42, is_pinned: true}

      assert {:ok, %LongHeadline{} = long_headline} = Assets.create_long_headline(valid_attrs)
      assert long_headline.text == "some text"
      assert long_headline.character_count == 42
      assert long_headline.score == 42
      assert long_headline.is_pinned == true
    end

    test "create_long_headline/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Assets.create_long_headline(@invalid_attrs)
    end

    test "update_long_headline/2 with valid data updates the long_headline" do
      long_headline = long_headline_fixture()
      update_attrs = %{text: "some updated text", character_count: 43, score: 43, is_pinned: false}

      assert {:ok, %LongHeadline{} = long_headline} = Assets.update_long_headline(long_headline, update_attrs)
      assert long_headline.text == "some updated text"
      assert long_headline.character_count == 43
      assert long_headline.score == 43
      assert long_headline.is_pinned == false
    end

    test "update_long_headline/2 with invalid data returns error changeset" do
      long_headline = long_headline_fixture()
      assert {:error, %Ecto.Changeset{}} = Assets.update_long_headline(long_headline, @invalid_attrs)
      assert long_headline == Assets.get_long_headline!(long_headline.id)
    end

    test "delete_long_headline/1 deletes the long_headline" do
      long_headline = long_headline_fixture()
      assert {:ok, %LongHeadline{}} = Assets.delete_long_headline(long_headline)
      assert_raise Ecto.NoResultsError, fn -> Assets.get_long_headline!(long_headline.id) end
    end

    test "change_long_headline/1 returns a long_headline changeset" do
      long_headline = long_headline_fixture()
      assert %Ecto.Changeset{} = Assets.change_long_headline(long_headline)
    end
  end

  describe "descriptions" do
    alias Launchkit.Assets.Description

    import Launchkit.AssetsFixtures

    @invalid_attrs %{text: nil, character_count: nil, score: nil, is_pinned: nil}

    test "list_descriptions/0 returns all descriptions" do
      description = description_fixture()
      assert Assets.list_descriptions() == [description]
    end

    test "get_description!/1 returns the description with given id" do
      description = description_fixture()
      assert Assets.get_description!(description.id) == description
    end

    test "create_description/1 with valid data creates a description" do
      valid_attrs = %{text: "some text", character_count: 42, score: 42, is_pinned: true}

      assert {:ok, %Description{} = description} = Assets.create_description(valid_attrs)
      assert description.text == "some text"
      assert description.character_count == 42
      assert description.score == 42
      assert description.is_pinned == true
    end

    test "create_description/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Assets.create_description(@invalid_attrs)
    end

    test "update_description/2 with valid data updates the description" do
      description = description_fixture()
      update_attrs = %{text: "some updated text", character_count: 43, score: 43, is_pinned: false}

      assert {:ok, %Description{} = description} = Assets.update_description(description, update_attrs)
      assert description.text == "some updated text"
      assert description.character_count == 43
      assert description.score == 43
      assert description.is_pinned == false
    end

    test "update_description/2 with invalid data returns error changeset" do
      description = description_fixture()
      assert {:error, %Ecto.Changeset{}} = Assets.update_description(description, @invalid_attrs)
      assert description == Assets.get_description!(description.id)
    end

    test "delete_description/1 deletes the description" do
      description = description_fixture()
      assert {:ok, %Description{}} = Assets.delete_description(description)
      assert_raise Ecto.NoResultsError, fn -> Assets.get_description!(description.id) end
    end

    test "change_description/1 returns a description changeset" do
      description = description_fixture()
      assert %Ecto.Changeset{} = Assets.change_description(description)
    end
  end

  describe "images" do
    alias Launchkit.Assets.Image

    import Launchkit.AssetsFixtures

    @invalid_attrs %{status: nil, prompt: nil, width: nil, url: nil, storage_path: nil, height: nil, aspect_ratio: nil}

    test "list_images/0 returns all images" do
      image = image_fixture()
      assert Assets.list_images() == [image]
    end

    test "get_image!/1 returns the image with given id" do
      image = image_fixture()
      assert Assets.get_image!(image.id) == image
    end

    test "create_image/1 with valid data creates a image" do
      valid_attrs = %{status: "some status", prompt: "some prompt", width: 42, url: "some url", storage_path: "some storage_path", height: 42, aspect_ratio: "some aspect_ratio"}

      assert {:ok, %Image{} = image} = Assets.create_image(valid_attrs)
      assert image.status == "some status"
      assert image.prompt == "some prompt"
      assert image.width == 42
      assert image.url == "some url"
      assert image.storage_path == "some storage_path"
      assert image.height == 42
      assert image.aspect_ratio == "some aspect_ratio"
    end

    test "create_image/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Assets.create_image(@invalid_attrs)
    end

    test "update_image/2 with valid data updates the image" do
      image = image_fixture()
      update_attrs = %{status: "some updated status", prompt: "some updated prompt", width: 43, url: "some updated url", storage_path: "some updated storage_path", height: 43, aspect_ratio: "some updated aspect_ratio"}

      assert {:ok, %Image{} = image} = Assets.update_image(image, update_attrs)
      assert image.status == "some updated status"
      assert image.prompt == "some updated prompt"
      assert image.width == 43
      assert image.url == "some updated url"
      assert image.storage_path == "some updated storage_path"
      assert image.height == 43
      assert image.aspect_ratio == "some updated aspect_ratio"
    end

    test "update_image/2 with invalid data returns error changeset" do
      image = image_fixture()
      assert {:error, %Ecto.Changeset{}} = Assets.update_image(image, @invalid_attrs)
      assert image == Assets.get_image!(image.id)
    end

    test "delete_image/1 deletes the image" do
      image = image_fixture()
      assert {:ok, %Image{}} = Assets.delete_image(image)
      assert_raise Ecto.NoResultsError, fn -> Assets.get_image!(image.id) end
    end

    test "change_image/1 returns a image changeset" do
      image = image_fixture()
      assert %Ecto.Changeset{} = Assets.change_image(image)
    end
  end

  describe "videos" do
    alias Launchkit.Assets.Video

    import Launchkit.AssetsFixtures

    @invalid_attrs %{status: nil, prompt: nil, url: nil, storage_path: nil, duration_seconds: nil, aspect_ratio: nil}

    test "list_videos/0 returns all videos" do
      video = video_fixture()
      assert Assets.list_videos() == [video]
    end

    test "get_video!/1 returns the video with given id" do
      video = video_fixture()
      assert Assets.get_video!(video.id) == video
    end

    test "create_video/1 with valid data creates a video" do
      valid_attrs = %{status: "some status", prompt: "some prompt", url: "some url", storage_path: "some storage_path", duration_seconds: 42, aspect_ratio: "some aspect_ratio"}

      assert {:ok, %Video{} = video} = Assets.create_video(valid_attrs)
      assert video.status == "some status"
      assert video.prompt == "some prompt"
      assert video.url == "some url"
      assert video.storage_path == "some storage_path"
      assert video.duration_seconds == 42
      assert video.aspect_ratio == "some aspect_ratio"
    end

    test "create_video/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Assets.create_video(@invalid_attrs)
    end

    test "update_video/2 with valid data updates the video" do
      video = video_fixture()
      update_attrs = %{status: "some updated status", prompt: "some updated prompt", url: "some updated url", storage_path: "some updated storage_path", duration_seconds: 43, aspect_ratio: "some updated aspect_ratio"}

      assert {:ok, %Video{} = video} = Assets.update_video(video, update_attrs)
      assert video.status == "some updated status"
      assert video.prompt == "some updated prompt"
      assert video.url == "some updated url"
      assert video.storage_path == "some updated storage_path"
      assert video.duration_seconds == 43
      assert video.aspect_ratio == "some updated aspect_ratio"
    end

    test "update_video/2 with invalid data returns error changeset" do
      video = video_fixture()
      assert {:error, %Ecto.Changeset{}} = Assets.update_video(video, @invalid_attrs)
      assert video == Assets.get_video!(video.id)
    end

    test "delete_video/1 deletes the video" do
      video = video_fixture()
      assert {:ok, %Video{}} = Assets.delete_video(video)
      assert_raise Ecto.NoResultsError, fn -> Assets.get_video!(video.id) end
    end

    test "change_video/1 returns a video changeset" do
      video = video_fixture()
      assert %Ecto.Changeset{} = Assets.change_video(video)
    end
  end
end
