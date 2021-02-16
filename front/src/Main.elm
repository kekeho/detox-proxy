module Main exposing (init)

import Html exposing (..)
import Html.Attributes exposing (..)
import Browser
import Browser.Navigation as Nav
import Url

import View
import Model exposing (..)
import IndexPage.View
import LoginPage.View
import Url.Parser

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
    (Model key url, Cmd.none)


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url


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


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Browser.Document Msg
view model =
    let
        (c, v) =
            case (Url.Parser.parse Model.routeParser model.url) of
                Just IndexPage ->
                    IndexPage.View.view
                Just LoginPage ->
                    LoginPage.View.view
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
