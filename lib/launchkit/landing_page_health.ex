defmodule Launchkit.LandingPageHealth do
  @moduledoc """
  Analyzes landing page health for conversion optimization.
  Checks meta tags, Open Graph tags, alt text, SSL, mobile-friendliness, and page speed indicators.
  """

  require Logger
  alias Launchkit.WebScraper

  @doc """
  Performs a comprehensive health check on a landing page.
  Returns a map with checks and their status/results.
  """
  def check_health(url) do
    Logger.info("Starting health check for: #{url}")

    with {:ok, page_data} <- scrape_for_health(url) do
      health_data = %{
        url: url,
        checked_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        meta_title: check_meta_title(page_data),
        meta_description: check_meta_description(page_data),
        open_graph: check_open_graph_tags(page_data),
        alt_text: check_alt_text(page_data),
        ssl: check_ssl(url),
        mobile_friendly: check_mobile_friendly(page_data),
        page_speed: check_page_speed_indicators(page_data),
        # Will be calculated
        overall_score: nil
      }

      # Calculate overall score
      overall_score = calculate_overall_score(health_data)
      health_data = Map.put(health_data, :overall_score, overall_score)

      {:ok, health_data}
    else
      {:error, reason} ->
        Logger.error("Health check failed for #{url}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # ----------------------------------------------------------------------------
  # PRIVATE: Scraping
  # ----------------------------------------------------------------------------

  defp scrape_for_health(url) do
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
      {:ok, %Req.Response{status: 200, body: body, headers: response_headers}} ->
        {:ok, doc} = Floki.parse_document(body)
        {:ok, %{html: body, doc: doc, headers: response_headers, url: url}}

      {:ok, %Req.Response{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  # ----------------------------------------------------------------------------
  # PRIVATE: Individual Checks
  # ----------------------------------------------------------------------------

  defp check_meta_title(%{doc: doc}) do
    title =
      case Floki.find(doc, "title") do
        [] -> nil
        [{_, _, [title_text]}] -> String.trim(title_text)
        _ -> nil
      end

    cond do
      is_nil(title) or title == "" ->
        %{status: :error, message: "Missing meta title", value: nil}

      String.length(title) > 60 ->
        %{
          status: :warning,
          message: "Title too long (#{String.length(title)} chars, recommended: 50-60)",
          value: title
        }

      String.length(title) < 30 ->
        %{
          status: :warning,
          message: "Title too short (#{String.length(title)} chars, recommended: 30-60)",
          value: title
        }

      true ->
        %{
          status: :ok,
          message: "Title length is good (#{String.length(title)} chars)",
          value: title
        }
    end
  end

  defp check_meta_description(%{doc: doc}) do
    description =
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

    cond do
      is_nil(description) or description == "" ->
        %{status: :error, message: "Missing meta description", value: nil}

      String.length(description) > 160 ->
        %{
          status: :warning,
          message:
            "Description too long (#{String.length(description)} chars, recommended: 120-160)",
          value: description
        }

      String.length(description) < 50 ->
        %{
          status: :warning,
          message:
            "Description too short (#{String.length(description)} chars, recommended: 50-160)",
          value: description
        }

      true ->
        %{
          status: :ok,
          message: "Description length is good (#{String.length(description)} chars)",
          value: description
        }
    end
  end

  defp check_open_graph_tags(%{doc: doc}) do
    og_tags = [
      {"og:title", "title"},
      {"og:description", "description"},
      {"og:image", "image"},
      {"og:url", "url"},
      {"og:type", "type"}
    ]

    found_tags =
      Enum.map(og_tags, fn {property, key} ->
        case Floki.find(doc, "meta[property='#{property}']") do
          [] ->
            {key, nil}

          [{_, attrs, _}] ->
            case Enum.find(attrs, fn {k, _} -> k == "content" end) do
              {_, value} -> {key, String.trim(value)}
              _ -> {key, nil}
            end
        end
      end)
      |> Enum.into(%{})

    missing = Enum.filter(og_tags, fn {_, key} -> is_nil(found_tags[key]) end)

    cond do
      length(missing) == length(og_tags) ->
        %{
          status: :error,
          message: "No Open Graph tags found",
          tags: found_tags,
          missing: Enum.map(missing, fn {_, k} -> k end)
        }

      length(missing) > 0 ->
        %{
          status: :warning,
          message:
            "Missing some Open Graph tags: #{Enum.join(Enum.map(missing, fn {_, k} -> k end), ", ")}",
          tags: found_tags,
          missing: Enum.map(missing, fn {_, k} -> k end)
        }

      true ->
        %{
          status: :ok,
          message: "All essential Open Graph tags present",
          tags: found_tags,
          missing: []
        }
    end
  end

  defp check_alt_text(%{doc: doc}) do
    images = Floki.find(doc, "img")

    if images == [] do
      %{status: :ok, message: "No images found", total: 0, missing_alt: 0, percentage: 100}
    else
      missing_alt =
        Enum.count(images, fn img ->
          attrs = elem(img, 1)
          alt_attr = Enum.find(attrs, fn {k, _} -> k == "alt" end)

          case alt_attr do
            {_, value} when is_binary(value) and value != "" -> false
            _ -> true
          end
        end)

      total = length(images)
      percentage = if total > 0, do: round((total - missing_alt) / total * 100), else: 100

      cond do
        missing_alt == 0 ->
          %{
            status: :ok,
            message: "All images have alt text (#{total} images)",
            total: total,
            missing_alt: 0,
            percentage: percentage
          }

        percentage >= 80 ->
          %{
            status: :warning,
            message:
              "#{missing_alt} of #{total} images missing alt text (#{percentage}% have alt text)",
            total: total,
            missing_alt: missing_alt,
            percentage: percentage
          }

        true ->
          %{
            status: :error,
            message:
              "#{missing_alt} of #{total} images missing alt text (#{percentage}% have alt text)",
            total: total,
            missing_alt: missing_alt,
            percentage: percentage
          }
      end
    end
  end

  defp check_ssl(url) do
    uri = URI.parse(url)

    case uri.scheme do
      "https" ->
        %{status: :ok, message: "Using HTTPS", scheme: "https"}

      "http" ->
        %{status: :error, message: "Not using HTTPS (insecure)", scheme: "http"}

      _ ->
        %{status: :warning, message: "Unknown scheme", scheme: uri.scheme || "unknown"}
    end
  end

  defp check_mobile_friendly(%{doc: doc}) do
    # Check for viewport meta tag
    viewport =
      case Floki.find(doc, "meta[name='viewport']") do
        [] ->
          nil

        [{_, attrs, _}] ->
          case Enum.find(attrs, fn {k, _} -> k == "content" end) do
            {_, value} -> value
            _ -> nil
          end

        _ ->
          nil
      end

    # Check for responsive design indicators
    has_responsive_css =
      Floki.find(doc, "link[rel='stylesheet']")
      |> Enum.any?(fn link ->
        attrs = elem(link, 1)
        href = Enum.find_value(attrs, fn {k, v} -> if k == "href", do: v end)

        if href do
          String.contains?(String.downcase(href), "responsive") or
            String.contains?(String.downcase(href), "mobile") or
            String.contains?(String.downcase(href), "bootstrap")
        else
          false
        end
      end)

    cond do
      is_nil(viewport) ->
        %{
          status: :error,
          message: "Missing viewport meta tag",
          has_viewport: false,
          has_responsive_css: has_responsive_css
        }

      not String.contains?(String.downcase(viewport), "width") ->
        %{
          status: :warning,
          message: "Viewport tag present but may not be configured correctly",
          has_viewport: true,
          has_responsive_css: has_responsive_css,
          viewport_content: viewport
        }

      true ->
        %{
          status: :ok,
          message: "Mobile-friendly viewport configured",
          has_viewport: true,
          has_responsive_css: has_responsive_css,
          viewport_content: viewport
        }
    end
  end

  defp check_page_speed_indicators(%{doc: doc, headers: headers}) do
    # Check for common performance optimizations
    has_defer_scripts =
      Floki.find(doc, "script")
      |> Enum.any?(fn script ->
        attrs = elem(script, 1)
        Enum.any?(attrs, fn {k, v} -> k == "defer" or k == "async" end)
      end)

    # Check for compression (gzip, brotli)
    content_encoding =
      Enum.find_value(headers, fn {k, encoding_value} ->
        if String.downcase(k) == "content-encoding", do: encoding_value
      end)

    has_compression = not is_nil(content_encoding)

    # Check for image optimization hints (lazy loading)
    has_lazy_images =
      Floki.find(doc, "img[loading='lazy']")
      |> length() > 0

    # Basic indicators (we can't actually measure load time without running the page)
    indicators = %{
      has_defer_scripts: has_defer_scripts,
      has_compression: has_compression,
      has_lazy_images: has_lazy_images,
      compression_type: content_encoding
    }

    score = 0
    score = if has_defer_scripts, do: score + 1, else: score
    score = if has_compression, do: score + 1, else: score
    score = if has_lazy_images, do: score + 1, else: score

    cond do
      score == 3 ->
        %{
          status: :ok,
          message: "Good performance indicators (deferred scripts, compression, lazy loading)",
          indicators: indicators,
          score: score
        }

      score >= 1 ->
        %{
          status: :warning,
          message: "Some performance optimizations missing (#{score}/3 indicators)",
          indicators: indicators,
          score: score
        }

      true ->
        %{
          status: :warning,
          message: "Limited performance optimizations detected",
          indicators: indicators,
          score: score
        }
    end
  end

  # ----------------------------------------------------------------------------
  # PRIVATE: Scoring
  # ----------------------------------------------------------------------------

  defp calculate_overall_score(health_data) do
    checks = [
      health_data.meta_title,
      health_data.meta_description,
      health_data.open_graph,
      health_data.alt_text,
      health_data.ssl,
      health_data.mobile_friendly,
      health_data.page_speed
    ]

    {ok_count, warning_count, error_count} =
      Enum.reduce(checks, {0, 0, 0}, fn check, {ok, warn, err} ->
        case check.status do
          :ok -> {ok + 1, warn, err}
          :warning -> {ok, warn + 1, err}
          :error -> {ok, warn, err + 1}
        end
      end)

    total = length(checks)
    score = (ok_count * 100 + warning_count * 50) / total

    %{
      score: round(score),
      ok: ok_count,
      warnings: warning_count,
      errors: error_count,
      total: total
    }
  end
end
