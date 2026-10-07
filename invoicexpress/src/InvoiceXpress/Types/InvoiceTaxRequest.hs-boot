module InvoiceXpress.Types.InvoiceTaxRequest where
import qualified Data.Aeson
import qualified InvoiceXpress.Common
data InvoiceTaxRequest
instance Show InvoiceTaxRequest
instance Eq InvoiceTaxRequest
instance Data.Aeson.FromJSON InvoiceTaxRequest
instance Data.Aeson.ToJSON InvoiceTaxRequest
