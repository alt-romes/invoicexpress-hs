module InvoiceXpress.Types.FullDocumentObject where
import qualified Data.Aeson
import qualified InvoiceXpress.Common
data FullDocumentObject
instance Show FullDocumentObject
instance Eq FullDocumentObject
instance Data.Aeson.FromJSON FullDocumentObject
instance Data.Aeson.ToJSON FullDocumentObject
