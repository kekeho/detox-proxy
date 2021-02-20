module Model exposing (..)

import Browser.Navigation as Nav
import Url
import Url.Parser

import RegistPage.Model
import LoginPage.Model


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , registPage: RegistPage.Model.RegistPageModel
    , loginPage: LoginPage.Model.LoginPageModel
    }



type Route
    = IndexPage
    | LoginPage
    | RegistPage



-- FUNC


initModel : Url.Url -> Nav.Key -> Model
initModel url key =
    Model key url
        RegistPage.Model.initModel
        LoginPage.Model.initLoginPageModel



routeParser: Url.Parser.Parser (Route -> a) a
routeParser =
    Url.Parser.oneOf
        [ Url.Parser.map IndexPage Url.Parser.top
        , Url.Parser.map LoginPage (Url.Parser.s "login")
        , Url.Parser.map RegistPage (Url.Parser.s "regist")
        ]
