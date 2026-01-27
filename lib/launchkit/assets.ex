defmodule Launchkit.Assets do
  @moduledoc """
  The Assets context.
  """

  import Ecto.Query, warn: false
  alias Launchkit.Repo

  alias Launchkit.Assets.Headline

  require Logger

  alias Launchkit.OpenAI

  @uploads_dir "priv/uploads/images"

  @doc """
  Returns the list of headlines.

  ## Examples

      iex> list_headlines()
      [%Headline{}, ...]

  """
  def list_headlines do
    Repo.all(Headline)
  end

  @doc """
  Returns the list of headlines for a website.
  """
  def list_headlines_by_website(website_id) do
    from(h in Headline, where: h.website_id == ^website_id, order_by: [asc: h.inserted_at])
    |> Repo.all()
  end

  @doc """
  Gets a single headline.

  Raises `Ecto.NoResultsError` if the Headline does not exist.

  ## Examples

      iex> get_headline!(123)
      %Headline{}

      iex> get_headline!(456)
      ** (Ecto.NoResultsError)

  """
  def get_headline!(id), do: Repo.get!(Headline, id)

  @doc """
  Creates a headline.

  ## Examples

      iex> create_headline(%{field: value})
      {:ok, %Headline{}}

      iex> create_headline(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_headline(attrs \\ %{}) do
    %Headline{}
    |> Headline.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a headline.

  ## Examples

      iex> update_headline(headline, %{field: new_value})
      {:ok, %Headline{}}

      iex> update_headline(headline, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_headline(%Headline{} = headline, attrs) do
    headline
    |> Headline.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a headline.

  ## Examples

      iex> delete_headline(headline)
      {:ok, %Headline{}}

      iex> delete_headline(headline)
      {:error, %Ecto.Changeset{}}

  """
  def delete_headline(%Headline{} = headline) do
    Repo.delete(headline)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking headline changes.

  ## Examples

      iex> change_headline(headline)
      %Ecto.Changeset{data: %Headline{}}

  """
  def change_headline(%Headline{} = headline, attrs \\ %{}) do
    Headline.changeset(headline, attrs)
  end

  alias Launchkit.Assets.LongHeadline

  @doc """
  Returns the list of long_headlines.

  ## Examples

      iex> list_long_headlines()
      [%LongHeadline{}, ...]

  """
  def list_long_headlines do
    Repo.all(LongHeadline)
  end

  @doc """
  Returns the list of long headlines for a website.
  """
  def list_long_headlines_by_website(website_id) do
    from(lh in LongHeadline, where: lh.website_id == ^website_id, order_by: [asc: lh.inserted_at])
    |> Repo.all()
  end

  @doc """
  Gets a single long_headline.

  Raises `Ecto.NoResultsError` if the Long headline does not exist.

  ## Examples

      iex> get_long_headline!(123)
      %LongHeadline{}

      iex> get_long_headline!(456)
      ** (Ecto.NoResultsError)

  """
  def get_long_headline!(id), do: Repo.get!(LongHeadline, id)

  @doc """
  Creates a long_headline.

  ## Examples

      iex> create_long_headline(%{field: value})
      {:ok, %LongHeadline{}}

      iex> create_long_headline(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_long_headline(attrs \\ %{}) do
    %LongHeadline{}
    |> LongHeadline.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a long_headline.

  ## Examples

      iex> update_long_headline(long_headline, %{field: new_value})
      {:ok, %LongHeadline{}}

      iex> update_long_headline(long_headline, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_long_headline(%LongHeadline{} = long_headline, attrs) do
    long_headline
    |> LongHeadline.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a long_headline.

  ## Examples

      iex> delete_long_headline(long_headline)
      {:ok, %LongHeadline{}}

      iex> delete_long_headline(long_headline)
      {:error, %Ecto.Changeset{}}

  """
  def delete_long_headline(%LongHeadline{} = long_headline) do
    Repo.delete(long_headline)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking long_headline changes.

  ## Examples

      iex> change_long_headline(long_headline)
      %Ecto.Changeset{data: %LongHeadline{}}

  """
  def change_long_headline(%LongHeadline{} = long_headline, attrs \\ %{}) do
    LongHeadline.changeset(long_headline, attrs)
  end

  alias Launchkit.Assets.Description

  @doc """
  Returns the list of descriptions.

  ## Examples

      iex> list_descriptions()
      [%Description{}, ...]

  """
  def list_descriptions do
    Repo.all(Description)
  end

  @doc """
  Returns the list of descriptions for a website.
  """
  def list_descriptions_by_website(website_id) do
    from(d in Description, where: d.website_id == ^website_id, order_by: [asc: d.inserted_at])
    |> Repo.all()
  end

  @doc """
  Gets a single description.

  Raises `Ecto.NoResultsError` if the Description does not exist.

  ## Examples

      iex> get_description!(123)
      %Description{}

      iex> get_description!(456)
      ** (Ecto.NoResultsError)

  """
  def get_description!(id), do: Repo.get!(Description, id)

  @doc """
  Creates a description.

  ## Examples

      iex> create_description(%{field: value})
      {:ok, %Description{}}

      iex> create_description(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_description(attrs \\ %{}) do
    %Description{}
    |> Description.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a description.

  ## Examples

      iex> update_description(description, %{field: new_value})
      {:ok, %Description{}}

      iex> update_description(description, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_description(%Description{} = description, attrs) do
    description
    |> Description.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a description.

  ## Examples

      iex> delete_description(description)
      {:ok, %Description{}}

      iex> delete_description(description)
      {:error, %Ecto.Changeset{}}

  """
  def delete_description(%Description{} = description) do
    Repo.delete(description)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking description changes.

  ## Examples

      iex> change_description(description)
      %Ecto.Changeset{data: %Description{}}

  """
  def change_description(%Description{} = description, attrs \\ %{}) do
    Description.changeset(description, attrs)
  end

  alias Launchkit.Assets.Image

  @doc """
  Returns the list of images.

  ## Examples

      iex> list_images()
      [%Image{}, ...]

  """
  def list_images do
    Repo.all(Image)
  end

  @doc """
  Returns the list of images for a website.
  """
  def list_images_by_website(website_id) do
    from(i in Image, where: i.website_id == ^website_id, order_by: [asc: i.inserted_at])
    |> Repo.all()
  end

  @doc """
  Gets a single image.

  Raises `Ecto.NoResultsError` if the Image does not exist.

  ## Examples

      iex> get_image!(123)
      %Image{}

      iex> get_image!(456)
      ** (Ecto.NoResultsError)

  """
  def get_image!(id), do: Repo.get!(Image, id)

  @doc """
  Creates a image.

  ## Examples

      iex> create_image(%{field: value})
      {:ok, %Image{}}

      iex> create_image(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_image(attrs \\ %{}) do
    %Image{}
    |> Image.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a image.

  ## Examples

      iex> update_image(image, %{field: new_value})
      {:ok, %Image{}}

      iex> update_image(image, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_image(%Image{} = image, attrs) do
    image
    |> Image.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a image.

  ## Examples

      iex> delete_image(image)
      {:ok, %Image{}}

      iex> delete_image(image)
      {:error, %Ecto.Changeset{}}

  """
  def delete_image(%Image{} = image) do
    Repo.delete(image)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking image changes.

  ## Examples

      iex> change_image(image)
      %Ecto.Changeset{data: %Image{}}

  """
  def change_image(%Image{} = image, attrs \\ %{}) do
    Image.changeset(image, attrs)
  end

  alias Launchkit.Assets.Video

  @doc """
  Returns the list of videos.

  ## Examples

      iex> list_videos()
      [%Video{}, ...]

  """
  def list_videos do
    Repo.all(Video)
  end

  @doc """
  Gets a single video.

  Raises `Ecto.NoResultsError` if the Video does not exist.

  ## Examples

      iex> get_video!(123)
      %Video{}

      iex> get_video!(456)
      ** (Ecto.NoResultsError)

  """
  def get_video!(id), do: Repo.get!(Video, id)

  @doc """
  Creates a video.

  ## Examples

      iex> create_video(%{field: value})
      {:ok, %Video{}}

      iex> create_video(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_video(attrs \\ %{}) do
    %Video{}
    |> Video.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a video.

  ## Examples

      iex> update_video(video, %{field: new_value})
      {:ok, %Video{}}

      iex> update_video(video, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_video(%Video{} = video, attrs) do
    video
    |> Video.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a video.

  ## Examples

      iex> delete_video(video)
      {:ok, %Video{}}

      iex> delete_video(video)
      {:error, %Ecto.Changeset{}}

  """
  def delete_video(%Video{} = video) do
    Repo.delete(video)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking video changes.

  ## Examples

      iex> change_video(video)
      %Ecto.Changeset{data: %Video{}}

  """
  def change_video(%Video{} = video, attrs \\ %{}) do
    Video.changeset(video, attrs)
  end

  # ============================================================================
  # HEADLINES GENERATION
  # ============================================================================

  @headlines_prompt """
  You are an expert Google Ads copywriter. Based on the brand analysis provided, generate compelling ad copy.

  REQUIREMENTS:
  - 15 short headlines (MUST be 30 characters or less each)
  - 5 long headlines (MUST be 90 characters or less each)
  - 5 descriptions (MUST be 90 characters or less each)

  GUIDELINES:
  - Use the brand voice and tone from the analysis
  - Include power words and emotional triggers
  - Highlight key benefits and differentiators
  - Include calls-to-action where appropriate
  - Vary the approaches: questions, statements, urgency, social proof
  - Make each headline unique - no repetition

  Return ONLY valid JSON with this exact structure:
  {
    "headlines": [
      {"text": "Headline 1", "char_count": 15},
      {"text": "Headline 2", "char_count": 20}
    ],
    "long_headlines": [
      {"text": "Long headline 1", "char_count": 45}
    ],
    "descriptions": [
      {"text": "Description 1", "char_count": 70}
    ]
  }

  CRITICAL: Double-check character counts. Short headlines over 30 chars will be rejected.
  """

  @doc """
  Generate headlines, long headlines, and descriptions based on website analysis.
  """
  def generate_headlines(analysis) do
    prompt = build_headlines_prompt(analysis)

    case OpenAI.send_request_to_openai(@headlines_prompt, prompt) do
      {:ok, response} ->
        parse_headlines_response(response)

      {:error, reason} ->
        Logger.error("Failed to generate headlines: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp build_headlines_prompt(analysis) do
    """
    BRAND ANALYSIS:
    Company: #{get_in(analysis, ["brand_summary", "company_name"]) || "Unknown"}
    One-liner: #{get_in(analysis, ["brand_summary", "one_liner"]) || "N/A"}
    Industry: #{get_in(analysis, ["brand_summary", "industry"]) || "N/A"}

    BRAND VOICE:
    Tone: #{inspect(get_in(analysis, ["brand_summary", "brand_voice", "tone"]) || [])}

    MESSAGING PILLARS:
    #{format_pillars(get_in(analysis, ["messaging_pillars"]) || [])}

    HEADLINE INGREDIENTS:
    Power words: #{inspect(get_in(analysis, ["headline_ingredients", "power_words"]) || [])}
    Benefits: #{inspect(get_in(analysis, ["headline_ingredients", "benefits"]) || [])}
    Features: #{inspect(get_in(analysis, ["headline_ingredients", "features"]) || [])}
    Social proof: #{inspect(get_in(analysis, ["headline_ingredients", "social_proof_snippets"]) || [])}

    TARGET AUDIENCE:
    Primary: #{get_in(analysis, ["target_audience", "primary_persona"]) || "N/A"}
    Pain points: #{inspect(get_in(analysis, ["target_audience", "pain_points"]) || [])}

    CALLS TO ACTION:
    Primary: #{get_in(analysis, ["calls_to_action", "primary"]) || "Learn More"}
    Secondary: #{inspect(get_in(analysis, ["calls_to_action", "secondary"]) || [])}

    Generate the headlines, long headlines, and descriptions now.
    """
  end

  defp format_pillars(pillars) do
    pillars
    |> Enum.map(fn p -> "- #{p["pillar"]}: #{p["emotional_hook"]}" end)
    |> Enum.join("\n")
  end

  defp parse_headlines_response(response) do
    cleaned =
      response
      |> String.trim()
      |> String.replace(~r/^```json\n?/, "")
      |> String.replace(~r/\n?```$/, "")
      |> String.trim()

    case Jason.decode(cleaned) do
      {:ok, data} ->
        headlines =
          (data["headlines"] || [])
          |> Enum.map(&%{text: &1["text"], char_count: String.length(&1["text"])})
          |> Enum.filter(&(&1.char_count <= 30))
          |> Enum.take(15)

        long_headlines =
          (data["long_headlines"] || [])
          |> Enum.map(&%{text: &1["text"], char_count: String.length(&1["text"])})
          |> Enum.filter(&(&1.char_count <= 90))
          |> Enum.take(5)

        descriptions =
          (data["descriptions"] || [])
          |> Enum.map(&%{text: &1["text"], char_count: String.length(&1["text"])})
          |> Enum.filter(&(&1.char_count <= 90))
          |> Enum.take(5)

        {:ok, %{headlines: headlines, long_headlines: long_headlines, descriptions: descriptions}}

      {:error, error} ->
        Logger.error("Failed to parse headlines JSON: #{inspect(error)}")
        {:error, "Invalid response format"}
    end
  end

  # ============================================================================
  # IMAGE GENERATION
  # ============================================================================

  @image_prompt_context """
  You are an expert at creating prompts for AI image generation for Google Ads.
  Based on the brand analysis, create image generation prompts that will produce
  professional, on-brand advertising visuals.

  Create prompts for these required Google Ads image sizes:
  1. Landscape (1200x628) - Main marketing image
  2. Square (1200x1200) - Social/display ads
  3. Portrait (960x1200) - Mobile ads

  Each prompt should:
  - Match the brand's visual direction and mood
  - Be suitable for advertising (professional, clean, eye-catching)
  - Not include any text (text will be added separately)
  - Focus on imagery that supports the brand message

  Return ONLY valid JSON:
  {
    "prompts": [
      {
        "aspect_ratio": "landscape",
        "width": 1200,
        "height": 628,
        "prompt": "Detailed image generation prompt here"
      },
      {
        "aspect_ratio": "square",
        "width": 1200,
        "height": 1200,
        "prompt": "Detailed image generation prompt here"
      },
      {
        "aspect_ratio": "portrait",
        "width": 960,
        "height": 1200,
        "prompt": "Detailed image generation prompt here"
      }
    ]
  }
  """

  @doc """
  Generate images based on website analysis.
  Creates prompts first, then generates images via DALL-E or similar.
  """
  def generate_images(analysis) do
    # First, generate image prompts
    with {:ok, prompts} <- generate_image_prompts(analysis),
         {:ok, images} <- generate_images_from_prompts(prompts) do
      {:ok, images}
    end
  end

  defp generate_image_prompts(analysis) do
    prompt = build_image_prompt_request(analysis)

    case OpenAI.send_request_to_openai(@image_prompt_context, prompt) do
      {:ok, response} ->
        parse_image_prompts(response)

      {:error, reason} ->
        Logger.error("Failed to generate image prompts: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp build_image_prompt_request(analysis) do
    """
    BRAND ANALYSIS:
    Company: #{get_in(analysis, ["brand_summary", "company_name"]) || "Unknown"}
    Industry: #{get_in(analysis, ["brand_summary", "industry"]) || "N/A"}
    One-liner: #{get_in(analysis, ["brand_summary", "one_liner"]) || "N/A"}

    VISUAL DIRECTION:
    Primary colors: #{inspect(get_in(analysis, ["visual_direction", "primary_colors"]) || [])}
    Imagery themes: #{inspect(get_in(analysis, ["visual_direction", "imagery_themes"]) || [])}
    Mood: #{inspect(get_in(analysis, ["visual_direction", "mood_keywords"]) || [])}
    Suggested scenes: #{inspect(get_in(analysis, ["visual_direction", "suggested_scenes"]) || [])}
    Avoid: #{inspect(get_in(analysis, ["visual_direction", "avoid"]) || [])}

    Generate image prompts for Google Ads now.
    """
  end

  defp parse_image_prompts(response) do
    cleaned =
      response
      |> String.trim()
      |> String.replace(~r/^```json\n?/, "")
      |> String.replace(~r/\n?```$/, "")
      |> String.trim()

    case Jason.decode(cleaned) do
      {:ok, %{"prompts" => prompts}} ->
        {:ok, prompts}

      {:error, error} ->
        Logger.error("Failed to parse image prompts: #{inspect(error)}")
        {:error, "Invalid response format"}
    end
  end

  defp generate_images_from_prompts(prompts) do
    images =
      prompts
      |> Enum.map(fn prompt_data ->
        case generate_single_image(prompt_data) do
          {:ok, image} ->
            image

          {:error, _} ->
            %{
              status: :failed,
              prompt: prompt_data["prompt"],
              aspect_ratio: prompt_data["aspect_ratio"]
            }
        end
      end)

    {:ok, images}
  end

  defp generate_single_image(prompt_data) do
    # Using OpenAI DALL-E 3
    api_key = Launchkit.OpenAI.get_api_key()

    if is_nil(api_key) do
      {:error, :missing_api_key}
    else
      size = dalle_size(prompt_data["aspect_ratio"])

      body = %{
        "model" => "dall-e-3",
        "prompt" => prompt_data["prompt"],
        "n" => 1,
        "size" => size,
        "quality" => "standard"
      }

      headers = [
        {"Content-Type", "application/json"},
        {"Authorization", "Bearer #{api_key}"}
      ]

      case Req.post("https://api.openai.com/v1/images/generations",
             headers: headers,
             json: body,
             receive_timeout: 120_000
           ) do
        {:ok, %{status: 200, body: %{"data" => [%{"url" => temp_url} | _]}}} ->
          # Download and save the image locally
          case download_and_save_image(temp_url) do
            {:ok, local_url, storage_path} ->
              {:ok,
               %{
                 url: local_url,
                 storage_path: storage_path,
                 prompt: prompt_data["prompt"],
                 aspect_ratio: prompt_data["aspect_ratio"],
                 width: prompt_data["width"],
                 height: prompt_data["height"],
                 status: :completed
               }}

            {:error, reason} ->
              Logger.error("Failed to download image: #{inspect(reason)}")
              # Fallback to original URL if download fails
              {:ok,
               %{
                 url: temp_url,
                 storage_path: temp_url,
                 prompt: prompt_data["prompt"],
                 aspect_ratio: prompt_data["aspect_ratio"],
                 width: prompt_data["width"],
                 height: prompt_data["height"],
                 status: :completed
               }}
          end

        {:ok, %{status: status, body: body}} ->
          Logger.error("DALL-E error (#{status}): #{inspect(body)}")
          {:error, "Image generation failed"}

        {:error, reason} ->
          Logger.error("DALL-E request failed: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  # DALL-E 3 only supports specific sizes
  defp dalle_size("landscape"), do: "1792x1024"
  defp dalle_size("square"), do: "1024x1024"
  defp dalle_size("portrait"), do: "1024x1792"
  defp dalle_size(_), do: "1024x1024"

  # Download image from URL and save to local storage
  defp download_and_save_image(url) do
    try do
      # Ensure uploads directory exists
      uploads_path = Path.join([Application.app_dir(:launchkit), @uploads_dir])
      File.mkdir_p!(uploads_path)

      # Generate unique filename
      filename =
        "#{System.unique_integer([:positive])}_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}.png"

      file_path = Path.join(uploads_path, filename)

      # Download the image - use decode_body: false to get raw binary
      case Req.get(url,
             receive_timeout: 30_000,
             decode_body: false
           ) do
        {:ok, %{status: 200, body: image_data}} when is_binary(image_data) ->
          # Save to file
          case File.write(file_path, image_data) do
            :ok ->
              # Return the public URL path and storage path
              public_url = "/uploads/images/#{filename}"
              Logger.info("Successfully saved image to #{file_path}")
              {:ok, public_url, file_path}

            {:error, reason} ->
              Logger.error("Failed to write image file: #{inspect(reason)}")
              {:error, :file_write_failed}
          end

        {:ok, %{status: status}} ->
          Logger.error("Failed to download image: HTTP #{status}")
          {:error, :download_failed}

        {:error, reason} ->
          Logger.error("Failed to download image: #{inspect(reason)}")
          {:error, reason}
      end
    rescue
      e ->
        Logger.error("Exception downloading image: #{inspect(e)}")
        {:error, :exception}
    end
  end

  # ============================================================================
  # VIDEO GENERATION
  # ============================================================================

  @video_prompt_context """
  You are an expert at creating video generation prompts for advertising.
  Based on the brand analysis and the image that will be animated, create
  a video generation prompt suitable for Google Veo or similar AI video tools.

  The video should:
  - Be 5-8 seconds long
  - Feature subtle, professional motion
  - Be suitable for advertising
  - Match the brand's tone and style

  Return ONLY valid JSON:
  {
    "prompt": "Detailed video generation prompt describing the motion and scene",
    "duration_seconds": 6,
    "motion_style": "subtle/dynamic/cinematic"
  }
  """

  @doc """
  Generate videos from images using Veo or similar.
  """
  def generate_videos(analysis, images) do
    completed_images = Enum.filter(images, &(&1.status == :completed))

    if completed_images == [] do
      {:error, "No completed images to generate videos from"}
    else
      videos =
        completed_images
        |> Enum.take(3)
        |> Enum.map(fn image ->
          case generate_single_video(analysis, image) do
            {:ok, video} ->
              video

            {:error, _} ->
              %{status: :failed, source_image: image.url, aspect_ratio: image.aspect_ratio}
          end
        end)

      {:ok, videos}
    end
  end

  defp generate_single_video(analysis, image) do
    # First generate the video prompt
    with {:ok, video_prompt} <- generate_video_prompt(analysis, image),
         {:ok, video} <- call_video_api(video_prompt, image) do
      {:ok, video}
    end
  end

  defp generate_video_prompt(analysis, image) do
    prompt = """
    BRAND CONTEXT:
    Company: #{get_in(analysis, ["brand_summary", "company_name"]) || "Unknown"}
    Industry: #{get_in(analysis, ["brand_summary", "industry"]) || "N/A"}

    VIDEO DIRECTION:
    Tone: #{get_in(analysis, ["video_direction", "tone"]) || "Professional"}
    Pacing: #{get_in(analysis, ["video_direction", "pacing"]) || "Medium"}

    SOURCE IMAGE:
    The video will animate an image with this prompt: #{image.prompt}
    Aspect ratio: #{image.aspect_ratio}

    Create a video generation prompt that adds subtle, professional motion to this image.
    """

    case OpenAI.send_request_to_openai(@video_prompt_context, prompt) do
      {:ok, response} ->
        parse_video_prompt(response)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_video_prompt(response) do
    cleaned =
      response
      |> String.trim()
      |> String.replace(~r/^```json\n?/, "")
      |> String.replace(~r/\n?```$/, "")
      |> String.trim()

    case Jason.decode(cleaned) do
      {:ok, data} -> {:ok, data}
      {:error, _} -> {:error, "Invalid video prompt format"}
    end
  end

  defp call_video_api(video_prompt, image) do
    # TODO: Implement actual Veo API call
    # For now, return a placeholder
    # You would integrate with Google Vertex AI Veo here

    Logger.info("Video generation requested for: #{image.aspect_ratio}")
    Logger.info("Video prompt: #{video_prompt["prompt"]}")

    # Placeholder response - replace with actual Veo integration
    {:ok,
     %{
       url: nil,
       prompt: video_prompt["prompt"],
       duration_seconds: video_prompt["duration_seconds"] || 6,
       aspect_ratio: image.aspect_ratio,
       source_image_url: image.url,
       status: :pending
     }}
  end

  # ============================================================================
  # EXPORT
  # ============================================================================

  @doc """
  Export all assets as a downloadable package.
  """
  def export_assets(headlines, long_headlines, descriptions, images, videos) do
    # TODO: Create a zip file with all assets
    %{
      headlines: Enum.map(headlines, & &1.text),
      long_headlines: Enum.map(long_headlines, & &1.text),
      descriptions: Enum.map(descriptions, & &1.text),
      images: Enum.map(images, & &1.url),
      videos: Enum.map(videos, & &1.url)
    }
  end
end
