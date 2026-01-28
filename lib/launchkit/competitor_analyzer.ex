defmodule Launchkit.CompetitorAnalyzer do
  @moduledoc """
  Analyzes competitor websites to help users understand what they're up against.
  Extracts meta tags, estimated keywords, and basic structure.
  """

  require Logger

  @doc """
  Analyzes a competitor URL and returns key insights.
  """
  def analyze_competitor(url) do
    Logger.info("Analyzing competitor: #{url}")

    with {:ok, page_data} <- scrape_competitor(url) do
      analysis = %{
        url: url,
        domain: extract_domain(url),
        meta_title: extract_meta_title(page_data),
        meta_description: extract_meta_description(page_data),
        meta_keywords: extract_meta_keywords(page_data),
        open_graph: extract_open_graph(page_data),
        estimated_keywords: estimate_keywords(page_data),
        structure: analyze_structure(page_data),
        analyzed_at: DateTime.utc_now() |> DateTime.to_iso8601()
      }

      {:ok, analysis}
    else
      {:error, reason} ->
        Logger.error("Competitor analysis failed for #{url}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # ----------------------------------------------------------------------------
  # PRIVATE: Scraping
  # ----------------------------------------------------------------------------

  defp scrape_competitor(url) do
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
        {:ok, %{doc: doc, url: url, html: body}}

      {:ok, %Req.Response{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  # ----------------------------------------------------------------------------
  # PRIVATE: Extraction
  # ----------------------------------------------------------------------------

  defp extract_meta_title(%{doc: doc}) do
    case Floki.find(doc, "title") do
      [] -> nil
      [{_, _, [title_text]}] -> String.trim(title_text)
      _ -> nil
    end
  end

  defp extract_meta_description(%{doc: doc}) do
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

  defp extract_meta_keywords(%{doc: doc}) do
    case Floki.find(doc, "meta[name='keywords']") do
      [] ->
        nil

      [{_, attrs, _}] ->
        case Enum.find(attrs, fn {k, _} -> k == "content" end) do
          {_, value} ->
            value
            |> String.trim()
            |> String.split(~r/,\s*/)
            |> Enum.map(&String.trim/1)
            |> Enum.reject(&(&1 == ""))

          _ ->
            nil
        end

      _ ->
        nil
    end
  end

  defp extract_open_graph(%{doc: doc}) do
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

  defp estimate_keywords(%{doc: doc}) do
    # Extract keywords from headings, title, and meta tags
    headings =
      Floki.find(doc, "h1, h2, h3")
      |> Enum.map(&Floki.text/1)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    title = extract_meta_title(%{doc: doc})
    description = extract_meta_description(%{doc: doc})
    meta_keywords = extract_meta_keywords(%{doc: doc}) || []

    # Combine and extract potential keywords (simple approach)
    all_text = [title, description | headings] |> Enum.join(" ")

    keywords =
      all_text
      |> String.downcase()
      |> String.split(~r/\W+/)
      |> Enum.reject(&(&1 == ""))
      |> Enum.reject(fn word -> String.length(word) < 3 end)
      |> Enum.frequencies()
      |> Enum.sort_by(fn {_, count} -> count end, :desc)
      |> Enum.take(10)
      |> Enum.map(fn {word, _} -> word end)

    # Combine with meta keywords
    (meta_keywords ++ keywords) |> Enum.uniq() |> Enum.take(15)
  end

  defp analyze_structure(%{doc: doc}) do
    %{
      has_nav: Floki.find(doc, "nav") != [],
      has_footer: Floki.find(doc, "footer") != [],
      has_header: Floki.find(doc, "header") != [],
      h1_count: Floki.find(doc, "h1") |> length(),
      h2_count: Floki.find(doc, "h2") |> length(),
      image_count: Floki.find(doc, "img") |> length(),
      link_count: Floki.find(doc, "a") |> length(),
      form_count: Floki.find(doc, "form") |> length()
    }
  end

  defp extract_domain(url) do
    case URI.parse(url) do
      %URI{host: host} when is_binary(host) -> host
      _ -> nil
    end
  end
end
