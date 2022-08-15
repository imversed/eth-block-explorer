defmodule BlockScoutWeb.API.RPC.TokenController do
  use BlockScoutWeb, :controller

  alias BlockScoutWeb.API.RPC.Helpers
  alias Explorer.Token.InstanceMetadataRetriever
  alias Explorer.{Chain, PagingOptions}

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

  defp fetch_address(params) do
    {:address_hash, Map.fetch(params, "address")}
  end

  defp fetch_token_id(params) do
    {:token_id, Map.fetch(params, "token_id")}
  end

  def metadata(conn, params) do
    with {:address_hash, {:ok, address_hash}} <- fetch_address(params),
         {:format, {:ok, address_hash}} <- to_address_hash(address_hash),
         {:metadata, metadata} <- {:metadata, Chain.metadata_from_hash(address_hash)} do
      render(conn, "metadata.json", %{metadata: metadata})
    else
      {:address_hash, :error} ->
        render(conn, :error, error: "Query parameter contract address is required")

      {:format, :error} ->
        render(conn, :error, error: "Invalid contract address hash")

    end
  end

  def tokenlist(conn, params) do
    with {:address_hash, {:ok, address_hash}} <- fetch_address(params),
         {:format, {:ok, address_hash}} <- to_address_hash(address_hash),
         {:tokens, tokens} <- {:tokens, Chain.get_tokens_from_hash(address_hash)} do
      render(conn, "tokens.json", %{tokens: tokens})
    else
      {:address_hash, :error} ->
        render(conn, :error, error: "Query parameter contract address is required")

      {:format, :error} ->
        render(conn, :error, error: "Invalid contract address hash")

    end
  end

  def token(conn, params) do
    with {:address_hash, {:ok, address_hash}} <- fetch_address(params),
         {:token_id, {:ok, token_id}} <- fetch_token_id(params),
         {:format, {:ok, address_hash}} <- to_address_hash(address_hash),
         {:tokens, tokens} <- {:tokens, Chain.get_token_by_token_hash_and_token_id(address_hash, token_id)} do
      render(conn, "tokens.json", %{tokens: tokens})
    else
      {:address_hash, :error} ->
        render(conn, :error, error: "Query parameter contract address is required")

      {:format, :error} ->
        render(conn, :error, error: "Invalid contract address hash")
    end
  end
end
