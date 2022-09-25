defmodule BlockScoutWeb.API.RPC.TokenView do
  use BlockScoutWeb, :view

  alias BlockScoutWeb.API.RPC.RPCView

  def render("gettoken.json", %{token: token}) do
    RPCView.render("show.json", data: prepare_token(token))
  end

  def render("tokenlist.json", %{token_transfers: token_transfers}) do
    RPCView.render("show.json", data: token_transfers |> Enum.map(&prepare_token_transfer/1))
  end

  def render("token_details.json", %{token_instance: token_instance}) do
    RPCView.render("show.json", data: prepare_token_instance(token_instance))
  end

  def render("gettokenholders.json", %{token_holders: token_holders}) do
    data = Enum.map(token_holders, &prepare_token_holder/1)
    RPCView.render("show.json", data: data)
  end

  def render("error.json", assigns) do
    RPCView.render("error.json", assigns)
  end

  defp prepare_token(token) do
    %{
      "type" => token.type,
      "name" => token.name,
      "symbol" => token.symbol,
      "totalSupply" => to_string(token.total_supply),
      "decimals" => to_string(token.decimals),
      "contractAddress" => to_string(token.contract_address_hash),
      "cataloged" => token.cataloged
    }
  end

  defp prepare_token_holder(token_holder) do
    %{
      "address" => to_string(token_holder.address_hash),
      "value" => token_holder.value
    }
  end

  defp prepare_token_transfer(token_transfer) do
    %{
      "tokenId" => token_transfer.token_id,
      "ownerAddress" => to_string(token_transfer.to_address),
      "contractAddress" => to_string(token_transfer.token_contract_address_hash)
    }
  end

  defp prepare_token_instance(token_instance) do
    base_fields =
      token_instance
      |> Map.take([:token_id, :token_contract_address_hash])
    Map.merge(base_fields, token_instance.metadata)
  end
end
