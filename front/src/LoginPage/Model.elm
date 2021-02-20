module LoginPage.Model exposing (..)

import Http
import Json.Encode as E

type alias LoginPageModel =
    { email: String
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
        [ ("email", E.string model.email)
        , ("raw_password", E.string model.password)
        , ("remember", E.bool model.remember)
        ]
