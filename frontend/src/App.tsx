import React, { useEffect, useState } from "react";
import "./App.css";
import { Button, ButtonGroup } from "react-bootstrap";
import "bootstrap/dist/css/bootstrap.min.css";
import "sf-font";
import Web3 from "web3";
import axios from "axios";
import {
  moralis_api,
  moralis_api_key,
  ropsten_etherscan_apiEndpoint,
  ropsten_etherscan_apiKey,
} from "./utils";
import {
  NFT_COLLECTION_CONTRACT_ABI,
  NFT_COLLECTION_CONTRACT_ADDRESS,
} from "./contracts/nft-collection";
import { Contract } from "web3-eth-contract";
import { AbiItem } from "web3-utils";
import {
  STAKING_CONTRACT_ABI,
  STAKING_CONTRACT_ADDRESS,
} from "./contracts/staking";
import {
  MART_REWARD_AS_PAYMENT_TOKEN_ADDRESS,
  MART_REWARD_CONTRACT_ABI,
} from "./contracts/payment-token";

function App() {
  const [account, setAccount] = useState<null | string>(null);
  const [totalSupply, setTotalSupply] = useState<null | string>(null);
  const [nftData, setNftData] = useState<null | any>(null);
  const [vaultContract, setVaultContract] = useState<null | Contract>(null);
  const [collectionContract, setCollectionContract] = useState<null | Contract>(
    null
  );
  const [martContract, setMartContract] = useState<null | Contract>(null);
  const [mintQuantity, setMintQuantity] = useState<null | string>(null);
  const [prefferedCrypto, setPreferredCrypto] = useState<null | string>(null);

  useEffect(() => {
    console.log("mintQuantity", mintQuantity);
    console.log("preferredCrypto", prefferedCrypto);
  }, [mintQuantity, prefferedCrypto]);

  const connectWallet = async () => {
    try {
      if (Web3.givenProvider) {
        await Web3.givenProvider.enable();
        let web3 = new Web3(Web3.givenProvider);
        let accounts = await web3.eth.getAccounts();
        setAccount(accounts[0]);
        const vault_Cont = await new web3.eth.Contract(
          STAKING_CONTRACT_ABI as AbiItem[],
          STAKING_CONTRACT_ADDRESS
        );
        setVaultContract(vault_Cont);
        const collection_Cont = new web3.eth.Contract(
          NFT_COLLECTION_CONTRACT_ABI as AbiItem[],
          NFT_COLLECTION_CONTRACT_ADDRESS
        );
        setCollectionContract(collection_Cont);

        const mart_cont = new web3.eth.Contract(
          MART_REWARD_CONTRACT_ABI as AbiItem[],
          MART_REWARD_AS_PAYMENT_TOKEN_ADDRESS
        );
        setMartContract(mart_cont);
      }
    } catch (err) {
      console.log("Error in connect wallet", err);
    }
  };

  const handleMintQuantity = async (
    e: React.MouseEvent<HTMLElement, MouseEvent>
  ) => {
    setMintQuantity((e as any).target.value as string);
  };

  const handlePreferredCrypto = async (index: string) => {
    setPreferredCrypto(index);
  };

  useEffect(() => {
    let config = { "X-API-Key": moralis_api_key, accept: "application/json" };

    const getTokenDetails = async () => {
      try {
        const getTokenSupply = await axios.get(
          ropsten_etherscan_apiEndpoint +
            `?module=stats&action=tokensupply&contractaddress=${NFT_COLLECTION_CONTRACT_ADDRESS}&apikey=${ropsten_etherscan_apiKey}`
        );

        setTotalSupply(getTokenSupply.data.result);
        const getNftData = await axios.get(
          moralis_api +
            `/nft/${NFT_COLLECTION_CONTRACT_ADDRESS}/owners?chain=rinkeby&format=decimal`,
          {
            headers: config,
          }
        );
        setNftData(getNftData.data);
        console.log("getNFTData", getNftData);
      } catch (err) {
        console.log("Error", err);
      }
    };

    getTokenDetails().catch(console.error);
  }, []);

  const stake = async (tokenId: string) => {
    try {
      await collectionContract?.methods.approve(
        STAKING_CONTRACT_ADDRESS,
        tokenId
      );
      // await vaultContract?.methods.stake([tokenId], 3).send({
      //   from: account,
      // });
    } catch (err) {
      console.log("Error in stake function", err);
    }
  };

  const unstake = async (tokenId: string) => {
    try {
      await vaultContract?.methods.unstake([tokenId]).send({
        from: account,
      });
    } catch (err) {
      console.log("Error in stake function", err);
    }
  };

  const mint = async () => {
    try {
      let owner: string = await collectionContract?.methods.owner().call();
      owner = owner.toLocaleLowerCase()
      const cost = BigInt(2 * 10 ** 18) * BigInt(Number(mintQuantity));
      if (prefferedCrypto == "3") {
        await martContract?.methods
          .approve(NFT_COLLECTION_CONTRACT_ADDRESS, cost)
          .send({ from: account });
      }
      await collectionContract?.methods
        .mint(account, Number(mintQuantity), Number(prefferedCrypto))
        .send({
          from: account,
          value: owner === account ? null : 2 * 10 ** 18 * Number(mintQuantity),
        });
    } catch (err) {
      console.log("Error in mint function", err);
    }
  };

  return (
    <div className="App nftapp">
      <nav className="navbar navbarfont navbarglow navbar-expand-md navbar-dark bg-dark mb-4">
        <div
          className="container-fluid"
          style={{ fontFamily: "SF Pro Display" }}
        >
          <a
            className="navbar-brand px-5"
            style={{ fontWeight: "800", fontSize: "25px" }}
            href="#"
          ></a>
          <img src="n2d-logo.png" width="7%" />
          <button
            className="navbar-toggler"
            type="button"
            data-bs-toggle="collapse"
            data-bs-target="#navbarCollapse"
            aria-controls="navbarCollapse"
            aria-expanded="false"
            aria-label="Toggle navigation"
          >
            <span className="navbar-toggler-icon"></span>
          </button>
          <div className="collapse navbar-collapse" id="navbarCollapse">
            <ul
              className="navbar-nav me-auto mb-2 px-3 mb-md-0"
              style={{ fontSize: "25px" }}
            >
              <li className="nav-item">
                <a className="nav-link active" aria-current="page" href="#">
                  Dashboard
                </a>
              </li>
              <li className="nav-item">
                <a className="nav-link" href="#">
                  List NFTs
                </a>
              </li>
              <li className="nav-item">
                <a className="nav-link">Bridge NFTs</a>
              </li>
            </ul>
          </div>
        </div>
        <div className="px-5">
          <input
            onClick={connectWallet}
            id="connectbtn"
            type="button"
            className="connectbutton"
            style={{ fontFamily: "SF Pro Display" }}
            value="Connect Your Wallet"
          />
        </div>
      </nav>
      <div className="container container-style">
        <div className="col">
          <body className="nftminter">
            <form>
              <div className="row pt-3">
                <div>
                  <h1 className="pt-2" style={{ fontWeight: "30" }}>
                    NFT Minter
                  </h1>
                </div>
                <h3>{totalSupply}/1000</h3>
                <h6>Your Wallet Address</h6>
                <div
                  className="pb-3"
                  id="wallet-address"
                  style={{
                    color: "#39FF14",
                    fontWeight: "400",
                    textShadow: "1px 1px 1px black",
                  }}
                >
                  <label onClick={connectWallet}>Please Connect Wallet</label>
                </div>
              </div>
              <div>
                <label style={{ fontWeight: "300", fontSize: "18px" }}>
                  Select NFT Quantity
                </label>
              </div>
              <ButtonGroup
                size="lg"
                aria-label="First group"
                style={{ boxShadow: "1px 1px 5px #000000" }}
                onClick={(e) => handleMintQuantity(e)}
              >
                <Button value="1">1</Button>
                <Button value="2">2</Button>
                <Button value="3">3</Button>
                <Button value="4">4</Button>
                <Button value="5">5</Button>
              </ButtonGroup>
              <h6
                className="pt-2"
                style={{
                  fontFamily: "SF Pro Display",
                  fontWeight: "300",
                  fontSize: "18px",
                }}
              >
                Buy with your preferred crypto!
              </h6>
              <div className="row px-2 pb-2 row-style">
                <div className="col ">
                  <Button
                    className="button-style"
                    style={{
                      border: "0.2px",
                      borderRadius: "14px",
                      boxShadow: "1px 1px 5px #000000",
                    }}
                    onClick={() => {
                      handlePreferredCrypto("3");
                    }}
                  >
                    <img src={"n2dr-logo.png"} width="100%" />
                  </Button>
                </div>
                <div className="col">
                  <Button
                    className="button-style"
                    style={{
                      border: "0.2px",
                      borderRadius: "14px",
                      boxShadow: "1px 1px 5px #000000",
                    }}
                    onClick={() => {
                      handlePreferredCrypto("1");
                    }}
                  >
                    <img src="usdt.png" width="70%" />
                  </Button>
                </div>
                <div className="col">
                  <Button
                    className="button-style"
                    style={{
                      border: "0.2px",
                      borderRadius: "14px",
                      boxShadow: "1px 1px 5px #000000",
                    }}
                    onClick={async () => {
                      handlePreferredCrypto("2");
                    }}
                  >
                    <img src="matic.png" width="70%" />
                  </Button>
                </div>
                <div>
                  <div
                    id="txout"
                    style={{
                      color: "#39FF14",
                      marginTop: "5px",
                      fontSize: "20px",
                      fontWeight: "500",
                      textShadow: "1px 1px 2px #000000",
                    }}
                  >
                    <Button onClick={() => mint()} className="px-5 mt-4 mb-4 ">
                      Mint
                    </Button>
                    <p style={{ fontSize: "20px" }}>Transfer Status</p>
                  </div>
                </div>
              </div>
            </form>
          </body>
        </div>
        <div className="col">
          <body className="nftstaker border-0">
            <form style={{ fontFamily: "SF Pro Display" }}>
              <h2
                style={{
                  borderRadius: "14px",
                  fontWeight: "300",
                  fontSize: "25px",
                }}
              >
                N2DR NFT Staking Vault{" "}
              </h2>
              <h6 style={{ fontWeight: "300" }}>First time staking?</h6>
              <Button
                className="btn"
                style={{
                  backgroundColor: "#ffffff10",
                  boxShadow: "1px 1px 5px #000000",
                }}
              >
                Authorize Your Wallet
              </Button>
              <div className="row px-3">
                <div className="col">
                  <form
                    className="stakingrewards"
                    style={{
                      borderRadius: "25px",
                      boxShadow: "1px 1px 15px #ffffff",
                    }}
                  >
                    <h5 style={{ color: "#FFFFFF", fontWeight: "300" }}>
                      Your Vault Activity
                    </h5>
                    <h6 style={{ color: "#FFFFFF" }}>Verify Staked Amount</h6>
                    <Button
                      style={{
                        backgroundColor: "#ffffff10",
                        boxShadow: "1px 1px 5px #000000",
                      }}
                    >
                      Verify
                    </Button>
                    <table className="table mt-3 mb-5 px-3 table-dark">
                      <tr>
                        <td style={{ fontSize: "19px" }}>
                          Your Staked NFTs:
                          <span
                            style={{
                              backgroundColor: "#ffffff00",
                              fontSize: "21px",
                              color: "#39FF14",
                              fontWeight: "500",
                              textShadow: "1px 1px 2px #000000",
                            }}
                            id="yournfts"
                          ></span>
                        </td>
                      </tr>
                      <tr>
                        <td style={{ fontSize: "19px" }}>
                          Total Staked NFTs:
                          <span
                            style={{
                              backgroundColor: "#ffffff00",
                              fontSize: "21px",
                              color: "#39FF14",
                              fontWeight: "500",
                              textShadow: "1px 1px 2px #000000",
                            }}
                            id="stakedbalance"
                          ></span>
                        </td>
                      </tr>
                      <tr>
                        <td style={{ fontSize: "19px" }}>
                          Unstake All Staked NFTs
                          <Button
                            className="mb-3"
                            style={{
                              backgroundColor: "#ffffff10",
                              boxShadow: "1px 1px 5px #000000",
                            }}
                          >
                            Unstake All
                          </Button>
                        </td>
                      </tr>
                    </table>
                  </form>
                </div>
                <img className="col-lg-4" src="art.png" />
                <div className="col">
                  <form
                    className="stakingrewards"
                    style={{
                      borderRadius: "25px",
                      boxShadow: "1px 1px 15px #ffffff",
                      fontFamily: "SF Pro Display",
                    }}
                  >
                    <h5 style={{ color: "#FFFFFF", fontWeight: "300" }}>
                      {" "}
                      Staking Rewards
                    </h5>
                    <Button
                      style={{
                        backgroundColor: "#ffffff10",
                        boxShadow: "1px 1px 5px #000000",
                      }}
                    >
                      Earned N2D Rewards
                    </Button>
                    <div
                      id="earned"
                      style={{
                        color: "#39FF14",
                        marginTop: "5px",
                        fontSize: "25px",
                        fontWeight: "500",
                        textShadow: "1px 1px 2px #000000",
                      }}
                    >
                      <p style={{ fontSize: "20px" }}>Earned Tokens</p>
                    </div>
                    <div className="col-12 mt-2">
                      <div style={{ color: "white" }}>Claim Rewards</div>
                      <Button
                        style={{
                          backgroundColor: "#ffffff10",
                          boxShadow: "1px 1px 5px #000000",
                        }}
                        className="mb-2"
                      >
                        Claim
                      </Button>
                    </div>
                  </form>
                </div>
              </div>
              <div className="row px-4 pt-2">
                <div className="header">
                  <div
                    style={{
                      fontSize: "25px",
                      borderRadius: "14px",
                      color: "#ffffff",
                      fontWeight: "300",
                    }}
                  >
                    N2DR NFT Staking Pool Active Rewards
                  </div>
                  <table className="table px-3 table-bordered table-dark">
                    <thead className="thead-light">
                      <tr>
                        <th scope="col">Collection</th>
                        <th scope="col">Rewards Per Day</th>
                        <th scope="col">Exchangeable Items</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr>
                        <td>N2D Bronze Collection</td>
                        <td
                          className="amount"
                          data-test-id="rewards-summary-ads"
                        >
                          <span className="amount">0.50</span>&nbsp;
                          <span className="currency">N2DR</span>
                        </td>
                        <td className="exchange">
                          <span className="amount">2</span>&nbsp;
                          <span className="currency">NFTs/M</span>
                        </td>
                      </tr>
                      <tr>
                        <td>N2D Silver Collection</td>
                        <td
                          className="amount"
                          data-test-id="rewards-summary-ac"
                        >
                          <span className="amount">2.50</span>&nbsp;
                          <span className="currency">N2DR</span>
                        </td>
                        <td className="exchange">
                          <span className="amount">10</span>&nbsp;
                          <span className="currency">NFTs/M</span>
                        </td>
                      </tr>
                      <tr className="stakegoldeffect">
                        <td>N2D Gold Collection</td>
                        <td
                          className="amount"
                          data-test-id="rewards-summary-one-time"
                        >
                          <span className="amount">1</span>&nbsp;
                          <span className="currency">N2DR+</span>
                        </td>
                        <td className="exchange">
                          <span className="amount">25 NFTs/M or </span>
                          <span className="currency">100 N2DR/M</span>
                        </td>
                      </tr>
                    </tbody>
                  </table>

                  <div className="header">
                    <div
                      style={{
                        fontSize: "25px",
                        borderRadius: "14px",
                        fontWeight: "300",
                      }}
                    >
                      N2DR Token Stake Farms
                    </div>
                    <table
                      className="table table-bordered table-dark"
                      style={{ borderRadius: "14px" }}
                    >
                      <thead className="thead-light">
                        <tr>
                          <th scope="col">Farm Pools</th>
                          <th scope="col">Harvest Daily Earnings</th>
                        </tr>
                      </thead>
                      <tbody>
                        <tr>
                          <td>Stake N2DR to Earn N2DR</td>
                          <td
                            className="amount"
                            data-test-id="rewards-summary-ads"
                          >
                            <span className="amount">0.01</span>&nbsp;
                            <span className="currency">Per N2DR</span>
                          </td>
                        </tr>
                        <tr>
                          <td>Stake N2DR to Earn N2DR+</td>
                          <td
                            className="amount"
                            data-test-id="rewards-summary-ac"
                          >
                            <span className="amount">0.005</span>&nbsp;
                            <span className="currency">Per N2DR</span>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            </form>
          </body>
        </div>
      </div>
      <div className="container col-lg-11">
        <div className="row items px-3 pt-3">
          <div
            className="ml-3 mr-3"
            style={{
              display: "inline-grid",
              gridTemplateColumns: "repeat(4, 5fr)",
              columnGap: "20px",
            }}
          >
            {nftData &&
              nftData.result.map((result: any, i: any) => {
                console.log(nftData.result);
                return (
                  <div className="card nft-card mt-3" key={i}>
                    <div className="image-over">
                      <img
                        className="card-img-top"
                        src={
                          "https://ipfs.io/ipfs/QmavM8Zpo9bD3r4zEnhbbBLLvHyfr1YL7f1faG3ovaeSSG/" +
                          result.token_id +
                          ".png"
                        }
                        alt=""
                      />
                    </div>
                    <div className="card-caption col-12 p-0">
                      <div className="card-body">
                        <h5 className="mb-0">
                          Net2Dev Collection NFT #{result.token_id}
                        </h5>
                        <h5 className="mb-0 mt-2">
                          Location Status
                          <p
                            style={{
                              color: "#39FF14",
                              fontWeight: "bold",
                              textShadow: "1px 1px 2px #000000",
                            }}
                          >
                            {result.owner_of}
                          </p>
                        </h5>
                        <div className="card-bottom d-flex justify-content-between">
                          <input
                            key={i}
                            type="hidden"
                            id="stakeid"
                            value={result.token_id}
                          />
                          <Button
                            style={{
                              marginLeft: "2px",
                              backgroundColor: "#ffffff10",
                            }}
                            onClick={async () => {
                              await stake(result.token_id);
                            }}
                          >
                            Stake it
                          </Button>
                          <Button
                            style={{
                              marginLeft: "2px",
                              backgroundColor: "#ffffff10",
                            }}
                            onClick={async () => {
                              await unstake(result.token_id);
                            }}
                          >
                            Unstake it
                          </Button>
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;
