module Main exposing (init)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Browser
import Browser.Navigation as Nav
import Url

import View
import Model exposing (..)
import IndexPage.View
import LoginPage.View
import RegistPage.RegistPage
import RegistPage.Model
import RegistPage.View
import LoginPage.LoginPage
import Url.Parser
import Html

main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
    }


init : () -> Url.Url -> Nav.Key -> (Model, Cmd Msg)
init () url key =
    (initModel url key, Cmd.none)


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | RegistPageMsg RegistPage.RegistPage.RegistPageMsg
    | LoginPageMsg LoginPage.LoginPage.LoginPageMsg


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        UrlRequested urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( { model | url = url }
            , Cmd.none
            )
        
        RegistPageMsg subMsg ->
            let
                (registModel, subCmd) =
                    RegistPage.RegistPage.update subMsg model.registPage
            in
            ( { model | registPage = registModel }
            , Cmd.map RegistPageMsg subCmd
            )
        
        LoginPageMsg subMsg ->
            let
                (loginModel, subCmd) =
                    LoginPage.LoginPage.update subMsg model.loginPage
            in
            ( { model | loginPage = loginModel }
            , Cmd.map LoginPageMsg subCmd
            )
            


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Browser.Document Msg
view model =
    let
        map : (a -> msg) -> (String, List (Html a)) -> (String, List (Html msg))
        map msg (cls, view_) =
            ( cls
            , List.map (Html.map msg) view_
            )

        (c, v) =
            case (Url.Parser.parse Model.routeParser model.url) of
                Just IndexPage ->
                    IndexPage.View.view
                Just LoginPage ->
                    LoginPage.View.view model.loginPage
                        |> map LoginPageMsg
                Just RegistPage ->
                    RegistPage.View.view model.registPage
                        |> \(c_, v_) ->
                            ( c_
                            , List.map (Html.map RegistPageMsg) v_
                            )
                Nothing ->
                    View.notFoundView
    in
    { title = "detox-proxy"
    , body =
        [ View.headerView
        , ( div [ class ("content " ++ c) ] v )
        , View.footerView
        ]
    }
