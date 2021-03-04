module Model exposing (..)

import Browser.Navigation as Nav
import Url
import Url.Parser

import UserPage.Model


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , userPage: UserPage.Model.UserPageModel
    }



type Route
    = IndexPage


-- FUNC


initModel : Url.Url -> Nav.Key -> Model
initModel url key =
    Model key url
        UserPage.Model.initUserPageModel


routeParser: Url.Parser.Parser (Route -> a) a
routeParser =
    Url.Parser.oneOf
        [ Url.Parser.map IndexPage Url.Parser.top ]
