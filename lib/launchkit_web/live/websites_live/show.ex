defmodule LaunchkitWeb.WebsitesLive.Show do
  use LaunchkitWeb, :live_view

  alias Launchkit.Campaigns
  alias Launchkit.Assets
  alias LaunchkitWeb.ExportHelpers

  def mount(%{"id" => id}, _session, socket) do
    website = Campaigns.get_website!(id)
    ai_record = Campaigns.get_ai_visibility_by_website(website.id)

    headlines =
      Assets.list_headlines_by_website(website.id)
      |> Enum.map(&%{text: &1.text})

    long_headlines =
      Assets.list_long_headlines_by_website(website.id)
      |> Enum.map(&%{text: &1.text})

    descriptions =
      Assets.list_descriptions_by_website(website.id)
      |> Enum.map(&%{text: &1.text})

    images =
      Assets.list_images_by_website(website.id)
      |> Enum.map(fn img ->
        status =
          cond do
            is_atom(img.status) -> img.status
            img.status == "completed" -> :completed
            img.status == "pending" -> :pending
            img.status == "failed" -> :failed
            true -> :completed
          end

        %{
          url: img.url,
          prompt: img.prompt,
          aspect_ratio: img.aspect_ratio,
          status: status
        }
      end)

    ai_visibility = if ai_record, do: ai_record.visibility_data, else: nil
    blog_topics = if ai_record && ai_record.blog_topics, do: ai_record.blog_topics, else: []
    generated_blog = if ai_record, do: ai_record.generated_blog, else: nil
    share_url = ExportHelpers.get_share_url(website.url)

    {:ok,
     socket
     |> assign(:page_title, website.name || URI.parse(website.url || "").host || "Website")
     |> assign(:website, website)
     |> assign(:share_url, share_url)
     |> assign(:export_tab, :headlines)
     |> assign(:headlines, headlines)
     |> assign(:long_headlines, long_headlines)
     |> assign(:descriptions, descriptions)
     |> assign(:images, images)
     |> assign(:ai_visibility, ai_visibility)
     |> assign(:blog_topics, blog_topics)
     |> assign(:generated_blog, generated_blog)}
  end

  def handle_event("set_export_tab", %{"tab" => tab}, socket) do
    export_tab =
      case tab do
        "headlines" -> :headlines
        "images" -> :images
        "ai_visibility" -> :ai_visibility
        _ -> :headlines
      end

    {:noreply, assign(socket, :export_tab, export_tab)}
  end

  def handle_event("copy_text", %{"text" => _text}, socket) do
    {:noreply, put_flash(socket, :info, "Copied to clipboard!")}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-[#fafaf9] font-sans antialiased">
      <div class="max-w-4xl mx-auto px-4 sm:px-6 py-8">
        <div class="mb-6">
          <.link
            navigate={~p"/websites"}
            class="inline-flex items-center gap-2 text-sm text-gray-600 hover:text-gray-900 transition-colors"
          >
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
            </svg>
            Back to Websites
          </.link>
          <h1 class="text-xl font-semibold text-gray-900 mt-2 truncate">{@website.name || @website.url}</h1>
          <p class="text-sm text-gray-500 truncate">{@website.url}</p>
        </div>

        <.export_content
          share_url={@share_url}
          export_tab={@export_tab}
          headlines={@headlines}
          long_headlines={@long_headlines}
          descriptions={@descriptions}
          images={@images}
          blog_topics={@blog_topics}
          generated_blog={@generated_blog}
          ai_visibility={@ai_visibility}
          show_ai_visibility_link={false}
          dashboard_url={@share_url}
        />
      </div>
    </div>
    """
  end

  # Export content (mirrors dashboard assets_export_tab, uses ExportHelpers)
  defp export_content(assigns) do
    ~H"""
    <div>
      <div class="bg-white border border-gray-200 rounded-xl p-6 mb-6 shadow-sm">
        <h2 class="text-lg font-semibold text-gray-900 mb-3">Share This Page</h2>
        <div class="flex flex-wrap items-center gap-3">
          <input
            type="text"
            readonly
            value={@share_url}
            class="flex-1 min-w-0 px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-lg text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-gray-300"
          />
          <button
            id="copy-share-url"
            phx-click="copy_text"
            phx-value-text={@share_url}
            phx-hook="CopyToClipboard"
            class="px-4 py-2.5 bg-gray-900 text-white rounded-lg text-sm font-medium hover:bg-gray-800 transition-colors flex items-center gap-2"
            title="Copy share link"
          >
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15.666 3.888A2.25 2.25 0 0013.5 2.25h-3c-1.03 0-1.9.693-2.166 1.638m7.332 0c.055.194.084.4.084.612v0a.75.75 0 01-.75.75H9a.75.75 0 01-.75-.75v0c0-.212.03-.418.084-.612m7.332 0c.646.049 1.288.11 1.927.184 1.1.128 1.907 1.077 1.907 2.185V19.5a2.25 2.25 0 01-2.25 2.25H6.75A2.25 2.25 0 014.5 19.5V6.257c0-1.108.806-2.057 1.907-2.185a48.208 48.208 0 011.927-.184" />
            </svg>
            Copy Link
          </button>
        </div>
      </div>

      <div class="flex justify-center mb-6 overflow-x-auto">
        <div class="inline-flex bg-gray-100 rounded-lg p-1.5 gap-1 flex-shrink-0">
          <button phx-click="set_export_tab" phx-value-tab="headlines" class={["px-5 py-2.5 rounded-md text-sm font-medium transition-all", @export_tab == :headlines && "bg-white text-gray-900 shadow-sm", @export_tab != :headlines && "text-gray-600 hover:text-gray-900"]}>
            Headlines
          </button>
          <button phx-click="set_export_tab" phx-value-tab="images" class={["px-5 py-2.5 rounded-md text-sm font-medium transition-all", @export_tab == :images && "bg-white text-gray-900 shadow-sm", @export_tab != :images && "text-gray-600 hover:text-gray-900"]}>
            Images
          </button>
          <button phx-click="set_export_tab" phx-value-tab="ai_visibility" class={["px-5 py-2.5 rounded-md text-sm font-medium transition-all", @export_tab == :ai_visibility && "bg-white text-gray-900 shadow-sm", @export_tab != :ai_visibility && "text-gray-600 hover:text-gray-900"]}>
            AI Visibility
          </button>
        </div>
      </div>

      <%= case @export_tab do %>
        <% :headlines -> %>
          <div class="bg-white border border-gray-200 rounded-xl p-6 shadow-sm">
            <h2 class="text-lg font-semibold text-gray-900 mb-6">Headlines & Descriptions</h2>
            <%= if @headlines != [] do %>
              <div class="mb-6">
                <h3 class="text-sm font-medium text-gray-700 mb-3">Short Headlines</h3>
                <div class="space-y-2">
                  <%= for {headline, idx} <- Enum.with_index(@headlines) do %>
                    <div class="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
                      <span class="text-xs font-medium text-gray-400 w-6 flex-shrink-0">{idx + 1}</span>
                      <span class="flex-1 text-sm text-gray-900">{headline.text}</span>
                      <button id={"copy-headline-#{idx}"} phx-click="copy_text" phx-value-text={headline.text} phx-hook="CopyToClipboard" class="px-3 py-1.5 text-xs font-medium text-gray-700 bg-white border border-gray-200 rounded hover:bg-gray-50 flex items-center gap-1.5" title="Copy">Copy</button>
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
                    <div class="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
                      <span class="text-xs font-medium text-gray-400 w-6 flex-shrink-0">{idx + 1}</span>
                      <span class="flex-1 text-sm text-gray-900">{headline.text}</span>
                      <button id={"copy-long-headline-#{idx}"} phx-click="copy_text" phx-value-text={headline.text} phx-hook="CopyToClipboard" class="px-3 py-1.5 text-xs font-medium text-gray-700 bg-white border border-gray-200 rounded hover:bg-gray-50" title="Copy">Copy</button>
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
                    <div class="flex items-start gap-3 p-3 bg-gray-50 rounded-lg">
                      <span class="text-xs font-medium text-gray-400 w-6 flex-shrink-0 pt-1">{idx + 1}</span>
                      <p class="flex-1 text-sm text-gray-900">{desc.text}</p>
                      <button id={"copy-description-#{idx}"} phx-click="copy_text" phx-value-text={desc.text} phx-hook="CopyToClipboard" class="px-3 py-1.5 text-xs font-medium text-gray-700 bg-white border border-gray-200 rounded hover:bg-gray-50 flex-shrink-0" title="Copy">Copy</button>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
            <%= if @headlines == [] && @long_headlines == [] && @descriptions == [] do %>
              <p class="text-sm text-gray-500">No headlines or descriptions for this website.</p>
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
                        <div class="absolute inset-0 flex items-center justify-center bg-gray-100 text-gray-400 text-sm">Loading...</div>
                      <% end %>
                    </div>
                    <div class="p-3 bg-white flex items-center justify-between">
                      <span class="text-xs text-gray-500">{image.aspect_ratio || "N/A"}</span>
                      <%= if image.status == :completed do %>
                        <a href={image.url} download class="px-3 py-1.5 bg-gray-900 text-white text-xs font-medium rounded hover:bg-gray-800">Download</a>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            <% else %>
              <p class="text-sm text-gray-500">No images for this website.</p>
            <% end %>
          </div>
        <% :ai_visibility -> %>
          <div class="space-y-6">
            <%= if @ai_visibility != nil do %>
              <div class="bg-white border border-gray-200 rounded-xl p-6 shadow-sm">
                <h3 class="text-base font-semibold text-gray-900 mb-4">Score & Recommendations</h3>
                <% overall = Map.get(@ai_visibility, "overall_score") || @ai_visibility[:overall_score] || @ai_visibility.overall_score %>
                <div class="text-center mb-6">
                  <div class="inline-flex items-center justify-center w-24 h-24 rounded-full border-6 border-gray-100 mb-3" style={"border-color: #{ExportHelpers.get_score_color(overall)}"}>
                    <div class="text-3xl font-bold" style={"color: #{ExportHelpers.get_score_color(overall)}"}>{overall}</div>
                  </div>
                  <p class="text-sm text-gray-600">{ExportHelpers.get_score_label(overall)}</p>
                </div>
                <% scores = Map.get(@ai_visibility, "scores") || @ai_visibility[:scores] || @ai_visibility.scores %>
                <div class="grid grid-cols-2 md:grid-cols-4 gap-3 mb-6">
                  <div class="text-center p-3 bg-gray-50 rounded-lg"><div class="text-xl font-semibold text-gray-900">{Map.get(scores, "presence") || scores[:presence] || scores.presence}</div><div class="text-xs text-gray-600">Presence</div></div>
                  <div class="text-center p-3 bg-gray-50 rounded-lg"><div class="text-xl font-semibold text-gray-900">{Map.get(scores, "completeness") || scores[:completeness] || scores.completeness}</div><div class="text-xs text-gray-600">Completeness</div></div>
                  <div class="text-center p-3 bg-gray-50 rounded-lg"><div class="text-xl font-semibold text-gray-900">{Map.get(scores, "recency") || scores[:recency] || scores.recency}</div><div class="text-xs text-gray-600">Recency</div></div>
                  <div class="text-center p-3 bg-gray-50 rounded-lg"><div class="text-xl font-semibold text-gray-900">{Map.get(scores, "authority") || scores[:authority] || scores.authority}</div><div class="text-xs text-gray-600">Authority</div></div>
                </div>
                <%= if recommendations = Map.get(@ai_visibility, "recommendations") || @ai_visibility[:recommendations] || @ai_visibility.recommendations do %>
                  <%= if priority = Map.get(recommendations, "priority_recommendations") || Map.get(recommendations, :priority_recommendations) do %>
                    <h4 class="font-medium text-gray-900 mb-2">Priority Recommendations</h4>
                    <div class="space-y-3 mb-4">
                      <%= for rec <- priority do %>
                        <div class="p-3 bg-gray-50 rounded-lg border border-gray-200">
                          <div class="flex items-start justify-between gap-2 mb-1">
                            <h5 class="font-medium text-gray-900">{rec["title"] || rec[:title]}</h5>
                            <span class={"px-2 py-0.5 text-xs font-medium rounded #{ExportHelpers.get_impact_class(rec["impact"] || rec[:impact])}"}>{rec["impact"] || rec[:impact]} impact</span>
                          </div>
                          <p class="text-sm text-gray-600">{rec["description"] || rec[:description]}</p>
                        </div>
                      <% end %>
                    </div>
                  <% end %>
                  <%= if quick_wins = Map.get(recommendations, "quick_wins") || Map.get(recommendations, :quick_wins) do %>
                    <h4 class="font-medium text-gray-900 mb-2">Quick Wins</h4>
                    <ul class="space-y-1.5 text-sm text-gray-600">
                      <%= for win <- quick_wins do %>
                        <li class="flex items-start gap-2">
                          <svg class="w-5 h-5 text-emerald-600 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
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
                    <% topic_title = topic["title"] || topic[:title] || topic["topic"] || topic[:topic] || "Untitled Topic" %>
                    <% topic_copy_text = ExportHelpers.export_blog_topic_copy_text(topic) %>
                    <div class="flex items-start gap-3 p-3 bg-gray-50 rounded-lg">
                      <div class="flex-1 min-w-0">
                        <h4 class="font-medium text-gray-900">{topic_title}</h4>
                        <%= if desc = topic["description"] || topic[:description] do %><p class="text-sm text-gray-600 mt-1">{desc}</p><% end %>
                        <%= if why = topic["why_it_helps"] || topic[:why_it_helps] || topic["reason"] || topic[:reason] do %><p class="text-xs text-gray-500 mt-1">{why}</p><% end %>
                      </div>
                      <button id={"copy-blog-topic-#{idx}"} phx-click="copy_text" phx-value-text={topic_copy_text} phx-hook="CopyToClipboard" class="px-3 py-1.5 text-xs font-medium text-gray-700 bg-white border border-gray-200 rounded hover:bg-gray-50 flex-shrink-0" title="Copy topic">Copy</button>
                    </div>
                  <% end %>
                </div>
              <% end %>
              <%= if @generated_blog != nil do %>
                <div class="pt-4 border-t border-gray-200">
                  <h4 class="font-medium text-gray-900 mb-2">Generated Blog Post</h4>
                  <div class="p-4 bg-gray-50 rounded-lg border border-gray-200">
                    <div class="flex items-start justify-between gap-3 mb-3">
                      <h5 class="font-semibold text-gray-900">{@generated_blog["title"] || @generated_blog[:title] || "Blog Post"}</h5>
                      <button id="copy-blog-content" phx-click="copy_text" phx-value-text={@generated_blog["content"] || @generated_blog[:content] || ""} phx-hook="CopyToClipboard" class="px-3 py-1.5 text-xs font-medium text-gray-700 bg-white border border-gray-200 rounded hover:bg-gray-50 flex-shrink-0" title="Copy full post">Copy Post</button>
                    </div>
                    <div class="prose prose-sm max-w-none text-gray-700 text-sm line-clamp-4">{ExportHelpers.render_markdown(@generated_blog["content"] || @generated_blog[:content] || "")}</div>
                    <%= if keywords = @generated_blog["keywords"] || @generated_blog[:keywords] do %><p class="text-xs text-gray-500 mt-2"><span class="font-medium">Keywords:</span> {Enum.join(keywords, ", ")}</p><% end %>
                    <%= if meta = @generated_blog["meta_description"] || @generated_blog[:meta_description] do %><p class="text-xs text-gray-500 mt-1"><span class="font-medium">Meta:</span> {meta}</p><% end %>
                  </div>
                </div>
              <% end %>
              <%= if @blog_topics == [] && @generated_blog == nil do %>
                <p class="text-sm text-gray-500">No blog topics or generated post for this website.</p>
              <% end %>
            </div>

            <%= if @dashboard_url do %>
              <div class="mt-4">
                <a href={@dashboard_url} target="_blank" rel="noopener noreferrer" class="text-sm font-medium text-emerald-600 hover:text-emerald-700">
                  Open in dashboard →
                </a>
              </div>
            <% end %>
          </div>
      <% end %>
    </div>
    """
  end
end
