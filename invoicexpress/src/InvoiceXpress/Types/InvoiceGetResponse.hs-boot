module InvoiceXpress.Types.InvoiceGetResponse where
import qualified Data.Aeson
import qualified InvoiceXpress.Common
data InvoiceGetResponse
instance Show InvoiceGetResponse
instance Eq InvoiceGetResponse
instance Data.Aeson.FromJSON InvoiceGetResponse
instance Data.Aeson.ToJSON InvoiceGetResponse
