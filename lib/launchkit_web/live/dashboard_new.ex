defmodule LaunchkitWeb.DashboardLive.New do
  @moduledoc """
  Multi-step asset generation flow:
  1. Analyze website
  2. Review brand analysis
  3. Generate assets (headlines, images, videos)
  4. Export
  """
  use LaunchkitWeb, :live_view

  alias Launchkit.WebScraper
  alias Launchkit.Assets
  alias Launchkit.Campaigns
  import Ecto.Query
  alias Launchkit.Repo

  @steps [:analyzing, :review, :generate, :export]

  def mount(params, _session, socket) do
    url = params["url"]
    step_param = params["step"]

    # Parse step from params, default to analyzing
    initial_step =
      if step_param do
        try do
          String.to_existing_atom(step_param)
        rescue
          ArgumentError -> :analyzing
        end
      else
        :analyzing
      end

    socket =
      socket
      |> assign(:steps, @steps)
      |> assign(:current_step, initial_step)
      |> assign(:url, url)
      |> assign(:analysis, nil)
      |> assign(:error, nil)
      |> assign(:active_tab, :headlines)
      # Expanded sections for review step
      |> assign(:expanded_sections, MapSet.new())
      # Asset states
      |> assign(:headlines, [])
      |> assign(:long_headlines, [])
      |> assign(:descriptions, [])
      |> assign(:images, [])
      |> assign(:videos, [])
      # Loading states
      |> assign(:generating_headlines, false)
      |> assign(:generating_images, false)
      |> assign(:generating_videos, false)

    # Check for existing website or start analysis if URL provided
    if url && url != "" do
      case Campaigns.get_website_by_url(url) do
        %{id: website_id, analysis: analysis} when not is_nil(analysis) ->
          # Load saved analysis and assets
          headlines = Assets.list_headlines_by_website(website_id) |> Enum.map(&%{text: &1.text})

          long_headlines =
            Assets.list_long_headlines_by_website(website_id) |> Enum.map(&%{text: &1.text})

          descriptions =
            Assets.list_descriptions_by_website(website_id) |> Enum.map(&%{text: &1.text})

          images =
            Assets.list_images_by_website(website_id)
            |> Enum.map(fn img ->
              status =
                case img.status do
                  s when is_atom(s) ->
                    s

                  s when is_binary(s) ->
                    try do
                      String.to_existing_atom(s)
                    rescue
                      ArgumentError -> :completed
                    end

                  _ ->
                    :completed
                end

              %{
                url: img.url,
                prompt: img.prompt,
                aspect_ratio: img.aspect_ratio,
                status: status
              }
            end)

          # Determine current step based on what's available, but respect URL param if set
          default_step =
            cond do
              headlines != [] or long_headlines != [] or descriptions != [] -> :generate
              analysis != nil -> :review
              true -> :analyzing
            end

          # Use step from URL if valid, otherwise use default
          current_step =
            if step_param && step_param in Enum.map(@steps, &Atom.to_string/1) do
              try do
                String.to_existing_atom(step_param)
              rescue
                ArgumentError -> default_step
              end
            else
              default_step
            end

          {:ok,
           socket
           |> assign(:analysis, analysis)
           |> assign(:website_id, website_id)
           |> assign(:headlines, headlines)
           |> assign(:long_headlines, long_headlines)
           |> assign(:descriptions, descriptions)
           |> assign(:images, images)
           |> assign(:current_step, current_step)}

        _ ->
          # No saved analysis, start fresh analysis
          send(self(), {:analyze_website, url})
          {:ok, socket}
      end
    else
      {:ok, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-[#fafaf9] font-['Outfit',sans-serif]">
      <!-- Header -->
      <header class="border-b border-[#e5e5e5] bg-white">
        <div class="max-w-6xl mx-auto px-6 py-4 flex items-center justify-between">
          <.link navigate={~p"/"} class="flex items-center gap-2">
            <div class="w-8 h-8 bg-[#0d0d0d] rounded-lg flex items-center justify-center">
              <svg
                class="w-4 h-4 text-white"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2.5"
              >
                <path d="M5 12l5 5L20 7" stroke-linecap="round" stroke-linejoin="round" />
              </svg>
            </div>
            <span class="text-xl font-semibold tracking-tight">LaunchKit</span>
          </.link>

    <!-- Progress Steps -->
          <div class="hidden md:flex items-center gap-2">
            <%= for {step, idx} <- Enum.with_index(@steps) do %>
              <div class={[
                "flex items-center gap-2 px-3 py-1.5 rounded-full text-sm",
                step == @current_step && "bg-[#0d0d0d] text-white",
                step != @current_step && step_completed?(step, @current_step, @steps) &&
                  "bg-emerald-100 text-emerald-700",
                step != @current_step && !step_completed?(step, @current_step, @steps) &&
                  "text-[#a3a3a3]"
              ]}>
                <span class="w-5 h-5 rounded-full bg-current/20 flex items-center justify-center text-xs">
                  {idx + 1}
                </span>
                <span class="capitalize">{step}</span>
              </div>
              <%= if idx < length(@steps) - 1 do %>
                <div class="w-8 h-px bg-[#e5e5e5]"></div>
              <% end %>
            <% end %>
          </div>

          <div class="text-sm text-[#525252]">
            {if @url, do: URI.parse(@url).host, else: "No URL"}
          </div>
        </div>
      </header>

    <!-- Main Content -->
      <main class="max-w-6xl mx-auto px-6 py-8">
        <%= case @current_step do %>
          <% :analyzing -> %>
            <.analyzing_step url={@url} error={@error} />
          <% :review -> %>
            <.review_step analysis={@analysis} expanded_sections={@expanded_sections} />
          <% :generate -> %>
            <.generate_step
              active_tab={@active_tab}
              analysis={@analysis}
              headlines={@headlines}
              long_headlines={@long_headlines}
              descriptions={@descriptions}
              images={@images}
              videos={@videos}
              generating_headlines={@generating_headlines}
              generating_images={@generating_images}
              generating_videos={@generating_videos}
            />
          <% :export -> %>
            <.export_step
              headlines={@headlines}
              long_headlines={@long_headlines}
              descriptions={@descriptions}
              images={@images}
              videos={@videos}
            />
        <% end %>
      </main>
    </div>
    """
  end

  # ============================================================================
  # STEP COMPONENTS
  # ============================================================================

  defp collapsible_section(assigns) do
    ~H"""
    <div class="bg-white border border-[#e5e5e5] rounded-2xl mb-6 overflow-hidden">
      <button
        type="button"
        phx-click="toggle_section"
        phx-value-section={@id}
        class="w-full px-6 py-4 flex items-center justify-between hover:bg-[#fafaf9] transition-colors"
      >
        <h2 class="text-lg font-semibold">{@title}</h2>
        <svg
          class={"w-5 h-5 text-[#525252] transition-transform#{if @expanded, do: " rotate-180", else: ""}"}
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          stroke-width="2"
        >
          <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
        </svg>
      </button>
      <div class={"overflow-hidden transition-all duration-300#{if @expanded, do: " max-h-[5000px] opacity-100", else: " max-h-0 opacity-0"}"}>
        <div class="px-6 pb-6">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  defp analyzing_step(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-[60vh]">
      <%= if @error do %>
        <div class="text-center">
          <div class="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-6">
            <svg
              class="w-8 h-8 text-red-500"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2"
            >
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </div>
          <h2 class="text-2xl font-semibold mb-2">Analysis Failed</h2>
          <p class="text-[#525252] mb-6">{@error}</p>
          <.link navigate={~p"/"} class="text-sm text-[#0d0d0d] underline">
            Try another URL
          </.link>
        </div>
      <% else %>
        <div class="text-center">
          <div class="w-16 h-16 bg-[#0d0d0d] rounded-full flex items-center justify-center mx-auto mb-6 animate-pulse">
            <svg class="w-8 h-8 text-white animate-spin" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
              </circle>
              <path
                class="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              >
              </path>
            </svg>
          </div>
          <h2 class="text-2xl font-semibold mb-2">Analyzing your website</h2>
          <p class="text-[#525252] mb-2">{@url}</p>
          <p class="text-sm text-[#a3a3a3]">
            Extracting brand voice, value propositions, and keywords...
          </p>
        </div>
      <% end %>
    </div>
    """
  end

  defp review_step(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto">
      <div class="text-center mb-8">
        <h1 class="text-3xl font-semibold mb-2">Review Your Brand Analysis</h1>
        <p class="text-[#525252]">
          We've analyzed your website. Review the insights before generating assets.
        </p>
      </div>

    <!-- Back Button (if not first step) -->
      <div class="mb-6">
        <button
          phx-click="go_to_step"
          phx-value-step="analyzing"
          class="flex items-center gap-2 text-sm text-gray-600 hover:text-gray-900 transition-colors"
        >
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
          </svg>
          Back to Analysis
        </button>
      </div>

    <!-- Brand Summary Card -->
      <.collapsible_section
        id="brand_summary"
        title="Brand Summary"
        expanded={MapSet.member?(@expanded_sections, "brand_summary")}
      >
        <div class="grid gap-4">
          <div>
            <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">Company</label>
            <p class="text-lg font-medium">
              {get_in(@analysis, ["brand_summary", "company_name"]) || "Unknown"}
            </p>
          </div>

          <div>
            <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
              One-Liner
            </label>
            <p class="text-[#525252]">
              {get_in(@analysis, ["brand_summary", "one_liner"]) || "Not detected"}
            </p>
          </div>

          <%= if tagline = get_in(@analysis, ["brand_summary", "tagline"]) do %>
            <div>
              <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                Tagline
              </label>
              <p class="text-[#525252]">{tagline}</p>
            </div>
          <% end %>

          <%= if industry = get_in(@analysis, ["brand_summary", "industry"]) do %>
            <div>
              <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                Industry
              </label>
              <p class="text-[#525252]">{industry}</p>
            </div>
          <% end %>

          <div>
            <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
              Brand Voice
            </label>
            <div class="flex flex-wrap gap-2 mt-1 mb-3">
              <%= for tone <- (get_in(@analysis, ["brand_summary", "brand_voice", "tone"]) || []) do %>
                <span class="px-3 py-1 bg-[#fafaf9] border border-[#e5e5e5] rounded-full text-sm">
                  {tone}
                </span>
              <% end %>
            </div>
            <%= if voice = get_in(@analysis, ["brand_summary", "brand_voice"]) do %>
              <%= if personality = voice["personality"] do %>
                <p class="text-sm text-[#525252] mb-2"><strong>Personality:</strong> {personality}</p>
              <% end %>
              <%= if do_list = voice["do"] do %>
                <div class="mb-2">
                  <p class="text-xs font-medium text-emerald-600 mb-1">DO:</p>
                  <ul class="text-sm text-[#525252] space-y-1">
                    <%= for item <- do_list do %>
                      <li class="flex items-start gap-2">
                        <span class="text-emerald-600 mt-1">✓</span>
                        <span>{item}</span>
                      </li>
                    <% end %>
                  </ul>
                </div>
              <% end %>
              <%= if dont_list = voice["dont"] do %>
                <div>
                  <p class="text-xs font-medium text-red-600 mb-1">DON'T:</p>
                  <ul class="text-sm text-[#525252] space-y-1">
                    <%= for item <- dont_list do %>
                      <li class="flex items-start gap-2">
                        <span class="text-red-600 mt-1">✗</span>
                        <span>{item}</span>
                      </li>
                    <% end %>
                  </ul>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>
      </.collapsible_section>

    <!-- Messaging Pillars -->
      <.collapsible_section
        id="messaging_pillars"
        title="Messaging Pillars"
        expanded={MapSet.member?(@expanded_sections, "messaging_pillars")}
      >
        <div class="space-y-4">
          <%= for pillar <- (get_in(@analysis, ["messaging_pillars"]) || []) do %>
            <div class="p-4 bg-[#fafaf9] rounded-xl">
              <p class="font-medium mb-1">{pillar["pillar"]}</p>
              <p class="text-sm text-[#525252] mb-3">{pillar["emotional_hook"]}</p>
              <%= if keywords = pillar["keywords"] do %>
                <div class="mb-2">
                  <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                    Keywords
                  </label>
                  <div class="flex flex-wrap gap-1.5 mt-1">
                    <%= for keyword <- keywords do %>
                      <span class="px-2 py-0.5 bg-white border border-[#e5e5e5] rounded text-xs text-[#525252]">
                        {keyword}
                      </span>
                    <% end %>
                  </div>
                </div>
              <% end %>
              <%= if proof_points = pillar["proof_points"] do %>
                <div>
                  <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                    Proof Points
                  </label>
                  <ul class="mt-1 space-y-1">
                    <%= for point <- proof_points do %>
                      <li class="text-sm text-[#525252] flex items-start gap-2">
                        <span class="text-emerald-600 mt-1">•</span>
                        <span>{point}</span>
                      </li>
                    <% end %>
                  </ul>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </.collapsible_section>

    <!-- Target Audience -->
      <.collapsible_section
        id="target_audience"
        title="Target Audience"
        expanded={MapSet.member?(@expanded_sections, "target_audience")}
      >
        <div class="mb-4">
          <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
            Primary Persona
          </label>
          <p class="text-[#525252] mt-1">
            {get_in(@analysis, ["target_audience", "primary_persona"]) || "Not detected"}
          </p>
        </div>

        <div class="grid md:grid-cols-2 gap-4 mb-4">
          <div>
            <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
              Pain Points
            </label>
            <ul class="mt-2 space-y-1">
              <%= for pain <- (get_in(@analysis, ["target_audience", "pain_points"]) || []) do %>
                <li class="text-sm text-[#525252]">• {pain}</li>
              <% end %>
            </ul>
          </div>
          <div>
            <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">Desires</label>
            <ul class="mt-2 space-y-1">
              <%= for desire <- (get_in(@analysis, ["target_audience", "desires"]) || []) do %>
                <li class="text-sm text-[#525252]">• {desire}</li>
              <% end %>
            </ul>
          </div>
        </div>
        <%= if objections = get_in(@analysis, ["target_audience", "objections"]) do %>
          <div>
            <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
              Objections
            </label>
            <ul class="mt-2 space-y-1">
              <%= for objection <- objections do %>
                <li class="text-sm text-[#525252]">• {objection}</li>
              <% end %>
            </ul>
          </div>
        <% end %>
      </.collapsible_section>

    <!-- Calls to Action -->
      <%= if cta = get_in(@analysis, ["calls_to_action"]) do %>
        <.collapsible_section
          id="calls_to_action"
          title="Calls to Action"
          expanded={MapSet.member?(@expanded_sections, "calls_to_action")}
        >
          <div class="space-y-3">
            <%= if primary = cta["primary"] do %>
              <div>
                <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                  Primary CTA
                </label>
                <p class="text-lg font-medium text-[#525252] mt-1">{primary}</p>
              </div>
            <% end %>
            <%= if secondary = cta["secondary"] do %>
              <div>
                <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                  Secondary CTAs
                </label>
                <div class="flex flex-wrap gap-2 mt-1">
                  <%= for cta_text <- secondary do %>
                    <span class="px-3 py-1 bg-[#fafaf9] border border-[#e5e5e5] rounded-full text-sm">
                      {cta_text}
                    </span>
                  <% end %>
                </div>
              </div>
            <% end %>
            <%= if urgency = cta["urgency_variants"] do %>
              <div>
                <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                  Urgency Variants
                </label>
                <ul class="mt-1 space-y-1">
                  <%= for variant <- urgency do %>
                    <li class="text-sm text-[#525252]">• {variant}</li>
                  <% end %>
                </ul>
              </div>
            <% end %>
          </div>
        </.collapsible_section>
      <% end %>

    <!-- Headline Ingredients -->
      <%= if ingredients = get_in(@analysis, ["headline_ingredients"]) do %>
        <.collapsible_section
          id="headline_ingredients"
          title="Headline Ingredients"
          expanded={MapSet.member?(@expanded_sections, "headline_ingredients")}
        >
          <div class="grid gap-4">
            <%= if benefits = ingredients["benefits"] do %>
              <div>
                <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                  Benefits
                </label>
                <div class="flex flex-wrap gap-2 mt-1">
                  <%= for benefit <- benefits do %>
                    <span class="px-2 py-1 bg-emerald-50 text-emerald-700 border border-emerald-200 rounded text-xs">
                      {benefit}
                    </span>
                  <% end %>
                </div>
              </div>
            <% end %>
            <%= if features = ingredients["features"] do %>
              <div>
                <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                  Features
                </label>
                <div class="flex flex-wrap gap-2 mt-1">
                  <%= for feature <- features do %>
                    <span class="px-2 py-1 bg-blue-50 text-blue-700 border border-blue-200 rounded text-xs">
                      {feature}
                    </span>
                  <% end %>
                </div>
              </div>
            <% end %>
            <%= if power_words = ingredients["power_words"] do %>
              <div>
                <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                  Power Words
                </label>
                <div class="flex flex-wrap gap-2 mt-1">
                  <%= for word <- power_words do %>
                    <span class="px-2 py-1 bg-purple-50 text-purple-700 border border-purple-200 rounded text-xs font-medium">
                      {word}
                    </span>
                  <% end %>
                </div>
              </div>
            <% end %>
            <%= if question_hooks = ingredients["question_hooks"] do %>
              <div>
                <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                  Question Hooks
                </label>
                <ul class="mt-1 space-y-1">
                  <%= for hook <- question_hooks do %>
                    <li class="text-sm text-[#525252]">• {hook}</li>
                  <% end %>
                </ul>
              </div>
            <% end %>
            <%= if urgency_triggers = ingredients["urgency_triggers"] do %>
              <div>
                <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                  Urgency Triggers
                </label>
                <div class="flex flex-wrap gap-2 mt-1">
                  <%= for trigger <- urgency_triggers do %>
                    <span class="px-2 py-1 bg-red-50 text-red-700 border border-red-200 rounded text-xs">
                      {trigger}
                    </span>
                  <% end %>
                </div>
              </div>
            <% end %>
            <%= if social_proof = ingredients["social_proof_snippets"] do %>
              <div>
                <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                  Social Proof
                </label>
                <ul class="mt-1 space-y-1">
                  <%= for proof <- social_proof do %>
                    <li class="text-sm text-[#525252]">• {proof}</li>
                  <% end %>
                </ul>
              </div>
            <% end %>
          </div>
        </.collapsible_section>
      <% end %>

    <!-- Competitive Advantages -->
      <%= if advantages = get_in(@analysis, ["competitive_advantages"]) do %>
        <.collapsible_section
          id="competitive_advantages"
          title="Competitive Advantages"
          expanded={MapSet.member?(@expanded_sections, "competitive_advantages")}
        >
          <div class="space-y-3">
            <%= for advantage <- advantages do %>
              <div class="p-3 bg-[#fafaf9] rounded-xl">
                <p class="font-medium text-sm mb-1">{advantage["advantage"]}</p>
                <%= if proof = advantage["proof"] do %>
                  <p class="text-xs text-[#525252]">Proof: {proof}</p>
                <% end %>
              </div>
            <% end %>
          </div>
        </.collapsible_section>
      <% end %>

    <!-- Visual Direction -->
      <%= if visual = get_in(@analysis, ["visual_direction"]) do %>
        <.collapsible_section
          id="visual_direction"
          title="Visual Direction"
          expanded={MapSet.member?(@expanded_sections, "visual_direction")}
        >
          <div class="grid gap-4">
            <%= if mood = visual["mood_keywords"] do %>
              <div>
                <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                  Mood Keywords
                </label>
                <div class="flex flex-wrap gap-2 mt-1">
                  <%= for keyword <- mood do %>
                    <span class="px-2 py-1 bg-[#fafaf9] border border-[#e5e5e5] rounded text-xs">
                      {keyword}
                    </span>
                  <% end %>
                </div>
              </div>
            <% end %>
            <%= if themes = visual["imagery_themes"] do %>
              <div>
                <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                  Imagery Themes
                </label>
                <div class="flex flex-wrap gap-2 mt-1">
                  <%= for theme <- themes do %>
                    <span class="px-2 py-1 bg-blue-50 text-blue-700 border border-blue-200 rounded text-xs">
                      {theme}
                    </span>
                  <% end %>
                </div>
              </div>
            <% end %>
            <%= if scenes = visual["suggested_scenes"] do %>
              <div>
                <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                  Suggested Scenes
                </label>
                <ul class="mt-1 space-y-1">
                  <%= for scene <- scenes do %>
                    <li class="text-sm text-[#525252]">• {scene}</li>
                  <% end %>
                </ul>
              </div>
            <% end %>
            <%= if avoid = visual["avoid"] do %>
              <div>
                <label class="text-xs font-medium text-red-600 uppercase tracking-wider">Avoid</label>
                <ul class="mt-1 space-y-1">
                  <%= for item <- avoid do %>
                    <li class="text-sm text-red-600">• {item}</li>
                  <% end %>
                </ul>
              </div>
            <% end %>
            <%= if primary_colors = visual["primary_colors"] do %>
              <div>
                <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                  Primary Colors
                </label>
                <div class="flex flex-wrap gap-2 mt-1">
                  <%= for color <- primary_colors do %>
                    <div class="flex items-center gap-2">
                      <div
                        class="w-6 h-6 rounded border border-[#e5e5e5]"
                        style={"background-color: #{color}"}
                      >
                      </div>
                      <span class="text-xs text-[#525252]">{color}</span>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </.collapsible_section>
      <% end %>

    <!-- Video Direction -->
      <%= if video = get_in(@analysis, ["video_direction"]) do %>
        <.collapsible_section
          id="video_direction"
          title="Video Direction"
          expanded={MapSet.member?(@expanded_sections, "video_direction")}
        >
          <div class="grid gap-4">
            <%= if tone = video["tone"] do %>
              <div>
                <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                  Tone
                </label>
                <p class="text-[#525252] mt-1">{tone}</p>
              </div>
            <% end %>
            <%= if pacing = video["pacing"] do %>
              <div>
                <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                  Pacing
                </label>
                <p class="text-[#525252] mt-1">{pacing}</p>
              </div>
            <% end %>
            <%= if concepts = video["suggested_concepts"] do %>
              <div>
                <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                  Suggested Concepts
                </label>
                <div class="space-y-3 mt-2">
                  <%= for concept <- concepts do %>
                    <div class="p-3 bg-[#fafaf9] rounded-xl">
                      <p class="font-medium text-sm mb-2">{concept["concept"]}</p>
                      <%= if hook = concept["opening_hook"] do %>
                        <p class="text-xs text-[#525252] mb-2">
                          <strong>Opening Hook:</strong> {hook}
                        </p>
                      <% end %>
                      <%= if visuals = concept["key_visuals"] do %>
                        <div>
                          <p class="text-xs font-medium text-[#a3a3a3] mb-1">Key Visuals:</p>
                          <ul class="text-xs text-[#525252] space-y-1">
                            <%= for visual <- visuals do %>
                              <li>• {visual}</li>
                            <% end %>
                          </ul>
                        </div>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </.collapsible_section>
      <% end %>

    <!-- SEO Keywords -->
      <%= if seo = get_in(@analysis, ["seo_keywords"]) do %>
        <.collapsible_section
          id="seo_keywords"
          title="SEO Keywords"
          expanded={MapSet.member?(@expanded_sections, "seo_keywords")}
        >
          <div class="grid gap-4">
            <%= if primary = seo["primary"] do %>
              <div>
                <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                  Primary Keywords
                </label>
                <div class="flex flex-wrap gap-2 mt-1">
                  <%= for keyword <- primary do %>
                    <span class="px-2 py-1 bg-emerald-50 text-emerald-700 border border-emerald-200 rounded text-xs font-medium">
                      {keyword}
                    </span>
                  <% end %>
                </div>
              </div>
            <% end %>
            <%= if secondary = seo["secondary"] do %>
              <div>
                <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                  Secondary Keywords
                </label>
                <div class="flex flex-wrap gap-2 mt-1">
                  <%= for keyword <- secondary do %>
                    <span class="px-2 py-1 bg-blue-50 text-blue-700 border border-blue-200 rounded text-xs">
                      {keyword}
                    </span>
                  <% end %>
                </div>
              </div>
            <% end %>
            <%= if long_tail = seo["long_tail"] do %>
              <div>
                <label class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                  Long Tail Keywords
                </label>
                <ul class="mt-1 space-y-1">
                  <%= for keyword <- long_tail do %>
                    <li class="text-sm text-[#525252]">• {keyword}</li>
                  <% end %>
                </ul>
              </div>
            <% end %>
          </div>
        </.collapsible_section>
      <% end %>

    <!-- Continue Button -->
      <div class="flex justify-center gap-4 mt-8 mb-4">
        <button
          phx-click="go_to_step"
          phx-value-step="analyzing"
          class="px-6 py-3 rounded-lg font-medium border border-gray-300 text-gray-700 hover:bg-gray-50 transition-colors flex items-center gap-2"
        >
          <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
          </svg>
          Back
        </button>
        <button
          phx-click="continue_to_generate"
          class="bg-black text-white px-8 py-3 rounded-lg font-medium hover:bg-gray-900 transition-colors flex items-center gap-2 shadow-sm"
        >
          Continue to Generate Assets
          <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3"
            />
          </svg>
        </button>
      </div>
    </div>
    """
  end

  defp generate_step(assigns) do
    ~H"""
    <div>
      <div class="text-center mb-8">
        <h1 class="text-3xl font-semibold mb-2">Generate Your Assets</h1>
        <p class="text-[#525252]">Generate headlines, images, and videos for your campaign.</p>
      </div>

    <!-- Back Button -->
      <div class="mb-6 flex justify-center">
        <button
          phx-click="go_to_step"
          phx-value-step="review"
          class="flex items-center gap-2 text-sm text-gray-600 hover:text-gray-900 transition-colors"
        >
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
          </svg>
          Back to Review
        </button>
      </div>

    <!-- Tabs -->
      <div class="flex justify-center mb-10">
        <div class="inline-flex bg-gray-100 rounded-lg p-1.5 gap-1">
          <button
            phx-click="switch_tab"
            phx-value-tab="headlines"
            class={[
              "px-6 py-2.5 rounded-md text-sm font-medium transition-all",
              @active_tab == :headlines && "bg-white text-gray-900 shadow-sm",
              @active_tab != :headlines && "text-gray-600 hover:text-gray-900"
            ]}
          >
            Headlines
          </button>
          <button
            phx-click="switch_tab"
            phx-value-tab="images"
            class={[
              "px-6 py-2.5 rounded-md text-sm font-medium transition-all",
              @active_tab == :images && "bg-white text-gray-900 shadow-sm",
              @active_tab != :images && "text-gray-600 hover:text-gray-900"
            ]}
          >
            Images
          </button>
          <button
            phx-click="switch_tab"
            phx-value-tab="videos"
            class={[
              "px-6 py-2.5 rounded-md text-sm font-medium transition-all",
              @active_tab == :videos && "bg-white text-gray-900 shadow-sm",
              @active_tab != :videos && "text-gray-600 hover:text-gray-900"
            ]}
          >
            Videos
          </button>
        </div>
      </div>

    <!-- Tab Content -->
      <%= case @active_tab do %>
        <% :headlines -> %>
          <.headlines_tab
            headlines={@headlines}
            long_headlines={@long_headlines}
            descriptions={@descriptions}
            generating={@generating_headlines}
            analysis={@analysis}
          />
        <% :images -> %>
          <.images_tab images={@images} generating={@generating_images} analysis={@analysis} />
        <% :videos -> %>
          <.videos_tab
            videos={@videos}
            images={@images}
            generating={@generating_videos}
            analysis={@analysis}
          />
      <% end %>

    <!-- Continue to Export -->
      <%= if has_assets?(@headlines, @images, @videos) do %>
        <div class="flex justify-center gap-4 mt-8">
          <button
            phx-click="go_to_step"
            phx-value-step="review"
            class="px-6 py-3 rounded-lg font-medium border border-gray-300 text-gray-700 hover:bg-gray-50 transition-colors flex items-center gap-2"
          >
            <svg
              class="w-5 h-5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2"
            >
              <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
            </svg>
            Back to Review
          </button>
          <button
            phx-click="continue_to_export"
            class="bg-black text-white px-8 py-3 rounded-lg font-medium hover:bg-gray-900 transition-colors flex items-center gap-2 shadow-sm"
          >
            Continue to Export
            <svg
              class="w-5 h-5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3"
              />
            </svg>
          </button>
        </div>
      <% end %>
    </div>
    """
  end

  defp headlines_tab(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto">
      <!-- Generate Button -->
      <div class="flex justify-center mb-10">
        <button
          phx-click="generate_headlines"
          disabled={@generating}
          class={[
            "px-8 py-3.5 rounded-lg font-medium flex items-center gap-2.5 transition-all shadow-sm",
            @generating && "bg-gray-100 text-gray-400 cursor-not-allowed",
            !@generating && "bg-black text-white hover:bg-gray-900 hover:shadow-md"
          ]}
        >
          <%= if @generating do %>
            <svg class="w-5 h-5 animate-spin" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
              </circle>
              <path
                class="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              >
              </path>
            </svg>
            Generating...
          <% else %>
            <svg
              class="w-5 h-5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09z"
              />
            </svg>
            Generate All Headlines
          <% end %>
        </button>
      </div>

      <%= if @headlines != [] or @long_headlines != [] or @descriptions != [] do %>
        <!-- Short Headlines -->
        <div class="bg-white border border-gray-200 rounded-xl p-6 mb-6 shadow-sm">
          <div class="flex items-center justify-between mb-5">
            <div>
              <h3 class="text-lg font-semibold text-gray-900">Short Headlines</h3>
              <p class="text-xs text-gray-500 mt-0.5">Max 30 characters each</p>
            </div>
            <span class="text-sm font-medium text-gray-600 bg-gray-50 px-3 py-1 rounded-full">
              {length(@headlines)}/15
            </span>
          </div>
          <div class="space-y-2.5">
            <%= for {headline, idx} <- Enum.with_index(@headlines) do %>
              <div class="flex items-center gap-3 p-3.5 bg-gray-50 rounded-lg group hover:bg-gray-100 transition-colors border border-transparent hover:border-gray-200">
                <span class="text-xs font-medium text-gray-400 w-6 flex-shrink-0">{idx + 1}</span>
                <input
                  type="text"
                  value={headline.text}
                  maxlength="30"
                  phx-blur="update_headline"
                  phx-value-type="short"
                  phx-value-index={idx}
                  class="flex-1 bg-transparent border-none outline-none text-sm text-gray-900 placeholder-gray-400"
                />
                <span class={[
                  "text-xs font-medium flex-shrink-0 w-12 text-right",
                  String.length(headline.text) <= 30 && "text-gray-400",
                  String.length(headline.text) > 30 && "text-red-500 font-semibold"
                ]}>
                  {String.length(headline.text)}/30
                </span>
                <button
                  id={"copy-headline-#{idx}"}
                  phx-click="copy_text"
                  phx-value-text={headline.text}
                  phx-hook="CopyToClipboard"
                  class="opacity-0 group-hover:opacity-100 text-gray-400 hover:text-gray-700 transition-all p-1.5 hover:bg-white rounded"
                  title="Copy to clipboard"
                >
                  <svg
                    class="w-4 h-4"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    stroke-width="2"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M15.666 3.888A2.25 2.25 0 0013.5 2.25h-3c-1.03 0-1.9.693-2.166 1.638m7.332 0c.055.194.084.4.084.612v0a.75.75 0 01-.75.75H9a.75.75 0 01-.75-.75v0c0-.212.03-.418.084-.612m7.332 0c.646.049 1.288.11 1.927.184 1.1.128 1.907 1.077 1.907 2.185V19.5a2.25 2.25 0 01-2.25 2.25H6.75A2.25 2.25 0 014.5 19.5V6.257c0-1.108.806-2.057 1.907-2.185a48.208 48.208 0 011.927-.184"
                    />
                  </svg>
                </button>
                <button
                  phx-click="regenerate_headline"
                  phx-value-type="short"
                  phx-value-index={idx}
                  class="opacity-0 group-hover:opacity-100 text-gray-400 hover:text-gray-700 transition-all p-1.5 hover:bg-white rounded"
                  title="Regenerate"
                >
                  <svg
                    class="w-4 h-4"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    stroke-width="2"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0l3.181 3.183a8.25 8.25 0 0013.803-3.7M4.031 9.865a8.25 8.25 0 0113.803-3.7l3.181 3.182m0-4.991v4.99"
                    />
                  </svg>
                </button>
              </div>
            <% end %>
          </div>
        </div>

    <!-- Long Headlines -->
        <div class="bg-white border border-gray-200 rounded-xl p-6 mb-6 shadow-sm">
          <div class="flex items-center justify-between mb-5">
            <div>
              <h3 class="text-lg font-semibold text-gray-900">Long Headlines</h3>
              <p class="text-xs text-gray-500 mt-0.5">Max 90 characters each</p>
            </div>
            <span class="text-sm font-medium text-gray-600 bg-gray-50 px-3 py-1 rounded-full">
              {length(@long_headlines)}/5
            </span>
          </div>
          <div class="space-y-2.5">
            <%= for {headline, idx} <- Enum.with_index(@long_headlines) do %>
              <div class="flex items-center gap-3 p-3.5 bg-gray-50 rounded-lg group hover:bg-gray-100 transition-colors border border-transparent hover:border-gray-200">
                <span class="text-xs font-medium text-gray-400 w-6 flex-shrink-0">{idx + 1}</span>
                <input
                  type="text"
                  value={headline.text}
                  maxlength="90"
                  phx-blur="update_headline"
                  phx-value-type="long"
                  phx-value-index={idx}
                  class="flex-1 bg-transparent border-none outline-none text-sm text-gray-900 placeholder-gray-400"
                />
                <span class="text-xs font-medium text-gray-400 flex-shrink-0 w-16 text-right">
                  {String.length(headline.text)}/90
                </span>
                <button
                  id={"copy-long-headline-#{idx}"}
                  phx-click="copy_text"
                  phx-value-text={headline.text}
                  phx-hook="CopyToClipboard"
                  class="opacity-0 group-hover:opacity-100 text-gray-400 hover:text-gray-700 transition-all p-1.5 hover:bg-white rounded"
                  title="Copy to clipboard"
                >
                  <svg
                    class="w-4 h-4"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    stroke-width="2"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M15.666 3.888A2.25 2.25 0 0013.5 2.25h-3c-1.03 0-1.9.693-2.166 1.638m7.332 0c.055.194.084.4.084.612v0a.75.75 0 01-.75.75H9a.75.75 0 01-.75-.75v0c0-.212.03-.418.084-.612m7.332 0c.646.049 1.288.11 1.927.184 1.1.128 1.907 1.077 1.907 2.185V19.5a2.25 2.25 0 01-2.25 2.25H6.75A2.25 2.25 0 014.5 19.5V6.257c0-1.108.806-2.057 1.907-2.185a48.208 48.208 0 011.927-.184"
                    />
                  </svg>
                </button>
              </div>
            <% end %>
          </div>
        </div>

    <!-- Descriptions -->
        <div class="bg-white border border-gray-200 rounded-xl p-6 shadow-sm">
          <div class="flex items-center justify-between mb-5">
            <div>
              <h3 class="text-lg font-semibold text-gray-900">Descriptions</h3>
              <p class="text-xs text-gray-500 mt-0.5">Max 90 characters each</p>
            </div>
            <span class="text-sm font-medium text-gray-600 bg-gray-50 px-3 py-1 rounded-full">
              {length(@descriptions)}/5
            </span>
          </div>
          <div class="space-y-2.5">
            <%= for {desc, idx} <- Enum.with_index(@descriptions) do %>
              <div class="flex items-start gap-3 p-3.5 bg-gray-50 rounded-lg group hover:bg-gray-100 transition-colors border border-transparent hover:border-gray-200">
                <span class="text-xs font-medium text-gray-400 w-6 flex-shrink-0 pt-1">
                  {idx + 1}
                </span>
                <textarea
                  maxlength="90"
                  phx-blur="update_description"
                  phx-value-index={idx}
                  rows="2"
                  class="flex-1 bg-transparent border-none outline-none text-sm resize-none text-gray-900 placeholder-gray-400"
                ><%= desc.text %></textarea>
                <div class="flex flex-col items-end gap-2 flex-shrink-0">
                  <span class="text-xs font-medium text-gray-400">{String.length(desc.text)}/90</span>
                  <button
                    id={"copy-description-#{idx}"}
                    phx-click="copy_text"
                    phx-value-text={desc.text}
                    phx-hook="CopyToClipboard"
                    class="opacity-0 group-hover:opacity-100 text-gray-400 hover:text-gray-700 transition-all p-1.5 hover:bg-white rounded"
                    title="Copy to clipboard"
                  >
                    <svg
                      class="w-4 h-4"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                      stroke-width="2"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M15.666 3.888A2.25 2.25 0 0013.5 2.25h-3c-1.03 0-1.9.693-2.166 1.638m7.332 0c.055.194.084.4.084.612v0a.75.75 0 01-.75.75H9a.75.75 0 01-.75-.75v0c0-.212.03-.418.084-.612m7.332 0c.646.049 1.288.11 1.927.184 1.1.128 1.907 1.077 1.907 2.185V19.5a2.25 2.25 0 01-2.25 2.25H6.75A2.25 2.25 0 014.5 19.5V6.257c0-1.108.806-2.057 1.907-2.185a48.208 48.208 0 011.927-.184"
                      />
                    </svg>
                  </button>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% else %>
        <div class="text-center py-20 text-gray-400">
          <svg
            class="w-12 h-12 mx-auto mb-4 opacity-50"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="1.5"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M7.5 8.25h9m-9 3H12m-9.75 1.51c0 1.6 1.123 2.994 2.707 3.227 1.129.166 2.27.293 3.423.379.35.026.67.21.865.501L12 21l2.755-4.133a1.14 1.14 0 01.865-.501 48.172 48.172 0 003.423-.379c1.584-.233 2.707-1.626 2.707-3.228V6.741c0-1.602-1.123-2.995-2.707-3.228A48.394 48.394 0 0012 3c-2.392 0-4.744.175-7.043.513C3.373 3.746 2.25 5.14 2.25 6.741v6.018z"
            />
          </svg>
          <p>Click "Generate All Headlines" to create your ad copy</p>
        </div>
      <% end %>
    </div>
    """
  end

  defp images_tab(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto">
      <!-- Generate Button -->
      <div class="flex justify-center mb-10">
        <button
          phx-click="generate_images"
          disabled={@generating}
          class={[
            "px-8 py-3.5 rounded-lg font-medium flex items-center gap-2.5 transition-all shadow-sm",
            @generating && "bg-gray-100 text-gray-400 cursor-not-allowed",
            !@generating && "bg-black text-white hover:bg-gray-900 hover:shadow-md"
          ]}
        >
          <%= if @generating do %>
            <svg class="w-5 h-5 animate-spin" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
              </circle>
              <path
                class="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
              >
              </path>
            </svg>
            Generating Images...
          <% else %>
            <svg
              class="w-5 h-5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 001.5-1.5V6a1.5 1.5 0 00-1.5-1.5H3.75A1.5 1.5 0 002.25 6v12a1.5 1.5 0 001.5 1.5z"
              />
            </svg>
            Generate Images
          <% end %>
        </button>
      </div>

      <%= if @images != [] do %>
        <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-5">
          <%= for image <- @images do %>
            <div class="bg-white border border-gray-200 rounded-xl overflow-hidden shadow-sm hover:shadow-md transition-shadow group">
              <div class="aspect-video bg-gray-100 relative overflow-hidden">
                <%= if image.status == :completed do %>
                  <img src={image.url} alt={image.prompt} class="w-full h-full object-cover" />
                <% else %>
                  <div class="absolute inset-0 flex items-center justify-center bg-gray-50">
                    <div class="text-center">
                      <svg
                        class="w-10 h-10 text-gray-400 animate-spin mx-auto mb-2"
                        fill="none"
                        viewBox="0 0 24 24"
                      >
                        <circle
                          class="opacity-25"
                          cx="12"
                          cy="12"
                          r="10"
                          stroke="currentColor"
                          stroke-width="4"
                        >
                        </circle>
                        <path
                          class="opacity-75"
                          fill="currentColor"
                          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
                        >
                        </path>
                      </svg>
                      <p class="text-xs text-gray-500">Generating...</p>
                    </div>
                  </div>
                <% end %>
              </div>
              <div class="p-4 border-t border-gray-100">
                <p class="text-sm text-gray-700 truncate font-medium mb-1">{image.prompt}</p>
                <p class="text-xs text-gray-500">{image.aspect_ratio}</p>
              </div>
            </div>
          <% end %>
        </div>
      <% else %>
        <div class="text-center py-20 text-gray-400">
          <svg
            class="w-12 h-12 mx-auto mb-4 opacity-50"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="1.5"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 001.5-1.5V6a1.5 1.5 0 00-1.5-1.5H3.75A1.5 1.5 0 002.25 6v12a1.5 1.5 0 001.5 1.5z"
            />
          </svg>
          <p>Click "Generate Images" to create ad visuals</p>
        </div>
      <% end %>
    </div>
    """
  end

  defp videos_tab(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto">
      <!-- Generate Button -->
      <div class="flex justify-center mb-8">
        <button
          phx-click="generate_videos"
          disabled={@generating or @images == []}
          class={[
            "px-6 py-3 rounded-full font-medium flex items-center gap-2 transition-colors",
            (@generating or @images == []) && "bg-[#e5e5e5] text-[#a3a3a3] cursor-not-allowed",
            !@generating and @images != [] && "bg-[#0d0d0d] text-white hover:bg-[#262626]"
          ]}
        >
          <%= if @generating do %>
            <svg class="w-5 h-5 animate-spin" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
              </circle>
              <path
                class="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
              >
              </path>
            </svg>
            Generating Videos...
          <% else %>
            <svg
              class="w-5 h-5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M5.25 5.653c0-.856.917-1.398 1.667-.986l11.54 6.348a1.125 1.125 0 010 1.971l-11.54 6.347a1.125 1.125 0 01-1.667-.985V5.653z"
              />
            </svg>
            Generate Videos from Images
          <% end %>
        </button>
      </div>

      <%= if @images == [] do %>
        <div class="text-center py-8 mb-8 bg-amber-50 border border-amber-200 rounded-xl">
          <p class="text-amber-700 text-sm">Generate images first to create videos from them</p>
        </div>
      <% end %>

      <%= if @videos != [] do %>
        <div class="grid md:grid-cols-2 gap-4">
          <%= for video <- @videos do %>
            <div class="bg-white border border-[#e5e5e5] rounded-2xl overflow-hidden">
              <div class="aspect-video bg-[#0d0d0d] relative">
                <%= if video.status == :completed do %>
                  <video src={video.url} controls class="w-full h-full object-cover" />
                <% else %>
                  <div class="absolute inset-0 flex items-center justify-center">
                    <div class="text-center text-white">
                      <svg class="w-8 h-8 mx-auto mb-2 animate-spin" fill="none" viewBox="0 0 24 24">
                        <circle
                          class="opacity-25"
                          cx="12"
                          cy="12"
                          r="10"
                          stroke="currentColor"
                          stroke-width="4"
                        >
                        </circle>
                        <path
                          class="opacity-75"
                          fill="currentColor"
                          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
                        >
                        </path>
                      </svg>
                      <p class="text-sm opacity-75">Generating...</p>
                    </div>
                  </div>
                <% end %>
              </div>
              <div class="p-3">
                <p class="text-xs text-[#525252]">{video.duration_seconds}s • {video.aspect_ratio}</p>
              </div>
            </div>
          <% end %>
        </div>
      <% else %>
        <div class="text-center py-16 text-[#a3a3a3]">
          <svg
            class="w-12 h-12 mx-auto mb-4 opacity-50"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="1.5"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M5.25 5.653c0-.856.917-1.398 1.667-.986l11.54 6.348a1.125 1.125 0 010 1.971l-11.54 6.347a1.125 1.125 0 01-1.667-.985V5.653z"
            />
          </svg>
          <p>Click "Generate Videos" to create video ads</p>
        </div>
      <% end %>
    </div>
    """
  end

  defp export_step(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto">
      <div class="text-center mb-8">
        <div class="w-16 h-16 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-6">
          <svg
            class="w-8 h-8 text-emerald-600"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="2"
          >
            <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
          </svg>
        </div>
        <h1 class="text-3xl font-semibold mb-2">Your Assets Are Ready!</h1>
        <p class="text-[#525252]">Download your assets or export directly to Google Ads.</p>
      </div>

    <!-- Back Button -->
      <div class="mb-6 flex justify-center">
        <button
          phx-click="go_to_step"
          phx-value-step="generate"
          class="flex items-center gap-2 text-sm text-gray-600 hover:text-gray-900 transition-colors"
        >
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
          </svg>
          Back to Generate
        </button>
      </div>

    <!-- Summary -->
      <div class="bg-white border border-[#e5e5e5] rounded-2xl p-6 mb-8">
        <h2 class="text-lg font-semibold mb-4">Asset Summary</h2>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div class="text-center p-4 bg-[#fafaf9] rounded-xl">
            <div class="text-2xl font-semibold">{length(@headlines)}</div>
            <div class="text-sm text-[#525252]">Headlines</div>
          </div>
          <div class="text-center p-4 bg-[#fafaf9] rounded-xl">
            <div class="text-2xl font-semibold">{length(@long_headlines)}</div>
            <div class="text-sm text-[#525252]">Long Headlines</div>
          </div>
          <div class="text-center p-4 bg-[#fafaf9] rounded-xl">
            <div class="text-2xl font-semibold">{length(@descriptions)}</div>
            <div class="text-sm text-[#525252]">Descriptions</div>
          </div>
          <div class="text-center p-4 bg-[#fafaf9] rounded-xl">
            <div class="text-2xl font-semibold">{length(@images)}</div>
            <div class="text-sm text-[#525252]">Images</div>
          </div>
        </div>
      </div>

    <!-- Export Options -->
      <div class="flex flex-col sm:flex-row gap-4 justify-center">
        <button
          phx-click="download_all"
          class="px-8 py-3 bg-[#0d0d0d] text-white rounded-full font-medium hover:bg-[#262626] transition-colors flex items-center justify-center gap-2"
        >
          <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3"
            />
          </svg>
          Download All
        </button>
        <button
          phx-click="export_to_google"
          class="px-8 py-3 bg-white border border-[#e5e5e5] text-[#0d0d0d] rounded-full font-medium hover:bg-[#fafaf9] transition-colors flex items-center justify-center gap-2"
        >
          <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
            <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
            <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
            <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" />
            <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
          </svg>
          Export to Google Ads
        </button>
      </div>
    </div>
    """
  end

  # ============================================================================
  # EVENT HANDLERS
  # ============================================================================

  def handle_info({:analyze_website, url}, socket) do
    case WebScraper.analyze_website(url) do
      {:ok, analysis} ->
        # Save or update website in database (non-blocking - don't fail if save fails)
        website_name =
          get_in(analysis, ["brand_summary", "company_name"]) ||
            case URI.parse(url) do
              %URI{host: host} when is_binary(host) -> host
              _ -> nil
            end || "Unknown"

        # Get or create website to get website_id
        website_id =
          case Campaigns.get_website_by_url(url) do
            nil ->
              case Campaigns.create_website(%{
                     name: website_name,
                     url: url,
                     analysis: analysis,
                     status: "completed"
                   }) do
                {:ok, website} -> website.id
                {:error, _changeset} -> nil
              end

            existing_website ->
              case Campaigns.update_website(existing_website, %{
                     name: website_name,
                     analysis: analysis,
                     status: "completed"
                   }) do
                {:ok, website} -> website.id
                {:error, _changeset} -> existing_website.id
              end
          end

        {:noreply,
         socket
         |> assign(:analysis, analysis)
         |> assign(:website_id, website_id)
         |> assign(:current_step, :review)}

      {:error, reason} ->
        # Save website with error status (non-blocking)
        website_name =
          case URI.parse(url) do
            %URI{host: host} when is_binary(host) -> host
            _ -> nil
          end || "Unknown"

        Task.start(fn ->
          case Campaigns.get_website_by_url(url) do
            nil ->
              case Campaigns.create_website(%{
                     name: website_name,
                     url: url,
                     status: "failed"
                   }) do
                {:ok, _website} -> :ok
                {:error, _changeset} -> :ok
              end

            existing_website ->
              case Campaigns.update_website(existing_website, %{status: "failed"}) do
                {:ok, _website} -> :ok
                {:error, _changeset} -> :ok
              end
          end
        end)

        {:noreply,
         socket
         |> assign(:error, "Failed to analyze website: #{inspect(reason)}")}
    end
  end

  def handle_info({:headlines_generated, headlines, long_headlines, descriptions}, socket) do
    website_id = socket.assigns[:website_id]

    # Save to database if website_id exists
    if website_id do
      Task.start(fn ->
        # Delete existing assets for this website
        import Ecto.Query
        alias Launchkit.Repo
        from(h in Assets.Headline, where: h.website_id == ^website_id) |> Repo.delete_all()
        from(lh in Assets.LongHeadline, where: lh.website_id == ^website_id) |> Repo.delete_all()
        from(d in Assets.Description, where: d.website_id == ^website_id) |> Repo.delete_all()

        # Save new headlines
        Enum.each(headlines, fn headline ->
          Assets.create_headline(%{
            text: headline.text,
            character_count: String.length(headline.text),
            score: 0,
            is_pinned: false,
            website_id: website_id
          })
        end)

        # Save new long headlines
        Enum.each(long_headlines, fn headline ->
          Assets.create_long_headline(%{
            text: headline.text,
            character_count: String.length(headline.text),
            score: 0,
            is_pinned: false,
            website_id: website_id
          })
        end)

        # Save new descriptions
        Enum.each(descriptions, fn desc ->
          Assets.create_description(%{
            text: desc.text,
            character_count: String.length(desc.text),
            score: 0,
            is_pinned: false,
            website_id: website_id
          })
        end)
      end)
    end

    {:noreply,
     socket
     |> assign(:headlines, headlines)
     |> assign(:long_headlines, long_headlines)
     |> assign(:descriptions, descriptions)
     |> assign(:generating_headlines, false)}
  end

  def handle_info({:images_generated, images}, socket) do
    website_id = socket.assigns[:website_id]

    # Save to database if website_id exists
    if website_id do
      Task.start(fn ->
        # Delete existing images for this website
        import Ecto.Query
        alias Launchkit.Repo
        from(i in Assets.Image, where: i.website_id == ^website_id) |> Repo.delete_all()

        # Save new images
        Enum.each(images, fn image ->
          Assets.create_image(%{
            prompt: image.prompt,
            url: image.url,
            # Using URL as storage path for now
            storage_path: image.url,
            width: image.width || 1024,
            height: image.height || 1024,
            aspect_ratio: image.aspect_ratio || "16:9",
            status: to_string(image.status || :completed),
            website_id: website_id
          })
        end)
      end)
    end

    {:noreply,
     socket
     |> assign(:images, images)
     |> assign(:generating_images, false)}
  end

  def handle_info({:videos_generated, videos}, socket) do
    {:noreply,
     socket
     |> assign(:videos, videos)
     |> assign(:generating_videos, false)}
  end

  def handle_info(
        {:headline_regenerated, type, index, headlines, long_headlines, _descriptions},
        socket
      ) do
    website_id = socket.assigns[:website_id]

    case type do
      "short" ->
        # Replace the headline at the specified index
        new_headlines =
          socket.assigns.headlines
          |> List.update_at(index, fn _old_headline ->
            Enum.at(headlines, index) || %{text: ""}
          end)

        # Save to database
        if website_id do
          Task.start(fn ->
            db_headlines = Assets.list_headlines_by_website(website_id)

            if Enum.at(db_headlines, index) && Enum.at(headlines, index) do
              headline = Enum.at(db_headlines, index)
              new_text = Enum.at(headlines, index).text

              Assets.update_headline(headline, %{
                text: new_text,
                character_count: String.length(new_text)
              })
            end
          end)
        end

        {:noreply, assign(socket, :headlines, new_headlines)}

      "long" ->
        # Replace the long headline at the specified index
        new_long_headlines =
          socket.assigns.long_headlines
          |> List.update_at(index, fn _old_headline ->
            Enum.at(long_headlines, index) || %{text: ""}
          end)

        # Save to database
        if website_id do
          Task.start(fn ->
            db_long_headlines = Assets.list_long_headlines_by_website(website_id)

            if Enum.at(db_long_headlines, index) && Enum.at(long_headlines, index) do
              long_headline = Enum.at(db_long_headlines, index)
              new_text = Enum.at(long_headlines, index).text

              Assets.update_long_headline(long_headline, %{
                text: new_text,
                character_count: String.length(new_text)
              })
            end
          end)
        end

        {:noreply, assign(socket, :long_headlines, new_long_headlines)}
    end
  end

  def handle_event("continue_to_generate", _, socket) do
    url = socket.assigns.url || ""

    {:noreply,
     socket
     |> assign(:current_step, :generate)
     |> update_url_params(url, :generate)}
  end

  def handle_event("continue_to_export", _, socket) do
    url = socket.assigns.url || ""

    {:noreply,
     socket
     |> assign(:current_step, :export)
     |> update_url_params(url, :export)}
  end

  def handle_event("go_to_step", %{"step" => step}, socket) do
    step_atom = String.to_existing_atom(step)
    url = socket.assigns.url || ""

    if step_atom in @steps do
      {:noreply,
       socket
       |> assign(:current_step, step_atom)
       |> update_url_params(url, step_atom)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, String.to_existing_atom(tab))}
  end

  def handle_event("toggle_section", %{"section" => section_id}, socket) do
    expanded_sections = socket.assigns.expanded_sections

    new_expanded_sections =
      if MapSet.member?(expanded_sections, section_id) do
        MapSet.delete(expanded_sections, section_id)
      else
        MapSet.put(expanded_sections, section_id)
      end

    {:noreply, assign(socket, :expanded_sections, new_expanded_sections)}
  end

  def handle_event("generate_headlines", _, socket) do
    pid = self()
    analysis = socket.assigns.analysis

    Task.start(fn ->
      case Assets.generate_headlines(analysis) do
        {:ok, result} ->
          send(
            pid,
            {:headlines_generated, result.headlines, result.long_headlines, result.descriptions}
          )

        {:error, _} ->
          send(pid, {:headlines_generated, [], [], []})
      end
    end)

    {:noreply, assign(socket, :generating_headlines, true)}
  end

  def handle_event("generate_images", _, socket) do
    pid = self()
    analysis = socket.assigns.analysis

    Task.start(fn ->
      case Assets.generate_images(analysis) do
        {:ok, images} ->
          send(pid, {:images_generated, images})

        {:error, _} ->
          send(pid, {:images_generated, []})
      end
    end)

    {:noreply, assign(socket, :generating_images, true)}
  end

  def handle_event("generate_videos", _, socket) do
    pid = self()
    analysis = socket.assigns.analysis
    images = socket.assigns.images

    Task.start(fn ->
      case Assets.generate_videos(analysis, images) do
        {:ok, videos} ->
          send(pid, {:videos_generated, videos})

        {:error, _} ->
          send(pid, {:videos_generated, []})
      end
    end)

    {:noreply, assign(socket, :generating_videos, true)}
  end

  def handle_event(
        "update_headline",
        %{"type" => type, "index" => index, "value" => value},
        socket
      ) do
    index = String.to_integer(index)
    website_id = socket.assigns[:website_id]

    case type do
      "short" ->
        headlines = List.update_at(socket.assigns.headlines, index, &Map.put(&1, :text, value))

        # Save to database
        if website_id do
          Task.start(fn ->
            db_headlines = Assets.list_headlines_by_website(website_id)

            if Enum.at(db_headlines, index) do
              headline = Enum.at(db_headlines, index)

              Assets.update_headline(headline, %{
                text: value,
                character_count: String.length(value)
              })
            end
          end)
        end

        {:noreply, assign(socket, :headlines, headlines)}

      "long" ->
        long_headlines =
          List.update_at(socket.assigns.long_headlines, index, &Map.put(&1, :text, value))

        # Save to database
        if website_id do
          Task.start(fn ->
            db_long_headlines = Assets.list_long_headlines_by_website(website_id)

            if Enum.at(db_long_headlines, index) do
              long_headline = Enum.at(db_long_headlines, index)

              Assets.update_long_headline(long_headline, %{
                text: value,
                character_count: String.length(value)
              })
            end
          end)
        end

        {:noreply, assign(socket, :long_headlines, long_headlines)}
    end
  end

  def handle_event("update_description", %{"index" => index, "value" => value}, socket) do
    index = String.to_integer(index)
    website_id = socket.assigns[:website_id]
    descriptions = List.update_at(socket.assigns.descriptions, index, &Map.put(&1, :text, value))

    # Save to database
    if website_id do
      Task.start(fn ->
        db_descriptions = Assets.list_descriptions_by_website(website_id)

        if Enum.at(db_descriptions, index) do
          description = Enum.at(db_descriptions, index)

          Assets.update_description(description, %{
            text: value,
            character_count: String.length(value)
          })
        end
      end)
    end

    {:noreply, assign(socket, :descriptions, descriptions)}
  end

  def handle_event("download_all", _, socket) do
    # TODO: Implement download
    {:noreply, put_flash(socket, :info, "Download started...")}
  end

  def handle_event("export_to_google", _, socket) do
    # TODO: Implement Google Ads export
    {:noreply, put_flash(socket, :info, "Google Ads export coming soon!")}
  end

  def handle_event("copy_text", %{"text" => _text}, socket) do
    # Copy is handled by JavaScript hook, just show flash message
    {:noreply, put_flash(socket, :info, "Copied to clipboard!")}
  end

  def handle_event("regenerate_headline", %{"type" => type, "index" => index}, socket) do
    index = String.to_integer(index)
    pid = self()
    analysis = socket.assigns.analysis

    # Generate all headlines and replace the one at the specified index
    Task.start(fn ->
      case Assets.generate_headlines(analysis) do
        {:ok, result} ->
          # Send message with the index and type to replace
          send(
            pid,
            {:headline_regenerated, type, index, result.headlines, result.long_headlines,
             result.descriptions}
          )

        {:error, _} ->
          send(pid, {:headline_regenerated, type, index, [], [], []})
      end
    end)

    {:noreply, socket}
  end

  # ============================================================================
  # HELPERS
  # ============================================================================

  defp step_completed?(step, current_step, steps) do
    step_index = Enum.find_index(steps, &(&1 == step))
    current_index = Enum.find_index(steps, &(&1 == current_step))
    step_index < current_index
  end

  defp has_assets?(headlines, images, videos) do
    headlines != [] or images != [] or videos != []
  end

  defp update_url_params(socket, url, step) do
    params = URI.encode_query(%{"url" => url, "step" => Atom.to_string(step)})
    path = "/dashboard/new?" <> params

    push_patch(socket, to: path)
  end
end
