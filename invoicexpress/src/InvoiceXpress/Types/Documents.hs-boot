module InvoiceXpress.Types.Documents where
import qualified Data.Aeson
import qualified InvoiceXpress.Common
data Documents
instance Show Documents
instance Eq Documents
instance Data.Aeson.FromJSON Documents
instance Data.Aeson.ToJSON Documents
data DocumentsErrors
instance Show DocumentsErrors
instance Eq DocumentsErrors
instance Data.Aeson.FromJSON DocumentsErrors
instance Data.Aeson.ToJSON DocumentsErrors
