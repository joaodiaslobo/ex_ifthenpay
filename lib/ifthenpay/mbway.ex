defmodule Ifthenpay.MbWay do
  @moduledoc """
  MB WAY payments related functions.

  ## Configuration

  To use MB WAY payments, you need to set the `mbway_key` configuration setting.

  Add the following configuration to your `config.exs` file:

      config :ifthenpay, mbway_key: "YOUR_SECRET_MBWAY_KEY"

  Alternatively, you can set the `IFTHENPAY_MBWAY_KEY` environment variable.
  """

  @mbway_endpoint "/spg/payment/mbway"

  alias Ifthenpay.AuthenticationError
  alias Ifthenpay.Utils

  @doc """
  Requests a new MB WAY payment to the specified mobile phone number.

  ## Parameters
    - `data` - A map containing the following keys:
      - `:orderid` - The order ID of the payment.
      - `:amount` - The amount of the payment.
      - `:mobilenumber` - The mobile phone number to send the payment request to.
      - `:email` - The email address of the customer. (optional)
      - `:description` - A description of the payment. (optional)

  ## Returns
    - `{:ok, response_data}` if the request was successful.
    - `{:error, message}` if an error occurred.

  ## Example

      iex> Ifthenpay.MbWay.request_new_mbway_payment(%{orderid: "123456", amount: 10, mobilenumber: "912345678"})
      {:ok, %{amount: 10, message: "Pending", requestid: "i2szvoUfPYBMWdSxqO3n", status: :success}}

      iex> Ifthenpay.MbWay.request_new_mbway_payment(%{orderid: "123456", amount: 10, mobilenumber: "912345678"})
      {:error, "Declined."}

  """
  def request_new_mbway_payment(data) do
    Utils.check_required_fields(data, [:orderid, :amount, :mobilenumber])

    case Ifthenpay.request_with_body(:post, @mbway_endpoint, include_mbway_key(data)) do
      {:ok, response} ->
        if Map.has_key?(response, :status) do
          case response.status do
            "000" -> {:ok, response |> Map.put(:status, :success)}
            "122" -> {:error, "Declined."}
            _ -> {:error, "Could not complete."}
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

  @doc """
  Requests the status of an MB WAY payment.

  ## Parameters
    - `order_id` - The order ID of the payment.

  ## Returns
    - `{:ok, response_data}` if the request was successful.
    - `{:error, message}` if an error occurred.

  ## Example

      iex> Ifthenpay.MbWay.request_mbway_payment_status("i2szvoUfPYBMWdSxqO3n")
      {:ok, %{createdat: "03-01-2024 15:15:06", message: "Success", requestid: "i2szvoUfPYBMWdSxqO3n", status: :paid, updatedat: "03-01-2024 15:15:06"}}

      iex> Ifthenpay.MbWay.request_mbway_payment_status("i2szvoUfPYBMWdSxqO3n")
      {:error, "Request not found."}
  """
  def request_mbway_payment_status(order_id) do
    endpoint = @mbway_endpoint <> "/status"
    data = include_mbway_key(%{orderid: order_id})

    case Ifthenpay.request(:get, endpoint, data) do
      {:ok, response} ->
        # Since the API returns [200 OK] even if an error has occurred, we need to check the status field
        if Map.has_key?(response, :status) do
          case response.status do
            "000" ->
              {:ok, response |> Map.put(:status, :paid)}

            "020" ->
              {:ok, response |> Map.put(:status, :rejected)}

            "101" ->
              {:ok, response |> Map.put(:status, :expired)}

            "122" ->
              {:ok, response |> Map.put(:status, :declined)}

            "123" ->
              {:error,
               if Map.has_key?(response, :message) do
                 response.message
               else
                 "Request not found."
               end}

            _ ->
              {:error, "Unknown error. Status code: #{response.status}"}
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

  defp include_mbway_key(data) do
    data |> Map.put_new(:mbwaykey, get_mbway_key())
  end

  defp get_mbway_key do
    Application.get_env(:ifthenpay, :mbway_key) ||
      System.get_env("IFTHENPAY_MBWAY_KEY") ||
      raise AuthenticationError,
        message: """

        The MB WAY key setting is required to use MB WAY payments.
        Please include your secret key in the application configuration like so:

            config :ifthenpay, mbway_key: YOUR_SECRET_MBWAY_KEY

        Alternatively, you can set the IFTHENPAY_MBWAY_KEY environment variable.

            IFTHENPAY_MBWAY_KEY=YOUR_SECRET_MBWAY_KEY

        """
  end
end
