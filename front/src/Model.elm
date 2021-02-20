module Model exposing (..)

import Browser.Navigation as Nav
import Url
import Url.Parser

import RegistPage.Model
import LoginPage.Model
import UserPage.Model


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , registPage: RegistPage.Model.RegistPageModel
    , loginPage: LoginPage.Model.LoginPageModel
    , userPage: UserPage.Model.UserPageModel
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
        UserPage.Model.initUserPageModel


routeParser: Url.Parser.Parser (Route -> a) a
routeParser =
    Url.Parser.oneOf
        [ Url.Parser.map IndexPage Url.Parser.top
        , Url.Parser.map LoginPage (Url.Parser.s "login")
        , Url.Parser.map RegistPage (Url.Parser.s "regist")
        ]
