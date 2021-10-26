module FakePAB.Address (
  toPubKeyAddress,
  fromPubKeyAddress,
  PubKeyAddress,
  unsafeSerialiseAddress,
  unsafeDeserialiseAddress,
  serialiseAddress,
  deserialiseAddress,
) where

import Cardano.Api (AsType (AsAddressInEra, AsAlonzoEra))
import Cardano.Api qualified
import Config (Config)
import Data.Either.Combinators (mapLeft, maybeToRight)
import Data.Text (Text)
import Data.Text qualified as Text
import Ledger.Address (Address (..))
import Ledger.Credential (Credential (..), StakingCredential)
import Ledger.Crypto (PubKeyHash)
import Plutus.Contract.CardanoAPI (fromCardanoAddress, toCardanoAddress)
import Prelude

{- | Serialise an address to the bech32 form
 For more details on the different address types see: https://github.com/cardano-foundation/CIPs/blob/master/CIP-0019/CIP-0019.md
-}
serialiseAddress :: Config -> Address -> Either Text Text
serialiseAddress config address =
  mapLeft (const "Couldn't create address") $
    Cardano.Api.serialiseAddress
      <$> toCardanoAddress config.network address

unsafeSerialiseAddress :: Config -> Address -> Text
unsafeSerialiseAddress config address =
  either (error . Text.unpack) id $ serialiseAddress config address

deserialiseAddress :: Text -> Either Text Address
deserialiseAddress addr = do
  cardanoAddr <-
    maybeToRight "Couldn't deserialise address" $
      Cardano.Api.deserialiseAddress (AsAddressInEra AsAlonzoEra) addr

  mapLeft (const "Couldn't convert address") $ fromCardanoAddress cardanoAddr

unsafeDeserialiseAddress :: Text -> Address
unsafeDeserialiseAddress address =
  either (error . Text.unpack) id $ deserialiseAddress address

-- | PukKeyCredential only address type to prevent validating addresses after parsing
data PubKeyAddress = PubKeyAddress
  { pkaPubKeyHash :: PubKeyHash
  , pkaStakingCredential :: Maybe StakingCredential
  }
  deriving stock (Show)

toPubKeyAddress :: Address -> Maybe PubKeyAddress
toPubKeyAddress (Address cred stakingCred) =
  case cred of
    PubKeyCredential pkh -> Just $ PubKeyAddress pkh stakingCred
    ScriptCredential _ -> Nothing

fromPubKeyAddress :: PubKeyAddress -> Address
fromPubKeyAddress (PubKeyAddress pkh stakingCred) =
  Address (PubKeyCredential pkh) stakingCred
