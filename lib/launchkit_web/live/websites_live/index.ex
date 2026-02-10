defmodule LaunchkitWeb.WebsitesLive.Index do
  use LaunchkitWeb, :live_view

  alias Launchkit.Campaigns

  def mount(_params, _session, socket) do
    websites = Campaigns.list_websites()

    {:ok,
     socket
     |> assign(:page_title, "Websites")
     |> assign(:websites, websites)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-[#fafaf9] font-sans antialiased">
      <div class="max-w-4xl mx-auto px-4 sm:px-6 py-8">
        <div class="mb-8">
          <.link
            navigate={~p"/"}
            class="inline-flex items-center gap-2 text-sm text-gray-600 hover:text-gray-900 transition-colors mb-4"
          >
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
            </svg>
            Home
          </.link>
          <h1 class="text-2xl font-semibold text-gray-900">Websites</h1>
          <p class="text-gray-500 mt-1">Click a website to view its headlines, images, and AI visibility results.</p>
        </div>

        <%= if @websites == [] do %>
          <div class="bg-white border border-gray-200 rounded-xl p-12 text-center text-gray-500">
            <p>No websites yet.</p>
            <p class="mt-2 text-sm">Enter a URL on the home page to analyze and generate assets.</p>
            <.link navigate={~p"/"} class="inline-block mt-4 text-sm font-medium text-[#0d0d0d] hover:underline">
              Go to home →
            </.link>
          </div>
        <% else %>
          <ul class="space-y-3">
            <%= for website <- @websites do %>
              <li>
                <.link
                  navigate={~p"/websites/#{website.id}"}
                  class="block bg-white border border-gray-200 rounded-xl p-4 sm:p-5 hover:border-gray-300 hover:shadow-md transition-all group"
                >
                  <div class="flex items-center justify-between gap-4">
                    <div class="min-w-0 flex-1">
                      <div class="font-medium text-gray-900 truncate">{website.name || "Untitled"}</div>
                      <div class="text-sm text-gray-500 truncate mt-0.5">{website.url}</div>
                    </div>
                    <span class="flex-shrink-0 text-gray-400 group-hover:text-gray-600 transition-colors">
                      <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
                      </svg>
                    </span>
                  </div>
                </.link>
              </li>
            <% end %>
          </ul>
        <% end %>
      </div>
    </div>
    """
  end
end
