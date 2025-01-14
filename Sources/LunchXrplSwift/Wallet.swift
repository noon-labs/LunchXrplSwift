//
//  Wallet.swift
//  LunchXrplSwift
//
//  Created by 한상범 on 12/27/24.
//

import Foundation
import XRPLSwift

public enum Servers: String {
    case devnet = "wss://s.devnet.rippletest.net:51233/"
    case testnet = "wss://s.altnet.rippletest.net:51233/"
    case mainnet = "wss://xrplcluster.com:443/"
}

public enum WalletError: Error {
    case NoResult
    case TxError(code: String, msg: String)
    case TxTimeout
    case NotFound
}

let DEFAULT_RETRY_COUNT = 1...20
let DEFAULT_RETRY_INTERVAL: UInt64 = 1
let TRN_BRIDGE_DEPOSIT_ADDRESS = "rPotpackAV39ysG1cyprYDa6ambUAPtKHk"
let TRN_BRIDGE_DEPOSIT_ADDRESS_ALTNET = "rnZiKvrWFGi2JfHtLS8kxcqCqVhch6W5k5"

public struct Wallet {
    public var keyPairs: XRPLSwift.Wallet
    public var client: XrplClient!
    
    public init(_ wallet: XRPLSwift.Wallet, _ node: String = Servers.devnet.rawValue) {
        self.keyPairs = wallet
        self.client = try! XrplClient(server: node)
    }
    
    public static func generateWallet(node: String = Servers.devnet.rawValue) throws -> (String, Wallet) {
        let mnemonics = try Bip39Mnemonic.create(strength: .hight)
        let wallet = try self.fromMnemonics(mnemonics: mnemonics, node: node)
        
        return (mnemonics, wallet)
    }
    
    public static func fromMnemonics(mnemonics: String, node: String = Servers.devnet.rawValue) throws -> Wallet {
        let wallet = try XRPLSwift.Wallet.fromMnemonic(
            mnemonics,
            MnemonicOptions(derivationPath: DerivationPath(), algorithm: .secp256k1)
        )
        
        return Wallet(wallet, node)
    }
    
    public static func fromSeed(seed: String, node: String = Servers.devnet.rawValue) -> Wallet {
        return Wallet(XRPLSwift.Wallet.fromSeed(seed), node)
    }
    
    public static func validateMnemonics(mnemonics: String) throws {
        try XRPLSwift.Bip39Mnemonic.validateMnemonics(mnemonics)
    }
    
    public func disconnect() async throws {
        _ = try await self.client.disconnect().get()
    }
    
    public func getAccountInfo(address: String? = nil) async throws -> AccountInfoResponse {
        if self.client.connection.ws == nil {
            _ = try await self.client.connect().get()
        }
        
        guard let eventLoop = self.client.connection.ws?.eventLoop else {
            throw WalletError.NotFound
        }
        
        let promise = eventLoop.makePromise(of: AccountInfoResponse.self)
        
        eventLoop.execute {
            Task {
                do {
                    if !self.client.isConnected() {
                        _ = try await self.client.connect().get()
                    }
                    
                    let xrpAddress = address ?? self.keyPairs.classicAddress
                    let accInfo = AccountInfoRequest(
                        account: xrpAddress,
                        queue: true,
                        strict: true
                    )
                    
                    guard let resp = try await self.client.request(r: accInfo).get() as? BaseResponse<AccountInfoResponse>,
                          let result = resp.result else {
                        throw WalletError.NoResult
                    }
                    
                    promise.succeed(result)
                } catch {
                    promise.fail(error)
                }
            }
        }
        
        return try await promise.futureResult.get()
    }
    
    public func getAccountLines(address: String? = nil, peer: String? = nil) async throws -> AccountLinesResponse {
        if self.client.connection.ws == nil {
            _ = try await self.client.connect().get()
        }
        
        guard let eventLoop = self.client.connection.ws?.eventLoop else {
            throw WalletError.NotFound
        }
        
        let promise = eventLoop.makePromise(of: AccountLinesResponse.self)
        
        eventLoop.execute {
            Task {
                do {
                    if !self.client.isConnected() {
                        _ = try await self.client.connect().get()
                    }
                    
                    let xrpAddress = address ?? self.keyPairs.classicAddress
                    let accLines = AccountLinesRequest(account: xrpAddress, peer: peer)
                    
                    guard let resp = try await self.client.request(r: accLines).get() as? BaseResponse<AccountLinesResponse>,
                          let result = resp.result else {
                        throw WalletError.NoResult
                    }
                    
                    promise.succeed(result)
                } catch {
                    promise.fail(error)
                }
            }
        }
        return try await promise.futureResult.get()
    }
    // TODO(KUSH): Use AccountCurrenciesRequest
    public func getTokensOfAccount(address: String?) async throws -> AccountObjectsResponse {
        if self.client.connection.ws == nil {
            _ = try await self.client.connect().get()
        }
        
        guard let eventLoop = self.client.connection.ws?.eventLoop else {
            throw WalletError.NotFound
        }
        
        let promise = eventLoop.makePromise(of: AccountObjectsResponse.self)
        
        eventLoop.execute {
            Task {
                do {
                    if !self.client.isConnected() {
                        _ = try await self.client.connect().get()
                    }
                    
                    let xrpAddress = address ?? self.keyPairs.classicAddress
                    let req = AccountObjectsRequest(account: xrpAddress)
                    
                    guard let resp = try await self.client.request(r: req).get() as? BaseResponse<AccountObjectsResponse>,
                          let result = resp.result else {
                        throw WalletError.NoResult
                    }
                    
                    promise.succeed(result)
                } catch {
                    promise.fail(error)
                }
            }
        }
        
        return try await promise.futureResult.get()
    }
    
    public func getNftListOfAccount(address: String?) async throws -> AccountNFTsResponse {
        if !self.client.isConnected() {
            _ = try await self.client.connect().get()
        }
        
        let xrpAddress = address ?? self.keyPairs.classicAddress
        
        let req = AccountNFTsRequest(account: xrpAddress)
        guard let resp = try? await self.client.request(r: req).get() as? BaseResponse<AccountNFTsResponse>,
              let result = resp.result else { throw WalletError.NoResult }
        
        return result
    }
    
    public func getUserTx(address: String?) async throws -> AccountTxResponse {
        if !self.client.isConnected() {
            _ = try await self.client.connect().get()
        }
        
        let xrpAddress = address ?? self.keyPairs.classicAddress
        
        let req = AccountTxRequest(account: xrpAddress)
        guard let resp = try await self.client.request(r: req).get() as? BaseResponse<AccountTxResponse>,
              let result = resp.result else { throw WalletError.NoResult }
        
        return result
    }
    
    /**
     amount
     - type string: Native XRP
     - type IssuedCurrencyAmount: non-native custom token
     to: target address
     destinationTag: (optional) only use when the send tx is for the CEX deposit
     memo: (optional) tx memo
     */
    public func sendToken(
        amount: Amount,
        to: String,
        destinationTag: Int? = nil,
        memo: String? = nil
    ) async throws -> (String, SubmitResponse) {
        let tx = Payment(
            amount: amount,
            destination: to,
            destinationTag: destinationTag
        )
        
        return try await self.sendTransaction(tx: tx, memo: memo)
    }
    
    public func sendNFTSendRequest(
        nfTokenId: String,
        to: String,
        memo: String? = nil
    ) async throws -> (String, SubmitResponse){
        let tx = NFTokenCreateOffer(
            nftokenId: nfTokenId,
            amount: .string("0"),
            owner: self.keyPairs.classicAddress,
            destination: to
        )
        
        return try await self.sendTransaction(tx: tx, memo: memo)
    }
    
    public func checkNFTSendOfferId(txHash: String) async throws -> String {
        if !self.client.isConnected() {
            _ = try await self.client.connect().get()
        }
        
        let req = AccountObjectsRequest(account: self.keyPairs.classicAddress, type: .nftOffer, deletionBlockersOnly: false)
        guard let resp = try await self.client.request(r: req).get() as? BaseResponse<AccountObjectsResponse>,
              let result = resp.result else { throw WalletError.NoResult }
        
        let nftOfferLists = result.accountObjects
        
        for unitOffer in nftOfferLists {
            guard let offer: LENFTOffer = unitOffer.toAny() as? LENFTOffer else {
                continue
            }
            
            if offer.previousTxnId == txHash {
                return offer.index
            }
        }
        
        throw WalletError.NotFound
    }
    
    // TODO: need implement below 2 off-chain methods
    //    public func recordNFTOfferIntoBackend(
    //        nfTokenId: String,
    //        to: String
    //    ) async throws {
    //
    //    }
    
    //    public func retrieveArrivedNFTList() async throws -> [String: String]{
    //
    //    }
    
    public func receiveNFT(
        nfTokenOfferId: String,
        memo: String? = nil
    ) async throws -> (String, SubmitResponse) {
        let tx = NFTokenAcceptOffer(nftokenSellOffer: nfTokenOfferId)
        return try await self.sendTransaction(tx: tx, memo: memo)
    }
    
    public func sendXrpToRootNetwork(
        amount: String, // Decimal 6, integer-like string
        trnAddress: String, // 0xFFFF....1200
        depositAddress: String? = nil
    ) async throws -> (String, SubmitResponse) {
        // deposit address may be frequently changed
        // in Aug 30 2024, the AltNet bridge is connected via TRN_BRIDGE_DEPOSIT_ADDRESS_ALTNET
        // you may use this constant
        let destination = depositAddress ?? TRN_BRIDGE_DEPOSIT_ADDRESS
        let tx = Payment(
            amount: .string(amount),
            destination: destination
        )
        
        let bridgeMemo = Memo(trnAddress.strToHex(), "Address".strToHex(), nil)
        tx.memos = [MemoWrapper(bridgeMemo)]
        
        return try await self.sendTransaction(tx: tx)
    }
    
    // addCurrency == TrustSet transaction
    // setTrustLine == make this asset receivable in my wallet
    // In XRPL, the fungible token should be allowed in my wallet first
    public func addCurrency(
        assetIssuerAddress: String,
        currency: String,
        memo: String? = nil
    ) async throws -> (String, SubmitResponse) {
        let trustSetFlags = TrustSetFlagsInterface(tfSetNoRipple: true, tfClearFreeze: true)
        let tx = TrustSet(
            limitAmount: IssuedCurrencyAmount(value: "9999999999999999", issuer: assetIssuerAddress, currency: currency),
            flags: trustSetFlags
        )
        
        return try await self.sendTransaction(tx: tx, memo: memo)
    }
    
    public func removeCurrency(
        assetIssuerAddress: String,
        currency: String,
        memo: String? = nil
    ) async throws -> (String, SubmitResponse) {
        let trustSetFlags = TrustSetFlagsInterface(tfSetNoRipple: true, tfClearFreeze: true)
        let tx = TrustSet(
            limitAmount: IssuedCurrencyAmount(value: "0", issuer: assetIssuerAddress, currency: currency),
            flags: trustSetFlags
        )

        return try await self.sendTransaction(tx: tx, memo: memo)
    }
    
    public func terminateAccount(
        depositHolder: String,
        memo: String? = nil
    ) async throws -> (String, SubmitResponse) {
        let tx = AccountDelete(destination: depositHolder)
        return try await self.sendTransaction(tx: tx, memo: memo)
    }
    
    public func sendTransaction(
        tx: BaseTransaction,
        memo: String? = nil
    ) async throws -> (String, SubmitResponse) {
        if !self.client.isConnected() {
            _ = try await self.client.connect().get()
        }
        
        tx.account = self.keyPairs.classicAddress
        
        if let memo  {
            let memo = Memo(
                memo.strToHex(),
                "Description".strToHex(),
                "text/plain".strToHex()
            )
            
            tx.memos = [MemoWrapper(memo)]
        }
        
        let txData = try JSONEncoder().encode(tx)
        let jsonTx = try JSONSerialization.jsonObject(with: txData, options: .mutableLeaves) as! [String: AnyObject]
        
        let filledTx = try await AutoFillSugar().autofill(self.client, jsonTx, 0).get()
        let signedTx = try self.keyPairs.sign(filledTx)
        
        // don't have to sign
        // submit method will sign on behalf of me
        let resp = try await self.client.submit(
            transaction: signedTx.txBlob,
            opts: SubmitOptions(
                autofill: true,
                failHard: false,
                wallet: self.keyPairs
            )
        ).get() as? BaseResponse<SubmitResponse>
        
        guard let resp,
              let result = resp.result else { throw WalletError.NoResult }
        
        
        let prelimRes = result.engineResult
        
        if prelimRes.hasPrefix("tem") {
            let errMsg = resp.result!.engineResultMessage
            throw WalletError.TxError(code: prelimRes, msg: errMsg)
        }
        
        return (signedTx.hash, result)
    }
    
    public func checkTx(txHash: String) async throws -> Bool {
        if !self.client.isConnected() {
            _ = try await self.client.connect().get()
        }
        
        let req = TxRequest(transaction: txHash, binary: false)
        
        debugPrint("finding for hash", txHash)
        
        for _ in DEFAULT_RETRY_COUNT {
            try await Task.sleep(nanoseconds: DEFAULT_RETRY_INTERVAL * 1_000_000_000)
            
            let resp = try await self.client.request(req: req)?.get()
            
            // if the tx can found, check whether it is succeeded of not
            if let res = resp as? BaseResponse<TxResponse> {
                
                guard let result = res.result else {
                    throw WalletError.NoResult
                }
                
                if let validated = result.validated,
                   validated, let meta = result.meta {
                    if meta.transactionResult == "tesSUCCESS" {
                        return true
                    } else {
                        return false
                    }
                }
            } else {
                debugPrint("retrying...")
                continue
            }
        }
        
        throw WalletError.TxTimeout
    }
    
    public func getServerInfo() async throws -> BaseResponse<ServerInfoResponse>? {
        if !self.client.isConnected() {
            _ = try await self.client.connect().get()
        }
        guard let eventLoop = self.client.connection.ws?.eventLoop else {
            throw WalletError.NotFound
        }
        
        let promise = eventLoop.makePromise(of: Optional<BaseResponse<ServerInfoResponse>>.self)
        
        eventLoop.execute {
            Task {
                do {
                    if !self.client.isConnected() {
                        _ = try await self.client.connect().get()
                    }
                    
                    let request = ServerInfoRequest()
                    let response = try await self.client.request(r: request).get()
                    let result = response as? BaseResponse<ServerInfoResponse>
                    
                    promise.succeed(result)
                } catch {
                    promise.fail(error)
                }
            }
        }
        
        return try await promise.futureResult.get()
    }
}
