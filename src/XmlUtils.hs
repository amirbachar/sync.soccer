module XmlUtils where

import qualified Data.ByteString as BS
import Text.XML.Light.Input (parseXMLDoc)
import Text.XML.Light.Types
    ( Element
    , Content(CRef, Text, Elem)
    , elContent
    , elAttribs
    , attrVal
    , attrKey
    , qName
    , elName
    )
import Control.Exception
import Control.Monad (liftM)
import Data.DateTime
import Data.Maybe
import Data.Typeable


data XmlFileError
    = ParserFailure
    | MissingData String
    deriving (Show, Typeable)

instance Exception XmlFileError

loadXmlFromFile :: String -> IO Element
loadXmlFromFile filepath = do
    xml <- BS.readFile filepath
    let result = parseXMLDoc xml
    case result of
        Just root -> return root
        Nothing -> throw ParserFailure

attrLookup :: Element -> (String -> a) -> String -> Maybe a
attrLookup el cast key =
    let
        makePair attr =
            ( qName $ attrKey attr
            , attrVal attr
            )
        val = lookup key $ map makePair (elAttribs el)
    in
    liftM cast val

attrLookupStrict :: Element -> (String -> a) -> String -> a
attrLookupStrict el cast key = let val = (attrLookup el cast key)
                               in maybe (throw $ MissingData key) id val


getAllChildren :: Element -> [ Element ]
getAllChildren = getChildren (const True)

getChildren :: (Element -> Bool) -> Element -> [Element]
getChildren cond el = let getElems :: [Content] -> [Element]
                          getElems [] = []
                          getElems ((Elem e):rest) = e:(getElems rest)
                          getElems ((Text _):rest) = getElems rest
                          getElems ((CRef _):rest) = getElems rest
                      in filter cond (getElems (elContent el))

qNameEquals :: String -> Element -> Bool
qNameEquals name element =
    (qName $ elName element) == name

getChildrenWithQName :: String -> Element -> [ Element ]
getChildrenWithQName name =
    getChildren (qNameEquals name)