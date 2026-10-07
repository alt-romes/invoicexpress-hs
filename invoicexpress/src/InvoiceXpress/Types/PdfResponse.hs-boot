module InvoiceXpress.Types.PdfResponse where
import qualified Data.Aeson
import qualified InvoiceXpress.Common
data PdfResponse
instance Show PdfResponse
instance Eq PdfResponse
instance Data.Aeson.FromJSON PdfResponse
instance Data.Aeson.ToJSON PdfResponse
data PdfResponseOutput
instance Show PdfResponseOutput
instance Eq PdfResponseOutput
instance Data.Aeson.FromJSON PdfResponseOutput
instance Data.Aeson.ToJSON PdfResponseOutput
