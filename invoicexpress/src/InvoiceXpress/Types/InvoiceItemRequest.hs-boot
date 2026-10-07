module InvoiceXpress.Types.InvoiceItemRequest where
import qualified Data.Aeson
import qualified InvoiceXpress.Common
data InvoiceItemRequest
instance Show InvoiceItemRequest
instance Eq InvoiceItemRequest
instance Data.Aeson.FromJSON InvoiceItemRequest
instance Data.Aeson.ToJSON InvoiceItemRequest
