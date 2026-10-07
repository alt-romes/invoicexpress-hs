module InvoiceXpress.OpenAPI.Types.Pagination where
import qualified Data.Aeson
import qualified InvoiceXpress.OpenAPI.Common
data Pagination
instance Show Pagination
instance Eq Pagination
instance Data.Aeson.FromJSON Pagination
instance Data.Aeson.ToJSON Pagination
