defmodule Ifthenpay.CallbackMissingError do
  @moduledoc """
  Missing callback endpoints.
  """
  defexception type: "callback_missing_error", message: nil
end
