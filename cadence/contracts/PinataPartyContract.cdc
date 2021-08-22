pub contract PinataPartyContract  {
    pub resource NFT  {
        pub let id: UInt64

        init(initID: UInt64) {
            self.id = initID
        }
    }

    pub resource interface NFTReceiver {
        pub fun deposit(token: @NFT, metadata: {String : String})
        pub fun getIDs(): [UInt64]
        pub fun idExists(id: UInt64): Bool
        pub fun getMetaData(id: UInt64): {String : String}
    }

    
    /*
    * Function that creates an empty NFT collection when called. This is how a user who is first interacting with our contract will have a storage location created that maps to the Collection resource we defined.
    * */
    pub fun createEmptyCollection(): @Collection {
        return <- create Collection()
    }

    pub resource NFTMinter {
        pub var idCount: UInt64

        init() {
            self.idCount = 1
        }

        pub fun mintNFT(): @NFT {
            var newNFT <- create NFT(initID: self.idCount)

            self.idCount = self.idCount + 1 as UInt64

            return <- newNFT
        }
    }

    init() {
        // Creates an empty Collection for the deployer of the collection so that the owner of the contract can mint and own NFTs from that contract.
        self.account.save(<-self.createEmptyCollection(), to: /storage/NFTCollection)
        // The Collection resource is published in a public location with reference to the NFTReceiver interface we created at the beginning. This is how we tell the contract that the functions defined on the NFTReceiver can be called by anyone.
        self.account.link<&{NFTReceiver}>(/public/NFTReceiver, target: /storage/NFTCollection)
        // The NFTMinter resource is saved in account storage for the creator of the contract. This means only the creator of the contract can mint tokens.
        self.account.save(<-create NFTMinter(), to: /storage/NFTMinter)
    }

    pub resource Collection: NFTReceiver {
        // Specifies all the NFT this user owns in this contract
        pub var ownedNFTs: @{UInt64: NFT}
        // Maps a token id to its associated metadata
        pub var metadataObjs: {UInt64: {String : String}}

        init () {
            self.ownedNFTs <- {}
            self.metadataObjs = {}
        }

        pub fun withdraw(withdarID: UInt64): @NFT {
            let token <- self.ownedNFTs.remove(key: withdarID)!

            return <-token
        }

        pub fun deposit(token: @NFT, metadata: {String : String}) {
            self.metadataObjs[token.id] = metadata
            self.ownedNFTs[token.id] <-! token
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun idExists(id: UInt64): Bool {
            return self.ownedNFTs[id] != nil
        }

        pub fun updateMetaData(id: UInt64, metadata: {String: String}) {
            self.metadataObjs[id] = metadata
        }

        pub fun getMetaData(id: UInt64): {String: String} {
            return self.metadataObjs[id]!
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }
}
