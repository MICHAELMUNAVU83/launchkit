defmodule Launchkit.AssetsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Launchkit.Assets` context.
  """

  @doc """
  Generate a headline.
  """
  def headline_fixture(attrs \\ %{}) do
    {:ok, headline} =
      attrs
      |> Enum.into(%{
        character_count: 42,
        is_pinned: true,
        score: 42,
        text: "some text"
      })
      |> Launchkit.Assets.create_headline()

    headline
  end

  @doc """
  Generate a long_headline.
  """
  def long_headline_fixture(attrs \\ %{}) do
    {:ok, long_headline} =
      attrs
      |> Enum.into(%{
        character_count: 42,
        is_pinned: true,
        score: 42,
        text: "some text"
      })
      |> Launchkit.Assets.create_long_headline()

    long_headline
  end

  @doc """
  Generate a description.
  """
  def description_fixture(attrs \\ %{}) do
    {:ok, description} =
      attrs
      |> Enum.into(%{
        character_count: 42,
        is_pinned: true,
        score: 42,
        text: "some text"
      })
      |> Launchkit.Assets.create_description()

    description
  end

  @doc """
  Generate a image.
  """
  def image_fixture(attrs \\ %{}) do
    {:ok, image} =
      attrs
      |> Enum.into(%{
        aspect_ratio: "some aspect_ratio",
        height: 42,
        prompt: "some prompt",
        status: "some status",
        storage_path: "some storage_path",
        url: "some url",
        width: 42
      })
      |> Launchkit.Assets.create_image()

    image
  end

  @doc """
  Generate a video.
  """
  def video_fixture(attrs \\ %{}) do
    {:ok, video} =
      attrs
      |> Enum.into(%{
        aspect_ratio: "some aspect_ratio",
        duration_seconds: 42,
        prompt: "some prompt",
        status: "some status",
        storage_path: "some storage_path",
        url: "some url"
      })
      |> Launchkit.Assets.create_video()

    video
  end
end
