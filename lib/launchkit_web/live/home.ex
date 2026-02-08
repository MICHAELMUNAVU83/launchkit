defmodule LaunchkitWeb.HomeLive.Index do
  use LaunchkitWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Google Ads Headlines, Copy & AI Visibility")}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-[#fafaf9] text-[#1a1a1a] font-sans antialiased">
      <!-- Subtle grid background -->
      <div class="fixed inset-0 bg-[linear-gradient(to_right,#e5e5e5_1px,transparent_1px),linear-gradient(to_bottom,#e5e5e5_1px,transparent_1px)] bg-[size:4rem_4rem] opacity-40 pointer-events-none">
      </div>
      
    <!-- Navigation -->
      <nav class="relative z-10 flex items-center justify-between px-4 sm:px-6 lg:px-8 py-6 max-w-7xl mx-auto">
        <div class="flex items-center gap-2">
          <span class="text-xl font-semibold tracking-tight">
            <img src="/images/small.png" alt="LaunchKit" class="w-10 h-10" />
          </span>
        </div>
      </nav>
      
    <!-- Hero Section -->
      <main class="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-16 sm:pt-24 pb-24 sm:pb-32">
        <div class="max-w-3xl">
          <!-- Badge -->
          <div class="inline-flex items-center gap-2 px-3 py-1.5 bg-white border border-[#e5e5e5] rounded-full text-xs text-[#525252] mb-8 shadow-sm">
            <span class="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-pulse"></span> Powered by AI
          </div>
          
    <!-- Headline -->
          <h1 class="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold tracking-tight mb-6 leading-tight">
            <span class="block text-[#1a1a1a]">Google Ads headlines & copy.</span>
            <span class="block mt-1 text-[#525252]">Generated assets. Your AI visibility score.</span>
          </h1>
          
    <!-- Subheadline -->
          <p class="text-base sm:text-lg md:text-xl text-[#525252] leading-relaxed max-w-xl mb-8 sm:mb-10">
            Drop your website URL. Get headlines and copy for Google Ads, AI-generated ad images, and a score showing how well you show up in AI search—so you can run better campaigns and improve visibility.
          </p>
          
    <!-- CTA -->
          <div class="flex flex-col sm:flex-row gap-4">
            <form phx-submit="analyze" class="flex-1 max-w-md">
              <div class="flex items-center gap-2 bg-white border border-[#e5e5e5] rounded-full p-1.5 shadow-sm focus-within:border-[#a3a3a3] focus-within:shadow-md transition-all">
                <input
                  type="url"
                  name="url"
                  placeholder="https://yourwebsite.com"
                  class="flex-1 bg-transparent px-4 py-2.5 text-sm outline-none border-none focus:outline-none focus:ring-0 focus:ring-offset-0 placeholder:text-[#a3a3a3]"
                  required
                />
                <button
                  type="submit"
                  class="bg-[#0d0d0d] text-white text-sm font-medium px-6 py-2.5 rounded-full hover:bg-[#262626] transition-colors whitespace-nowrap"
                >
                  Get My Headlines & Score
                </button>
              </div>
            </form>
          </div>
          
    <!-- Social Proof -->
          <div class="flex flex-wrap items-center justify-center sm:justify-start gap-4 sm:gap-6 mt-12 pt-12 border-t border-[#e5e5e5]">
            <div>
              <div class="text-2xl font-semibold">2,400+</div>
              <div class="text-sm text-[#525252]">products launched</div>
            </div>
            <div class="w-px h-10 bg-[#e5e5e5]"></div>
            <div>
              <div class="text-2xl font-semibold">89%</div>
              <div class="text-sm text-[#525252]">time saved</div>
            </div>
            <div class="w-px h-10 bg-[#e5e5e5]"></div>
            <div>
              <div class="text-2xl font-semibold">4.9/5</div>
              <div class="text-sm text-[#525252]">user rating</div>
            </div>
          </div>
        </div>
        
    <!-- Preview Card -->
        <div class="absolute right-8 top-32 hidden xl:block w-[420px]">
          <div class="bg-white border border-[#e5e5e5] rounded-2xl shadow-xl p-6 transform rotate-1 hover:rotate-0 transition-transform duration-300">
            <div class="flex items-center gap-3 mb-6">
              <img src="/images/small.png" alt="LaunchKit" class="w-10 h-10 rounded-xl object-cover" />
              <div>
                <div class="font-medium text-sm">Your Product</div>
                <div class="text-xs text-[#a3a3a3]">yourproduct.com</div>
              </div>
              <div class="ml-auto px-2 py-1 bg-emerald-50 text-emerald-600 text-xs font-medium rounded-full">
                Ready
              </div>
            </div>

            <div class="space-y-3">
              <div class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                Google Ads Headlines
              </div>
              <div class="flex flex-wrap gap-2">
                <span class="px-3 py-1.5 bg-[#fafaf9] border border-[#e5e5e5] rounded-lg text-xs">
                  Launch Faster Today
                </span>
                <span class="px-3 py-1.5 bg-[#fafaf9] border border-[#e5e5e5] rounded-lg text-xs">
                  Get Started Now
                </span>
                <span class="px-3 py-1.5 bg-[#fafaf9] border border-[#e5e5e5] rounded-lg text-xs">
                  Built for You
                </span>
              </div>
            </div>

            <div class="mt-4 space-y-3">
              <div class="text-xs font-medium text-[#a3a3a3] uppercase tracking-wider">
                Generated Ad Images
              </div>
              <div class="grid grid-cols-3 gap-2">
                <div class="aspect-square bg-gradient-to-br from-slate-100 to-slate-200 rounded-lg">
                </div>
                <div class="aspect-square bg-gradient-to-br from-blue-100 to-blue-200 rounded-lg">
                </div>
                <div class="aspect-square bg-gradient-to-br from-amber-100 to-amber-200 rounded-lg">
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
      
    <!-- Features Section -->
      <section id="features" class="relative z-10 bg-white border-y border-[#e5e5e5] py-16 sm:py-24">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="text-center mb-16">
            <h2 class="text-3xl md:text-4xl font-semibold tracking-tight mb-4">
              Everything for better Google Ads
            </h2>
            <p class="text-[#525252] max-w-lg mx-auto">
              Get headlines and copy for Google Ads, generated ad images, and your AI visibility score—all from your website URL. Copy what you need and improve how you show up in AI search.
            </p>
          </div>

          <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-6 sm:gap-8">
            <!-- Feature 1: Headlines & Copy -->
            <div class="group p-6 sm:p-8 rounded-2xl border border-[#e5e5e5] hover:border-[#a3a3a3] hover:shadow-lg transition-all">
              <div class="w-12 h-12 bg-[#fafaf9] rounded-xl flex items-center justify-center mb-6 group-hover:bg-[#0d0d0d] transition-colors">
                <svg
                  class="w-6 h-6 text-[#525252] group-hover:text-white transition-colors"
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
              </div>
              <h3 class="text-lg font-semibold mb-2">Google Ads Headlines & Copy</h3>
              <p class="text-sm text-[#525252] leading-relaxed">
                Short and long headlines plus descriptions, optimized for Google Ads character limits and ready to copy into your campaigns.
              </p>
            </div>
            
    <!-- Feature 2: Images -->
            <div class="group p-6 sm:p-8 rounded-2xl border border-[#e5e5e5] hover:border-[#a3a3a3] hover:shadow-lg transition-all">
              <div class="w-12 h-12 bg-[#fafaf9] rounded-xl flex items-center justify-center mb-6 group-hover:bg-[#0d0d0d] transition-colors">
                <svg
                  class="w-6 h-6 text-[#525252] group-hover:text-white transition-colors"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  stroke-width="1.5"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 001.5-1.5V6a1.5 1.5 0 00-1.5-1.5H3.75A1.5 1.5 0 002.25 6v12a1.5 1.5 0 001.5 1.5zm10.5-11.25h.008v.008h-.008V8.25zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0z"
                  />
                </svg>
              </div>
              <h3 class="text-lg font-semibold mb-2">Generated Ad Images</h3>
              <p class="text-sm text-[#525252] leading-relaxed">
                AI-generated ad images in landscape, square, and portrait. On-brand and ready to download for your campaigns.
              </p>
            </div>
            
    <!-- Feature 3: AI Visibility -->
            <div class="group p-6 sm:p-8 rounded-2xl border border-[#e5e5e5] hover:border-[#a3a3a3] hover:shadow-lg transition-all sm:col-span-2 lg:col-span-1">
              <div class="w-12 h-12 bg-[#fafaf9] rounded-xl flex items-center justify-center mb-6 group-hover:bg-[#0d0d0d] transition-colors">
                <svg
                  class="w-6 h-6 text-[#525252] group-hover:text-white transition-colors"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  stroke-width="1.5"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09zM18.259 8.715L18 9.75l-.259-1.035a3.375 3.375 0 00-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 002.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 002.456 2.456L21.75 6l-1.035.259a3.375 3.375 0 00-2.456 2.456zM16.894 20.567L16.5 21.75l-.394-1.183a2.25 2.25 0 00-1.423-1.423L13.5 18.75l1.183-.394a2.25 2.25 0 001.423-1.423l.394-1.183.394 1.183a2.25 2.25 0 001.423 1.423l1.183.394-1.183.394a2.25 2.25 0 00-1.423 1.423z"
                  />
                </svg>
              </div>
              <h3 class="text-lg font-semibold mb-2">AI Visibility Score</h3>
              <p class="text-sm text-[#525252] leading-relaxed">
                See how well you show up in AI search. Get a score, actionable recommendations, and blog ideas to improve visibility.
              </p>
            </div>
          </div>
        </div>
      </section>
      
    <!-- How it works -->
      <section class="relative z-10 py-16 sm:py-24">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="text-center mb-16">
            <h2 class="text-3xl md:text-4xl font-semibold tracking-tight mb-4">
              Three steps to better campaigns
            </h2>
          </div>

          <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-10 sm:gap-12">
            <div class="text-center">
              <div class="w-12 h-12 bg-[#0d0d0d] text-white rounded-full flex items-center justify-center text-lg font-semibold mx-auto mb-6">
                1
              </div>
              <h3 class="font-semibold mb-2">Paste your URL</h3>
              <p class="text-sm text-[#525252]">
                We analyze your website's content, brand voice, and value propositions.
              </p>
            </div>
            <div class="text-center">
              <div class="w-12 h-12 bg-[#0d0d0d] text-white rounded-full flex items-center justify-center text-lg font-semibold mx-auto mb-6">
                2
              </div>
              <h3 class="font-semibold mb-2">Review & generate</h3>
              <p class="text-sm text-[#525252]">
                Review your brand analysis, generate Google Ads headlines and copy, ad images, and get your AI visibility score.
              </p>
            </div>
            <div class="text-center">
              <div class="w-12 h-12 bg-[#0d0d0d] text-white rounded-full flex items-center justify-center text-lg font-semibold mx-auto mb-6">
                3
              </div>
              <h3 class="font-semibold mb-2">Copy & export</h3>
              <p class="text-sm text-[#525252]">
                Copy headlines and descriptions, download images, and use your AI visibility report to improve.
              </p>
            </div>
          </div>
        </div>
      </section>
      
    <!-- Footer -->
      <footer class="relative z-10 border-t border-[#e5e5e5] py-10 sm:py-12">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center text-sm text-[#525252]">
          Built by Michael Munavu (<a href="https://www.michaelmunavu.com" target="_blank" rel="noopener noreferrer" class="text-blue-600 underline hover:text-blue-800 transition-colors">www.michaelmunavu.com</a>)
        </div>
      </footer>
    </div>
    """
  end

  def handle_event("analyze", %{"url" => url}, socket) do
    # TODO: Kick off website analysis
    {:noreply, push_navigate(socket, to: ~p"/dashboard/new?url=#{url}")}
  end
end
