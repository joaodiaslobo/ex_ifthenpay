defmodule Ifthenpay.CreditCard do
  @moduledoc """
  Credit Card payments related functions.

  ## Configuration

  To use Credit Card payments, you must include the following settings in your application configuration:

  Add the following configuration to your `config.exs` file:

      config :ifthenpay, creditcard_key: "YOUR_SECRET_CREDITCARD_KEY"
      config :ifthenpay, creditcard_success_callback: "YOUR_SUCCESS_CALLBACK"
      config :ifthenpay, creditcard_error_callback: "YOUR_ERROR_CALLBACK"
      config :ifthenpay, creditcard_cancel_callback: "YOUR_CANCEL_CALLBACK"

  Alternatively, you can set them as environment variables.
  """

  @creditcard_endpoint "/creditcard/init"

  alias Ifthenpay.{AuthenticationError, CallbackMissingError}
  alias Ifthenpay.Utils

  @doc """
  Requests a new Credit Card payment.
  In the case of a successful request, the response will contain a payment gateway URL which the user can use to complete the payment.
  Depending on the outcome of the payment, the user will be redirected to the success, error, or cancel callback URLs defined in the configuratiion.

  ## Parameters
    - `data` - A map containing the following keys:
      - `:orderid` - The order ID of the payment.
      - `:amount` - The amount of the payment.
      - `:language` - The language of the payment page. (optional)

  ## Returns
    - `{:ok, response_data}` if the request was successful.
    - `{:error, message}` if an error occurred.

  ## Example

      iex> Ifthenpay.CreditCard.request_new_credit_card_payment(%{orderid: "order_45678", amount: 11.55})
      {:ok, %{message: "Success", paymenturl: "https://payment.com/id", requestid: "36jvlEhUYeknQ8PHKprR", status: :success}}

      iex> Ifthenpay.CreditCard.request_new_credit_card_payment(%{orderid: "order_45678", amount: 11.55})
      {:error, "Unauthorized."}
  """
  def request_new_credit_card_payment(data) do
    Utils.check_required_fields(data, [:orderid, :amount])

    case Ifthenpay.request_with_body(
           :post,
           generate_endpoint(),
           include_credit_card_callbacks(data)
         ) do
      {:ok, response} ->
        if Map.has_key?(response, :status) do
          case response.status do
            "0" ->
              {:ok, response |> Map.put(:status, :success)}

            "-1" ->
              {:error, "Unauthorized."}

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

      {:error, error} ->
        {:error, error}
    end
  end

  defp generate_endpoint() do
    Path.join(@creditcard_endpoint, get_creditcard_key())
  end

  defp include_credit_card_callbacks(data) do
    data
    |> Map.put(:successurl, get_creditcard_success_callback())
    |> Map.put(:errorurl, get_creditcard_error_callback())
    |> Map.put(:cancelurl, get_creditcard_cancel_callback())
  end

  defp get_creditcard_key do
    Application.get_env(:ifthenpay, :creditcard_key) ||
      System.get_env("IFTHENPAY_CREDITCARD_KEY") ||
      raise AuthenticationError,
        message: """

        The Credit Card key setting is required to use Credit Card payments.
        Please include your secret key in the application configuration like so:

            config :ifthenpay, creditcard_key: YOUR_SECRET_CREDITCARD_KEY

        Alternatively, you can set the IFTHENPAY_CREDITCARD_KEY environment variable.

            IFTHENPAY_CREDITCARD_KEY=YOUR_SECRET_CREDITCARD_KEY

        """
  end

  defp get_creditcard_success_callback do
    Application.get_env(:ifthenpay, :creditcard_success_callback) ||
      System.get_env("IFTHENPAY_CREDITCARD_SUCCESS_CALLBACK") ||
      raise CallbackMissingError,
        message: """

        The Credit Card success callback setting is required to use Credit Card payments.
        Please include your success callback in the application configuration like so:

            config :ifthenpay, creditcard_success_callback: YOUR_SUCCESS_CALLBACK

        Alternatively, you can set the IFTHENPAY_CREDITCARD_SUCCESS_CALLBACK environment variable.

            IFTHENPAY_CREDITCARD_SUCCESS_CALLBACK=YOUR_SUCCESS_CALLBACK

        """
  end

  defp get_creditcard_error_callback do
    Application.get_env(:ifthenpay, :creditcard_error_callback) ||
      System.get_env("IFTHENPAY_CREDITCARD_ERROR_CALLBACK") ||
      raise CallbackMissingError,
        message: """

        The Credit Card error callback setting is required to use Credit Card payments.
        Please include your error callback in the application configuration like so:

            config :ifthenpay, creditcard_error_callback: YOUR_ERROR_CALLBACK

        Alternatively, you can set the IFTHENPAY_CREDITCARD_ERROR_CALLBACK environment variable.

            IFTHENPAY_CREDITCARD_ERROR_CALLBACK=YOUR_ERROR_CALLBACK

        """
  end

  defp get_creditcard_cancel_callback do
    Application.get_env(:ifthenpay, :creditcard_cancel_callback) ||
      System.get_env("IFTHENPAY_CREDITCARD_CANCEL_CALLBACK") ||
      raise CallbackMissingError,
        message: """

        The Credit Card cancel callback setting is required to use Credit Card payments.
        Please include your cancel callback in the application configuration like so:

            config :ifthenpay, creditcard_cancel_callback: YOUR_CANCEL_CALLBACK

        Alternatively, you can set the IFTHENPAY_CREDITCARD_CANCEL_CALLBACK environment variable.

            IFTHENPAY_CREDITCARD_CANCEL_CALLBACK=YOUR_CANCEL_CALLBACK

        """
  end
end
