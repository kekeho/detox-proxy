-- Copyright (c) 2021 Hiroki Takemura (kekeho)

-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT

module LoginPage.LoginPage exposing (..)

import Http
import Browser.Navigation as Nav

import LoginPage.Model exposing (..)


type InputEvent
    = Username String
    | Password String
    | Remember Bool
    | SubmitForm


type LoginPageMsg
    = FormInput InputEvent
    | GotLoginResult (Result Http.Error ())



update : Nav.Key -> LoginPageMsg -> LoginPageModel ->  ( LoginPageModel, Cmd LoginPageMsg )
update key msg model =
    case msg of
        FormInput event ->
            case event of
                Username u ->
                    ( { model | username = u }
                    , Cmd.none 
                    )
                
                Password p ->
                    ( { model | password = p }
                    , Cmd.none
                    )
                
                Remember b ->
                    ( { model | remember = b }
                    , Cmd.none
                    )
                
                SubmitForm ->
                    ( model, loginRequest model )

        GotLoginResult result ->
            case result of
                Ok () ->
                    ( { model | result = Just result }
                    , Nav.load "/"
                    )
                
                Err _ ->
                    ( { model | result = Just result }
                    , Cmd.none
                    )

-- CMD

loginRequest : LoginPageModel -> Cmd LoginPageMsg
loginRequest model =
    Http.post
        { url = "/api/user/login"
        , body = Http.jsonBody <| loginModelEncoder model
        , expect = Http.expectWhatever GotLoginResult
        }
