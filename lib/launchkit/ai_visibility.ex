defmodule Launchkit.AIVisibility do
  @moduledoc """
  Analyzes and improves AI search visibility for businesses.
  Simulates how AI search engines (ChatGPT, Perplexity, etc.) would find and understand a business.
  """

  require Logger
  alias Launchkit.OpenAI
  alias Launchkit.WebScraper

  # Context prompts for OpenAI
  @ai_search_context """
  You are an AI search engine simulator. You analyze how well a business would appear in AI-powered search results (like ChatGPT, Perplexity, Claude).
  Focus on understanding what information would be available, how relevant it is, and what gaps exist.
  """

  @recommendations_context """
  You are an AI visibility expert. You provide actionable recommendations to improve how businesses appear in AI search results.
  Focus on practical, implementable suggestions that will have real impact.
  """

  @blog_generator_context """
  You are an expert content writer specializing in SEO and AI-optimized content.
  You write blog posts that help businesses improve their visibility in AI search engines while providing value to readers.
  """

  @doc """
  Analyzes AI visibility for a website and returns a comprehensive score and recommendations.
  """
  def analyze_visibility(url, analysis \\ nil) do
    Logger.info("Starting AI visibility analysis for: #{url}")

    with {:ok, website_data} <- gather_website_data(url, analysis),
         {:ok, ai_search_simulation} <- simulate_ai_search(website_data),
         {:ok, scores} <- calculate_scores(website_data, ai_search_simulation),
         {:ok, recommendations} <- generate_recommendations(website_data, scores) do
      {:ok,
       %{
         overall_score: scores.overall,
         scores: scores,
         recommendations: recommendations,
         ai_search_simulation: ai_search_simulation,
         analyzed_at: DateTime.utc_now() |> DateTime.to_iso8601()
       }}
    else
      {:error, reason} ->
        Logger.error("AI visibility analysis failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Generates blog post topics and content to improve AI visibility.
  """
  def generate_blog_topics(analysis, visibility_data) do
    prompt = build_blog_topics_prompt(analysis, visibility_data)

    case OpenAI.send_request_to_openai(@blog_generator_context, prompt) do
      {:ok, response} ->
        parse_blog_topics(response)

      {:error, reason} ->
        Logger.error("Failed to generate blog topics: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Generates a full blog post based on a topic.
  """
  def generate_blog_post(topic, analysis) do
    prompt = build_blog_post_prompt(topic, analysis)

    case OpenAI.send_request_to_openai(@blog_generator_context, prompt) do
      {:ok, response} ->
        parse_blog_post(response)

      {:error, reason} ->
        Logger.error("Failed to generate blog post: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # ============================================================================
  # PRIVATE FUNCTIONS
  # ============================================================================

  defp gather_website_data(url, nil) do
    # If no analysis provided, do a quick scrape
    case WebScraper.analyze_website(url, max_pages: 3) do
      {:ok, analysis} -> {:ok, %{url: url, analysis: analysis}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp gather_website_data(url, analysis) do
    {:ok, %{url: url, analysis: analysis}}
  end

  defp simulate_ai_search(website_data) do
    prompt = build_ai_search_simulation_prompt(website_data)

    case OpenAI.send_request_to_openai(@ai_search_context, prompt) do
      {:ok, response} ->
        parse_ai_search_response(response)

      {:error, reason} ->
        Logger.error("Failed to simulate AI search: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp calculate_scores(website_data, ai_search_simulation) do
    # Calculate various scores based on the simulation
    presence_score = calculate_presence_score(ai_search_simulation)
    completeness_score = calculate_completeness_score(website_data, ai_search_simulation)
    recency_score = calculate_recency_score(website_data, ai_search_simulation)
    authority_score = calculate_authority_score(ai_search_simulation)

    overall =
      (presence_score * 0.3 + completeness_score * 0.3 + recency_score * 0.2 +
         authority_score * 0.2)
      |> round()

    {:ok,
     %{
       overall: overall,
       presence: presence_score,
       completeness: completeness_score,
       recency: recency_score,
       authority: authority_score
     }}
  end

  defp generate_recommendations(website_data, scores) do
    prompt = build_recommendations_prompt(website_data, scores)

    case OpenAI.send_request_to_openai(@recommendations_context, prompt) do
      {:ok, response} ->
        parse_recommendations(response)

      {:error, reason} ->
        Logger.error("Failed to generate recommendations: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Score calculation helpers
  defp calculate_presence_score(ai_search_simulation) do
    # Based on how well the business appears in AI search results
    mentions = Map.get(ai_search_simulation, "mentions", 0)
    relevance = Map.get(ai_search_simulation, "relevance_score", 0)

    base_score = min(mentions * 10, 50)
    relevance_bonus = relevance * 0.5

    min(round(base_score + relevance_bonus), 100)
  end

  defp calculate_completeness_score(website_data, ai_search_simulation) do
    analysis = website_data.analysis

    # Check for key information
    has_company_name = !is_nil(get_in(analysis, ["brand_summary", "company_name"]))
    has_description = !is_nil(get_in(analysis, ["brand_summary", "one_liner"]))
    has_industry = !is_nil(get_in(analysis, ["brand_summary", "industry"]))

    has_services =
      !is_nil(get_in(analysis, ["products_services"])) &&
        length(get_in(analysis, ["products_services"]) || []) > 0

    completeness =
      [
        has_company_name && 25,
        has_description && 25,
        has_industry && 25,
        has_services && 25
      ]
      |> Enum.filter(& &1)
      |> Enum.sum()

    # Adjust based on AI search findings
    ai_findings = Map.get(ai_search_simulation, "information_found", [])
    ai_bonus = min(length(ai_findings) * 5, 20)

    min(completeness + ai_bonus, 100)
  end

  defp calculate_recency_score(website_data, _ai_search_simulation) do
    # Check if there's recent content (this is a simplified version)
    # In a real implementation, you'd check for blog posts, news, social media activity
    analysis = website_data.analysis

    # Check if analysis is recent (within last 6 months)
    analyzed_at = Map.get(analysis, "analyzed_at")

    if analyzed_at do
      case DateTime.from_iso8601(analyzed_at) do
        {:ok, datetime, _} ->
          # Calculate difference in days, then convert to approximate months
          days_ago = DateTime.diff(DateTime.utc_now(), datetime, :day)
          months_ago = div(days_ago, 30)

          if months_ago <= 6, do: 80, else: max(80 - (months_ago - 6) * 10, 20)

        _ ->
          50
      end
    else
      50
    end
  end

  defp calculate_authority_score(ai_search_simulation) do
    # Based on citations, mentions, and credibility signals
    citations = Map.get(ai_search_simulation, "citations", 0)
    credibility_signals = Map.get(ai_search_simulation, "credibility_signals", [])

    base_score = min(citations * 15, 60)
    credibility_bonus = length(credibility_signals) * 10

    min(base_score + credibility_bonus, 100)
  end

  # Prompt builders
  defp build_ai_search_simulation_prompt(website_data) do
    analysis = website_data.analysis
    company_name = get_in(analysis, ["brand_summary", "company_name"]) || "Unknown"
    industry = get_in(analysis, ["brand_summary", "industry"]) || "Unknown"
    one_liner = get_in(analysis, ["brand_summary", "one_liner"]) || "N/A"

    """
    You are simulating how an AI search engine (like ChatGPT, Perplexity, Claude) would find and understand this business when someone searches for it.

    BUSINESS INFORMATION:
    Company: #{company_name}
    Industry: #{industry}
    Description: #{one_liner}
    Website: #{website_data.url}

    Analyze and return JSON with:
    {
      "mentions": <number of times business would be mentioned in AI search results>,
      "relevance_score": <0-10, how relevant the business is to its industry>,
      "information_found": ["list of information AI would find about the business"],
      "citations": <number of credible sources that would mention this business>,
      "credibility_signals": ["list of credibility indicators"],
      "gaps": ["list of information gaps that would hurt AI visibility"],
      "summary": "Brief summary of how well this business appears in AI search"
    }
    """
  end

  defp build_recommendations_prompt(website_data, scores) do
    analysis = website_data.analysis
    company_name = get_in(analysis, ["brand_summary", "company_name"]) || "Unknown"

    """
    Based on the AI visibility analysis, provide actionable recommendations to improve this business's visibility in AI search engines.

    BUSINESS: #{company_name}
    CURRENT SCORES:
    - Overall: #{scores.overall}/100
    - Presence: #{scores.presence}/100
    - Completeness: #{scores.completeness}/100
    - Recency: #{scores.recency}/100
    - Authority: #{scores.authority}/100

    Return JSON with:
    {
      "priority_recommendations": [
        {
          "title": "Recommendation title",
          "description": "What to do",
          "impact": "high/medium/low",
          "effort": "high/medium/low"
        }
      ],
      "blog_topics": [
        {
          "topic": "Blog topic title",
          "reason": "Why this would help AI visibility",
          "priority": "high/medium/low"
        }
      ],
      "quick_wins": ["List of quick improvements"],
      "long_term_strategy": "Brief strategy for long-term AI visibility improvement"
    }
    """
  end

  defp build_blog_topics_prompt(analysis, visibility_data) do
    company_name = get_in(analysis, ["brand_summary", "company_name"]) || "Unknown"
    industry = get_in(analysis, ["brand_summary", "industry"]) || "Unknown"

    """
    Generate blog post topics that would improve AI search visibility for this business.

    BUSINESS: #{company_name}
    INDUSTRY: #{industry}

    AI VISIBILITY GAPS: #{inspect(Map.get(visibility_data, :gaps, []))}

    Generate 5-8 blog topics that:
    1. Are relevant to the business and industry
    2. Would help AI search engines understand the business better
    3. Are SEO-friendly and informative
    4. Address the visibility gaps identified

    Return JSON:
    {
      "topics": [
        {
          "title": "Blog post title",
          "description": "What the blog post would cover",
          "keywords": ["relevant", "keywords"],
          "estimated_impact": "high/medium/low",
          "why_it_helps": "Why this topic improves AI visibility"
        }
      ]
    }
    """
  end

  defp build_blog_post_prompt(topic, analysis) do
    company_name = get_in(analysis, ["brand_summary", "company_name"]) || "Unknown"
    industry = get_in(analysis, ["brand_summary", "industry"]) || "Unknown"
    brand_voice = get_in(analysis, ["brand_summary", "brand_voice"]) || %{}

    """
    Write a comprehensive, SEO-optimized blog post for this business.

    TOPIC: #{topic["title"]}
    DESCRIPTION: #{topic["description"] || "N/A"}

    BUSINESS CONTEXT:
    Company: #{company_name}
    Industry: #{industry}
    Brand Voice: #{inspect(brand_voice)}

    Write a blog post that:
    1. Is 800-1200 words
    2. Is well-structured with headings
    3. Includes the business naturally (not overly promotional)
    4. Is informative and valuable to readers
    5. Includes relevant keywords naturally
    6. Has a clear introduction and conclusion
    7. Is written in the brand's voice

    Return JSON:
    {
      "title": "Final blog post title",
      "content": "Full blog post content in markdown format",
      "excerpt": "Brief excerpt (100-150 words)",
      "keywords": ["list", "of", "keywords"],
      "meta_description": "SEO meta description"
    }
    """
  end

  # Parsers
  defp parse_ai_search_response(response) do
    cleaned =
      response
      |> String.trim()
      |> String.replace(~r/^```json\n?/, "")
      |> String.replace(~r/\n?```$/, "")
      |> String.trim()

    case Jason.decode(cleaned) do
      {:ok, parsed} ->
        {:ok, parsed}

      {:error, error} ->
        Logger.error("Failed to parse AI search response: #{inspect(error)}")
        {:error, "Invalid response format"}
    end
  end

  defp parse_recommendations(response) do
    cleaned =
      response
      |> String.trim()
      |> String.replace(~r/^```json\n?/, "")
      |> String.replace(~r/\n?```$/, "")
      |> String.trim()

    case Jason.decode(cleaned) do
      {:ok, parsed} ->
        {:ok, parsed}

      {:error, error} ->
        Logger.error("Failed to parse recommendations: #{inspect(error)}")
        {:error, "Invalid response format"}
    end
  end

  defp parse_blog_topics(response) do
    cleaned =
      response
      |> String.trim()
      |> String.replace(~r/^```json\n?/, "")
      |> String.replace(~r/\n?```$/, "")
      |> String.trim()

    case Jason.decode(cleaned) do
      {:ok, parsed} ->
        {:ok, parsed}

      {:error, error} ->
        Logger.error("Failed to parse blog topics: #{inspect(error)}")
        {:error, "Invalid response format"}
    end
  end

  defp parse_blog_post(response) do
    cleaned =
      response
      |> String.trim()
      |> String.replace(~r/^```json\n?/, "")
      |> String.replace(~r/\n?```$/, "")
      |> String.trim()

    case Jason.decode(cleaned) do
      {:ok, parsed} ->
        {:ok, parsed}

      {:error, error} ->
        Logger.error("Failed to parse blog post: #{inspect(error)}")
        {:error, "Invalid response format"}
    end
  end
end
