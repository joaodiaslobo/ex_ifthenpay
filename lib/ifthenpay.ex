defmodule Ifthenpay do
  @moduledoc """
  Documentation for `ifthenpay`.
  """

  @default_api_endpoint "https://ifthenpay.com/api/"

  defp get_api_endpoint do
    Application.get_env(:ifthenpay, :api_endpoint) ||
      System.get_env("IFTHENPAY_API_ENDPOINT") ||
      @default_api_endpoint
  end

  defp request_url(endpoint) do
    Path.join(get_api_endpoint(), endpoint)
  end

  defp request_url(endpoint, data) do
    base_url = request_url(endpoint)
    query_params = Ifthenpay.Utils.encode_data(data)
    "#{base_url}?#{query_params}"
  end

  defp request_headers do
    [
      {"Content-Type", "application/json"}
    ]
  end

  def request(action, endpoint, query_arguments) when action in [:get, :post, :delete] do
    HTTPoison.request(action, request_url(endpoint, query_arguments), "", request_headers())
    |> handle_response
  end

  def request_with_body(action, endpoint, body) when action in [:post, :put] do
    HTTPoison.request(action, request_url(endpoint), Poison.encode!(body), request_headers())
    |> handle_response
  end

  defp handle_response({:ok, %{body: body, status_code: 200}}) do
    {:ok, process_response_body(body)}
  end

  defp handle_response({:ok, %{body: body, status_code: _code}}) do
    {:error, process_response_body(body)}
  end

  defp handle_response({:error, %HTTPoison.Error{reason: reason}}) do
    {:error, "network error: #{reason}"}
  end

  defp process_response_body(body) do
    Poison.decode!(body)
    |> Map.new(fn {k, v} -> {k |> String.downcase() |> String.to_atom(), v} end)
  end
end
