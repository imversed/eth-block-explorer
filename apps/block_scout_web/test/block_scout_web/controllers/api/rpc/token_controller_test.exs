defmodule BlockScoutWeb.API.RPC.TokenControllerTest do
  use BlockScoutWeb.ConnCase

  describe "gettoken" do
    test "with missing contract address", %{conn: conn} do
      params = %{
        "module" => "token",
        "action" => "getToken"
      }

      assert response =
               conn
               |> get("/api", params)
               |> json_response(200)

      assert response["message"] =~ "contract address is required"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
    end

    test "with an invalid contract address hash", %{conn: conn} do
      params = %{
        "module" => "token",
        "action" => "getToken",
        "contractaddress" => "badhash"
      }

      assert response =
               conn
               |> get("/api", params)
               |> json_response(200)

      assert response["message"] =~ "Invalid contract address hash"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
    end

    test "with a contract address that doesn't exist", %{conn: conn} do
      params = %{
        "module" => "token",
        "action" => "getToken",
        "contractaddress" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b"
      }

      assert response =
               conn
               |> get("/api", params)
               |> json_response(200)

      assert response["message"] =~ "contract address not found"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
    end

    test "response includes all required fields", %{conn: conn} do
      token = insert(:token)

      params = %{
        "module" => "token",
        "action" => "getToken",
        "contractaddress" => to_string(token.contract_address_hash)
      }

      expected_result = %{
        "name" => token.name,
        "symbol" => token.symbol,
        "totalSupply" => to_string(token.total_supply),
        "decimals" => to_string(token.decimals),
        "type" => token.type,
        "cataloged" => token.cataloged,
        "contractAddress" => to_string(token.contract_address_hash)
      }

      assert response =
               conn
               |> get("/api", params)
               |> json_response(200)

      assert response["result"] == expected_result
      assert response["status"] == "1"
      assert response["message"] == "OK"
    end
  end

  describe "tokenList" do
    test "returns a list of tokens", %{conn: conn} do
      token_contract_address = insert(:contract_address)
      token = insert(:token, contract_address: token_contract_address, type: "ERC-721")

      insert(
        :token_instance,
        token_contract_address_hash: token_contract_address.hash,
        token_id: 11
      )

      insert(
        :token_instance,
        token_contract_address_hash: token_contract_address.hash,
        token_id: 29
      )

      transaction =
        :transaction
        |> insert()
        |> with_block(insert(:block, number: 1))

      tt1 =
        insert(
          :token_transfer,
          block_number: 1000,
          to_address: build(:address),
          transaction: transaction,
          token_contract_address: token_contract_address,
          token: token,
          token_id: 29
        )

        tt2 = insert(
          :token_transfer,
          block_number: 999,
          to_address: build(:address),
          transaction: transaction,
          token_contract_address: token_contract_address,
          token: token,
          token_id: 11
        )


      params = %{
        "module" => "token",
        "action" => "tokenList",
        "contractaddress" => to_string(token_contract_address.hash)
      }

      expected_result = [
        %{
          "contractAddress" => to_string(token_contract_address.hash),
          "ownerAddress" => to_string(tt1.to_address.hash),
          "tokenId" => to_string(tt1.token_id)
        },
        %{
          "contractAddress" => to_string(token_contract_address.hash),
          "ownerAddress" => to_string(tt2.to_address.hash),
          "tokenId" => to_string(tt2.token_id)
        }
      ]
      assert response =
        conn
        |> get("/api", params)
        |> json_response(200)

        assert response["result"] == expected_result
        assert response["status"] == "1"
        assert response["message"] == "OK"
    end
  end

  describe "token" do
    test "returns token instance details", %{conn: conn} do
      token_contract_address = insert(:contract_address)
      token = insert(:token, contract_address: token_contract_address, type: "ERC-721")

      ti = insert(
        :token_instance,
        token_contract_address_hash: token_contract_address.hash,
        token_id: 42,
        metadata: %{:random_fact => "This is a test"}
      )

      params = %{
        "module" => "token",
        "action" => "token",
        "contractaddress" => to_string(token_contract_address.hash),
        "tokenId" => to_string(ti.token_id)
      }

      expected_result =
        %{
          "token_contract_address_hash" => to_string(token_contract_address.hash),
          "token_id" => to_string(ti.token_id),
          "random_fact" => "This is a test"
        }
      assert response =
        conn
        |> get("/api", params)
        |> json_response(200)

        assert response["result"] == expected_result
        assert response["status"] == "1"
        assert response["message"] == "OK"
    end

    test "with missing contract address", %{conn: conn} do
      params = %{
        "module" => "token",
        "action" => "token"
      }

      assert response =
               conn
               |> get("/api", params)
               |> json_response(200)

      assert response["message"] =~ "contract address is required"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
    end

    test "with missing token id", %{conn: conn} do
      params = %{
        "module" => "token",
        "action" => "token",
        "contractaddress" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b"
      }

      assert response =
               conn
               |> get("/api", params)
               |> json_response(200)

      assert response["message"] =~ "token id is required"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
    end

    test "with invalid token id", %{conn: conn} do
      params = %{
        "module" => "token",
        "action" => "token",
        "contractaddress" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b",
        "tokenId" => "not_an_integer"
      }

      assert response =
               conn
               |> get("/api", params)
               |> json_response(200)

      assert response["message"] =~ "Token id format is invalid"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
    end
  end

  # defp gettoken_schema do
  #   ExJsonSchema.Schema.resolve(%{
  #     "type" => "object",
  #     "properties" => %{
  #       "message" => %{"type" => "string"},
  #       "status" => %{"type" => "string"},
  #       "result" => %{
  #         "type" => "object",
  #         "properties" => %{
  #           "name" => %{"type" => "string"},
  #           "symbol" => %{"type" => "string"},
  #           "totalSupply" => %{"type" => "string"},
  #           "decimals" => %{"type" => "string"},
  #           "type" => %{"type" => "string"},
  #           "cataloged" => %{"type" => "string"},
  #           "contractAddress" => %{"type" => "string"}
  #         }
  #       }
  #     }
  #   })
  # end
end
