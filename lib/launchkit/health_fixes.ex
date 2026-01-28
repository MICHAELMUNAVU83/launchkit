defmodule Launchkit.HealthFixes do
  @moduledoc """
  Generates fixes and code snippets for landing page health issues.
  """

  require Logger
  alias Launchkit.OpenAI

  @meta_generator_context """
  You are an expert SEO and web optimization specialist. Generate optimized meta tags and Open Graph tags based on website analysis.
  Focus on creating tags that are compelling, within character limits, and optimized for search and social sharing.
  """

  @doc """
  Generates optimized meta title and description based on analysis.
  """
  def generate_meta_tags(analysis, url) do
    company_name = get_in(analysis, ["brand_summary", "company_name"]) || "Company"
    one_liner = get_in(analysis, ["brand_summary", "one_liner"]) || ""
    tagline = get_in(analysis, ["brand_summary", "tagline"]) || ""

    prompt = """
    Generate optimized meta tags for this website:

    Company: #{company_name}
    Tagline: #{tagline}
    Description: #{one_liner}
    URL: #{url}

    Generate:
    1. Meta title (50-60 characters, compelling and keyword-rich)
    2. Meta description (120-160 characters, compelling call-to-action)

    Return JSON:
    {
      "title": "Optimized title here",
      "description": "Optimized description here"
    }
    """

    case OpenAI.send_request_to_openai(@meta_generator_context, prompt) do
      {:ok, response} ->
        parse_meta_response(response)

      {:error, reason} ->
        Logger.error("Failed to generate meta tags: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Generates Open Graph tags based on analysis.
  """
  def generate_og_tags(analysis, url) do
    company_name = get_in(analysis, ["brand_summary", "company_name"]) || "Company"
    one_liner = get_in(analysis, ["brand_summary", "one_liner"]) || ""
    tagline = get_in(analysis, ["brand_summary", "tagline"]) || ""

    prompt = """
    Generate Open Graph tags for social media sharing:

    Company: #{company_name}
    Tagline: #{tagline}
    Description: #{one_liner}
    URL: #{url}

    Generate:
    - og:title (compelling, 60 chars max)
    - og:description (compelling, 200 chars max)
    - og:type (usually "website")
    - og:url (the URL)
    - og:site_name (company name)

    Return JSON:
    {
      "og:title": "Title here",
      "og:description": "Description here",
      "og:type": "website",
      "og:url": "#{url}",
      "og:site_name": "#{company_name}"
    }
    """

    case OpenAI.send_request_to_openai(@meta_generator_context, prompt) do
      {:ok, response} ->
        parse_og_response(response)

      {:error, reason} ->
        Logger.error("Failed to generate OG tags: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Generates HTML code snippets for meta tags.
  """
  def generate_meta_html(meta_data) do
    title_html =
      if meta_data[:title] do
        "  <title>#{escape_html(meta_data[:title])}</title>"
      else
        nil
      end

    description_html =
      if meta_data[:description] do
        "  <meta name=\"description\" content=\"#{escape_html(meta_data[:description])}\">"
      else
        nil
      end

    og_html =
      if meta_data[:og_tags] do
        Enum.map(meta_data[:og_tags], fn {property, content} ->
          "  <meta property=\"#{property}\" content=\"#{escape_html(content)}\">"
        end)
      else
        []
      end

    all_tags =
      [title_html, description_html | og_html]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("\n")

    if all_tags != "" do
      "<!-- Add these tags to your <head> section -->\n#{all_tags}"
    else
      ""
    end
  end

  # ----------------------------------------------------------------------------
  # PRIVATE
  # ----------------------------------------------------------------------------

  defp parse_meta_response(response) do
    cleaned =
      response
      |> String.trim()
      |> String.replace(~r/^```json\n?/, "")
      |> String.replace(~r/^```\n?/, "")
      |> String.replace(~r/\n?```$/, "")
      |> String.trim()

    case Jason.decode(cleaned) do
      {:ok, parsed} ->
        {:ok, %{title: parsed["title"], description: parsed["description"]}}

      {:error, error} ->
        Logger.error("JSON parse failed: #{inspect(error)}")
        {:error, "Invalid JSON from AI"}
    end
  end

  defp parse_og_response(response) do
    cleaned =
      response
      |> String.trim()
      |> String.replace(~r/^```json\n?/, "")
      |> String.replace(~r/^```\n?/, "")
      |> String.replace(~r/\n?```$/, "")
      |> String.trim()

    case Jason.decode(cleaned) do
      {:ok, parsed} ->
        og_tags =
          %{
            "og:title" => parsed["og:title"],
            "og:description" => parsed["og:description"],
            "og:type" => parsed["og:type"] || "website",
            "og:url" => parsed["og:url"],
            "og:site_name" => parsed["og:site_name"]
          }
          |> Enum.reject(fn {_, v} -> is_nil(v) end)
          |> Enum.into(%{})

        {:ok, og_tags}

      {:error, error} ->
        Logger.error("JSON parse failed: #{inspect(error)}")
        {:error, "Invalid JSON from AI"}
    end
  end

  defp escape_html(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  defp escape_html(nil), do: ""
end
