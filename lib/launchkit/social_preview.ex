defmodule Launchkit.SocialPreview do
  @moduledoc """
  Generates social media previews for Facebook, Twitter/X, and LinkedIn.
  Shows how content will appear when shared on social platforms.
  """

  require Logger

  @doc """
  Generates social preview data for a URL.
  Extracts Open Graph tags and Twitter Card data.
  """
  def generate_preview(url, _options \\ []) do
    Logger.info("Generating social preview for: #{url}")

    with {:ok, page_data} <- scrape_for_preview(url) do
      preview_data = %{
        url: url,
        facebook: generate_facebook_preview(page_data),
        twitter: generate_twitter_preview(page_data),
        linkedin: generate_linkedin_preview(page_data),
        generated_at: DateTime.utc_now() |> DateTime.to_iso8601()
      }

      {:ok, preview_data}
    else
      {:error, reason} ->
        Logger.error("Social preview generation failed for #{url}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Generates optimized OG images in specific dimensions for each platform.
  """
  def generate_og_images(_headlines, _descriptions, _analysis) do
    # This would call the image generation service with specific dimensions
    # For now, return dimensions and prompts
    platforms = [
      %{
        platform: "facebook",
        dimensions: "1200x630",
        aspect_ratio: "1.91:1",
        recommended_size: "1200x630px"
      },
      %{
        platform: "twitter",
        dimensions: "1200x675",
        aspect_ratio: "16:9",
        recommended_size: "1200x675px"
      },
      %{
        platform: "linkedin",
        dimensions: "1200x627",
        aspect_ratio: "1.91:1",
        recommended_size: "1200x627px"
      }
    ]

    {:ok, platforms}
  end

  # ----------------------------------------------------------------------------
  # PRIVATE: Scraping
  # ----------------------------------------------------------------------------

  defp scrape_for_preview(url) do
    headers = [
      {"User-Agent", "Mozilla/5.0 (compatible; LaunchKit/1.0; +https://launchkit.ai)"},
      {"Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"}
    ]

    options = [
      headers: headers,
      redirect: true,
      max_redirects: 5,
      receive_timeout: 30_000,
      retry: :transient,
      max_retries: 3
    ]

    case Req.get(url, options) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, doc} = Floki.parse_document(body)
        {:ok, %{doc: doc, url: url}}

      {:ok, %Req.Response{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  # ----------------------------------------------------------------------------
  # PRIVATE: Platform-specific Previews
  # ----------------------------------------------------------------------------

  defp generate_facebook_preview(%{doc: doc, url: url}) do
    og_data = extract_og_tags(doc)
    title = og_data["og:title"] || extract_title(doc) || "No title"
    description = og_data["og:description"] || extract_meta_description(doc) || "No description"
    image = og_data["og:image"] || nil
    site_name = og_data["og:site_name"] || extract_domain(url)

    %{
      title: title,
      description: description,
      image: image,
      url: url,
      site_name: site_name,
      preview_size: "1200x630px",
      has_image: not is_nil(image)
    }
  end

  defp generate_twitter_preview(%{doc: doc, url: url}) do
    twitter_data = extract_twitter_tags(doc)
    og_data = extract_og_tags(doc)

    title =
      twitter_data["twitter:title"] || og_data["og:title"] || extract_title(doc) || "No title"

    description =
      twitter_data["twitter:description"] || og_data["og:description"] ||
        extract_meta_description(doc) || "No description"

    image = twitter_data["twitter:image"] || og_data["og:image"] || nil
    card_type = twitter_data["twitter:card"] || "summary_large_image"

    %{
      title: title,
      description: description,
      image: image,
      url: url,
      card_type: card_type,
      preview_size: "1200x675px",
      has_image: not is_nil(image)
    }
  end

  defp generate_linkedin_preview(%{doc: doc, url: url}) do
    # LinkedIn uses Open Graph tags
    og_data = extract_og_tags(doc)
    title = og_data["og:title"] || extract_title(doc) || "No title"
    description = og_data["og:description"] || extract_meta_description(doc) || "No description"
    image = og_data["og:image"] || nil
    site_name = og_data["og:site_name"] || extract_domain(url)

    %{
      title: title,
      description: description,
      image: image,
      url: url,
      site_name: site_name,
      preview_size: "1200x627px",
      has_image: not is_nil(image)
    }
  end

  # ----------------------------------------------------------------------------
  # PRIVATE: Extraction Helpers
  # ----------------------------------------------------------------------------

  defp extract_og_tags(doc) do
    Floki.find(doc, "meta[property^='og:']")
    |> Enum.reduce(%{}, fn meta_tag, acc ->
      attrs = elem(meta_tag, 1)
      property = Enum.find_value(attrs, fn {k, v} -> if k == "property", do: v end)
      content = Enum.find_value(attrs, fn {k, v} -> if k == "content", do: v end)

      if property && content do
        Map.put(acc, property, content)
      else
        acc
      end
    end)
  end

  defp extract_twitter_tags(doc) do
    Floki.find(doc, "meta[name^='twitter:']")
    |> Enum.reduce(%{}, fn meta_tag, acc ->
      attrs = elem(meta_tag, 1)
      name = Enum.find_value(attrs, fn {k, v} -> if k == "name", do: v end)
      content = Enum.find_value(attrs, fn {k, v} -> if k == "content", do: v end)

      if name && content do
        Map.put(acc, name, content)
      else
        acc
      end
    end)
  end

  defp extract_title(doc) do
    case Floki.find(doc, "title") do
      [] -> nil
      [{_, _, [title_text]}] -> String.trim(title_text)
      _ -> nil
    end
  end

  defp extract_meta_description(doc) do
    case Floki.find(doc, "meta[name='description']") do
      [] ->
        nil

      [{_, attrs, _}] ->
        case Enum.find(attrs, fn {k, _} -> k == "content" end) do
          {_, value} -> String.trim(value)
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp extract_domain(url) do
    case URI.parse(url) do
      %URI{host: host} when is_binary(host) -> host
      _ -> nil
    end
  end
end
