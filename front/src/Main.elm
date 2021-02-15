module Main exposing (Model, init, Msg, update, view, subscriptions)

import Html exposing (..)
import Html.Attributes exposing (..)
import Browser
import Browser.Navigation as Nav
import Url

import View
import IndexPage.View

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


type alias Model =
    { key : Nav.Key
    , url : Url.Url
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
    { title = "detox-proxy"
    , body =
        [ View.headerView
        , div [ class "content" ]
            IndexPage.View.view
        ]
    }
