defmodule BlockScoutWeb.API.RPC.TokenView do
  use BlockScoutWeb, :view

  alias BlockScoutWeb.API.RPC.RPCView

  def render("gettoken.json", %{token: token}) do
    RPCView.render("show.json", data: prepare_token(token))
  end

  def render("tokenlist.json", %{token_transfers: token_transfers}) do
    RPCView.render("show.json", data: token_transfers |> Enum.map(&prepare_token_transfer/1))
  end

  def render("token_details.json", %{token_transfer: tt}) do
    RPCView.render("show.json", data: token_details(tt))
  end

  def render("tokenx.json", %{tokenx: tokenx}) do
    RPCView.render("show.json", data: tokenx)
  end

  def render("tokentx.json", %{token_transfers: transfers}) do
    RPCView.render("show.json", data: transfers |> Enum.map(&prepare_transfer_for_tx/1))
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

  defp prepare_transfer_for_tx(tt) do
    %{
      "token_type" => tt.token.type,
      "from_address" => tt.from_address_hash,
      "to_address" => tt.to_address_hash,
      "contract_address" => to_string(tt.token_contract_address_hash),
      "token_id" => tt.token_id,
      "token_amount" => tt.amount
    }
  end

  defp token_details(tt) do
    tt_fields = tt
      |> Map.take([
        :token_id,
        :token_contract_address_hash,
        :block_number,
        :amount,
        :token_uri])
    token_fields = tt.token
    |> Map.take([
      :symbol,
      :type,
      :name
    ])
    instance_fields = [tt.instance.metadata |> Jason.encode!()]
    # |> Map.put(:metadata, tt.instance.metadata |> Jason.decode!())

    tt_fields |> Map.merge(token_fields) |> Map.merge(instance_fields)
  end
end
