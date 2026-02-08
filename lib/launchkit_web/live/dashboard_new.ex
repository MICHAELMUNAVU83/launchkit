defmodule LaunchkitWeb.DashboardLive.New do
  @moduledoc """
  Multi-step asset generation flow:
  1. Analyze website
  2. Review brand analysis
  3. Generate assets (headlines, images)
  4. Export
  """
  use LaunchkitWeb, :live_view

  alias Launchkit.WebScraper
  alias Launchkit.Assets
  alias Launchkit.Campaigns
  alias Launchkit.AIVisibility
  import Ecto.Query
  alias Launchkit.Repo

  @steps [:analyzing, :review, :generate, :ai_visibility, :export]

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
      # Loading states
      |> assign(:generating_headlines, false)
      |> assign(:generating_images, false)
      # AI Visibility
      |> assign(:ai_visibility, nil)
      |> assign(:analyzing_visibility, false)
      |> assign(:blog_topics, [])
      |> assign(:generating_blog, false)
      |> assign(:selected_blog_topic, nil)
      |> assign(:generated_blog, nil)
      |> assign(:export_tab, :headlines)

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

          # Load persisted AI visibility if present
          ai_visibility_assigns =
            case Campaigns.get_ai_visibility_by_website(website_id) do
              nil ->
                [
                  ai_visibility: nil,
                  blog_topics: [],
                  generated_blog: nil
                ]

              record ->
                [
                  ai_visibility: record.visibility_data || nil,
                  blog_topics: record.blog_topics || [],
                  generated_blog: record.generated_blog
                ]
            end

          ai_visibility_assigns = Keyword.put(ai_visibility_assigns, :export_tab, :headlines)

          socket =
            socket
            |> assign(:analysis, analysis)
            |> assign(:website_id, website_id)
            |> assign(:headlines, headlines)
            |> assign(:long_headlines, long_headlines)
            |> assign(:descriptions, descriptions)
            |> assign(:images, images)
            |> assign(:current_step, current_step)
            |> assign(:analyzing_visibility, false)
            |> assign(:generating_blog, false)
            |> assign(:selected_blog_topic, nil)
            |> assign(ai_visibility_assigns)

          # Scroll to top if we're loading a specific step from URL
          socket = if step_param, do: push_event(socket, "scroll-to-top", %{}), else: socket

          {:ok, socket}

        _ ->
          # No saved analysis, start fresh analysis
          send(self(), {:analyze_website, url})
          {:ok, socket}
      end
    else
      {:ok, socket}
    end
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-[#fafaf9] font-sans antialiased">
      <!-- Header -->
      <header class="bg-white">
        <div class="max-w-6xl mx-auto px-4 sm:px-6 py-4 flex items-center justify-between gap-2">
          <.link navigate={~p"/"} class="flex items-center gap-2 flex-shrink-0">
            <span class="text-xl font-semibold tracking-tight">
              <img src="/images/small.png" alt="LaunchKit" class="w-10 h-10 sm:w-12 sm:h-12" />
            </span>
          </.link>
          
    <!-- Progress Steps -->
          <div class="md:hidden text-sm text-[#525252]">
            <span class="font-medium text-[#0d0d0d]">{step_label(@current_step)}</span>
            <span class="mx-1">·</span>
            <span>{Enum.find_index(@steps, &(&1 == @current_step)) + 1} of {length(@steps)}</span>
          </div>
          <div class="hidden md:flex items-center gap-2 flex-wrap justify-center min-w-0">
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
                <span>{step_label(step)}</span>
              </div>
              <%= if idx < length(@steps) - 1 do %>
                <div class="w-8 h-px bg-[#e5e5e5]"></div>
              <% end %>
            <% end %>
          </div>

          <div
            class="text-sm text-[#525252] truncate max-w-[140px] sm:max-w-none"
            title={if @url, do: @url, else: ""}
          >
            {if @url, do: URI.parse(@url).host, else: "No URL"}
          </div>
        </div>
      </header>
      
    <!-- Main Content -->
      <main
        class="max-w-6xl mx-auto px-4 sm:px-6 py-6 sm:py-8"
        phx-hook="ScrollToTop"
        id="main-content"
      >
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
              generating_headlines={@generating_headlines}
              generating_images={@generating_images}
            />
          <% :export -> %>
            <.export_step
              url={@url}
              export_tab={@export_tab}
              headlines={@headlines}
              long_headlines={@long_headlines}
              descriptions={@descriptions}
              images={@images}
              blog_topics={@blog_topics}
              generated_blog={@generated_blog}
              ai_visibility={@ai_visibility}
            />
          <% :ai_visibility -> %>
            <.ai_visibility_step
              url={@url}
              analysis={@analysis}
              ai_visibility={@ai_visibility}
              analyzing_visibility={@analyzing_visibility}
              blog_topics={@blog_topics}
              generating_blog={@generating_blog}
              selected_blog_topic={@selected_blog_topic}
              generated_blog={@generated_blog}
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
      
    <!-- Continue Buttons -->
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
    <div class="px-2 sm:px-0">
      <div class="text-center mb-6 sm:mb-8">
        <h1 class="text-3xl font-semibold mb-2">Generate Your Assets</h1>
        <p class="text-[#525252]">Generate headlines and images for your campaign.</p>
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
      <div class="flex justify-center mb-6 sm:mb-10 overflow-x-auto">
        <div class="inline-flex bg-gray-100 rounded-lg p-1.5 gap-1 flex-shrink-0">
          <button
            phx-click="switch_tab"
            phx-value-tab="headlines"
            class={[
              "px-4 sm:px-6 py-2.5 rounded-md text-sm font-medium transition-all",
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
              "px-4 sm:px-6 py-2.5 rounded-md text-sm font-medium transition-all",
              @active_tab == :images && "bg-white text-gray-900 shadow-sm",
              @active_tab != :images && "text-gray-600 hover:text-gray-900"
            ]}
          >
            Images
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
      <% end %>
      
    <!-- Continue to Export -->
      <%= if has_assets?(@headlines, @images) do %>
        <div class="flex flex-wrap justify-center gap-3 sm:gap-4 mt-6 sm:mt-8">
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
            phx-click="go_to_step"
            phx-value-step="ai_visibility"
            class="bg-black text-white px-8 py-3 rounded-lg font-medium hover:bg-gray-900 transition-colors flex items-center gap-2 shadow-sm"
          >
            Check AI Visibility
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
    <div class="max-w-5xl mx-auto px-2 sm:px-0">
      <!-- Generate Button -->
      <div class="flex justify-center mb-6">
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
        <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-3 items-start">
          <%= for image <- @images do %>
            <div class="bg-white border border-gray-200 rounded-xl overflow-hidden shadow-sm hover:shadow-md transition-shadow group">
              <div class={[
                "bg-gray-100 relative overflow-hidden min-h-0",
                aspect_ratio_class(image.aspect_ratio)
              ]}>
                <%= if image.status == :completed do %>
                  <img
                    src={image.url}
                    alt={image.prompt}
                    class="w-full h-full object-cover object-center"
                  />
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
              <div class="p-3 border-t border-gray-100">
                <p class="text-sm text-gray-700 truncate font-medium">{image.prompt}</p>
                <p class="text-xs text-gray-500 mt-0.5">{image.aspect_ratio}</p>
              </div>
            </div>
          <% end %>
        </div>
      <% else %>
        <div class="text-center py-12 text-gray-400">
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

  defp export_step(assigns) do
    url = Map.get(assigns, :url) || ""
    assigns = assign(assigns, :share_url, get_share_url(url))

    ~H"""
    <div class="max-w-4xl mx-auto px-2 sm:px-0">
      <!-- Back Button -->
      <div class="mb-6">
        <button
          phx-click="go_to_step"
          phx-value-step="ai_visibility"
          class="flex items-center gap-2 text-sm text-gray-600 hover:text-gray-900 transition-colors"
        >
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
          </svg>
          Back to AI Visibility
        </button>
      </div>

      <.assets_export_tab
        share_url={@share_url}
        export_tab={@export_tab}
        images={@images}
        headlines={@headlines}
        long_headlines={@long_headlines}
        descriptions={@descriptions}
        blog_topics={@blog_topics}
        generated_blog={@generated_blog}
        ai_visibility={@ai_visibility}
      />
    </div>
    """
  end

  defp ai_visibility_step(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-2 sm:px-0">
      <!-- Back Buttons -->
      <div class="mb-6 flex flex-wrap items-center gap-3">
        <button
          phx-click="go_to_step"
          phx-value-step="generate"
          class="flex items-center gap-2 text-sm text-gray-600 hover:text-gray-900 transition-colors"
        >
          <svg
            class="w-4 h-4 flex-shrink-0"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="2"
          >
            <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
          </svg>
          Back to Generate
        </button>
        <button
          phx-click="go_to_step"
          phx-value-step="export"
          class="flex items-center gap-2 text-sm text-gray-600 hover:text-gray-900 transition-colors"
        >
          <svg
            class="w-4 h-4 flex-shrink-0"
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
          Go to Export
        </button>
      </div>

      <.ai_visibility_tab
        url={@url}
        analysis={@analysis}
        ai_visibility={@ai_visibility}
        analyzing_visibility={@analyzing_visibility}
        blog_topics={@blog_topics}
        generating_blog={@generating_blog}
        selected_blog_topic={@selected_blog_topic}
        generated_blog={@generated_blog}
      />
      
    <!-- Continue to Export -->
      <div class="flex flex-wrap justify-center gap-3 sm:gap-4 mt-6 sm:mt-8">
        <button
          phx-click="go_to_step"
          phx-value-step="export"
          class="px-8 py-3 bg-[#0d0d0d] text-white rounded-lg font-medium hover:bg-[#262626] transition-colors flex items-center gap-2"
        >
          Continue to Export
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

  defp assets_export_tab(assigns) do
    ~H"""
    <div>
      <!-- Share Link Section -->
      <div class="bg-white border border-gray-200 rounded-xl p-6 mb-6 shadow-sm">
        <h2 class="text-lg font-semibold text-gray-900 mb-3">Share This Page</h2>
        <div class="flex items-center gap-3">
          <input
            type="text"
            readonly
            value={@share_url}
            id="share-url-input"
            class="flex-1 px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-lg text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-gray-300"
          />
          <button
            phx-click="copy_text"
            phx-value-text={@share_url}
            phx-hook="CopyToClipboard"
            id="copy-share-url"
            class="px-4 py-2.5 bg-gray-900 text-white rounded-lg text-sm font-medium hover:bg-gray-800 transition-colors flex items-center gap-2"
            title="Copy share link"
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
            Copy Link
          </button>
        </div>
      </div>
      
    <!-- Report Tabs -->
      <div class="flex justify-center mb-6">
        <div class="inline-flex bg-gray-100 rounded-lg p-1.5 gap-1">
          <button
            phx-click="set_export_tab"
            phx-value-tab="headlines"
            class={[
              "px-5 py-2.5 rounded-md text-sm font-medium transition-all",
              @export_tab == :headlines && "bg-white text-gray-900 shadow-sm",
              @export_tab != :headlines && "text-gray-600 hover:text-gray-900"
            ]}
          >
            Headlines
          </button>
          <button
            phx-click="set_export_tab"
            phx-value-tab="images"
            class={[
              "px-5 py-2.5 rounded-md text-sm font-medium transition-all",
              @export_tab == :images && "bg-white text-gray-900 shadow-sm",
              @export_tab != :images && "text-gray-600 hover:text-gray-900"
            ]}
          >
            Images
          </button>
          <button
            phx-click="set_export_tab"
            phx-value-tab="ai_visibility"
            class={[
              "px-5 py-2.5 rounded-md text-sm font-medium transition-all",
              @export_tab == :ai_visibility && "bg-white text-gray-900 shadow-sm",
              @export_tab != :ai_visibility && "text-gray-600 hover:text-gray-900"
            ]}
          >
            AI Visibility
          </button>
        </div>
      </div>
      
    <!-- Tab Content -->
      <%= case @export_tab do %>
        <% :headlines -> %>
          <div class="bg-white border border-gray-200 rounded-xl p-6 shadow-sm">
            <h2 class="text-lg font-semibold text-gray-900 mb-6">Headlines & Descriptions</h2>
            <%= if @headlines != [] do %>
              <div class="mb-6">
                <h3 class="text-sm font-medium text-gray-700 mb-3">Short Headlines</h3>
                <div class="space-y-2">
                  <%= for {headline, idx} <- Enum.with_index(@headlines) do %>
                    <div class="flex items-center gap-3 p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors group">
                      <span class="text-xs font-medium text-gray-400 w-6 flex-shrink-0">
                        {idx + 1}
                      </span>
                      <span class="flex-1 text-sm text-gray-900">{headline.text}</span>
                      <button
                        id={"export-copy-headline-#{idx}"}
                        phx-click="copy_text"
                        phx-value-text={headline.text}
                        phx-hook="CopyToClipboard"
                        class="px-3 py-1.5 text-xs font-medium text-gray-700 bg-white border border-gray-200 rounded hover:bg-gray-50 transition-colors flex items-center gap-1.5"
                        title="Copy to clipboard"
                      >
                        <svg
                          class="w-3.5 h-3.5"
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
                        Copy
                      </button>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
            <%= if @long_headlines != [] do %>
              <div class="mb-6">
                <h3 class="text-sm font-medium text-gray-700 mb-3">Long Headlines</h3>
                <div class="space-y-2">
                  <%= for {headline, idx} <- Enum.with_index(@long_headlines) do %>
                    <div class="flex items-center gap-3 p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors group">
                      <span class="text-xs font-medium text-gray-400 w-6 flex-shrink-0">
                        {idx + 1}
                      </span>
                      <span class="flex-1 text-sm text-gray-900">{headline.text}</span>
                      <button
                        id={"export-copy-long-headline-#{idx}"}
                        phx-click="copy_text"
                        phx-value-text={headline.text}
                        phx-hook="CopyToClipboard"
                        class="px-3 py-1.5 text-xs font-medium text-gray-700 bg-white border border-gray-200 rounded hover:bg-gray-50 transition-colors flex items-center gap-1.5"
                        title="Copy to clipboard"
                      >
                        <svg
                          class="w-3.5 h-3.5"
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
                        Copy
                      </button>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
            <%= if @descriptions != [] do %>
              <div>
                <h3 class="text-sm font-medium text-gray-700 mb-3">Descriptions</h3>
                <div class="space-y-2">
                  <%= for {desc, idx} <- Enum.with_index(@descriptions) do %>
                    <div class="flex items-start gap-3 p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors group">
                      <span class="text-xs font-medium text-gray-400 w-6 flex-shrink-0 pt-1">
                        {idx + 1}
                      </span>
                      <p class="flex-1 text-sm text-gray-900">{desc.text}</p>
                      <button
                        id={"export-copy-description-#{idx}"}
                        phx-click="copy_text"
                        phx-value-text={desc.text}
                        phx-hook="CopyToClipboard"
                        class="px-3 py-1.5 text-xs font-medium text-gray-700 bg-white border border-gray-200 rounded hover:bg-gray-50 transition-colors flex items-center gap-1.5 flex-shrink-0"
                        title="Copy to clipboard"
                      >
                        <svg
                          class="w-3.5 h-3.5"
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
                        Copy
                      </button>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
            <%= if @headlines == [] && @long_headlines == [] && @descriptions == [] do %>
              <p class="text-sm text-gray-500">
                No headlines or descriptions yet. Generate assets in the Generate step.
              </p>
            <% end %>
          </div>
        <% :images -> %>
          <div class="bg-white border border-gray-200 rounded-xl p-6 shadow-sm">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">Images</h2>
            <%= if @images != [] do %>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <%= for image <- @images do %>
                  <div class="border border-gray-200 rounded-lg overflow-hidden">
                    <div class="aspect-video bg-gray-100 relative">
                      <%= if image.status == :completed do %>
                        <img src={image.url} alt="Generated image" class="w-full h-full object-cover" />
                      <% else %>
                        <div class="absolute inset-0 flex items-center justify-center bg-gray-100">
                          <div class="text-center text-gray-400">
                            <svg
                              class="w-8 h-8 mx-auto mb-2 animate-spin"
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
                              />
                              <path
                                class="opacity-75"
                                fill="currentColor"
                                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
                              />
                            </svg>
                            <p class="text-xs">Generating...</p>
                          </div>
                        </div>
                      <% end %>
                    </div>
                    <div class="p-3 bg-white flex items-center justify-between">
                      <span class="text-xs text-gray-500">{image.aspect_ratio || "N/A"}</span>
                      <%= if image.status == :completed do %>
                        <a
                          href={image.url}
                          download
                          class="px-3 py-1.5 bg-gray-900 text-white text-xs font-medium rounded hover:bg-gray-800 transition-colors flex items-center gap-1.5"
                        >
                          <svg
                            class="w-3.5 h-3.5"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                            stroke-width="2"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3"
                            />
                          </svg>
                          Download
                        </a>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            <% else %>
              <p class="text-sm text-gray-500">
                No images yet. Generate images in the Generate step.
              </p>
            <% end %>
          </div>
        <% :ai_visibility -> %>
          <div class="space-y-6">
            <div class="flex items-center justify-between">
              <h2 class="text-lg font-semibold text-gray-900">AI Visibility</h2>
              <button
                type="button"
                phx-click="go_to_step"
                phx-value-step="ai_visibility"
                class="text-sm font-medium text-emerald-600 hover:text-emerald-700 flex items-center gap-1.5"
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
                    d="M15.75 19.5L8.25 12l7.5-7.5"
                  />
                </svg>
                Go to AI Visibility
              </button>
            </div>

            <%= if @ai_visibility != nil do %>
              <div class="bg-white border border-gray-200 rounded-xl p-6 shadow-sm">
                <h3 class="text-base font-semibold text-gray-900 mb-4">Score & Recommendations</h3>
                <div class="text-center mb-6">
                  <% overall =
                    Map.get(@ai_visibility, "overall_score") || @ai_visibility[:overall_score] ||
                      @ai_visibility.overall_score %>
                  <div
                    class="inline-flex items-center justify-center w-24 h-24 rounded-full border-6 border-gray-100 mb-3"
                    style={"border-color: #{get_score_color(overall)}"}
                  >
                    <div class="text-3xl font-bold" style={"color: #{get_score_color(overall)}"}>
                      {overall}
                    </div>
                  </div>
                  <p class="text-sm text-gray-600">{get_score_label(overall)}</p>
                </div>
                <% scores =
                  Map.get(@ai_visibility, "scores") || @ai_visibility[:scores] ||
                    @ai_visibility.scores %>
                <div class="grid grid-cols-2 md:grid-cols-4 gap-3 mb-6">
                  <div class="text-center p-3 bg-gray-50 rounded-lg">
                    <div class="text-xl font-semibold text-gray-900">
                      {Map.get(scores, "presence") || scores[:presence] || scores.presence}
                    </div>
                    <div class="text-xs text-gray-600">Presence</div>
                  </div>
                  <div class="text-center p-3 bg-gray-50 rounded-lg">
                    <div class="text-xl font-semibold text-gray-900">
                      {Map.get(scores, "completeness") || scores[:completeness] || scores.completeness}
                    </div>
                    <div class="text-xs text-gray-600">Completeness</div>
                  </div>
                  <div class="text-center p-3 bg-gray-50 rounded-lg">
                    <div class="text-xl font-semibold text-gray-900">
                      {Map.get(scores, "recency") || scores[:recency] || scores.recency}
                    </div>
                    <div class="text-xs text-gray-600">Recency</div>
                  </div>
                  <div class="text-center p-3 bg-gray-50 rounded-lg">
                    <div class="text-xl font-semibold text-gray-900">
                      {Map.get(scores, "authority") || scores[:authority] || scores.authority}
                    </div>
                    <div class="text-xs text-gray-600">Authority</div>
                  </div>
                </div>
                <%= if recommendations = Map.get(@ai_visibility, "recommendations") || @ai_visibility[:recommendations] || @ai_visibility.recommendations do %>
                  <%= if priority = Map.get(recommendations, "priority_recommendations") || Map.get(recommendations, :priority_recommendations) do %>
                    <h4 class="font-medium text-gray-900 mb-2">Priority Recommendations</h4>
                    <div class="space-y-3 mb-4">
                      <%= for rec <- priority do %>
                        <div class="p-3 bg-gray-50 rounded-lg border border-gray-200">
                          <div class="flex items-start justify-between gap-2 mb-1">
                            <h5 class="font-medium text-gray-900">{rec["title"] || rec[:title]}</h5>
                            <span class={"px-2 py-0.5 text-xs font-medium rounded #{get_impact_class(rec["impact"] || rec[:impact])}"}>
                              {rec["impact"] || rec[:impact]} impact
                            </span>
                          </div>
                          <p class="text-sm text-gray-600">
                            {rec["description"] || rec[:description]}
                          </p>
                        </div>
                      <% end %>
                    </div>
                  <% end %>
                  <%= if quick_wins = Map.get(recommendations, "quick_wins") || Map.get(recommendations, :quick_wins) do %>
                    <h4 class="font-medium text-gray-900 mb-2">Quick Wins</h4>
                    <ul class="space-y-1.5 text-sm text-gray-600">
                      <%= for win <- quick_wins do %>
                        <li class="flex items-start gap-2">
                          <svg
                            class="w-5 h-5 text-emerald-600 flex-shrink-0 mt-0.5"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                            stroke-width="2"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                            />
                          </svg>
                          <span>{win}</span>
                        </li>
                      <% end %>
                    </ul>
                  <% end %>
                <% end %>
              </div>
            <% end %>

            <div class="bg-white border border-gray-200 rounded-xl p-6 shadow-sm">
              <h3 class="text-base font-semibold text-gray-900 mb-4">Blog Topics & Generated Post</h3>
              <%= if @blog_topics != [] do %>
                <div class="space-y-3 mb-6">
                  <%= for {topic, idx} <- Enum.with_index(@blog_topics) do %>
                    <% topic_title =
                      topic["title"] || topic[:title] || topic["topic"] || topic[:topic] ||
                        "Untitled Topic" %>
                    <% topic_copy_text = export_blog_topic_copy_text(topic) %>
                    <div class="flex items-start gap-3 p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors group">
                      <div class="flex-1 min-w-0">
                        <h4 class="font-medium text-gray-900">{topic_title}</h4>
                        <%= if desc = topic["description"] || topic[:description] do %>
                          <p class="text-sm text-gray-600 mt-1">{desc}</p>
                        <% end %>
                        <%= if why = topic["why_it_helps"] || topic[:why_it_helps] || topic["reason"] || topic[:reason] do %>
                          <p class="text-xs text-gray-500 mt-1">{why}</p>
                        <% end %>
                      </div>
                      <button
                        id={"export-copy-blog-topic-#{idx}"}
                        phx-click="copy_text"
                        phx-value-text={topic_copy_text}
                        phx-hook="CopyToClipboard"
                        class="px-3 py-1.5 text-xs font-medium text-gray-700 bg-white border border-gray-200 rounded hover:bg-gray-50 flex-shrink-0"
                        title="Copy topic"
                      >
                        <svg
                          class="w-3.5 h-3.5"
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
                        Copy
                      </button>
                    </div>
                  <% end %>
                </div>
              <% end %>
              <%= if @generated_blog != nil do %>
                <div class="pt-4 border-t border-gray-200">
                  <h4 class="font-medium text-gray-900 mb-2">Generated Blog Post</h4>
                  <div class="p-4 bg-gray-50 rounded-lg border border-gray-200">
                    <div class="flex items-start justify-between gap-3 mb-3">
                      <h5 class="font-semibold text-gray-900">
                        {@generated_blog["title"] || @generated_blog[:title] || "Blog Post"}
                      </h5>
                      <button
                        id="export-copy-blog-content"
                        phx-click="copy_text"
                        phx-value-text={@generated_blog["content"] || @generated_blog[:content] || ""}
                        phx-hook="CopyToClipboard"
                        class="px-3 py-1.5 text-xs font-medium text-gray-700 bg-white border border-gray-200 rounded hover:bg-gray-50 flex-shrink-0"
                        title="Copy full post"
                      >
                        Copy Post
                      </button>
                    </div>
                    <div class="prose prose-sm max-w-none text-gray-700 text-sm line-clamp-4">
                      {render_markdown(@generated_blog["content"] || @generated_blog[:content] || "")}
                    </div>
                    <%= if keywords = @generated_blog["keywords"] || @generated_blog[:keywords] do %>
                      <p class="text-xs text-gray-500 mt-2">
                        <span class="font-medium">Keywords:</span> {Enum.join(keywords, ", ")}
                      </p>
                    <% end %>
                    <%= if meta = @generated_blog["meta_description"] || @generated_blog[:meta_description] do %>
                      <p class="text-xs text-gray-500 mt-1">
                        <span class="font-medium">Meta:</span> {meta}
                      </p>
                    <% end %>
                  </div>
                </div>
              <% end %>
              <%= if @blog_topics == [] && @generated_blog == nil do %>
                <p class="text-sm text-gray-500">
                  No blog topics or generated post yet. Use "Go to AI Visibility" to analyze and generate content.
                </p>
              <% end %>
            </div>
          </div>
      <% end %>
    </div>
    """
  end

  defp export_blog_topic_copy_text(topic) do
    title = topic["title"] || topic[:title] || topic["topic"] || topic[:topic] || "Untitled Topic"
    desc = topic["description"] || topic[:description] || ""
    why = topic["why_it_helps"] || topic[:why_it_helps] || topic["reason"] || topic[:reason] || ""

    [title, desc, why]
    |> Enum.filter(&(is_binary(&1) and String.trim(&1) != ""))
    |> Enum.join("\n\n")
  end

  defp ai_visibility_tab(assigns) do
    ~H"""
    <div>
      <!-- Analyze Button -->
      <%= if @ai_visibility == nil do %>
        <div class="bg-white border border-gray-200 rounded-xl p-8 mb-8 shadow-sm text-center">
          <div class="w-16 h-16 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg
              class="w-8 h-8 text-emerald-600"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09zM18.259 8.715L18 9.75l-.259-1.035a3.375 3.375 0 00-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 002.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 002.456 2.456L21.75 6l-1.035.259a3.375 3.375 0 00-2.456 2.456zM16.894 20.567L16.5 21.75l-.394-1.183a2.25 2.25 0 00-1.423-1.423L13.5 18.75l1.183-.394a2.25 2.25 0 001.423-1.423l.394-1.183.394 1.183a2.25 2.25 0 001.423 1.423l1.183.394-1.183.394a2.25 2.25 0 00-1.423 1.423z"
              />
            </svg>
          </div>
          <h2 class="text-2xl font-semibold text-gray-900 mb-2">AI Search Visibility</h2>
          <p class="text-gray-600 mb-6">
            Analyze how well your business appears in AI search results and get recommendations to improve visibility.
          </p>
          <button
            phx-click="analyze_ai_visibility"
            disabled={@analyzing_visibility}
            class={[
              "px-8 py-3 rounded-lg font-medium transition-all flex items-center gap-2 mx-auto",
              @analyzing_visibility && "bg-gray-100 text-gray-400 cursor-not-allowed",
              !@analyzing_visibility && "bg-emerald-600 text-white hover:bg-emerald-700 shadow-sm"
            ]}
          >
            <%= if @analyzing_visibility do %>
              <svg class="w-5 h-5 animate-spin" fill="none" viewBox="0 0 24 24">
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
              Analyzing...
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
              Analyze AI Visibility
            <% end %>
          </button>
        </div>
      <% else %>
        <!-- Score Display -->
        <div class="bg-white border border-gray-200 rounded-xl p-6 mb-8 shadow-sm">
          <div class="flex items-center justify-between mb-6">
            <h2 class="text-xl font-semibold text-gray-900">AI Visibility Score</h2>
            <button
              phx-click="analyze_ai_visibility"
              disabled={@analyzing_visibility}
              class="text-sm text-gray-600 hover:text-gray-900 flex items-center gap-1"
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
              Refresh
            </button>
          </div>
          
    <!-- Overall Score -->
          <% overall_score =
            Map.get(@ai_visibility, "overall_score") || @ai_visibility[:overall_score] ||
              @ai_visibility.overall_score %>
          <div class="text-center mb-8">
            <div
              class="inline-flex items-center justify-center w-32 h-32 rounded-full border-8 border-gray-100 mb-4"
              style={"border-color: #{get_score_color(overall_score)}"}
            >
              <div class="text-center">
                <div class="text-4xl font-bold" style={"color: #{get_score_color(overall_score)}"}>
                  {overall_score}
                </div>
                <div class="text-xs text-gray-500 mt-1">/ 100</div>
              </div>
            </div>
            <p class="text-sm text-gray-600">
              {get_score_label(overall_score)}
            </p>
          </div>
          
    <!-- Individual Scores -->
          <% scores =
            Map.get(@ai_visibility, "scores") || @ai_visibility[:scores] || @ai_visibility.scores %>
          <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div class="text-center p-4 bg-gray-50 rounded-lg">
              <div class="text-2xl font-semibold text-gray-900">
                {Map.get(scores, "presence") || scores[:presence] || scores.presence}
              </div>
              <div class="text-xs text-gray-600 mt-1">Presence</div>
            </div>
            <div class="text-center p-4 bg-gray-50 rounded-lg">
              <div class="text-2xl font-semibold text-gray-900">
                {Map.get(scores, "completeness") || scores[:completeness] || scores.completeness}
              </div>
              <div class="text-xs text-gray-600 mt-1">Completeness</div>
            </div>
            <div class="text-center p-4 bg-gray-50 rounded-lg">
              <div class="text-2xl font-semibold text-gray-900">
                {Map.get(scores, "recency") || scores[:recency] || scores.recency}
              </div>
              <div class="text-xs text-gray-600 mt-1">Recency</div>
            </div>
            <div class="text-center p-4 bg-gray-50 rounded-lg">
              <div class="text-2xl font-semibold text-gray-900">
                {Map.get(scores, "authority") || scores[:authority] || scores.authority}
              </div>
              <div class="text-xs text-gray-600 mt-1">Authority</div>
            </div>
          </div>
        </div>
        
    <!-- Recommendations -->
        <%= if recommendations = Map.get(@ai_visibility, "recommendations") || @ai_visibility[:recommendations] || @ai_visibility.recommendations do %>
          <div class="bg-white border border-gray-200 rounded-xl p-6 mb-8 shadow-sm">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Recommendations</h3>

            <%= if priority = Map.get(recommendations, "priority_recommendations") || Map.get(recommendations, :priority_recommendations) do %>
              <div class="space-y-4 mb-6">
                <%= for rec <- priority do %>
                  <div class="p-4 bg-gray-50 rounded-lg border border-gray-200">
                    <div class="flex items-start justify-between mb-2">
                      <h4 class="font-medium text-gray-900">{rec["title"] || rec[:title]}</h4>
                      <div class="flex gap-2">
                        <span class={"px-2 py-1 text-xs font-medium rounded #{get_impact_class(rec["impact"] || rec[:impact])}"}>
                          {rec["impact"] || rec[:impact]} impact
                        </span>
                        <span class={"px-2 py-1 text-xs font-medium rounded #{get_effort_class(rec["effort"] || rec[:effort])}"}>
                          {rec["effort"] || rec[:effort]} effort
                        </span>
                      </div>
                    </div>
                    <p class="text-sm text-gray-600">{rec["description"] || rec[:description]}</p>
                  </div>
                <% end %>
              </div>
            <% end %>

            <%= if quick_wins = Map.get(recommendations, "quick_wins") || Map.get(recommendations, :quick_wins) do %>
              <div class="mb-6">
                <h4 class="font-medium text-gray-900 mb-3">Quick Wins</h4>
                <ul class="space-y-2">
                  <%= for win <- quick_wins do %>
                    <li class="flex items-start gap-2 text-sm text-gray-600">
                      <svg
                        class="w-5 h-5 text-emerald-600 flex-shrink-0 mt-0.5"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                        stroke-width="2"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                        />
                      </svg>
                      <span>{win}</span>
                    </li>
                  <% end %>
                </ul>
              </div>
            <% end %>
          </div>
        <% end %>
        
    <!-- Blog Topics -->
        <div class="bg-white border border-gray-200 rounded-xl p-6 shadow-sm">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-900">Blog Topics to Improve Visibility</h3>
            <%= if @blog_topics == [] do %>
              <button
                phx-click="generate_blog_topics"
                disabled={@generating_blog}
                class="text-sm text-blue-600 hover:text-blue-700 font-medium"
              >
                Generate Topics
              </button>
            <% end %>
          </div>

          <%= if @blog_topics != [] do %>
            <div class="space-y-3 mb-6">
              <%= for {topic, idx} <- Enum.with_index(@blog_topics) do %>
                <div class="p-4 border border-gray-200 rounded-lg hover:border-gray-300 transition-colors">
                  <div class="flex items-start justify-between mb-2">
                    <h4 class="font-medium text-gray-900">
                      {topic["title"] || topic[:title] || topic["topic"] || topic[:topic] ||
                        "Untitled Topic"}
                    </h4>
                    <span class={"px-2 py-1 text-xs font-medium rounded #{get_priority_class(topic["estimated_impact"] || topic[:estimated_impact] || topic["priority"] || topic[:priority])}"}>
                      {topic["estimated_impact"] || topic[:estimated_impact] || topic["priority"] ||
                        topic[:priority] || "medium"} impact
                    </span>
                  </div>
                  <%= if desc = topic["description"] || topic[:description] do %>
                    <p class="text-sm text-gray-600 mb-2">{desc}</p>
                  <% end %>
                  <%= if why = topic["why_it_helps"] || topic[:why_it_helps] || topic["reason"] || topic[:reason] do %>
                    <p class="text-xs text-gray-500 mb-3">{why}</p>
                  <% end %>
                  <button
                    phx-click="generate_blog_post"
                    phx-value-topic-index={idx}
                    disabled={@generating_blog}
                    class={[
                      "text-sm font-medium transition-all flex items-center gap-2",
                      @generating_blog && "text-gray-400 cursor-not-allowed",
                      !@generating_blog && "text-blue-600 hover:text-blue-700"
                    ]}
                  >
                    <%= if @generating_blog && @selected_blog_topic && (@selected_blog_topic["title"] == topic["title"] || @selected_blog_topic[:title] == topic[:title] || @selected_blog_topic["topic"] == topic["topic"] || @selected_blog_topic[:topic] == topic[:topic]) do %>
                      <svg class="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
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
                      Generating...
                    <% else %>
                      Generate Blog Post →
                    <% end %>
                  </button>
                </div>
              <% end %>
            </div>
          <% else %>
            <p class="text-sm text-gray-500 text-center py-8">
              Click "Generate Topics" to see blog post ideas that will improve your AI visibility.
            </p>
          <% end %>
          
    <!-- Generated Blog Post -->
          <%= if @generating_blog && @selected_blog_topic do %>
            <div class="mt-6 p-6 bg-gray-50 rounded-lg border border-gray-200">
              <div class="flex items-center justify-center py-12">
                <div class="text-center">
                  <svg
                    class="w-8 h-8 animate-spin text-blue-600 mx-auto mb-3"
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
                  <p class="text-sm text-gray-600">Generating blog post...</p>
                </div>
              </div>
            </div>
          <% end %>

          <%= if @generated_blog && !@generating_blog do %>
            <div class="mt-6 p-6 bg-gray-50 rounded-lg border border-gray-200">
              <div class="flex items-center justify-between mb-4">
                <h4 class="font-semibold text-gray-900">
                  {@generated_blog["title"] || @generated_blog[:title] || "Blog Post"}
                </h4>
                <button
                  id="copy-blog-content"
                  phx-click="copy_text"
                  phx-value-text={@generated_blog["content"]}
                  phx-hook="CopyToClipboard"
                  class="px-3 py-1.5 text-xs font-medium text-gray-700 bg-white border border-gray-200 rounded hover:bg-gray-50"
                >
                  Copy Content
                </button>
              </div>
              <div class="prose prose-sm max-w-none text-gray-700">
                {render_markdown(@generated_blog["content"] || @generated_blog[:content] || "")}
              </div>
              <%= if @generated_blog["content"] || @generated_blog[:content] do %>
                <div class="mt-4 pt-4 border-t border-gray-200">
                  <div class="text-xs text-gray-500 space-y-1">
                    <%= if keywords = @generated_blog["keywords"] || @generated_blog[:keywords] do %>
                      <div>
                        <span class="font-medium">Keywords:</span> {Enum.join(keywords, ", ")}
                      </div>
                    <% end %>
                    <%= if meta = @generated_blog["meta_description"] || @generated_blog[:meta_description] do %>
                      <div>
                        <span class="font-medium">Meta Description:</span> {meta}
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  # Aspect ratio classes for images_tab (match DALL-E sizes: landscape 1792×1024, square 1024×1024, portrait 1024×1792)
  defp aspect_ratio_class("landscape"), do: "aspect-[1792/1024]"
  defp aspect_ratio_class("square"), do: "aspect-square"
  defp aspect_ratio_class("portrait"), do: "aspect-[1024/1792]"
  defp aspect_ratio_class(_), do: "aspect-video"

  # green
  defp get_score_color(score) when score >= 80, do: "#10b981"
  # amber
  defp get_score_color(score) when score >= 60, do: "#f59e0b"
  # orange
  defp get_score_color(score) when score >= 40, do: "#f97316"
  # red
  defp get_score_color(_score), do: "#ef4444"

  defp get_score_label(score) when score >= 80, do: "Excellent AI Visibility"
  defp get_score_label(score) when score >= 60, do: "Good AI Visibility"
  defp get_score_label(score) when score >= 40, do: "Fair AI Visibility"
  defp get_score_label(_score), do: "Poor AI Visibility - Needs Improvement"

  defp get_impact_class("high"), do: "bg-red-100 text-red-700"
  defp get_impact_class("medium"), do: "bg-yellow-100 text-yellow-700"
  defp get_impact_class(_), do: "bg-gray-100 text-gray-700"

  defp get_effort_class("high"), do: "bg-blue-100 text-blue-700"
  defp get_effort_class("medium"), do: "bg-purple-100 text-purple-700"
  defp get_effort_class(_), do: "bg-gray-100 text-gray-700"

  defp get_priority_class("high"), do: "bg-red-100 text-red-700"
  defp get_priority_class("medium"), do: "bg-yellow-100 text-yellow-700"
  defp get_priority_class(_), do: "bg-gray-100 text-gray-700"

  # Simple markdown renderer - converts markdown to HTML
  defp render_markdown(text) when is_binary(text) and text != "" do
    import Phoenix.HTML

    lines = String.split(text, "\n")

    {html_parts, in_list} =
      lines
      |> Enum.reduce({[], false}, fn line, {acc, in_list} ->
        {rendered, new_in_list} = render_markdown_line(line, in_list)
        {[rendered | acc], new_in_list}
      end)

    # Close any open list
    final_html =
      if in_list do
        Enum.reverse(html_parts) |> Enum.join() |> Kernel.<>("</ul>")
      else
        Enum.reverse(html_parts) |> Enum.join()
      end

    raw(final_html)
  end

  defp render_markdown(""), do: raw("")
  defp render_markdown(nil), do: raw("")

  defp render_markdown_line(line, in_list) do
    trimmed = String.trim(line)

    cond do
      trimmed == "" ->
        if in_list, do: {"</ul>", false}, else: {"<br>", false}

      String.starts_with?(trimmed, "#### ") ->
        content = escape_html(String.slice(trimmed, 5..-1))

        html =
          if in_list,
            do: "</ul><h4 class='text-base font-semibold mb-2 mt-3'>#{content}</h4>",
            else: "<h4 class='text-base font-semibold mb-2 mt-3'>#{content}</h4>"

        {html, false}

      String.starts_with?(trimmed, "### ") ->
        content = escape_html(String.slice(trimmed, 4..-1))

        html =
          if in_list,
            do: "</ul><h3 class='text-lg font-semibold mb-2 mt-4'>#{content}</h3>",
            else: "<h3 class='text-lg font-semibold mb-2 mt-4'>#{content}</h3>"

        {html, false}

      String.starts_with?(trimmed, "## ") ->
        content = escape_html(String.slice(trimmed, 3..-1))

        html =
          if in_list,
            do: "</ul><h2 class='text-xl font-semibold mb-3 mt-5'>#{content}</h2>",
            else: "<h2 class='text-xl font-semibold mb-3 mt-5'>#{content}</h2>"

        {html, false}

      String.starts_with?(trimmed, "# ") ->
        content = escape_html(String.slice(trimmed, 2..-1))

        html =
          if in_list,
            do: "</ul><h1 class='text-2xl font-bold mb-4 mt-6'>#{content}</h1>",
            else: "<h1 class='text-2xl font-bold mb-4 mt-6'>#{content}</h1>"

        {html, false}

      String.starts_with?(trimmed, "- ") or String.starts_with?(trimmed, "* ") ->
        content = escape_html(String.slice(trimmed, 2..-1))

        html =
          if in_list,
            do: "<li class='mb-1'>#{content}</li>",
            else: "<ul class='list-disc ml-6 mb-3'><li class='mb-1'>#{content}</li>"

        {html, true}

      true ->
        content = escape_html(trimmed)

        html =
          if in_list,
            do: "</ul><p class='mb-3 leading-relaxed'>#{content}</p>",
            else: "<p class='mb-3 leading-relaxed'>#{content}</p>"

        {html, false}
    end
  end

  defp escape_html(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end

  defp get_share_url(url) do
    # Use JavaScript to get the current origin, or construct from endpoint config
    # For now, we'll use a client-side approach via a data attribute
    # The actual URL will be constructed in JavaScript
    base_url = "https://launchkit.info"
    path = "/dashboard/new"
    params = URI.encode_query(%{"url" => url || "", "step" => "export"})
    "#{base_url}#{path}?#{params}"
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
         |> assign(:current_step, :review)
         |> push_event("scroll-to-top", %{})}

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

  def handle_info({:ai_visibility_analyzed, visibility_data}, socket) do
    # Extract blog topics from recommendations if available
    # Handle both map and atom key access
    recommendations =
      visibility_data[:recommendations] || visibility_data["recommendations"] || %{}

    blog_topics =
      Map.get(recommendations, "blog_topics") || Map.get(recommendations, :blog_topics) || []

    # Persist to database
    website_id = socket.assigns[:website_id]

    if website_id do
      Campaigns.upsert_ai_visibility(website_id, %{
        visibility_data: visibility_data,
        blog_topics: blog_topics
      })
    end

    {:noreply,
     socket
     |> assign(:ai_visibility, visibility_data)
     |> assign(:analyzing_visibility, false)
     |> assign(:blog_topics, blog_topics)}
  end

  def handle_info({:ai_visibility_error, reason}, socket) do
    {:noreply,
     socket
     |> assign(:analyzing_visibility, false)
     |> put_flash(:error, "Failed to analyze AI visibility: #{inspect(reason)}")}
  end

  def handle_info({:blog_topics_generated, topics}, socket) do
    website_id = socket.assigns[:website_id]

    if website_id do
      Campaigns.upsert_ai_visibility(website_id, %{blog_topics: topics})
    end

    {:noreply,
     socket
     |> assign(:blog_topics, topics)
     |> assign(:generating_blog, false)}
  end

  def handle_info({:blog_topics_error, reason}, socket) do
    {:noreply,
     socket
     |> assign(:generating_blog, false)
     |> put_flash(:error, "Failed to generate blog topics: #{inspect(reason)}")}
  end

  def handle_info({:blog_post_generated, blog_post}, socket) do
    website_id = socket.assigns[:website_id]

    if website_id do
      Campaigns.upsert_ai_visibility(website_id, %{generated_blog: blog_post})
    end

    {:noreply,
     socket
     |> assign(:generated_blog, blog_post)
     |> assign(:generating_blog, false)
     |> assign(:selected_blog_topic, nil)}
  end

  def handle_info({:blog_post_error, reason}, socket) do
    {:noreply,
     socket
     |> assign(:generating_blog, false)
     |> put_flash(:error, "Failed to generate blog post: #{inspect(reason)}")}
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
            storage_path: image.storage_path || image.url,
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
     |> update_url_params(url, :generate)
     |> push_event("scroll-to-top", %{})}
  end

  def handle_event("go_to_step", %{"step" => step}, socket) do
    step_atom = String.to_existing_atom(step)
    url = socket.assigns.url || ""

    if step_atom in @steps do
      socket =
        socket
        |> assign(:current_step, step_atom)
        |> update_url_params(url, step_atom)
        |> push_event("scroll-to-top", %{})

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, String.to_existing_atom(tab))}
  end

  def handle_event("set_export_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :export_tab, String.to_existing_atom(tab))}
  end

  def handle_event("analyze_ai_visibility", _, socket) do
    pid = self()
    url = socket.assigns.url
    analysis = socket.assigns.analysis

    Task.start(fn ->
      case AIVisibility.analyze_visibility(url, analysis) do
        {:ok, visibility_data} ->
          send(pid, {:ai_visibility_analyzed, visibility_data})

        {:error, reason} ->
          send(pid, {:ai_visibility_error, reason})
      end
    end)

    {:noreply, assign(socket, :analyzing_visibility, true)}
  end

  def handle_event("generate_blog_topics", _, socket) do
    pid = self()
    analysis = socket.assigns.analysis
    visibility_data = socket.assigns.ai_visibility

    Task.start(fn ->
      case AIVisibility.generate_blog_topics(analysis, visibility_data) do
        {:ok, %{"topics" => topics}} ->
          send(pid, {:blog_topics_generated, topics})

        {:ok, topics} when is_list(topics) ->
          send(pid, {:blog_topics_generated, topics})

        {:error, reason} ->
          send(pid, {:blog_topics_error, reason})
      end
    end)

    {:noreply, assign(socket, :generating_blog, true)}
  end

  def handle_event("generate_blog_post", %{"topic-index" => topic_index}, socket) do
    topic_index = String.to_integer(topic_index)
    topics = socket.assigns.blog_topics
    analysis = socket.assigns.analysis

    if topic = Enum.at(topics, topic_index) do
      pid = self()

      Task.start(fn ->
        case AIVisibility.generate_blog_post(topic, analysis) do
          {:ok, blog_post} ->
            send(pid, {:blog_post_generated, blog_post})

          {:error, reason} ->
            send(pid, {:blog_post_error, reason})
        end
      end)

      {:noreply,
       socket
       |> assign(:generating_blog, true)
       |> assign(:selected_blog_topic, topic)
       |> assign(:generated_blog, nil)}
    else
      {:noreply, socket}
    end
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

  defp step_label(:ai_visibility), do: "AI Visibility"

  defp step_label(step) do
    step
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp step_completed?(step, current_step, steps) do
    step_index = Enum.find_index(steps, &(&1 == step))
    current_index = Enum.find_index(steps, &(&1 == current_step))
    step_index < current_index
  end

  defp has_assets?(headlines, images) do
    headlines != [] or images != []
  end

  defp update_url_params(socket, url, step) do
    params = URI.encode_query(%{"url" => url, "step" => Atom.to_string(step)})
    path = "/dashboard/new?" <> params

    push_patch(socket, to: path)
  end
end
