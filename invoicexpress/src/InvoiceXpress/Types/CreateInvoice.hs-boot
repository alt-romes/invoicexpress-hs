module InvoiceXpress.Types.CreateInvoice where
import qualified Data.Aeson
import qualified InvoiceXpress.Common
data CreateInvoice
instance Show CreateInvoice
instance Eq CreateInvoice
instance Data.Aeson.FromJSON CreateInvoice
instance Data.Aeson.ToJSON CreateInvoice
data CreateInvoiceErrors
instance Show CreateInvoiceErrors
instance Eq CreateInvoiceErrors
instance Data.Aeson.FromJSON CreateInvoiceErrors
instance Data.Aeson.ToJSON CreateInvoiceErrors
