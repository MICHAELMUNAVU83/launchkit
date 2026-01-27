defmodule Launchkit.OpenAI do
  @moduledoc """
  OpenAI API client for LaunchKit.

  Configure via environment variable:
    OPENAI_API_KEY=sk-...

  Or in config.exs:
    config :launchkit, Launchkit.OpenAI,
      api_key: "sk-..."
  """

  require Logger

  @api_url "https://api.openai.com/v1/chat/completions"
  @default_model "gpt-4o"

  @doc """
  Send a request to OpenAI.

  ## Parameters
    - `context` - System prompt
    - `prompt` - User prompt
    - `opts` - Optional overrides:
      - `:model` - Model to use (default: gpt-4o)
      - `:temperature` - Temperature (default: 0.5)
      - `:max_tokens` - Max tokens (default: 4096)

  ## Returns
    `{:ok, response_text}` or `{:error, reason}`
  """
  def send_request_to_openai(context, prompt, opts \\ []) do
    api_key = get_api_key()

    if is_nil(api_key) or api_key == "" do
      Logger.error("Missing OPENAI_API_KEY")
      {:error, :missing_openai_api_key}
    else
      model = Keyword.get(opts, :model, @default_model)
      temperature = Keyword.get(opts, :temperature, 0.5)
      max_tokens = Keyword.get(opts, :max_tokens, 4096)

      body = %{
        "model" => model,
        "messages" => [
          %{"role" => "system", "content" => context},
          %{"role" => "user", "content" => prompt}
        ],
        "temperature" => temperature,
        "max_tokens" => max_tokens
      }

      headers = [
        {"Content-Type", "application/json"},
        {"Authorization", "Bearer #{api_key}"}
      ]

      options = [
        headers: headers,
        json: body,
        retry: :transient,
        max_retries: 5,
        receive_timeout: 120_000
      ]

      case Req.post(@api_url, options) do
        {:ok, %{status: 200, body: %{"choices" => [%{"message" => %{"content" => content}} | _]}}} ->
          {:ok, content}

        {:ok, %{status: 200, body: %{"choices" => []}}} ->
          Logger.warning("OpenAI returned empty choices")
          {:error, :empty_response}

        {:ok, %{status: 429, body: body}} ->
          Logger.warning("OpenAI rate limited: #{inspect(body)}")
          {:error, :rate_limited}

        {:ok, %{status: status, body: body}} ->
          Logger.error("OpenAI error (#{status}): #{inspect(body)}")
          {:error, "OpenAI API error: #{status}"}

        {:error, reason} ->
          Logger.error("OpenAI request failed: #{inspect(reason)}")
          {:error, "Request failed: #{inspect(reason)}"}
      end
    end
  end

  # Convenience alias
  def chat(context, prompt, opts \\ []), do: send_request_to_openai(context, prompt, opts)

  def get_api_key do
    Application.get_env(:launchkit, :openai_api_key)
  end
end
