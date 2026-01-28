defmodule LaunchkitWeb.HomeLive.Index do
  use LaunchkitWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-[#fafaf9] text-[#1a1a1a] font-['Outfit',sans-serif]">
      <!-- Subtle grid background -->
      <div class="fixed inset-0 bg-[linear-gradient(to_right,#e5e5e5_1px,transparent_1px),linear-gradient(to_bottom,#e5e5e5_1px,transparent_1px)] bg-[size:4rem_4rem] opacity-40 pointer-events-none">
      </div>
      
    <!-- Navigation -->
      <nav class="relative z-10 flex items-center justify-between px-8 py-6 max-w-7xl mx-auto">
        <div class="flex items-center gap-2">
          <span class="text-xl font-semibold tracking-tight">
            <img src="/images/small.png" alt="LaunchKit" class="w-10 h-10" />
          </span>
        </div>

        <div class="hidden md:flex items-center gap-8 text-sm text-[#525252]">
          <a href="#features" class="hover:text-[#0d0d0d] transition-colors">Features</a>
          <a href="#pricing" class="hover:text-[#0d0d0d] transition-colors">Pricing</a>
          <a href="#docs" class="hover:text-[#0d0d0d] transition-colors">Docs</a>
        </div>

        <div class="flex items-center gap-3">
          <.link
            navigate={~p"/login"}
            class="text-sm text-[#525252] hover:text-[#0d0d0d] transition-colors px-4 py-2"
          >
            Log in
          </.link>
          <.link
            navigate={~p"/register"}
            class="text-sm bg-[#0d0d0d] text-white px-5 py-2.5 rounded-full hover:bg-[#262626] transition-colors"
          >
            Get Started
          </.link>
        </div>
      </nav>
      
    <!-- Hero Section -->
      <main class="relative z-10 max-w-7xl mx-auto px-8 pt-24 pb-32">
        <div class="max-w-3xl">
          <!-- Badge -->
          <div class="inline-flex items-center gap-2 px-3 py-1.5 bg-white border border-[#e5e5e5] rounded-full text-xs text-[#525252] mb-8 shadow-sm">
            <span class="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-pulse"></span> Powered by AI
          </div>
          
    <!-- Headline -->
          <h1 class="text-4xl md:text-5xl lg:text-6xl font-bold tracking-tight mb-6 leading-none">
            <span class="block text-[#1a1a1a]">You just built your app.</span>
            <span class="block mt-1 text-[#525252]">Let's help you launch it.</span>
          </h1>
          
    <!-- Subheadline -->
          <p class="text-lg md:text-xl text-[#525252] leading-relaxed max-w-xl mb-10">
            Drop your website URL. Get ad copy, images, landing page fixes, and everything else you need to get your product in front of customers.
          </p>
          
    <!-- CTA -->
          <div class="flex flex-col sm:flex-row gap-4">
            <form phx-submit="analyze" class="flex-1 max-w-md">
              <div class="flex items-center gap-2 bg-white border border-[#e5e5e5] rounded-full p-1.5 shadow-sm focus-within:border-[#a3a3a3] focus-within:shadow-md transition-all">
                <input
                  type="url"
                  name="url"
                  placeholder="https://yourwebsite.com"
                  class="flex-1 bg-transparent px-4 py-2.5 text-sm outline-none border-none outline:border-none placeholder:text-[#a3a3a3]"
                  required
                />
                <button
                  type="submit"
                  class="bg-[#0d0d0d] text-white text-sm font-medium px-6 py-2.5 rounded-full hover:bg-[#262626] transition-colors whitespace-nowrap"
                >
                  Launch My Product
                </button>
              </div>
            </form>
          </div>
          
    <!-- Social Proof -->
          <div class="flex items-center gap-6 mt-12 pt-12 border-t border-[#e5e5e5]">
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
              <div class="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl"></div>
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
                Ad Headlines
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
                Generated Assets
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
      <section id="features" class="relative z-10 bg-white border-y border-[#e5e5e5] py-24">
        <div class="max-w-7xl mx-auto px-8">
          <div class="text-center mb-16">
            <h2 class="text-3xl md:text-4xl font-semibold tracking-tight mb-4">
              Everything you need
            </h2>
            <p class="text-[#525252] max-w-lg mx-auto">
              Everything you need to launch your product. Generate ads, optimize your landing page, and get in front of customers—no design skills required.
            </p>
          </div>

          <div class="grid md:grid-cols-3 gap-8">
            <!-- Feature 1: Headlines -->
            <div class="group p-8 rounded-2xl border border-[#e5e5e5] hover:border-[#a3a3a3] hover:shadow-lg transition-all">
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
              <h3 class="text-lg font-semibold mb-2">Smart Headlines</h3>
              <p class="text-sm text-[#525252] leading-relaxed">
                15 short headlines, 5 long headlines—all optimized for character limits and designed to convert.
              </p>
            </div>
            
    <!-- Feature 2: Images -->
            <div class="group p-8 rounded-2xl border border-[#e5e5e5] hover:border-[#a3a3a3] hover:shadow-lg transition-all">
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
              <h3 class="text-lg font-semibold mb-2">AI Images</h3>
              <p class="text-sm text-[#525252] leading-relaxed">
                Generate on-brand images in every required size. Landscape, square, portrait—all ready to use.
              </p>
            </div>
            
    <!-- Feature 3: AI Visibility -->
            <div class="group p-8 rounded-2xl border border-[#e5e5e5] hover:border-[#a3a3a3] hover:shadow-lg transition-all">
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
              <h3 class="text-lg font-semibold mb-2">AI Visibility</h3>
              <p class="text-sm text-[#525252] leading-relaxed">
                Check how well your product appears in AI search results. Get recommendations and generate blog posts to improve visibility.
              </p>
            </div>
          </div>
        </div>
      </section>
      
    <!-- How it works -->
      <section class="relative z-10 py-24">
        <div class="max-w-7xl mx-auto px-8">
          <div class="text-center mb-16">
            <h2 class="text-3xl md:text-4xl font-semibold tracking-tight mb-4">
              Launch in three steps
            </h2>
          </div>

          <div class="grid md:grid-cols-3 gap-12">
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
              <h3 class="font-semibold mb-2">Review & refine</h3>
              <p class="text-sm text-[#525252]">
                Review your brand analysis, refine your assets, and check your AI search visibility.
              </p>
            </div>
            <div class="text-center">
              <div class="w-12 h-12 bg-[#0d0d0d] text-white rounded-full flex items-center justify-center text-lg font-semibold mx-auto mb-6">
                3
              </div>
              <h3 class="font-semibold mb-2">Launch & grow</h3>
              <p class="text-sm text-[#525252]">
                Download your assets, copy the code, and start getting customers.
              </p>
            </div>
          </div>
        </div>
      </section>
      
    <!-- CTA Section -->
      <section class="relative z-10 py-24">
        <div class="max-w-3xl mx-auto px-8 text-center">
          <h2 class="text-3xl md:text-4xl font-semibold tracking-tight mb-4">
            Ready to launch your product?
          </h2>
          <p class="text-[#525252] mb-8">
            Get everything you need to start acquiring customers. No credit card required.
          </p>
          <.link
            navigate={~p"/register"}
            class="inline-flex items-center gap-2 bg-[#0d0d0d] text-white px-8 py-4 rounded-full text-lg font-medium hover:bg-[#262626] transition-colors"
          >
            Get Started Free
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
          </.link>
        </div>
      </section>
      
    <!-- Footer -->
      <footer class="relative z-10 border-t border-[#e5e5e5] py-12">
        <div class="max-w-7xl mx-auto px-8 flex flex-col md:flex-row items-center justify-between gap-6">
          <div class="flex items-center gap-2">
            <div class="w-6 h-6 bg-[#0d0d0d] rounded-md flex items-center justify-center">
              <svg
                class="w-3 h-3 text-white"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2.5"
              >
                <path d="M5 12l5 5L20 7" stroke-linecap="round" stroke-linejoin="round" />
              </svg>
            </div>
            <span class="text-sm font-medium">LaunchKit</span>
          </div>
          <div class="flex items-center gap-6 text-sm text-[#525252]">
            <a href="#" class="hover:text-[#0d0d0d] transition-colors">Privacy</a>
            <a href="#" class="hover:text-[#0d0d0d] transition-colors">Terms</a>
            <a href="#" class="hover:text-[#0d0d0d] transition-colors">Twitter</a>
          </div>
          <div class="text-sm text-[#a3a3a3]">
            © 2026 LaunchKit. Built with Elixir.
          </div>
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
