module InvoiceXpress.Types.InvoiceClient where
import qualified Data.Aeson
import qualified InvoiceXpress.Common
data InvoiceClient
instance Show InvoiceClient
instance Eq InvoiceClient
instance Data.Aeson.FromJSON InvoiceClient
instance Data.Aeson.ToJSON InvoiceClient
