module InvoiceXpress.Types.MbReference where
import qualified Data.Aeson
import qualified InvoiceXpress.Common
data MbReference
instance Show MbReference
instance Eq MbReference
instance Data.Aeson.FromJSON MbReference
instance Data.Aeson.ToJSON MbReference
