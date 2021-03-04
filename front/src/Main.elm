-- Copyright (c) 2021 Hiroki Takemura (kekeho)

-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT

module Main exposing (init)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Browser
import Browser.Navigation as Nav
import Url

import View
import Model exposing (..)
import UserPage.UserPage
import UserPage.View
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
    ( initModel url key
    , Cmd.map UserPageMsg UserPage.UserPage.getBlockAddressList
    )


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | UserPageMsg UserPage.UserPage.UserPageMsg


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

        UserPageMsg subMsg ->
            let
                (userModel, subCmd) =
                    UserPage.UserPage.update subMsg model.userPage
            in
            ( { model | userPage = userModel }
            , Cmd.map UserPageMsg subCmd
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
                    UserPage.View.view model.userPage
                        |> map UserPageMsg
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
