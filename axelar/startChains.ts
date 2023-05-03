// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
import { createAndExport, getAllNetworks, relay, getFee } from "@axelar-network/axelar-local-dev";
import { Wallet } from "ethers"
import fs from 'fs';


async function main() {
    const account = Wallet.fromMnemonic("test test test test test test test test test test test junk")
    await createAndExport({
        port: 8545,
        chains: ["Ethereum", "Polygon"],
        chainOutputPath: "./axelar/out/chains.json",
        accountsToFund: [
            account.address,
        ],
    })

    const networks = await getAllNetworks("http://localhost:8545")

    for (const n of networks) {
        const envVars = {
            AXELAR_GATEWAY: n.gateway.address,
            AXELAR_GAS_RECEIVER: n.gasService.address,
        };
        const envContent = Object.entries(envVars)
            .map(([key, value]) => `${key}=${value}`)
            .join('\n');
        fs.writeFileSync('./axelar/out/.' + n.chainId, envContent);
    }
}

main().then().catch(console.error)
