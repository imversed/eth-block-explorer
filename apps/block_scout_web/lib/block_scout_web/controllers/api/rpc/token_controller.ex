defmodule BlockScoutWeb.API.RPC.TokenController do
  use BlockScoutWeb, :controller

  alias BlockScoutWeb.API.RPC.Helpers
  alias Explorer.{Chain, PagingOptions}

  @rpc_paging_options %PagingOptions{page_size: 10_000}

  def gettoken(conn, params) do
    with {:contractaddress_param, {:ok, contractaddress_param}} <- fetch_contractaddress(params),
         {:format, {:ok, address_hash}} <- to_address_hash(contractaddress_param),
         {:token, {:ok, token}} <- {:token, Chain.token_from_address_hash(address_hash)} do
      render(conn, "gettoken.json", %{token: token})
    else
      {:contractaddress_param, :error} ->
        render(conn, :error, error: "Query parameter contract address is required")

      {:format, :error} ->
        render(conn, :error, error: "Invalid contract address hash")

      {:token, {:error, :not_found}} ->
        render(conn, :error, error: "contract address not found")
    end
  end

  def tokenlist(conn, params) do
    with {:contractaddress_param, {:ok, contractaddress_param}} <- fetch_contractaddress(params),
         {:format, {:ok, address_hash}} <- to_address_hash(contractaddress_param),
         {:token_transfers, token_transfers} <- {:token_transfers, Chain.address_to_unique_tokens(address_hash, paging_options: @rpc_paging_options)} do
      render(conn, "tokenlist.json", %{token_transfers: token_transfers})
    else
      {:contractaddress_param, :error} ->
        render(conn, :error, error: "Query parameter contract address is required")

      {:format, :error} ->
        render(conn, :error, error: "Invalid contract address hash")

    end
  end

  def token(conn, params) do
    with {:contractaddress_param, {:ok, contractaddress_param}} <- fetch_contractaddress(params),
         {:tokenid_param, {:ok, tokenid_param}} <- fetch_tokenid(params),
         {:ok, token_id} <- to_token_id(tokenid_param),
         {:format, {:ok, address_hash}} <- to_address_hash(contractaddress_param),
         {:token_transfer, {:ok, token_transfer}} <-
          {:token_transfer, Chain.token_by_address_and_id(address_hash, token_id)} do
      render(conn, "token_details.json", %{token_transfer: token_transfer})
    else
      {:contractaddress_param, :error} ->
        render(conn, :error, error: "Query parameter contract address is required")

      {:format, :error} ->
        render(conn, :error, error: "Invalid contract address hash")

      {:tokenid_param, :error} ->
        render(conn, :error, error: "Query parameter token id is required")

      {:error, :invalid_token_id} ->
        render(conn, :error, error: "Token id format is invalid (not an integer)")

      {:error, :failed_to_fetch_metadata_uri} ->
        render(conn, :error, error: "Failed to get token metadata URI")

      {:token_transfer, {:error, :not_found}} ->
        render(conn, :error, error: "Token not found")
    end
  end

  def tokenx(conn, params) do
    with {:contractaddress_param, {:ok, contractaddress_param}} <- fetch_contractaddress(params),
         {:tokenid_param, {:ok, tokenid_param}} <- fetch_tokenid(params),
         {:ok, token_id} <- to_token_id(tokenid_param),
         {:format, {:ok, address_hash}} <- to_address_hash(contractaddress_param),
         {:tokenx, {:ok, tokenx}} <-
          {:tokenx, Chain.tokenx_by_address_and_id(address_hash, token_id)} do
      render(conn, "tokenx.json", %{tokenx: tokenx})
    else
      {:contractaddress_param, :error} ->
        render(conn, :error, error: "Query parameter contract address is required")

      {:format, :error} ->
        render(conn, :error, error: "Invalid contract address hash")

      {:tokenid_param, :error} ->
        render(conn, :error, error: "Query parameter token id is required")

      {:error, :invalid_token_id} ->
        render(conn, :error, error: "Token id format is invalid (not an integer)")

      {:error, :failed_to_fetch_metadata_uri} ->
        render(conn, :error, error: "Failed to get token metadata URI")

      {:tokenx, {:error, :not_found}} ->
        render(conn, :error, error: "Token not found")
    end
  end

  def gettokenholders(conn, params) do
    with pagination_options <- Helpers.put_pagination_options(%{}, params),
         {:contractaddress_param, {:ok, contractaddress_param}} <- fetch_contractaddress(params),
         {:format, {:ok, address_hash}} <- to_address_hash(contractaddress_param) do
      options_with_defaults =
        pagination_options
        |> Map.put_new(:page_number, 0)
        |> Map.put_new(:page_size, 10)

      options = [
        paging_options: %PagingOptions{
          key: nil,
          page_number: options_with_defaults.page_number,
          page_size: options_with_defaults.page_size
        }
      ]

      from_api = true
      token_holders = Chain.fetch_token_holders_from_token_hash(address_hash, from_api, options)
      render(conn, "gettokenholders.json", %{token_holders: token_holders})
    else
      {:contractaddress_param, :error} ->
        render(conn, :error, error: "Query parameter contract address is required")

      {:format, :error} ->
        render(conn, :error, error: "Invalid contract address hash")
    end
  end

  defp fetch_contractaddress(params) do
    {:contractaddress_param, Map.fetch(params, "contractaddress")}
  end

  defp to_address_hash(address_hash_string) do
    {:format, Chain.string_to_address_hash(address_hash_string)}
  end

  defp fetch_tokenid(params) do
    {:tokenid_param, Map.fetch(params, "tokenId")}
  end

  defp to_token_id(token_id_string) do
    case Integer.parse(token_id_string) do
      {token_id, ""} ->
        {:ok, token_id}
      {_token_id, _remainder} ->
        {:error, :invalid_token_id}
      :error ->
        {:error, :invalid_token_id}
    end
  end
end
