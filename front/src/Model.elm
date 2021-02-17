module Model exposing (..)

import Browser.Navigation as Nav
import Url
import Url.Parser


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    }



type Route
    = IndexPage
    | LoginPage
    | RegistPage



-- FUNC

routeParser: Url.Parser.Parser (Route -> a) a
routeParser =
    Url.Parser.oneOf
        [ Url.Parser.map IndexPage Url.Parser.top
        , Url.Parser.map LoginPage (Url.Parser.s "login")
        , Url.Parser.map RegistPage (Url.Parser.s "regist")
        ]
