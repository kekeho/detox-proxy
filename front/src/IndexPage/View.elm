module IndexPage.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


view: (String, List (Html msg))
view =
    ( "indexpage"
    , [ div [ class "index-top" ]
        [ img 
            [ src "/static/img/index-top-bg.svg" ]
            []
        , div [ ] [ text "サービスの説明とか" ]
        ]
      ]
    )

