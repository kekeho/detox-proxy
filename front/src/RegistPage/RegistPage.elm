-- Copyright (c) 2021 Hiroki Takemura (kekeho)

-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT

module RegistPage.RegistPage exposing (..)

import Http
import RegistPage.Model exposing (..)
import UserPage.Model exposing (..)



type InputEvent
    = UserName String
    | Email String
    | Password String
    | TeamOfService Bool
    | SubmitForm


type RegistPageMsg
    = FormInput InputEvent
    | GotRegistStatus (Result Http.Error User)


update : RegistPageMsg -> RegistPageModel -> (RegistPageModel, Cmd RegistPageMsg)
update msg model =
    case msg of
        FormInput event ->
            case event of
                UserName username ->
                    ( { model | username = username }
                    , Cmd.none
                    )
                
                Email email ->
                    ( { model | email = email }
                    , Cmd.none
                    )
                
                Password pw ->
                    ( { model | password = pw }
                    , Cmd.none
                    )
                
                TeamOfService v ->
                    ( { model | teamOfServiceAccept = v }
                    , Cmd.none
                    )
                
                SubmitForm ->
                    ( model
                    , createUserRequest model
                    )

        GotRegistStatus result ->
            case result of
                Ok _ ->
                    ( { initModel | result = Just result }
                    , Cmd.none
                    )
                Err _ ->
                    ( { model | result = Just result }
                    , Cmd.none
                    )


-- CMD

createUserRequest : RegistPageModel -> Cmd RegistPageMsg
createUserRequest model =
    Http.post
        { url = "/api/user"
        , body = Http.jsonBody <| registModelEncoder model
        , expect = Http.expectJson GotRegistStatus userDecoder
        }
