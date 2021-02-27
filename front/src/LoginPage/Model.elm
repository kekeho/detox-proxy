-- Copyright (c) 2021 Hiroki Takemura (kekeho)

-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT

module LoginPage.Model exposing (..)

import Http
import Json.Encode as E

type alias LoginPageModel =
    { username: String
    , password: String
    , remember: Bool
    , result: Maybe (Result Http.Error ())
    }


initLoginPageModel : LoginPageModel
initLoginPageModel =
    LoginPageModel
        "" "" True Nothing



-- JSON Encoder

loginModelEncoder : LoginPageModel -> E.Value
loginModelEncoder model =
    E.object
        [ ("username", E.string model.username)
        , ("raw_password", E.string model.password)
        , ("remember", E.bool model.remember)
        ]
