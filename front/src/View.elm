module View exposing (..)


import Html exposing (..)
import Html.Attributes exposing (..)


headerView: Html msg
headerView =
    header []
        [ div [ class "logo" ] [ text "detox-proxy" ]
        ]

