module InvoiceXpress.Types.PaymentResponse where
import qualified Data.Aeson
import qualified InvoiceXpress.Common
data PaymentResponse
instance Show PaymentResponse
instance Eq PaymentResponse
instance Data.Aeson.FromJSON PaymentResponse
instance Data.Aeson.ToJSON PaymentResponse
