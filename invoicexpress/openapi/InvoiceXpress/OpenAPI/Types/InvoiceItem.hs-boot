module InvoiceXpress.OpenAPI.Types.InvoiceItem where
import qualified Data.Aeson
import qualified InvoiceXpress.OpenAPI.Common
data InvoiceItem
instance Show InvoiceItem
instance Eq InvoiceItem
instance Data.Aeson.FromJSON InvoiceItem
instance Data.Aeson.ToJSON InvoiceItem
data InvoiceItemTax
instance Show InvoiceItemTax
instance Eq InvoiceItemTax
instance Data.Aeson.FromJSON InvoiceItemTax
instance Data.Aeson.ToJSON InvoiceItemTax
