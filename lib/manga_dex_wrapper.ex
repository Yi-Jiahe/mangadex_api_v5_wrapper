defmodule MangaDexWrapper do
  @moduledoc """
  Simple module for retrieving and parsing data from the MangaDex API

  An example use case for retrieving images to read goes as follows:
  1) Retrieve id of manga by title search by calling get_manga_list(title) where title is the title of the manga to be read. Pick the id of the desired manga from the results.
  2) Retrieve id of chapter by calling get_manga_chapters(manga_id) with the previously obtained id. As before, pick the id of the chapter to be read from the results.
  3) Call get_details_for_reading(chapter_id) using the id of the chapter to be read. It will return the server from which to retrieve the images from, as well as a required hash and two lists of image filenames for data and dataSaver modes.
  """

  @base_url "https://api.mangadex.org"

  @doc """
  Get a list of manga from title.

  Other options such as tags, authors, artists not supported.

  On success returns a tuple of :ok and a map of the results which can be seen from the MangaDex API docs. On failure returns a tuple of :error and the errors from the MangaDex error if it was an error associated with the API or a reason if it is something else.
  """
  @spec get_manga_list(String.t) :: {:ok, term} | {:error, term}
  def get_manga_list(title) do
    # todo parse title into url 
    title = URI.encode(title)
    request_url = @base_url <> "/manga?title=#{title}"
    case :httpc.request(:get, {request_url, []}, [], []) do
      {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} ->
        {:ok, Jason.decode!(body)}
      # Untested failure cases
      # Bad response from mangadex
      {:ok, {{'HTTP/1.1', _status_code, _reason_phrase}, _headers, body}} ->
        {:error, Jason.decode!(body)}
      # Problem with the request
      {:error, reason} -> {:error, reason}
      _ -> {:error, "Unhandled exception"}
    end
  end

  @doc """
  Get a list of chapters for a manga identified by manga_id.
  """
  @spec get_manga_chapters(String.t) :: {:ok, term} | {:error, term}
  def get_manga_chapters(manga_id) do
    request_url = @base_url <> "/chapter?manga=#{manga_id}"
    case :httpc.request(:get, {request_url, []}, [], []) do
      {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} ->
        {:ok, Jason.decode!(body)}
      {:ok, {{'HTTP/1.1', _status_code, _reason_phrase}, _headers, body}} ->
        {:error, Jason.decode!(body)}
      {:error, reason} -> {:error, reason}
      _ -> {:error, "Unhandled exception"}
    end
  end

  @doc """
  Get the necessary information to request a page for reading.

  Images can be found using the url:
  {athome_server_url}/{data_mode: "data" or "dataSaver"}/{hash}/{filename: element from data or dataSaver lists}
  """
  def get_details_for_reading(chapter_id) do
    {:ok, %{"data" => %{"attributes" => %{"hash" => hash, "data" => data, "dataSaver" => dataSaver}}}} = get_chapter_details(chapter_id)
    {:ok, athome_server_url} = get_athome_server_url(chapter_id)
    {:ok, %{"athome_server_url" => athome_server_url, "hash" => hash, "data" => data, "dataSaver" => dataSaver}}
  end

  @doc """
  Gets details about the chapter identified by chapter_id.
  """
  def get_chapter_details(chapter_id) do
    request_url = @base_url <> "/chapter/#{chapter_id}"
    case :httpc.request(:get, {request_url, []}, [], []) do
      {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} ->
        body = Jason.decode!(body)
        {:ok, body}
      {:ok, {{'HTTP/1.1', _status_code, _reason_phrase}, _headers, body}} ->
        {:error, Jason.decode!(body)}
      {:error, reason} -> {:error, reason}
      _ -> {:error, "Unhandled exception"}
    end
  end

  @doc """
  Retrieves the url of a server for reading of a chapter identified by chapter_id.
  The url only works for the specific chapter.
  It also contains a temporary access token that lasts 15 minutes.
  forcePort443 is on because according to the MangaDex API docs, this prevents the request for images from the server from being blocked by school and office networks.
  """
  def get_athome_server_url(chapter_id) do
    # Force port 443 to prevent blocking by certain firewalls
    request_url = @base_url <> "/at-home/server/#{chapter_id}?forcePort443=true"
    IO.inspect(request_url)
    case :httpc.request(:get, {request_url, []}, [], []) do
      {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} ->
          %{"baseUrl" => athome_server_url} = Jason.decode!(body)
        {:ok, athome_server_url}
      {:ok, {{'HTTP/1.1', _status_code, _reason_phrase}, _headers, body}} ->
        {:error, Jason.decode!(body)}
      {:error, reason} -> {:error, reason}
      _ -> {:error, "Unhandled exception"}
    end
  end
end
