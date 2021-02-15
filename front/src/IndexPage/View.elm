module IndexPage.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


view: List (Html msg)
view =
    [ div [ class "index-top" ]
        [ img 
            [ src "/static/img/index-top-bg.svg" ]
            []
        ]
    ]

