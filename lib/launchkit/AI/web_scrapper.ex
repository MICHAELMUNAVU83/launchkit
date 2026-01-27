defmodule Launchkit.WebScraper do
  @moduledoc """
  Web scraper optimized for Google Ads asset generation.
  Extracts brand voice, value propositions, keywords, and visual themes
  to power AI generation of headlines, descriptions, images, and videos.
  """

  require Logger

  # ----------------------------------------------------------------------------
  # §1: AI PROMPTS FOR ADS ASSET GENERATION
  # ----------------------------------------------------------------------------

  @page_analyzer_context """
  You are an expert marketing analyst specializing in Google Ads. Your task is to analyze a web page and extract information that will be used to generate Performance Max campaign assets.

  Focus on extracting:
  - Brand voice and tone (professional, friendly, urgent, luxurious, etc.)
  - Unique value propositions and differentiators
  - Key benefits and features (customer-focused)
  - Target audience signals
  - Emotional triggers and pain points addressed
  - Call-to-action patterns used

  Return a JSON response with this structure:
  {
    "page_type": "homepage/landing/product/service/pricing/about/other",
    "company_name": "Company Name",
    "tagline": "Main tagline or slogan if present",
    "brand_voice": {
      "tone": ["professional", "friendly", "urgent", "etc"],
      "personality": "Brief description of brand personality",
      "language_style": "formal/casual/technical/conversational"
    },
    "value_propositions": [
      {
        "statement": "The core value prop",
        "benefit": "What the customer gains",
        "differentiator": "What makes this unique"
      }
    ],
    "target_audience": {
      "primary": "Main target audience",
      "pain_points": ["Pain point 1", "Pain point 2"],
      "desires": ["Desire 1", "Desire 2"]
    },
    "products_services": [
      {
        "name": "Product/Service name",
        "description": "Brief description",
        "key_benefits": ["Benefit 1", "Benefit 2"],
        "keywords": ["keyword1", "keyword2"]
      }
    ],
    "social_proof": {
      "testimonials": ["Quote 1", "Quote 2"],
      "stats": ["2000+ customers", "99% uptime"],
      "trust_signals": ["Award", "Certification"]
    },
    "calls_to_action": ["Get Started", "Book Demo", "Learn More"],
    "pricing_signals": {
      "has_pricing": true,
      "price_points": ["$29/mo", "$99/mo"],
      "free_trial": true,
      "money_back_guarantee": false
    },
    "visual_themes": {
      "primary_colors": ["#hex1", "#hex2"],
      "imagery_style": "tech/people/abstract/product-focused",
      "mood": "modern/classic/playful/serious"
    },
    "seo_keywords": ["keyword1", "keyword2", "keyword3"]
  }
  """

  @final_synthesizer_context """
  You are an expert Google Ads strategist. You will receive analysis from multiple pages of a website.
  Synthesize this into a comprehensive brief that will power AI generation of:
  - 15 short headlines (max 30 characters each)
  - 5 long headlines (max 90 characters each)
  - 5 descriptions (max 90 characters each)
  - Image generation prompts
  - Video generation prompts

  Return a single JSON with this structure:
  {
    "brand_summary": {
      "company_name": "Name",
      "industry": "Industry",
      "one_liner": "One sentence describing what they do",
      "tagline": "Their tagline if available",
      "brand_voice": {
        "tone": ["tone1", "tone2"],
        "personality": "Description",
        "do": ["Write like this", "Use these words"],
        "dont": ["Avoid this", "Never say that"]
      }
    },
    "messaging_pillars": [
      {
        "pillar": "Core message theme",
        "proof_points": ["Evidence 1", "Evidence 2"],
        "emotional_hook": "The feeling this evokes",
        "keywords": ["keyword1", "keyword2"]
      }
    ],
    "target_audience": {
      "primary_persona": "Description of ideal customer",
      "pain_points": ["Pain 1", "Pain 2", "Pain 3"],
      "desires": ["Want 1", "Want 2", "Want 3"],
      "objections": ["Objection 1", "Objection 2"]
    },
    "competitive_advantages": [
      {
        "advantage": "What sets them apart",
        "proof": "Evidence or reason to believe"
      }
    ],
    "headline_ingredients": {
      "power_words": ["Transform", "Instant", "Free"],
      "benefits": ["Save time", "Increase revenue"],
      "features": ["24/7 support", "AI-powered"],
      "social_proof_snippets": ["2000+ customers", "99% satisfaction"],
      "urgency_triggers": ["Limited time", "Start today"],
      "question_hooks": ["Tired of X?", "Want to Y?"]
    },
    "visual_direction": {
      "primary_colors": ["#hex1", "#hex2"],
      "secondary_colors": ["#hex3"],
      "imagery_themes": ["theme1", "theme2"],
      "mood_keywords": ["modern", "trustworthy", "innovative"],
      "avoid": ["Avoid this style", "Not this"],
      "suggested_scenes": [
        "Description of scene that would work for an ad image"
      ]
    },
    "video_direction": {
      "tone": "Energetic/Calm/Professional/etc",
      "pacing": "Fast/Medium/Slow",
      "suggested_concepts": [
        {
          "concept": "Brief video concept",
          "opening_hook": "First 2 seconds idea",
          "key_visuals": ["Visual 1", "Visual 2"]
        }
      ]
    },
    "calls_to_action": {
      "primary": "Main CTA",
      "secondary": ["Alt CTA 1", "Alt CTA 2"],
      "urgency_variants": ["CTA with urgency"]
    },
    "seo_keywords": {
      "primary": ["main keyword 1", "main keyword 2"],
      "secondary": ["supporting keyword 1"],
      "long_tail": ["long tail phrase 1"]
    },
    "metadata": {
      "website_url": "url",
      "pages_analyzed": 5,
      "confidence_score": "high/medium/low",
      "missing_info": ["What we couldn't find"]
    }
  }
  """

  # ----------------------------------------------------------------------------
  # §2: PUBLIC API
  # ----------------------------------------------------------------------------

  @doc """
  Main entry point. Analyzes a website and returns a comprehensive brief
  for generating Google Ads assets.

  ## Options
    - `:max_pages` - Maximum pages to analyze (default: 8)

  ## Returns
    `{:ok, analysis}` or `{:error, reason}`
  """
  def analyze_website(url, options \\ []) do
    Logger.info("Starting website analysis for ads generation: #{url}")
    max_pages = Keyword.get(options, :max_pages, 8)

    with {:ok, urls_to_scrape} <- discover_pages(url, max_pages),
         {:ok, page_analyses} <- analyze_pages_in_parallel(urls_to_scrape),
         {:ok, final_analysis} <- synthesize_for_ads(page_analyses) do
      Logger.info("Successfully completed analysis for #{url}")

      result =
        final_analysis
        |> add_metadata(url, urls_to_scrape)
        |> add_generation_ready_flag()

      {:ok, result}
    else
      {:error, reason} ->
        Logger.error("Website analysis failed for #{url}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # ----------------------------------------------------------------------------
  # §3: WORKFLOW FUNCTIONS
  # ----------------------------------------------------------------------------

  defp discover_pages(url, max_pages) do
    Logger.info("Discovering pages from #{url}...")

    with {:ok, main_page_data} <- scrape_single_page(url) do
      related =
        discover_ads_relevant_pages(url, main_page_data)
        |> Enum.take(max_pages - 1)

      urls = [url | related] |> Enum.uniq()
      Logger.info("Found #{length(urls)} pages to analyze")
      {:ok, urls}
    end
  end

  defp analyze_pages_in_parallel(urls) do
    tasks =
      Enum.map(urls, fn url ->
        Task.async(fn -> analyze_single_page(url) end)
      end)

    results = Task.await_many(tasks, 180_000)

    {successes, failures} =
      Enum.partition(results, fn
        {:ok, _} -> true
        _ -> false
      end)

    if failures != [] do
      Logger.warning("Failed to analyze #{length(failures)} pages")
    end

    successful = Enum.map(successes, fn {:ok, analysis} -> analysis end)

    if successful == [] do
      {:error, "All pages failed to analyze"}
    else
      {:ok, successful}
    end
  end

  defp analyze_single_page(url) do
    with {:ok, page_data} <- scrape_single_page(url),
         prompt <- build_page_prompt(page_data),
         {:ok, response} <-
           Launchkit.OpenAI.send_request_to_openai(@page_analyzer_context, prompt),
         {:ok, parsed} <- parse_ai_response(response) do
      {:ok, Map.put(parsed, "source_url", url)}
    else
      {:error, reason} ->
        Logger.error("Failed to analyze #{url}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp synthesize_for_ads(page_analyses) do
    Logger.info("Synthesizing #{length(page_analyses)} pages into ads brief...")
    prompt = build_synthesis_prompt(page_analyses)

    with {:ok, response} <-
           Launchkit.OpenAI.send_request_to_openai(@final_synthesizer_context, prompt),
         {:ok, parsed} <- parse_ai_response(response) do
      {:ok, parsed}
    end
  end

  # ----------------------------------------------------------------------------
  # §4: PROMPT BUILDING
  # ----------------------------------------------------------------------------

  defp build_page_prompt(page_data) do
    title = page_data[:title] |> safe_text()
    meta = page_data[:meta_description] |> safe_text()
    content = page_data[:main_content] |> safe_text() |> String.slice(0, 15_000)
    headings = page_data[:headings] |> Enum.join("\n")
    ctas = page_data[:ctas] |> Enum.join(", ")

    """
    Analyze this webpage for Google Ads asset generation:

    URL: #{page_data[:source_url]}
    TITLE: #{title}
    META DESCRIPTION: #{meta}

    HEADINGS:
    #{headings}

    CALLS TO ACTION FOUND:
    #{ctas}

    PAGE CONTENT:
    #{content}
    """
  end

  defp build_synthesis_prompt(page_analyses) do
    """
    Synthesize these page analyses into a comprehensive Google Ads brief.
    Focus on extracting actionable insights for headline, description, image, and video generation.

    PAGE ANALYSES:
    #{Jason.encode!(page_analyses, pretty: true)}
    """
  end

  # ----------------------------------------------------------------------------
  # §5: PAGE SCRAPING
  # ----------------------------------------------------------------------------

  defp scrape_single_page(url) do
    Logger.info("Scraping: #{url}")

    with {:ok, html} <- fetch_page(url),
         false <- is_pdf?(html),
         {:ok, doc} <- parse_html(html) do
      {:ok,
       %{
         source_url: url,
         title: extract_title(doc),
         meta_description: extract_meta(doc, "description"),
         meta_keywords: extract_meta(doc, "keywords"),
         main_content: extract_main_content(doc),
         headings: extract_headings(doc),
         ctas: extract_ctas(doc),
         links: extract_links(doc),
         navigation: extract_navigation(doc),
         images: extract_image_info(doc),
         colors: extract_colors(doc)
       }}
    else
      true -> {:error, "Content is PDF"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp fetch_page(url) do
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
      {:ok, %Req.Response{status: 200, body: body}} -> {:ok, body}
      {:ok, %Req.Response{status: status}} -> {:error, "HTTP #{status}"}
      {:error, reason} -> {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  defp is_pdf?(content), do: String.starts_with?(String.trim(content), "%PDF-")

  defp parse_html(html) do
    {:ok, Floki.parse_document!(html)}
  rescue
    e -> {:error, "Parse failed: #{inspect(e)}"}
  end

  # ----------------------------------------------------------------------------
  # §6: DATA EXTRACTION
  # ----------------------------------------------------------------------------

  defp extract_title(doc) do
    case Floki.find(doc, "title") do
      [{"title", _, [title]}] -> String.trim(title)
      _ -> nil
    end
  end

  defp extract_meta(doc, name) do
    Floki.find(doc, "meta[name='#{name}']")
    |> Enum.find_value(fn {"meta", attrs, _} ->
      Enum.find_value(attrs, fn
        {"content", content} -> String.trim(content)
        _ -> nil
      end)
    end)
  end

  defp extract_main_content(doc) do
    doc
    |> Floki.filter_out("nav, header, footer, aside, script, style, noscript")
    |> Floki.text()
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp extract_headings(doc) do
    Floki.find(doc, "h1, h2, h3")
    |> Enum.map(&Floki.text/1)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.take(20)
  end

  defp extract_ctas(doc) do
    # Find buttons and links that look like CTAs
    cta_patterns =
      ~r/get started|sign up|try|demo|contact|buy|order|subscribe|download|learn more|start|join/i

    buttons =
      Floki.find(doc, "button, a.btn, a.button, [class*='cta'], [class*='btn']")
      |> Enum.map(&Floki.text/1)
      |> Enum.map(&String.trim/1)

    links =
      Floki.find(doc, "a")
      |> Enum.map(&Floki.text/1)
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&Regex.match?(cta_patterns, &1))

    (buttons ++ links)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    |> Enum.take(10)
  end

  defp extract_links(doc) do
    Floki.find(doc, "a[href]")
    |> Enum.map(fn {"a", attrs, content} ->
      href = get_attr(attrs, "href")
      %{href: href, text: Floki.text(content) |> String.trim()}
    end)
    |> Enum.reject(fn %{href: href, text: text} ->
      is_nil(href) or href == "#" or text == ""
    end)
  end

  defp extract_navigation(doc) do
    Floki.find(doc, "nav a")
    |> Enum.map(fn {"a", attrs, content} ->
      %{
        href: get_attr(attrs, "href"),
        text: Floki.text(content) |> String.trim()
      }
    end)
    |> Enum.reject(fn %{href: href, text: text} ->
      is_nil(href) or href == "#" or text == ""
    end)
  end

  defp extract_image_info(doc) do
    Floki.find(doc, "img[src]")
    |> Enum.map(fn {"img", attrs, _} ->
      %{
        src: get_attr(attrs, "src"),
        alt: get_attr(attrs, "alt") || ""
      }
    end)
    |> Enum.take(20)
  end

  defp extract_colors(doc) do
    # Try to find brand colors from inline styles or CSS variables
    # This is a basic implementation - could be enhanced
    Floki.find(doc, "[style]")
    |> Enum.flat_map(fn {_, attrs, _} ->
      style = get_attr(attrs, "style") || ""

      Regex.scan(~r/#[0-9A-Fa-f]{6}|#[0-9A-Fa-f]{3}/, style)
      |> List.flatten()
    end)
    |> Enum.uniq()
    |> Enum.take(5)
  end

  defp get_attr(attrs, name) do
    Enum.find_value(attrs, fn
      {^name, value} -> value
      _ -> nil
    end)
  end

  # ----------------------------------------------------------------------------
  # §7: PAGE DISCOVERY
  # ----------------------------------------------------------------------------

  defp discover_ads_relevant_pages(base_url, main_page_data) do
    base_domain = extract_domain(base_url)

    # Pages most valuable for ads generation
    priority_keywords = [
      # Highest priority - understand offering
      "pricing",
      "plans",
      "features",
      "product",
      "service",
      # High priority - social proof & trust
      "testimonial",
      "case study",
      "customer",
      "success",
      "review",
      # Medium priority - brand voice
      "about",
      "why",
      "how it works",
      "solution",
      # Lower priority but useful
      "faq",
      "contact",
      "demo"
    ]

    nav_links = main_page_data[:navigation] || []
    all_links = main_page_data[:links] || []

    (nav_links ++ all_links)
    |> Enum.filter(fn %{href: href, text: text} ->
      is_internal?(href, base_domain) and
        matches_keywords?(text, priority_keywords)
    end)
    |> Enum.map(fn %{href: href} -> normalize_url(href, base_url) end)
    |> Enum.uniq()
    |> prioritize_for_ads()
  end

  defp prioritize_for_ads(urls) do
    priority_patterns = [
      {~r/pricing|plans|cost/i, 100},
      {~r/features?|product|service/i, 90},
      {~r/testimonial|review|case.?study|success/i, 85},
      {~r/customer|client/i, 80},
      {~r/about|why|how.?it.?works/i, 70},
      {~r/solution|benefit/i, 60},
      {~r/faq|demo|contact/i, 50}
    ]

    urls
    |> Enum.map(fn url ->
      score =
        Enum.reduce(priority_patterns, 0, fn {pattern, weight}, acc ->
          if Regex.match?(pattern, url), do: max(acc, weight), else: acc
        end)

      {url, score}
    end)
    |> Enum.sort_by(fn {_, score} -> score end, :desc)
    |> Enum.map(fn {url, _} -> url end)
  end

  defp matches_keywords?(text, keywords) do
    text_lower = String.downcase(text || "")
    Enum.any?(keywords, &String.contains?(text_lower, &1))
  end

  defp is_internal?(nil, _), do: false
  defp is_internal?("", _), do: false

  defp is_internal?(href, base_domain) do
    case URI.parse(href) do
      %URI{scheme: "mailto"} -> false
      %URI{scheme: "tel"} -> false
      %URI{host: nil} -> true
      %URI{host: ^base_domain} -> true
      %URI{host: host} -> String.ends_with?(host, "." <> base_domain)
      _ -> false
    end
  end

  defp normalize_url(href, base_url) do
    case URI.parse(href) do
      %URI{host: nil} -> URI.merge(URI.parse(base_url), href) |> URI.to_string()
      _ -> href
    end
  end

  defp extract_domain(url) do
    case URI.parse(url) do
      %URI{host: host} when is_binary(host) -> host
      _ -> nil
    end
  end

  # ----------------------------------------------------------------------------
  # §8: RESPONSE HANDLING
  # ----------------------------------------------------------------------------

  defp parse_ai_response(response) do
    cleaned =
      response
      |> String.trim()
      |> String.replace(~r/^```json\n?/, "")
      |> String.replace(~r/^```\n?/, "")
      |> String.replace(~r/\n?```$/, "")
      |> String.trim()

    case Jason.decode(cleaned) do
      {:ok, parsed} ->
        {:ok, parsed}

      {:error, error} ->
        Logger.error("JSON parse failed: #{inspect(error)}")
        Logger.error("First 200 chars: #{String.slice(cleaned, 0, 200)}")
        {:error, "Invalid JSON from AI"}
    end
  end

  defp add_metadata(analysis, url, scraped_urls) do
    Map.merge(analysis, %{
      "website_url" => url,
      "analyzed_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "scraper_version" => "1.0.0-launchkit",
      "pages_analyzed" => length(scraped_urls),
      "analyzed_urls" => scraped_urls
    })
  end

  defp add_generation_ready_flag(analysis) do
    # Check if we have minimum required data
    has_company = get_in(analysis, ["brand_summary", "company_name"]) != nil
    has_pillars = length(get_in(analysis, ["messaging_pillars"]) || []) > 0

    Map.put(analysis, "ready_for_generation", has_company and has_pillars)
  end

  defp safe_text(nil), do: ""

  defp safe_text(text) when is_binary(text) do
    :unicode.characters_to_binary(text, :utf8, :utf8)
    |> case do
      {:error, _, _} -> ""
      {:incomplete, _, _} -> ""
      result -> result
    end
  end

  defp safe_text(_), do: ""
end
