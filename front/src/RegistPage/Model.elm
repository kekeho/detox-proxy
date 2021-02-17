module RegistPage.Model exposing (..)

import UserPage.Model exposing (..)
import Json.Encode as E
import Http


type alias RegistPageModel =
    { username: String
    , email: String
    , password: String
    , teamOfServiceAccept: Bool
    , result: Maybe (Result Http.Error User)
    }



-- FUNC

initModel : RegistPageModel
initModel =
    RegistPageModel
        ""
        ""
        ""
        False
        Nothing



-- Encoder

registModelEncoder : RegistPageModel -> E.Value
registModelEncoder model =
    E.object
        [ ("username", E.string model.username)
        , ("email", E.string model.email )
        , ("raw_password", E.string model.password)
        ]
