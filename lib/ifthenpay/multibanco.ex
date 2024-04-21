defmodule Ifthenpay.Multibanco do
  @moduledoc """
  Module to generate Multibanco payment references.

  ## Configuration

  To use Multibanco payments, you need to set the `multibanco_key` configuration setting.

  Add the following configuration to your `config.exs` file:

      config :ifthenpay, multibanco_key: "YOUR_SECRET_MULTIBANCO_KEY"

  Alternatively, you can set the `IFTHENPAY_MULTIBANCO_KEY` environment variable.
  """

  @multibanco_endpoint "/multibanco/reference/init"

  alias Ifthenpay.AuthenticationError
  alias Ifthenpay.Utils

  @doc """
  Requests a new Multibanco reference for the specified order.

  ## Parameters
    - `data` - A map containing the following keys:
      - `:orderid` - The order ID of the payment.
      - `:amount` - The amount of the payment.
      - `:description` - Short description of the order. (optional)
      - `:url` - Web address. (optional)
      - `:clientcode` - Client code. (optional)
      - `:clientname` - Client name. (optional)
      - `:clientemail` - Client email. (optional)
      - `:clientusername` - Client username. (optional)
      - `:clientphone` - Client phone. (optional)
      - `:expirydays` - Number of days the reference is valid. (optional)

  ## Returns
    - `{:ok, response_data}` if the request was successful.
    - `{:error, message}` if an error occurred.

  ## Examples

      iex> Ifthenpay.Multibanco.request_new_multibanco_reference(%{orderid: "123456", amount: 10})
      {:ok, %{amount: 10, entity: "11200", expirydate: "", orderid: "123456", reference: "000000291", requestid: "5Qd8gtWLAEUJ6n0lkS5g", status: :success}}

      iex> Ifthenpay.Multibanco.request_new_multibanco_reference(%{orderid: "123456", amount: 10})
      {:error, "Not Authorized. Please verify your credentials."}
  """
  def request_new_multibanco_reference(data) do
    Utils.check_required_fields(data, [:orderid, :amount])

    case Ifthenpay.request_with_body(:post, @multibanco_endpoint, include_multibanco_key(data)) do
      {:ok, response} ->
        if Map.has_key?(response, :status) do
          case response.status do
            "0" ->
              {:ok, response |> Map.put(:status, :success)}

            _ ->
              {:error,
               if Map.has_key?(response, :message) do
                 response.message
               else
                 "Unknown error."
               end}
          end
        else
          {:error, "Unknown error."}
        end

      {:error, response} ->
        if Map.has_key?(response, :message) do
          {:error, response.message}
        else
          {:error, "Unknown error."}
        end
    end
  end

  defp include_multibanco_key(data) do
    data |> Map.put_new(:mbkey, get_multibanco_key())
  end

  defp get_multibanco_key do
    Application.get_env(:ifthenpay, :multibanco_key) ||
      System.get_env("IFTHENPAY_MULTIBANCO_KEY") ||
      raise AuthenticationError,
        message: """

        The Multibanco key setting is required to generate Multibanco references.
        Please include your secret key in the application configuration like so:

            config :ifthenpay, multibanco_key: YOUR_SECRET_MULTIBANCO_KEY

        Alternatively, you can set the IFTHENPAY_MULTIBANCO_KEY environment variable.

            IFTHENPAY_MULTIBANCO_KEY=YOUR_SECRET_MULTIBANCO_KEY

        """
  end
end
