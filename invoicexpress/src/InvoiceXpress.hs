{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OrPatterns #-}
{-# LANGUAGE OverloadedStrings #-}

-- | A small, declarative interface to InvoiceXpress.
--
-- Describe a 'Document' and 'issue' it:
--
-- > issue account (document Invoice (client "Mogbit, LLC") today (addDays 30 today) [item "Consultoria" "Outubro" 10 50 Isento])
-- >   {taxExemption = Just M40}
--
-- Failed requests throw an 'InvoiceXpressError'. For anything not covered here use
-- the generated bindings in "InvoiceXpress.OpenAPI" (package @invoicexpress:openapi@).
module InvoiceXpress
  ( -- * Account
    Account (..)
    -- * Documents
  , Document (..)
  , DocumentType (..)
  , Address (..)
  , document
  , Client (..)
  , client
  , Item (..)
  , item
  , Tax (..)
  , TaxExemption (..)
    -- * Operations
  , Stored (..)
  , draft
  , finalize
  , issue
  , pdfUrl
    -- * Errors
  , InvoiceXpressError (..)
  ) where

import Control.Exception (Exception, throwIO)
import Control.Monad (unless)
import Data.Text (Text, pack)
import qualified Data.Text as T
import Data.Time (Day, LocalTime, defaultTimeLocale, formatTime)
import Network.HTTP.Client (Response, responseBody)
import Numeric (showFFloat)

import InvoiceXpress.OpenAPI

-- | An InvoiceXpress account, i.e. @https://NAME.app.invoicexpress.com@, and its API key.
data Account = Account
  { accountName :: Text
  , apiKey :: Text
  }

data DocumentType
  = Invoice
  | InvoiceReceipt
  | SimplifiedInvoice
  | CreditNote
  | DebitNote
  -- | Guia de remessa: from, to and when the goods were loaded.
  | Shipping Address Address LocalTime
  deriving (Show, Eq)

data Address = Address
  { addressDetail :: Text
  , addressPostalCode :: Text
  , addressCity :: Text
  , addressCountry :: Text
  }
  deriving (Show, Eq)

data Document = Document
  { kind :: DocumentType
  , customer :: Client
  , date :: Day
  , dueDate :: Day
  , items :: [Item]
  -- | Required when some item is 'Isento'.
  , taxExemption :: Maybe TaxExemption
  -- | The invoice a credit or debit note refers to.
  , ownerInvoice :: Maybe Int
  , reference :: Maybe Text
  , observations :: Maybe Text
  }
  deriving (Show, Eq)

-- | @document type client date dueDate items@, with the remaining fields empty.
document :: DocumentType -> Client -> Day -> Day -> [Item] -> Document
document ty c day due is = Document ty c day due is Nothing Nothing Nothing Nothing

-- | Clients are matched by code, then by name (also when the code is unknown), and created if neither matches.
-- Set 'clientId' (from the client's page URL in the web app) to avoid ambiguous matches.
data Client = Client
  { clientName :: Text
  , clientId :: Maybe Int
  , clientCode :: Maybe Text
  , clientFiscalId :: Maybe Text
  , clientEmail :: Maybe Text
  , clientAddress :: Maybe Text
  , clientPostalCode :: Maybe Text
  , clientCity :: Maybe Text
  , clientCountry :: Maybe Text
  }
  deriving (Show, Eq)

client :: Text -> Client
client name = Client name Nothing Nothing Nothing Nothing Nothing Nothing Nothing Nothing

data Item = Item
  { itemName :: Text
  , itemDescription :: Text
  , itemQuantity :: Double
  , itemUnitPrice :: Double
  , itemTax :: Tax
  }
  deriving (Show, Eq)

-- | @item name description quantity unitPrice tax@
item :: Text -> Text -> Double -> Double -> Tax -> Item
item = Item

-- | Taxes are matched by name, so these must exist in the account.
data Tax = IVA23 | IVA22 | IVA16 | Isento
  deriving (Show, Eq, Enum, Bounded)

-- | IVA exemption reasons, as in the Tax Authority's table of exemption codes.
data TaxExemption
  = M01 | M02 | M04 | M05 | M06 | M07 | M09 | M10 | M11 | M12 | M13 | M14 | M15 | M16
  | M19 | M20 | M21 | M25 | M26 | M30 | M31 | M32 | M33 | M34 | M40 | M41 | M42 | M43
  | M44 | M45 | M46 | M99
  deriving (Show, Eq, Enum, Bounded)

-- | A document created in InvoiceXpress.
data Stored = Stored
  { storedType :: DocumentType
  , storedId :: Int
  , storedPermalink :: Maybe Text
  }
  deriving (Show, Eq)

newtype InvoiceXpressError = InvoiceXpressError String
  deriving (Show)

instance Exception InvoiceXpressError

-- | Create a document as a draft.
--
-- Fails before sending anything if a field exceeds InvoiceXpress' length limits.
draft :: Account -> Document -> IO Stored
draft acc doc = do
  unless (null (limits doc)) $ throwIO (InvoiceXpressError (unlines (limits doc)))
  create acc doc

-- | Field length limits, beyond which InvoiceXpress truncates or rejects values.
limits :: Document -> [String]
limits doc = concat $
  [ tooLong "client name" 100 (clientName c)
  , foldMap (tooLong "client email" 254) (clientEmail c)
  , foldMap (tooLong "reference" 255) (reference doc)
  ] ++
  [ tooLong "item name" 60 (itemName i) ++ tooLong "item description" 200 (itemDescription i)
      ++ [ "item description has more than 20 lines: " <> show (itemDescription i) | length (T.lines (itemDescription i)) > 20 ]
  | i <- items doc ]
  where
    c = customer doc
    tooLong what n t = [ what <> " longer than " <> show n <> " characters: " <> show t | T.length t > n ]

create :: Account -> Document -> IO Stored
create acc doc = case kind doc of
  Shipping from to loaded ->
    call acc (createGuide (mkCreateGuideParameters (CreateGuideParametersPathGuidesTypeTyped path) (apiKey acc))
                          (mkGuideCreateRequest (shipping from to loaded))) >>= \case
      CreateGuideResponse201 GuideGetResponse {guideGetResponseShipping = Just s}
        | Just i <- guideGetResponseShippingId s -> pure (Stored (kind doc) i (guideGetResponseShippingPermalink s))
      other -> failure other
  (Invoice; InvoiceReceipt; SimplifiedInvoice; CreditNote; DebitNote) ->
    call acc (createInvoice (mkCreateInvoiceParameters (CreateInvoiceParametersPathInvoicesTypeTyped path) (apiKey acc))
                            (mkInvoiceCreateRequest invoice)) >>= \case
      CreateInvoiceResponse201 InvoiceGetResponse {invoiceGetResponseInvoice = Just d}
        | Just i <- fullDocumentObjectId d -> pure (Stored (kind doc) i (fullDocumentObjectPermalink d))
      other -> failure other
  where
    path = typePath (kind doc)
    c = customer doc
    invoice = (mkCreateBody docClient (formatDay (date doc)) (formatDay (dueDate doc)) (map invoiceItem (items doc)))
      { createBodyTaxExemption = showT <$> taxExemption doc
      , createBodyOwnerInvoiceId = ownerInvoice doc
      , createBodyReference = reference doc
      , createBodyObservations = observations doc
      }
    docClient = mkDocumentClientRequest
      { documentClientRequestName = Just (clientName c)
      , documentClientRequestId = clientId c
      , documentClientRequestCode = clientCode c
      , documentClientRequestFiscalId = clientFiscalId c
      , documentClientRequestEmail = clientEmail c
      , documentClientRequestAddress = clientAddress c
      , documentClientRequestPostalCode = clientPostalCode c
      , documentClientRequestCity = clientCity c
      , documentClientRequestCountry = clientCountry c
      }
    invoiceItem (Item n d q p t) = (mkInvoiceItemRequest d n q p)
      {invoiceItemRequestTax = Just mkInvoiceTaxRequest {invoiceTaxRequestName = Just (showT t)}}
    shipping (Address fd fp fc fco) (Address td tp tc tco) loaded =
      (mkGuideCreateRequestShipping
        (mkGuideCreateRequestShippingAddressFrom fc fco fd fp)
        (mkGuideCreateRequestShippingAddressTo tc tco td tp)
        guideClient (formatDay (date doc)) (formatDay (dueDate doc)) (map guideItem (items doc))
        (pack (formatTime defaultTimeLocale "%d/%m/%Y %H:%M:%S" loaded)))
        { guideCreateRequestShippingTaxExemption = showT <$> taxExemption doc
        , guideCreateRequestShippingReference = reference doc
        , guideCreateRequestShippingObservations = observations doc
        }
    guideClient = mkGuideCreateRequestShippingClient
      { guideCreateRequestShippingClientName = Just (clientName c)
      , guideCreateRequestShippingClientId = clientId c
      , guideCreateRequestShippingClientCode = clientCode c
      , guideCreateRequestShippingClientFiscalId = clientFiscalId c
      , guideCreateRequestShippingClientEmail = clientEmail c
      , guideCreateRequestShippingClientAddress = clientAddress c
      , guideCreateRequestShippingClientPostalCode = clientPostalCode c
      , guideCreateRequestShippingClientCity = clientCity c
      , guideCreateRequestShippingClientCountry = clientCountry c
      }
    guideItem (Item n d q p t) = (mkGuideCreateRequestShippingItems d n (decimal q) (decimal p))
      {guideCreateRequestShippingItemsTax = Just mkGuideCreateRequestShippingItemsTax {guideCreateRequestShippingItemsTaxName = Just (showT t)}}

-- | Finalize a draft, assigning it its sequence number.
finalize :: Account -> Stored -> IO ()
finalize acc (Stored ty i _) = case ty of
  Shipping {} ->
    call acc (changeGuideState (mkChangeGuideStateParameters i (ChangeGuideStateParametersPathGuidesTypeTyped (typePath ty)) (apiKey acc))
      (mkChangeStateGuideRequest (mkChangeStateGuideRequestShipping ChangeStateGuideRequestShippingStateEnumFinalized))) >>= \case
      ChangeGuideStateResponse200 _ -> pure ()
      other -> failure other
  (Invoice; InvoiceReceipt; SimplifiedInvoice; CreditNote; DebitNote) ->
    call acc (changeInvoiceState (mkChangeInvoiceStateParameters i (ChangeInvoiceStateParametersPathInvoicesTypeTyped (typePath ty)) (apiKey acc))
      (mkChangeStateInvoiceRequest (mkChangeStateInvoiceRequestInvoice ChangeStateInvoiceRequestInvoiceStateEnumFinalized))) >>= \case
      ChangeInvoiceStateResponse200 _ -> pure ()
      other -> failure other

-- | Create and finalize a document.
issue :: Account -> Document -> IO Stored
issue acc doc = do
  s <- draft acc doc
  finalize acc s
  pure s

-- | The URL of the document's PDF, or 'Nothing' if it is still being generated.
pdfUrl :: Account -> Stored -> IO (Maybe Text)
pdfUrl acc s = call acc (generatePdf (mkGeneratePdfParameters (storedId s) (apiKey acc))) >>= \case
  GeneratePdfResponse200 PdfResponse {pdfResponseOutput = Just o} -> pure (pdfResponseOutputPdfUrl o)
  GeneratePdfResponse202 -> pure Nothing
  other -> failure other

typePath :: DocumentType -> Text
typePath = \case
  Invoice -> "invoices"
  InvoiceReceipt -> "invoice_receipts"
  SimplifiedInvoice -> "simplified_invoices"
  CreditNote -> "credit_notes"
  DebitNote -> "debit_notes"
  Shipping {} -> "shippings"

call :: Account -> ClientM (Response a) -> IO a
call acc = fmap responseBody . runWithConfiguration config
  where config = defaultConfiguration {configBaseURL = "https://" <> accountName acc <> ".app.invoicexpress.com"}

failure :: Show a => a -> IO b
failure = throwIO . InvoiceXpressError . show

formatDay :: Day -> Text
formatDay = pack . formatTime defaultTimeLocale "%d/%m/%Y"

showT :: Show a => a -> Text
showT = pack . show

decimal :: Double -> Text
decimal x = pack (showFFloat Nothing x "")
