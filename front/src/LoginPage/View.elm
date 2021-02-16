module LoginPage.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


view: (String, List (Html msg))
view =
    ( "loginpage"
    , [ div [ class "login" ]
        [ text "login"

        ]
      ]
    )
