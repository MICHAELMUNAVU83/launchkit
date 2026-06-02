# LaunchKit

LaunchKit is a Phoenix LiveView app that turns a website URL into ad-ready marketing assets and an AI visibility report.

The app analyzes a website, builds a structured brand and messaging brief, then lets a user:

- generate short Google Ads headlines
- generate long headlines and descriptions within ad-style limits
- create AI-generated ad images in multiple aspect ratios
- score how visible the brand is in AI search experiences
- generate blog topic ideas and a blog post from the visibility analysis
- revisit saved websites and share an export view of the generated results

## What the project does

The current product flow is:

1. Enter a website URL on the home page.
2. LaunchKit discovers and scrapes relevant pages from that site.
3. The scraper synthesizes a brand brief covering positioning, messaging pillars, audience, calls to action, keywords, and visual direction.
4. From that analysis, the app generates headlines, descriptions, images, and an AI visibility report.
5. Results are stored in Postgres so they can be reopened later from the websites library.
6. Each saved website has an export/share view for copied text, downloaded images, and AI visibility output.

## Main routes

- `/` - landing page with URL input
- `/dashboard/new?url=...` - multi-step generation flow
- `/websites` - saved website analyses
- `/websites/:id` - share/export view for one analyzed website

## Feature summary

### Website analysis

- Scrapes and analyzes multiple pages from a site
- Extracts company summary, value props, target audience, keywords, CTAs, and visual themes
- Persists the analyzed website and its generated assets

### Google Ads assets

- Generates short headlines
- Generates long headlines
- Generates descriptions
- Keeps outputs grouped per website for later reuse

### Creative generation

- Generates ad images through OpenAI image generation
- Supports multiple aspect ratios
- Lets users download completed images from the export view

### AI visibility

- Produces an overall AI visibility score
- Breaks the score down into presence, completeness, recency, and authority
- Generates recommendations and quick wins
- Generates blog topics and a longer blog draft based on the analysis

## Stack

- Elixir and Phoenix 1.7
- Phoenix LiveView
- Ecto with PostgreSQL
- Req, Finch, and Floki for HTTP and scraping work
- Tailwind CSS and esbuild for frontend assets
- OpenAI for text and image generation

## Local development

### Prerequisites

- Elixir 1.14+
- Erlang/OTP compatible with your Elixir version
- PostgreSQL
- An OpenAI API key

### Setup

1. Install dependencies and prepare the database:

```bash
mix setup
```

2. Start the Phoenix server:

```bash
mix phx.server
```

3. Open <http://localhost:4000>.

### Configuration notes

There are two important setup details in the current repo state:

1. The repo includes test and production config, but no checked-in development repo config. Before running `mix setup`, make sure your local development config points `Launchkit.Repo` at a local Postgres database.
2. The OpenAI client reads `:openai_api_key` from app config via `Application.get_env(:launchkit, :openai_api_key)`. Exporting `OPENAI_API_KEY` by itself is not enough unless you also wire that env var into your config.

One workable local configuration looks like this:

```elixir
import Config

config :launchkit,
  openai_api_key: System.get_env("OPENAI_API_KEY")

config :launchkit, Launchkit.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "launchkit_dev",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
```

### Tests

```bash
mix test
```

## Persistence and exports

- Websites are stored in the database and can be revisited from `/websites`.
- Generated headlines, descriptions, images, and AI visibility data are stored per website.
- Export views support copying text outputs and downloading generated images.
- Share links are built for the export flow and currently use `https://launchkit.info` as the base URL.

## Production

Production database and endpoint runtime configuration live in `config/runtime.exs`. For general Phoenix deployment guidance, see the official deployment docs: <https://hexdocs.pm/phoenix/deployment.html>.

---

Built by [Michael Munavu](https://www.michaelmunavu.com)
