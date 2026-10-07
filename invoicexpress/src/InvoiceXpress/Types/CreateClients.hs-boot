module InvoiceXpress.Types.CreateClients where
import qualified Data.Aeson
import qualified InvoiceXpress.Common
data CreateClients
instance Show CreateClients
instance Eq CreateClients
instance Data.Aeson.FromJSON CreateClients
instance Data.Aeson.ToJSON CreateClients
