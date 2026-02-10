defmodule LaunchkitWeb.ExportHelpers do
  @moduledoc """
  Shared helpers for export-style views (dashboard export tab and websites show).
  """

  import Phoenix.HTML, only: [raw: 1]

  def get_score_color(score) when score >= 80, do: "#10b981"
  def get_score_color(score) when score >= 60, do: "#f59e0b"
  def get_score_color(score) when score >= 40, do: "#f97316"
  def get_score_color(_score), do: "#ef4444"

  def get_score_label(score) when score >= 80, do: "Excellent AI Visibility"
  def get_score_label(score) when score >= 60, do: "Good AI Visibility"
  def get_score_label(score) when score >= 40, do: "Fair AI Visibility"
  def get_score_label(_score), do: "Poor AI Visibility - Needs Improvement"

  def get_impact_class("high"), do: "bg-red-100 text-red-700"
  def get_impact_class("medium"), do: "bg-yellow-100 text-yellow-700"
  def get_impact_class(_), do: "bg-gray-100 text-gray-700"

  def get_effort_class("high"), do: "bg-blue-100 text-blue-700"
  def get_effort_class("medium"), do: "bg-purple-100 text-purple-700"
  def get_effort_class(_), do: "bg-gray-100 text-gray-700"

  def get_priority_class("high"), do: "bg-red-100 text-red-700"
  def get_priority_class("medium"), do: "bg-yellow-100 text-yellow-700"
  def get_priority_class(_), do: "bg-gray-100 text-gray-700"

  def export_blog_topic_copy_text(topic) do
    title = topic["title"] || topic[:title] || topic["topic"] || topic[:topic] || "Untitled Topic"
    desc = topic["description"] || topic[:description] || ""
    why = topic["why_it_helps"] || topic[:why_it_helps] || topic["reason"] || topic[:reason] || ""

    [title, desc, why]
    |> Enum.filter(&(is_binary(&1) and String.trim(&1) != ""))
    |> Enum.join("\n\n")
  end

  def get_share_url(url) do
    base_url = "https://launchkit.info"
    path = "/dashboard/new"
    params = URI.encode_query(%{"url" => url || "", "step" => "export"})
    "#{base_url}#{path}?#{params}"
  end

  def render_markdown(text) when is_binary(text) and text != "" do
    import Phoenix.HTML

    lines = String.split(text, "\n")

    {html_parts, in_list} =
      lines
      |> Enum.reduce({[], false}, fn line, {acc, in_list} ->
        {rendered, new_in_list} = render_markdown_line(line, in_list)
        {[rendered | acc], new_in_list}
      end)

    final_html =
      if in_list do
        Enum.reverse(html_parts) |> Enum.join() |> Kernel.<>("</ul>")
      else
        Enum.reverse(html_parts) |> Enum.join()
      end

    raw(final_html)
  end

  def render_markdown(""), do: raw("")
  def render_markdown(nil), do: raw("")

  defp render_markdown_line(line, in_list) do
    trimmed = String.trim(line)

    cond do
      trimmed == "" ->
        if in_list, do: {"</ul>", false}, else: {"<br>", false}

      String.starts_with?(trimmed, "#### ") ->
        content = escape_html(String.slice(trimmed, 5..-1))
        html = if in_list, do: "</ul><h4 class='text-base font-semibold mb-2 mt-3'>#{content}</h4>", else: "<h4 class='text-base font-semibold mb-2 mt-3'>#{content}</h4>"
        {html, false}

      String.starts_with?(trimmed, "### ") ->
        content = escape_html(String.slice(trimmed, 4..-1))
        html = if in_list, do: "</ul><h3 class='text-lg font-semibold mb-2 mt-4'>#{content}</h3>", else: "<h3 class='text-lg font-semibold mb-2 mt-4'>#{content}</h3>"
        {html, false}

      String.starts_with?(trimmed, "## ") ->
        content = escape_html(String.slice(trimmed, 3..-1))
        html = if in_list, do: "</ul><h2 class='text-xl font-semibold mb-3 mt-5'>#{content}</h2>", else: "<h2 class='text-xl font-semibold mb-3 mt-5'>#{content}</h2>"
        {html, false}

      String.starts_with?(trimmed, "# ") ->
        content = escape_html(String.slice(trimmed, 2..-1))
        html = if in_list, do: "</ul><h1 class='text-2xl font-bold mb-4 mt-6'>#{content}</h1>", else: "<h1 class='text-2xl font-bold mb-4 mt-6'>#{content}</h1>"
        {html, false}

      String.starts_with?(trimmed, "- ") or String.starts_with?(trimmed, "* ") ->
        content = escape_html(String.slice(trimmed, 2..-1))
        html = if in_list, do: "<li class='mb-1'>#{content}</li>", else: "<ul class='list-disc ml-6 mb-3'><li class='mb-1'>#{content}</li>"
        {html, true}

      true ->
        content = escape_html(trimmed)
        html = if in_list, do: "</ul><p class='mb-3 leading-relaxed'>#{content}</p>", else: "<p class='mb-3 leading-relaxed'>#{content}</p>"
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
end
